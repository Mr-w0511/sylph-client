import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, FileMode, Platform;
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config/env.dart';

/// 崩溃监控上报（鸿蒙 3.0 闪退定位用）：
/// 1) 捕获 Flutter 框架异常 / 平台未捕获异常 / isolate 未捕获异常；
/// 2) 携带最近 20 条操作面包屑（进入扫码页、保存图片、启动前台服务等）
///    上报到后端 /api/client-logs（匿名，服务器落本地文件）；
/// 3) 上报失败（离线/后端未更新）时写入沙箱 crash_pending.log 兜底，
///    下次启动 5 秒后自动重发，成功即删除，保证离线崩溃日志不丢。
/// 注意：native 信号崩溃（SIGSEGV 等）Dart 层捕获不到，此时最后一条
/// 面包屑就是定位关键——说明崩溃发生在哪个操作之后。
/// 上传失败静默（离线/弱网不阻塞、不递归崩溃）。
class CrashReporter {
  CrashReporter._();
  static final CrashReporter instance = CrashReporter._();

  static const int _maxBreadcrumbs = 20;
  final List<String> _breadcrumbs = [];
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Env.apiBase,
    connectTimeout: const Duration(seconds: 8),
    sendTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));
  String? _version;
  int? _uid;
  String? _lastReportKey;
  DateTime _lastReportAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    unawaited(PackageInfo.fromPlatform().then((i) {
      _version = '${i.version}+${i.buildNumber}';
    }).onError((_, _) {}));
    // 启动后延迟重发上次失败时暂存的崩溃日志。
    unawaited(Future.delayed(const Duration(seconds: 5), _flushPending));

    // 1) Flutter 框架层异常（build/layout/手势回调里的异常）。
    FlutterError.onError = (details) {
      _report('flutter', details.exceptionAsString(),
          details.stack?.toString());
      // 保留原控制台输出，不影响开发调试。
      FlutterError.presentError(details);
    };
    // 2) Dart 平台层未捕获异常（主 isolate 顶层）。
    PlatformDispatcher.instance.onError = (error, stack) {
      _report('platform', error.toString(), stack.toString());
      debugPrint('Uncaught platform error: $error\n$stack');
      return true;
    };
    // 3) 其他 isolate 的未捕获异常。
    Isolate.current.addErrorListener(RawReceivePort((pair) {
      final list = pair as List<Object?>;
      _report('isolate', list[0]?.toString() ?? 'unknown isolate error',
          list[1]?.toString());
    }).sendPort);
  }

  /// 操作面包屑：在关键页面/关键插件调用处埋一行，用于还原崩溃前的操作路径。
  static void b(String tag) => instance._add(tag);

  /// 登录成功后注入当前用户 UID（服务器按 UID 分文件存储日志）；登出置空。
  static void setUid(int? uid) => instance._uid = uid;

  /// 已被业务层兜住的非致命异常（如坏头像降级显示），仍上报用于定位数据源。
  static void warn(String message) =>
      instance._report('handled', message, null);

  void _add(String tag) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    _breadcrumbs.add('$ts $tag');
    if (_breadcrumbs.length > _maxBreadcrumbs) _breadcrumbs.removeAt(0);
  }

  void _report(String source, String message, String? stack) {
    final tag = source == 'handled' ? 'WARN' : 'CRASH[$source]';
    _add('$tag ${message.split('\n').first}');
    final now = DateTime.now();
    final key = '$source|$message';
    // 同一错误 30 秒内只上报一次，防止崩溃-上报-崩溃死循环刷爆接口。
    if (key == _lastReportKey &&
        now.difference(_lastReportAt) < const Duration(seconds: 30)) {
      return;
    }
    _lastReportKey = key;
    _lastReportAt = now;
    unawaited(_send({
      'source': source,
      'message': message,
      'stack': stack,
      'breadcrumbs': List<String>.from(_breadcrumbs),
      'platform': defaultTargetPlatform.name,
      'debugMode': kDebugMode,
      'version': _version,
      'uid': _uid,
      'ts': now.toIso8601String(),
    }));
  }

  Future<void> _send(Map<String, dynamic> payload) async {
    try {
      await _dio.post<void>('/api/client-logs', data: payload);
    } catch (_) {
      // 上报失败写入沙箱兜底文件，下次启动重发（诊断通道绝不再抛异常）。
      await _stashPending(payload);
    }
  }

  Future<File> _pendingFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}crash_pending.log');
  }

  Future<void> _stashPending(Map<String, dynamic> payload) async {
    if (kIsWeb) return;
    try {
      final file = await _pendingFile();
      // 一行一条 JSON（jsonEncode 不产生换行），追加写入。
      await file.writeAsString('${jsonEncode(payload)}\n',
          mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  /// 启动后重发暂存日志：全部成功才删除文件；中途失败保留剩余部分。
  Future<void> _flushPending() async {
    if (kIsWeb) return;
    try {
      final file = await _pendingFile();
      if (!await file.exists()) return;
      final all = await file.readAsLines();
      final lines = all
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      var sentCount = 0;
      for (final line in lines) {
        try {
          await _dio.post<void>('/api/client-logs', data: jsonDecode(line));
          sentCount++;
        } catch (_) {
          break; // 网络仍不可用，本条及其后保留到下次。
        }
      }
      if (sentCount == lines.length) {
        await file.delete();
      } else {
        final remaining = lines.sublist(sentCount);
        await file.writeAsString('${remaining.join('\n')}\n', flush: true);
      }
    } catch (_) {}
  }
}
