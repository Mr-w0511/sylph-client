import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/call/call_controller.dart';
import '../../core/call/group_call_controller.dart';
import '../../core/crypto/e2ee_service.dart';
import '../../core/db/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/network/ws_client.dart';
import '../../core/network/ws_frame.dart';
import '../../core/notify/notifications.dart';
import '../../core/monitor/crash_reporter.dart';
import '../../core/service/foreground_service.dart';
import '../../core/storage/kv_store.dart';
import '../../core/storage/secure_store.dart';
import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/misc_repositories.dart';
import '../../data/repositories/social_repositories.dart';
import '../../data/repositories/user_repository.dart';
import '../widgets/app_toast.dart';

/// 当前客户端平台标识（POST /api/auth/* 的 device.platform）。
/// web → 'WEB'，android → 'ANDROID'，ios → 'IOS'，其余（windows/macos/linux）→ 'WINDOWS'。
String get currentPlatform {
  if (kIsWeb) return 'WEB';
  if (Platform.isAndroid) return 'ANDROID';
  if (Platform.isIOS) return 'IOS';
  if (Platform.isWindows) return 'WINDOWS';
  if (Platform.isMacOS) return 'MACOS';
  if (Platform.isLinux) return 'LINUX';
  return 'WEB';
}

/// 当前设备友好名称（写登录设备列表）。
String get currentDeviceName {
  if (kIsWeb) return 'Flutter Web';
  if (Platform.isAndroid) return 'Android Device';
  if (Platform.isIOS) return 'iOS Device';
  if (Platform.isWindows) return 'Windows Desktop';
  if (Platform.isMacOS) return 'macOS Desktop';
  if (Platform.isLinux) return 'Linux Desktop';
  return 'Sylph Client';
}

// ---------------- 基础设施 ----------------

final kvProvider = Provider<KvStore>((_) => throw UnimplementedError());
final secureStoreProvider = Provider<SecureStore>(
  (_) => throw UnimplementedError(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.watch(secureStoreProvider));
  client.onAuthLost = () {
    // 401 刷新失败：微任务里清态，避免在请求构建期间触发状态变更。
    scheduleMicrotask(
      () => ref.read(sessionControllerProvider.notifier).handleAuthLost(),
    );
  };
  return client;
});

final databaseProvider = Provider<AppDatabase>((_) => AppDatabase());
final usersDaoProvider = Provider(
  (ref) => UsersDao(ref.watch(databaseProvider)),
);
final conversationsDaoProvider = Provider(
  (ref) => ConversationsDao(ref.watch(databaseProvider)),
);
final messagesDaoProvider = Provider(
  (ref) => MessagesDao(ref.watch(databaseProvider)),
);

