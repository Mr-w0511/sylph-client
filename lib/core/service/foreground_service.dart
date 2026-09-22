// Android 前台服务保活：把进程提升为前台优先级，WS 长连接与心跳
// 在应用退后台/锁屏后尽量不被系统挂起，从而继续收消息并弹通知。
// 注意：App 被彻底划掉/强杀后仍无法收消息，那需要 FCM/厂商推送通道。
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../monitor/crash_reporter.dart';

class FgKeepAlive {
  FgKeepAlive._();

  static bool _initialized = false;
  static bool _requested = false;
  static bool _callMode = false;

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  static void init() {
    if (!_supported || _initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sylph_keepalive',
        channelName: '后台连接',
        channelDescription: '保持消息实时接收',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  /// 登录成功后调用：幂等启动。使用 remoteMessaging 类型——
  /// Android 14+ 下 dataSync 每天有 6 小时上限，而 IM 长连接无此限制。
  static Future<void> start() async {
    if (!_supported || !_initialized || _requested) return;
    _requested = true;
    CrashReporter.b('FGS start begin');
    try {
      if (await FlutterForegroundTask.isRunningService) return;
      final result = await FlutterForegroundTask.startService(
        serviceTypes: const [ForegroundServiceTypes.remoteMessaging],
        notificationTitle: 'Sylph',
        notificationText: '正在保持消息连接',
        callback: _keepAliveEntryPoint,
      );
      CrashReporter.b('FGS start done');
      if (result is ServiceRequestFailure) {
        debugPrint('FgKeepAlive start failed: ${result.error}');
      }
    } catch (e) {
      CrashReporter.b('FGS start error: $e');
      debugPrint('FgKeepAlive start error: $e');
      _requested = false; // 失败允许下次登录重试
    }
  }

  /// 进入语音通话：叠加 microphone 前台服务类型。
  /// 调用方必须已获得 RECORD_AUDIO 运行时权限，否则 Android 14+ 会抛异常。
  static Future<void> enterCallMode() async {
    if (!_supported || !_initialized || _callMode) return;
    _callMode = true;
    try {
      await _restartWithTypes(const [
        ForegroundServiceTypes.remoteMessaging,
        ForegroundServiceTypes.microphone,
      ], 'Sylph', '正在进行语音通话');
    } catch (e) {
      debugPrint('FgKeepAlive enterCallMode error: $e');
    }
  }

  /// 进入视频通话：叠加 camera + microphone 前台服务类型。
  /// 调用方必须已获得 CAMERA/RECORD_AUDIO 运行时权限，否则 Android 14+ 会抛异常。
  static Future<void> enterVideoCallMode() async {
    if (!_supported || !_initialized || _callMode) return;
    _callMode = true;
    try {
      await _restartWithTypes(const [
        ForegroundServiceTypes.remoteMessaging,
        ForegroundServiceTypes.microphone,
        ForegroundServiceTypes.camera,
      ], 'Sylph', '正在进行视频通话');
    } catch (e) {
      debugPrint('FgKeepAlive enterVideoCallMode error: $e');
    }
  }

  /// 通话结束：恢复为仅 remoteMessaging。
  static Future<void> exitCallMode() async {
    if (!_supported || !_initialized) return;
    _callMode = false;
    try {
      await _restartWithTypes(const [ForegroundServiceTypes.remoteMessaging],
          'Sylph', '正在保持消息连接');
    } catch (e) {
      debugPrint('FgKeepAlive exitCallMode error: $e');
    }
  }

  static Future<void> _restartWithTypes(
      List<ForegroundServiceTypes> types, String title, String text) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    final result = await FlutterForegroundTask.startService(
      serviceTypes: types,
      notificationTitle: title,
      notificationText: text,
      callback: _keepAliveEntryPoint,
    );
    if (result is ServiceRequestFailure) {
      debugPrint('FgKeepAlive restart($types) failed: ${result.error}');
    }
  }

  /// 申请电池优化白名单（REQUEST_IGNORE_BATTERY_OPTIMIZATIONS）。
  /// 被拒绝不阻塞业务；MIUI/鸿蒙等厂商还需用户手动在自启动管理放开。
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!_supported || !_initialized) return;
    try {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } catch (e) {
      debugPrint('requestIgnoreBatteryOptimization error: $e');
    }
  }

  /// 退出登录时调用。
  static Future<void> stop() async {
    if (!_supported || !_initialized) return;
    _requested = false;
    _callMode = false;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('FgKeepAlive stop error: $e');
    }
  }
}

/// 后台 isolate 入口：保活服务本身不做任何业务，只负责持有前台服务身份。
@pragma('vm:entry-point')
void _keepAliveEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveTaskHandler());
}

class _KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
