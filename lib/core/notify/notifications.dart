// #14 手机系统通知：App 在后台时新消息通过系统通知栏提醒。
// 仅 Android/iOS 生效（web/desktop 由 kIsWeb/Platform 守卫跳过）。
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  Notifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 点击通知后的跳转回调（参数为会话 id），由 SylphApp 注入 goRouter。
  static void Function(int convId)? onTap;

  bool _initialized = false;

  static final Notifications instance = Notifications._();

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    // 桌面端（Windows/Linux/macOS 调试）不初始化，避免插件缺实现报错。
    if (!defaultTargetPlatform.supportsLocalNotifications) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
    );
    _initialized = true;
  }

  void _onResponse(NotificationResponse resp) {
    final payload = resp.payload;
    if (payload == null || payload.isEmpty) return;
    final convId = int.tryParse(payload);
    if (convId != null) onTap?.call(convId);
  }

  /// 登录后请求通知权限（Android 13+ / iOS）。
  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    if (!defaultTargetPlatform.supportsLocalNotifications) return;
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// 展示一条新消息通知。
  static Future<void> showMessage({
    required String title,
    required String body,
    required int convId,
  }) async {
    if (kIsWeb) return;
    if (!defaultTargetPlatform.supportsLocalNotifications) return;
    const androidDetails = AndroidNotificationDetails(
      'messages',
      '消息通知',
      channelDescription: '新消息提醒',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.message,
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id: convId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
          android: androidDetails, iOS: iosDetails),
      payload: '$convId',
    );
  }

  /// 语音来电通知（独立 calls 通道，铃声由 CallController 循环播放）。
  static Future<void> showCall({
    required String title,
    required String body,
    required int convId,
  }) async {
    if (kIsWeb) return;
    if (!defaultTargetPlatform.supportsLocalNotifications) return;
    const androidDetails = AndroidNotificationDetails(
      'calls',
      '通话通知',
      channelDescription: '语音通话来电与通话中状态',
      importance: Importance.max,
      priority: Priority.max,
      // 通话通知默认提示音 + 振动：之前 playSound=false，
      // 导致通话通知在系统通知栏静默，用户感知不到来电。
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      // Android 10+：APP 在后台/锁屏时把通话页直接拉到前台全屏。
      fullScreenIntent: true,
    );
    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    await _plugin.show(
      id: callNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
          android: androidDetails, iOS: iosDetails),
      payload: '$convId',
    );
  }

  /// 固定的来电通知 id。
  static const int callNotificationId = 911001;

  /// 取消指定会话（或任意指定 id）的通知：进入会话时清除该会话的未读通知。
  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    if (!defaultTargetPlatform.supportsLocalNotifications) return;
    await _plugin.cancel(id: id);
  }

  /// 冷启动是否由点击通知触发：返回通知载荷中的会话 id（非通知启动返回 null）。
  /// 在登录态就绪后调用一次即可。
  static Future<int?> getLaunchConversationId() async {
    if (kIsWeb) return null;
    if (!defaultTargetPlatform.supportsLocalNotifications) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      final payload = details!.notificationResponse?.payload;
      return payload == null ? null : int.tryParse(payload);
    } catch (_) {
      return null;
    }
  }
}

extension on TargetPlatform {
  bool get supportsLocalNotifications =>
      this == TargetPlatform.android || this == TargetPlatform.iOS;
}