final authRepoProvider = Provider(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
final userRepoProvider = Provider(
  (ref) => UserRepository(ref.watch(apiClientProvider)),
);
final conversationRepoProvider = Provider(
  (ref) => ConversationRepository(ref.watch(apiClientProvider)),
);
final groupRepoProvider = Provider(
  (ref) => GroupRepository(ref.watch(apiClientProvider)),
);
final mediaRepoProvider = Provider(
  (ref) => MediaRepository(ref.watch(apiClientProvider)),
);
final syncRepoProvider = Provider(
  (ref) => SyncRepository(ref.watch(apiClientProvider)),
);
final e2eeRepoProvider = Provider(
  (ref) => E2eeRepository(ref.watch(apiClientProvider)),
);
final socialRepoProvider = Provider(
  (ref) => SocialRepository(ref.watch(apiClientProvider)),
);
final contactsRepoProvider = Provider(
  (ref) => ContactsRepository(ref.watch(apiClientProvider)),
);
final feedbackRepoProvider = Provider(
  (ref) => FeedbackRepository(ref.watch(apiClientProvider)),
);
final callRepoProvider = Provider(
  (ref) => CallRepository(ref.watch(apiClientProvider)),
);

/// 社交事件节拍：好友申请/群邀请/群变更等 WS 事件到达时 +1，
/// 通讯录等页面 watch 此值即可自动刷新。
final socialTickProvider = StateProvider<int>((_) => 0);
final e2eeServiceProvider = Provider(
  (ref) =>
      E2eeService(ref.watch(secureStoreProvider), ref.watch(e2eeRepoProvider)),
);

// ---------------- 设置（语言 / 主题） ----------------

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;

  /// 主题种子色（ARGB 值，默认 Sylph 蓝）。
  final int seedColor;

  /// 聊天壁纸本地文件路径；null 表示默认壁纸。
  final String? wallpaperPath;

  /// 壁纸遮罩不透明度（0.25–0.85）。
  final double wallpaperOverlay;

  const AppSettings(
    this.locale,
    this.themeMode, {
    this.seedColor = 0xFF3B6EF6,
    this.wallpaperPath,
    this.wallpaperOverlay = 0.55,
  });

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    int? seedColor,
    // 显式包装以区分“不传”和“置空”。
    Object? wallpaperPath = _sentinel,
    double? wallpaperOverlay,
  }) => AppSettings(
    locale ?? this.locale,
    themeMode ?? this.themeMode,
    seedColor: seedColor ?? this.seedColor,
    wallpaperPath: wallpaperPath == _sentinel
        ? this.wallpaperPath
        : wallpaperPath as String?,
    wallpaperOverlay: wallpaperOverlay ?? this.wallpaperOverlay,
  );

  static const _sentinel = Object();
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final kv = ref.watch(kvProvider);
    const locale = Locale('zh');
    final mode = switch (kv.getString(KvStore.kThemeMode)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final loc = switch (kv.getString(KvStore.kLocale)) {
      'en' => const Locale('en'),
      'zh' => const Locale('zh'),
      _ => locale,
    };
    final seed = kv.getInt(KvStore.kThemeColor);
    final overlay = kv.getDouble(KvStore.kWallpaperOverlay);
    return AppSettings(
      loc,
      mode,
      seedColor: seed ?? 0xFF3B6EF6,
      wallpaperPath: kv.getString(KvStore.kWallpaper),
      wallpaperOverlay: overlay ?? 0.55,
    );
  }

  Future<void> setLocale(Locale locale) async {
    await ref.read(kvProvider).setString(KvStore.kLocale, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await ref.read(kvProvider).setString(KvStore.kThemeMode, value);
    state = state.copyWith(themeMode: mode);
  }

  /// 切换主题种子色。
  Future<void> setSeedColor(int color) async {
    await ref.read(kvProvider).setInt(KvStore.kThemeColor, color);
    state = state.copyWith(seedColor: color);
  }

  /// 设置/清除聊天壁纸路径（null 恢复默认）。
  Future<void> setWallpaper(String? path) async {
    final kv = ref.read(kvProvider);
    if (path == null) {
      await kv.remove(KvStore.kWallpaper);
    } else {
      await kv.setString(KvStore.kWallpaper, path);
    }
    state = state.copyWith(wallpaperPath: path);
  }

  /// 调整壁纸遮罩不透明度（限制在 0.25–0.85）。
  Future<void> setWallpaperOverlay(double value) async {
    final clamped = value.clamp(0.25, 0.85).toDouble();
    await ref.read(kvProvider).setDouble(KvStore.kWallpaperOverlay, clamped);
    state = state.copyWith(wallpaperOverlay: clamped);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

// ---------------- 会话状态 ----------------

enum AuthStatus { bootstrap, unauthenticated, authenticated }

class SessionState {
  final AuthStatus status;
  final AppUser? user;
  final String? deviceId;

  const SessionState({required this.status, this.user, this.deviceId});

  static const boot = SessionState(status: AuthStatus.bootstrap);
}

class SessionController extends Notifier<SessionState> {
  final _uuid = const Uuid();

  @override
  SessionState build() => SessionState.boot;

  Future<String> _deviceId() =>
      ref.read(kvProvider).ensureDeviceId(() => _uuid.v4());

  /// splash：有 token → /users/me 成功进主页，否则登录页。
  Future<void> bootstrap() async {
    final deviceId = await _deviceId();
    final api = ref.read(apiClientProvider);
    await api.hydrateTokens();
    if (api.accessTokenSync == null) {
      state = SessionState(
        status: AuthStatus.unauthenticated,
        deviceId: deviceId,
      );
      return;
    }
    try {
      final me = await ref.read(userRepoProvider).me();
      state = SessionState(
        status: AuthStatus.authenticated,
        user: me,
        deviceId: deviceId,
      );
      ref.read(realtimeProvider).start();
      _postAuthSetup();
    } catch (_) {
      await api.clearTokens();
      state = SessionState(
        status: AuthStatus.unauthenticated,
        deviceId: deviceId,
      );
    }
  }

  /// 登录 / 自动登录成功后的保活与预热（不阻塞主流程）。
  void _postAuthSetup() {
    // 崩溃日志按 UID 归档。
    CrashReporter.setUid(state.user?.id);
    // #14 通知权限（Android 13+ / iOS）。
    unawaited(Notifications.requestPermission());
    // Android 前台服务保活，尽量保证后台/锁屏仍能收消息。
    unawaited(FgKeepAlive.start());
    // E2EE：提前生成并上传公钥束，避免首次开私密会话时才准备导致失败。
    unawaited(ref
        .read(e2eeServiceProvider)
        .ensureBundleUploaded()
        .catchError((Object _) {}));
    // 电池优化白名单：仅首次登录后申请一次（系统页会打断用户，不重复弹），
    // 被拒绝不阻塞；MIUI/鸿蒙等厂商自启动设置由设置页入口手动放开。
    unawaited(_requestBatteryWhitelistOnce());
  }

  Future<void> _requestBatteryWhitelistOnce() async {
    try {
      final kv = ref.read(kvProvider);
      const key = 'fgs.battery_whitelist_req_v1';
      if (kv.getString(key) == '1') return;
      await kv.setString(key, '1');
      await FgKeepAlive.requestIgnoreBatteryOptimizations();
    } catch (_) {
      // 尽力而为，不影响登录流程。
    }
  }

  Future<void> login(String username, String password) async {
    final deviceId = await _deviceId();
    final pair = await ref
        .read(authRepoProvider)
        .login(
          username: username.trim(),
          password: password,
          device: DeviceInfo(
            deviceId: deviceId,
            platform: currentPlatform,
            deviceName: currentDeviceName,
          ),
        );
    await _applyLogin(deviceId, pair);
  }

  /// 发送邮箱验证码（不修改会话状态）。
  Future<void> sendEmailCode(String email) =>
      ref.read(authRepoProvider).sendEmailCode(email);

  /// 邮箱 + 验证码登录（主流程，未注册邮箱后端自动注册）。
  Future<void> loginByEmail(String email, String code) async {
    final deviceId = await _deviceId();
    final pair = await ref
        .read(authRepoProvider)
        .loginByEmail(
          email: email,
          code: code,
          device: DeviceInfo(
            deviceId: deviceId,
            platform: currentPlatform,
            deviceName: currentDeviceName,
          ),
        );
    await _applyLogin(deviceId, pair);
  }

  /// UID + 密码登录（次级流程）。
  Future<void> loginByUid(String uid, String password) async {
    final deviceId = await _deviceId();
    final pair = await ref
        .read(authRepoProvider)
        .loginByUid(
          uid: uid,
          password: password,
          device: DeviceInfo(
            deviceId: deviceId,
            platform: currentPlatform,
            deviceName: currentDeviceName,
          ),
        );
    await _applyLogin(deviceId, pair);
  }

  /// 首次设置初始密码（邮箱登录后引导用户主动设置）。
  Future<void> setInitialPassword(String password) =>
      ref.read(authRepoProvider).setInitialPassword(password);

  /// 修改密码（已设置过密码时使用）。
  Future<void> changePassword(String oldPassword, String newPassword) => ref
      .read(authRepoProvider)
      .changePassword(oldPassword: oldPassword, newPassword: newPassword);

  Future<void> _applyLogin(String deviceId, TokenPair pair) async {
    await ref
        .read(apiClientProvider)
        .saveTokens(pair.accessToken, pair.refreshToken);
    state = SessionState(
      status: AuthStatus.authenticated,
      user: pair.user,
      deviceId: deviceId,
    );
    // #14 登录后请求系统通知权限（Android 13+ / iOS）。
    // 启动 Android 前台服务保活，尽量保证后台/锁屏仍能收消息。
    // E2EE 公钥束预热 / 电池白名单申请。
    _postAuthSetup();
    ref.read(realtimeProvider).start();
  }

  Future<AppUser> register(String username, String password, String? nickname) {
    return ref
        .read(authRepoProvider)
        .register(
          username: username.trim(),
          password: password,
          nickname: nickname,
        );
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepoProvider).logout();
    } catch (_) {
      /* 本地态无论如何清掉 */
    }
    await _teardown();
  }

  /// 401 刷新失败 / 设备被远程下线。
  Future<void> handleAuthLost() async {
    if (state.status == AuthStatus.unauthenticated) return;
    await _teardown();
  }

  Future<void> _teardown() async {
    CrashReporter.setUid(null);
    ref.read(realtimeProvider).stop();
    await FgKeepAlive.stop();
    await ref.read(apiClientProvider).clearTokens();
    state = SessionState(
      status: AuthStatus.unauthenticated,
      deviceId: state.deviceId,
    );
  }

  void updateUser(AppUser user) {
    state = SessionState(
      status: state.status,
      user: user,
      deviceId: state.deviceId,
    );
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

// ---------------- 会话列表缓存流 ----------------

final conversationsStreamProvider = StreamProvider<List<Conversation>>((ref) {
  return ref.watch(conversationsDaoProvider).watchAll();
});

/// 群详情（含 myMutedUntil）；群成员变更/禁言广播时由 Realtime 失效刷新。
final groupDetailProvider = FutureProvider.autoDispose
    .family<GroupModel, int>((ref, convId) async {
  return ref.watch(groupRepoProvider).detail(convId);
});

/// 群成员列表（ACTIVE 过滤由使用方按需处理）：@提及/角色徽章复用。
final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMember>, int>((ref, convId) async {
  final all = await ref.watch(groupRepoProvider).members(convId);
  return all.where((m) => m.status == 'ACTIVE').toList();
});

/// 通讯录 tab 红点：待处理好友申请 + 待处理群邀请，扣除本地“已读” id。
/// 进入通讯录 tab 或拖除红点时调用 [markSeen]；之后新到的不同 id 会再次亮红点。
class ContactsBadgeNotifier extends AsyncNotifier<int> {
  static const _seenKey = 'contacts_badge_seen_ids_v1';
  Set<String> _pendingIds = const {};

  @override
  Future<int> build() async {
    ref.watch(socialTickProvider);
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
    try {
      final social = ref.read(socialRepoProvider);
      final group = ref.read(groupRepoProvider);
      final results = await Future.wait<dynamic>([
        social.incomingRequests(),
        group.invites(),
      ]);
      final friendReqs = results[0] as List<FriendRequestModel>;
      final groupInvites = results[1] as List<GroupRequestModel>;
      _pendingIds = {
        for (final r in friendReqs)
          if (r.status == 'PENDING') 'f${r.id}',
        for (final r in groupInvites)
          if (r.status == 'PENDING') 'g${r.id}',
      };
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_seenKey)?.toSet() ?? <String>{};
      return _pendingIds.difference(seen).length;
    } catch (_) {
      return 0;
    }
  }

  /// 将当前待处理项全部记为已读（红点清零，不影响申请/邀请本身的状态）。
  Future<void> markSeen() async {
    if (_pendingIds.isEmpty) {
      state = const AsyncData(0);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_seenKey)?.toSet() ?? <String>{};
      seen.addAll(_pendingIds);
      await prefs.setStringList(_seenKey, seen.toList());
    } catch (_) {/* 持久化失败仅本地置零 */}
    state = const AsyncData(0);
  }
}

