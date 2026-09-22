import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/monitor/crash_reporter.dart';
import 'core/notify/notifications.dart';
import 'core/service/foreground_service.dart';
import 'core/storage/kv_store.dart';
import 'core/storage/secure_store.dart';
import 'presentation/state/providers.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // 崩溃监控：尽早接管 Dart 层异常捕获（鸿蒙真机闪退定位）。
  CrashReporter.instance.init();
  CrashReporter.b('app main start');
  // 显式声明系统 UI 模式：状态栏/导航栏常驻（edgeToEdge 下透明绘制，
  // AppBar/SafeArea 自动避让）。防止 App 在全屏视频沉浸式状态下被系统
  // 杀死后重启、或其他异常路径继承了隐藏状态栏的窗口标志。
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  // 端到端加密：启用原生（BoringSSL）P-256/AES-GCM 实现。
  // 纯 Dart 端 ECDH/ECDSA P-256 会抛 UnimplementedError，必须切换实例。
  Cryptography.freezeInstance(FlutterCryptography.defaultInstance);
  // 自动化/无障碍：?semantics=1 时开启语义树（生产默认行为不变）。
  if (Uri.base.queryParameters['semantics'] == '1') {
    binding.ensureSemantics();
  }
  final kv = await KvStore.create();
  final secure = createSecureStore();
  // #14 系统通知初始化（web/桌面自动跳过）。
  await Notifications.instance.init();
  // Android 前台保活服务初始化（仅 Android 生效）。
  FgKeepAlive.init();

  runApp(ProviderScope(
    overrides: [
      kvProvider.overrideWithValue(kv),
      secureStoreProvider.overrideWithValue(secure),
    ],
    child: const SylphApp(),
  ));
}