final contactsBadgeProvider =
    AsyncNotifierProvider<ContactsBadgeNotifier, int>(
        ContactsBadgeNotifier.new);

/// “我的” tab 红点：意见反馈未读回复数（30s 轮询补偿）。
final feedbackUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
  try {
    return await ref.read(feedbackRepoProvider).unreadCount();
  } catch (_) {
    return 0;
  }
});

// ---------------- 实时编排（WS 帧 → DB / 同步 / 待发补发） ----------------

class Realtime with WidgetsBindingObserver {
  final Ref ref;
  WsClient? _ws;
  StreamSubscription<WsFrame>? _frameSub;
  StreamSubscription<WsStatus>? _statusSub;
  Timer? _convRefreshTimer;
  Timer? _readTimer;
  int? _pendingReadConvId;
  int? _pendingReadSeq;
  bool _syncing = false;

  /// 刚上报过已读的会话：服务端 list 的 unreadCount 可能尚未更新，
  /// refreshConversations 覆盖本地缓存时对这些会话短时强制 0，防止红点返回。
  final Map<int, DateTime> _justReadConvs = {};
  static const _justReadTtl = Duration(seconds: 6);

  /// 标记会话已读刚刚已上报（进入/离开聊天页、已读回执成功时调用）。
  void markJustRead(int convId) {
    _justReadConvs[convId] = DateTime.now();
  }

  bool _isJustRead(int convId) {
    final t = _justReadConvs[convId];
    if (t == null) return false;
    if (DateTime.now().difference(t) > _justReadTtl) {
      _justReadConvs.remove(convId);
      return false;
    }
    return true;
  }

  /// App 是否处于前台 resumed 状态：不活跃时收到消息只入库 + ACK，
  /// 不清红点、不上报已读，回到前台后在 [_onResumed] 里补处理。
  bool _appActive = true;

  /// inactive（权限弹窗/下拉通知栏/系统来电）宽限定时器：
  /// 1.5s 内回到 resumed 不视为后台，避免短暂失焦即弹系统通知。
  Timer? _inactiveGraceTimer;

  int? activeConvId;
  WsStatus wsStatus = WsStatus.disconnected;
  final statusController = StreamController<WsStatus>.broadcast();

  Realtime(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasActive = _appActive;
    _inactiveGraceTimer?.cancel();
    switch (state) {
      case AppLifecycleState.resumed:
        _appActive = true;
      case AppLifecycleState.inactive:
        // 短暂失焦：给 1.5s 宽限，超时仍未 resumed 才按后台处理。
        _inactiveGraceTimer =
            Timer(const Duration(milliseconds: 1500), () {
          _appActive = false;
        });
        return;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _appActive = false;
        return;
    }
    if (_appActive && !wasActive) {
      unawaited(_onResumed());
    }
  }

  /// 回到前台：无条件强制重建 WS（open 也重建，杀掉可能的 TCP 半开连接），
  /// 补发挂起的已读上报；当前打开的会话按本地 lastSeq 补报。
  Future<void> _onResumed() async {
    final ws = _ws;
    if (ws != null) {
      unawaited(ws.forceReconnect());
    }
    unawaited(_flushPendingRead());
    final convId = activeConvId;
    if (convId == null) return;
    final conv = await ref.read(conversationsDaoProvider).findById(convId);
    if (conv == null) return;
    if (conv.unreadCount > 0) {
      await ref.read(conversationsDaoProvider).zeroUnread(convId);
    }
    final lastSeq = conv.lastSeq;
    if (lastSeq != null && lastSeq > 0) {
      await reportRead(convId, lastSeq);
    }
  }

  void start() {
    if (_ws != null) return;
    WidgetsBinding.instance.addObserver(this);
    _appActive =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final client = WsClient(
      tokenProvider: () => ref.read(apiClientProvider).accessTokenSync ?? '',
      onReconnected: _onConnected,
      // #12 设备被远程下线/账号停用：服务端以 4001/4003 关闭 WS，
      // 客户端停止重连并立即清登录态，回到登录页（不再静默自动登录）。
      onFatalClose: (_) {
        unawaited(
            ref.read(sessionControllerProvider.notifier).handleAuthLost());
      },
    );
    _ws = client;
    _frameSub = client.frames.listen(_onFrame);
    _statusSub = client.statusStream.listen((s) {
      wsStatus = s;
      if (!statusController.isClosed) statusController.add(s);
    });
    client.start();
    // 冷启动：REST 增量同步 + 会话列表覆盖。
    unawaited(_fullSync());
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _appActive = true;
    _inactiveGraceTimer?.cancel();
    _frameSub?.cancel();
    _statusSub?.cancel();
    _convRefreshTimer?.cancel();
    // 退出前补发挂起的已读位点，再取消防抖定时器。
    unawaited(_flushPendingRead());
    _ws?.dispose();
    _ws = null;
    wsStatus = WsStatus.disconnected;
    if (!statusController.isClosed) {
      statusController.add(WsStatus.disconnected);
    }
  }

  bool get isConnected => _ws?.isOpen ?? false;

  /// 供聊天页发送：返回 false 表示离线，消息留在待发表，重连后补发。
  bool sendFrame(WsFrame frame) => _ws?.send(frame) ?? false;

  /// 跨会话发送（转发/名片等聊天页之外的入口复用同一条链路）：
  /// 本地先落 PENDING，再发 MSG_SEND；离线时由待发队列自动补发，
  /// 服务端 ACK 回来后按 msgId 幂等合并。媒体只透传 mediaUrl，不重新上传。
  Future<String> sendMessageTo({
    required int convId,
    required String type,
    String content = '',
    String? mediaUrl,
    String? mediaMeta,
    bool encrypted = false,
    String? msgId,
  }) async {
    final me = ref.read(sessionControllerProvider).user;
    if (me == null) throw StateError('not logged in');
    final id = msgId ?? const Uuid().v4().replaceAll('-', '');
    final now = DateTime.now();
    await ref.read(messagesDaoProvider).insertPending(
          MessagesCompanion.insert(
            msgId: id,
            convId: convId,
            senderId: me.id,
            type: type,
            content: Value(content),
            mediaUrl: Value(mediaUrl),
            mediaMeta: Value(mediaMeta),
            encrypted: Value(encrypted),
            clientStatus: const Value('PENDING'),
            createdAt: Value(now),
            updatedAt: now,
          ),
        );
    sendFrame(
      WsFrame(
        type: WsType.msgSend,
        msgId: id,
        convId: convId,
        data: {
          'type': type,
          'content': content,
          'mediaUrl': ?mediaUrl,
          'mediaMeta': ?_json(mediaMeta),
          'encrypted': encrypted,
        },
      ),
    );
    return id;
  }

  Future<void> _onConnected() async {
    await _flushOutbox();
    await _fullSync();
  }

  // ---- 待发补发（复用 msgId 幂等） ----
  Future<void> _flushOutbox() async {
    final client = _ws;
    if (client == null || !client.isOpen) return;
    final pending = await ref.read(messagesDaoProvider).pending();
    for (final m in pending) {
      client.send(
        WsFrame(
          type: WsType.msgSend,
          msgId: m.msgId,
          convId: m.convId,
          data: {
            'type': m.type,
            if (m.content != null) 'content': m.content,
            if (m.mediaUrl != null) 'mediaUrl': m.mediaUrl,
            if (m.mediaMeta != null) 'mediaMeta': _json(m.mediaMeta),
            'encrypted': m.encrypted,
          },
        ),
      );
    }
  }

  // ---- 增量同步（游标=消息全局 id，设备级，服务端记录） ----
  Future<void> _fullSync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final sync = ref.read(syncRepoProvider);
      // 优先用服务端设备游标；传 null 即由后端按设备记录续传。
      int? cursor;
      for (;;) {
        final SyncBatch batch;
        try {
          batch = await sync.pull(cursor: cursor, limit: 100);
        } catch (_) {
          break;
        }
        for (final m in batch.messages) {
          await _mergeMessage(m, 'SENT');
        }
        cursor = batch.nextCursor;
        if (!batch.hasMore) break;
      }
      await refreshConversations();
      // 同步完成后若有历史遗留待发，也补发一次。
      await _flushOutbox();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _onFrame(WsFrame frame) async {
    try {
      switch (frame.type) {
        case WsType.msgAck:
          final m = MessageModel.fromJson(frame.dataMap);
          await _mergeMessage(m, m.status == 'BLOCKED' ? 'FAILED' : 'SENT');
          _scheduleConversationRefresh();
          break;

        case WsType.msgDeliver:
          final m = MessageModel.fromJson(frame.dataMap);
          await _mergeMessage(m, 'SENT');
          // 回 ACK_DELIVERED（服务端不自动标记送达，需客户端回执）。
          _ws?.send(
            WsFrame(type: WsType.ackDelivered, convId: m.convId, seq: m.seq),
          );
          // App 在后台/非活跃时只入库与回执，不清红点、不上报已读，
          // 回到前台由 _onResumed 统一补处理。
          // #14 系统通知仅在 App 处于后台时弹（前台任何页面都不弹系统通知，
          // 避免应用内使用时被自己 App 的通知打扰；inactive 有 1.5s 宽限）。
          final meId = ref.read(sessionControllerProvider).user?.id;
          if (m.senderId != meId && !_appActive) {
            unawaited(_notifyMessage(m));
          }
          if (activeConvId == m.convId && m.seq != null && _appActive) {
            await ref.read(conversationsDaoProvider).zeroUnread(m.convId);
            _scheduleReadReport(m.convId, m.seq!);
          }
          _scheduleConversationRefresh();
          break;

        case WsType.ackDelivered:
          final d = frame.dataMap;
          final convId = (d['convId'] as num?)?.toInt();
          final seq = (d['seq'] as num?)?.toInt();
          final me = ref.read(sessionControllerProvider).user?.id;
          if (convId != null && seq != null && me != null) {
            await ref
                .read(messagesDaoProvider)
                .advanceMyStatus(
                  convId: convId,
                  toSeq: seq,
                  myUserId: me,
                  status: 'DELIVERED',
                );
          }
          break;

        case WsType.ackRead:
          final d = frame.dataMap;
          final convId = (d['convId'] as num?)?.toInt();
          final seq = (d['seq'] as num?)?.toInt();
          final me = ref.read(sessionControllerProvider).user?.id;
          if (convId != null && seq != null && me != null) {
            await ref
                .read(messagesDaoProvider)
                .advanceMyStatus(
                  convId: convId,
                  toSeq: seq,
                  myUserId: me,
                  status: 'READ',
                );
            _scheduleConversationRefresh();
          }
          break;

        case WsType.error:
          final refMsgId = frame.msgId;
          if (refMsgId != null) {
            await ref
                .read(messagesDaoProvider)
                .updateClientStatus(refMsgId, 'FAILED');
          }
          // #5 拉黑后明确文字提示：兼容后端 errorCode / code 两种字段名。
          final errData = frame.dataMap;
          final errorCode =
              (errData['errorCode'] as String?) ?? (errData['code'] as String?);
          final errMsg = (errData['message'] as String?) ?? '';
          if (errorCode == 'BLOCKED_BY_PEER') {
            AppToast.showError('您已被对方拉黑，消息未送达');
          } else if (errorCode == 'CONVERSATION_TERMINATED') {
            AppToast.showError('会话已终止，无法发送消息');
          } else if (errorCode == 'MEMBER_MUTED') {
            AppToast.showError('你已被禁言，暂时无法发送消息');
          } else if (errorCode == '40101') {
            // 设备被远程下线：清登录态并回到登录页。
            ref.read(sessionControllerProvider.notifier).handleAuthLost();
          } else if (errMsg.isNotEmpty) {
            AppToast.showError(errMsg);
          }
          break;

        case WsType.groupEvent:
          _bumpSocial();
          _scheduleConversationRefresh();
          // 成员变更/禁言广播：刷新对应群详情（禁言锁定条/角色即时生效）。
          final ge = frame.dataMap;
          final event = ge['event'] as String?;
          final gConvId = (ge['convId'] as num?)?.toInt();
          if (gConvId != null &&
              (event == 'MEMBERS_CHANGED' || event == 'MUTE')) {
            ref.invalidate(groupDetailProvider(gConvId));
            // #8/#10 成员角色/禁言/进出群变更后同步刷新成员列表页。
            ref.invalidate(groupMembersProvider(gConvId));
          }
          // 群资料变更（SETTINGS）：改名/换头像直接回写本地会话行，
          // 会话列表的群名与群头像即时生效。
          if (gConvId != null && event == 'SETTINGS') {
            final gName = (ge['name'] as String?) ?? '';
            final gAvatar = (ge['avatarUrl'] as String?) ?? '';
            await ref
                .read(conversationsDaoProvider)
                .updateGroupMeta(
                  gConvId,
                  title: gName.isEmpty ? null : gName,
                  avatarUrl: gAvatar.isEmpty ? null : gAvatar,
                );
            ref.invalidate(groupDetailProvider(gConvId));
          }
          break;

        case WsType.friendEvent:
          // 好友申请/接受/拒绝/删除：刷新通讯录 + 会话列表（接受会建单聊）。
          _bumpSocial();
          _scheduleConversationRefresh();
          break;

        case WsType.msgEvent:
          await _onMessageEvent(frame.dataMap);
          _scheduleConversationRefresh();
          break;

        case WsType.callSignal:
          // 群多人语音事件（g_ 前缀）交给群通话状态机，其余为 1v1 通话。
          final ev = frame.dataMap['event'];
          if (ev is String && ev.startsWith('g_')) {
            unawaited(
                ref.read(groupCallControllerProvider).handleSignal(frame));
          } else {
            unawaited(ref.read(callControllerProvider).handleSignal(frame));
          }
          break;
      }
    } catch (_) {
      // 单帧处理失败不影响连接。
    }
  }

  Future<void> _mergeMessage(MessageModel m, String fallback) async {
    await ref
        .read(messagesDaoProvider)
        .upsertRemote(
          msgId: m.msgId,
          globalId: m.id,
          convId: m.convId,
          senderId: m.senderId,
          type: m.type,
          content: m.content,
          mediaUrl: m.mediaUrl,
          mediaMeta: m.mediaMeta,
          seq: m.seq,
          encrypted: m.encrypted,
          serverStatus: m.status,
          createdAt: m.createdAt,
          fallbackClientStatus: fallback,
        );
  }

  /// #14 新消息系统通知：标题=对端昵称/群名，正文按消息类型降级。
  /// 加密消息（密文本地不可读）显示占位文案；免打扰会话跳过。
  Future<void> _notifyMessage(MessageModel m) async {
    try {
      final conv = await ref.read(conversationsDaoProvider).findById(m.convId);
      if (conv == null || conv.muted) return;
      final String body;
      if (m.encrypted) {
        body = '[加密消息]';
      } else {
        body = switch (m.type) {
          'TEXT' => (m.content != null && m.content!.isNotEmpty)
              ? m.content!
              : '[消息]',
          'IMAGE' => '[图片]',
          'VOICE' => '[语音]',
          'VIDEO' => '[视频]',
          'FILE' => '[文件]',
          'LOCATION' => '[位置]',
          'MUSIC' => '[音乐]',
          'CALL' => '[语音通话]',
          'SYSTEM' => m.content ?? '[系统消息]',
          _ => '[消息]',
        };
      }
      final title = conv.type == 'SINGLE'
          ? (conv.peerNickname ?? '新消息')
          : (conv.title ?? '群聊');
      // 群聊带发送者前缀（系统消息本身已含完整描述，不加前缀）。
      final prefixed = (conv.type != 'SINGLE' && m.type != 'SYSTEM')
          ? '${m.senderNickname ?? ''}: $body'
          : body;
      await Notifications.showMessage(
        title: title,
        body: prefixed,
        convId: m.convId,
      );
    } catch (_) {
      // 通知失败不影响消息处理主流程。
    }
  }

  void _scheduleReadReport(int convId, int seq) {
    _pendingReadConvId = convId;
    _pendingReadSeq = seq;
    _readTimer?.cancel();
    _readTimer = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(_flushPendingRead()),
    );
  }

  /// 立即补发挂起的已读位点（取最新一条，只报一次；失败吞掉）。
  Future<void> _flushPendingRead() async {
    _readTimer?.cancel();
    final convId = _pendingReadConvId;
    final seq = _pendingReadSeq;
    _pendingReadConvId = null;
    _pendingReadSeq = null;
    if (convId == null || seq == null) return;
    try {
      await ref.read(conversationRepoProvider).markRead(convId, seq: seq);
    } catch (_) {
      /* 防抖补发失败直接放弃 */
    }
  }

  /// 进入聊天页：同步设置当前会话标记，并立刻撤销该会话已弹出的系统通知
  /// （用户正在看这个会话，通知继续留在通知栏没有意义）。
  Future<void> setActiveConversation(int convId) async {
    activeConvId = convId;
    unawaited(Notifications.cancel(convId));
  }

  /// 离开聊天页：先补发挂起的已读，再清除当前会话标记。
  /// 补发成功后再次本地清零并刷新（#9 覆盖快速进出会话时红点残留的竞态）。
  Future<void> clearActiveConversation() async {
    final id = activeConvId;
    await _flushPendingRead();
    activeConvId = null;
    if (id != null) {
      await ref.read(conversationsDaoProvider).zeroUnread(id);
      markJustRead(id);
      unawaited(refreshConversations());
    }
  }

  /// 进入聊天页时立即上报已读；失败延迟 1.5s 重试一次，再失败放弃。
  Future<void> reportRead(int convId, int seq) async {
    await ref.read(conversationsDaoProvider).zeroUnread(convId);
    markJustRead(convId);
    final repo = ref.read(conversationRepoProvider);
    try {
      await repo.markRead(convId, seq: seq);
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      try {
        await repo.markRead(convId, seq: seq);
      } catch (_) {
        /* 重试仍失败，放弃 */
      }
    }
  }

  void _bumpSocial() {
    if (ref.exists(socialTickProvider)) {
      ref.read(socialTickProvider.notifier).state++;
    }
  }

  /// 管理端处置消息（MSG_EVENT: RECALLED / REMOVED）。
  Future<void> _onMessageEvent(Map<String, dynamic> d) async {
    final event = d['event'] as String?;
    if (event == null) return;
    final msgId = d['msgId'] as String?;
    final dao = ref.read(messagesDaoProvider);
    switch (event) {
      case 'RECALLED':
        if (msgId != null) {
          final by = (d['by'] as num?)?.toInt();
          final byAdmin = d['byAdmin'] == true;
          await dao.markRecalled(msgId, by: by, byAdmin: byAdmin);
          // 同步会话列表最后消息预览（仅当撤回的是最后一条时生效）。
          final local = await dao.byMsgId(msgId);
          if (local != null) {
            await ref
                .read(conversationsDaoProvider)
                .markLastRecalled(local.convId, msgId);
          }
          _scheduleConversationRefresh();
        }
        break;
      case 'REMOVED':
        if (msgId != null) await dao.removeByMsgId(msgId);
        break;
    }
  }

  void _scheduleConversationRefresh() {
    _convRefreshTimer?.cancel();
    _convRefreshTimer = Timer(
      const Duration(milliseconds: 500),
      refreshConversations,
    );
  }

  /// GET /api/conversations 覆盖本地缓存。
  Future<void> refreshConversations() async {
    try {
      final list = await ref.read(conversationRepoProvider).list();
      final convDao = ref.read(conversationsDaoProvider);
      final userDao = ref.read(usersDaoProvider);
      final now = DateTime.now();
      // #4 终止会话后服务端不再返回该会话，清理本地残留避免列表仍显示。
      final validIds = list.map((c) => c.id).toSet();
      await convDao.deleteAbsent(validIds);
      await convDao.upsertAll(
        list.map((c) {
          final last = c.lastMessage;
          // 正在打开 / 刚上报已读的会话：未读数强制清零，
          // 避免同步覆盖本地已读状态（服务端位点生效有延迟）。
          final unread = (c.id == activeConvId || _isJustRead(c.id))
              ? 0
              : c.unreadCount;
          return ConversationsCompanion.insert(
            id: Value(c.id),
            type: c.type,
            title: Value(c.title),
            peerUserId: Value(c.peer?.userId),
            // #7 备注展示同步：会话列表展示名优先 peer.remark，其次 peer.nickname。
            peerNickname: Value(c.peer?.displayName),
            peerAvatarUrl: Value(c.peer?.avatarUrl),
            // #11 群头像由服务端会话列表直接下发，同步回本地。
            groupAvatarUrl: Value(c.groupAvatarUrl),
            unreadCount: Value(unread),
            lastSeq: Value(c.lastSeq),
            muted: Value(c.muted),
            privateFlag: Value(c.privateFlag),
            dissolved: Value(c.dissolved),
            pinned: Value(c.pinned),
            pinnedAt: Value(c.pinnedAt),
            lastMsgId: Value(last?.msgId),
            // 撤回消息的最后一条：列表统一显示"撤回了一条消息"。
            lastMsgType: Value(last?.status == 'RECALLED'
                ? 'RECALLED'
                : last?.type),
            lastMsgContent: Value(
                last?.status == 'RECALLED' ? null : last?.content),
            lastMsgSender: Value(last?.senderId),
            lastMsgEncrypted: Value(last?.encrypted ?? false),
            lastMsgTime: Value(last?.createdAt ?? c.updatedAt),
            updatedAt: c.updatedAt ?? now,
          );
        }),
      );
      for (final c in list) {
        final p = c.peer;
        if (p != null) {
          await userDao.upsert(
            UsersCompanion.insert(
              id: Value(p.userId),
              username: p.nickname ?? 'u${p.userId}',
              nickname: p.nickname ?? '',
              avatarUrl: Value(p.avatarUrl),
              updatedAt: now,
            ),
          );
        }
      }
    } catch (_) {
      /* 弱网静默，缓存继续展示 */
    }
  }

  static Object? _json(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}

final realtimeProvider = Provider<Realtime>((ref) => Realtime(ref));

/// #11 全局语音通话状态机（单例 ChangeNotifier，由 Realtime 喂信令帧）。
final callControllerProvider =
    ChangeNotifierProvider<CallController>((ref) => CallController(ref));

/// #7 群多人语音通话状态机（g_* 信令，Mesh P2P）。
final groupCallControllerProvider =
    ChangeNotifierProvider<GroupCallController>(
        (ref) => GroupCallController(ref));
