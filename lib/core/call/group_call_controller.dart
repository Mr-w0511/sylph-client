import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../notify/notifications.dart';
import '../network/ws_frame.dart';
import '../service/foreground_service.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/features/call/mini_call_pill.dart';
import '../../presentation/router/app_router.dart';
import '../../presentation/state/providers.dart';
import '../../presentation/widgets/app_toast.dart';
import 'webrtc_engine.dart';

/// 群通话阶段：空闲 / 来电响铃 / 房间内 / 结束。
enum GroupCallPhase { idle, ringing, inRoom, ended }

/// 群通话成员（名单由服务器 g_roster 权威下发）。
class GroupCallMember {
  final int id;
  final String name;
  final String? avatar;
  bool micOn;

  GroupCallMember({
    required this.id,
    required this.name,
    this.avatar,
    this.micOn = true,
  });
}

/// #7 群多人语音全局状态机：CALL_SIGNAL(g_*) 信令 + Mesh P2P 音频。
/// 与 1v1 CallController 完全独立：每个对端一条 PeerConnection（≤7 条），
/// 老成员→新成员单向发 offer 防 glare；服务器只转发 JSON。
class GroupCallController extends ChangeNotifier {
  GroupCallController(this._ref);

  final Ref _ref;
  final Uuid _uuid = const Uuid();

  GroupCallPhase _phase = GroupCallPhase.idle;
  GroupCallPhase get phase => _phase;

  String? _callId;
  int? _convId;
  String _groupName = '';
  String? _groupAvatar;
  String? _endReason;
  String? get endReason => _endReason;

  String get groupName => _groupName;
  String? get groupAvatar => _groupAvatar;
  String? get callId => _callId;
  int? get convId => _convId;

  /// 响铃邀请人。
  int? _inviterId;
  String _inviterName = '';
  String? _inviterAvatar;
  int? get inviterId => _inviterId;
  String get inviterName => _inviterName;
  String? get inviterAvatar => _inviterAvatar;

  final LinkedHashMap<int, GroupCallMember> _members = LinkedHashMap();
  List<GroupCallMember> get members => _members.values.toList(growable: false);

  bool _micOn = true;
  // 群语音默认扬声器外放。
  bool _speakerOn = true;
  bool get micOn => _micOn;
  bool get speakerOn => _speakerOn;

  bool get isActive =>
      _phase == GroupCallPhase.ringing || _phase == GroupCallPhase.inRoom;
  bool get isRinging => _phase == GroupCallPhase.ringing;
  bool get isInRoom => _phase == GroupCallPhase.inRoom;

  DateTime? _joinedAt;
  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Timer? _tickTimer;
  Timer? _ringToneTimer;

  final Map<int, WebRtcAudioEngine> _engines = {};
  // ignore: unused_field
  final Map<int, rtc.MediaStream> _remoteStreams = {};
  final Map<int, List<Map<String, dynamic>>> _pendingCandidates = {};
  final Set<int> _remoteDescriptionReady = {};
  final Set<int> _offering = <int>{};

  OverlayEntry? _overlay;
  bool _routeOpen = false;

  int get _meId => _ref.read(sessionControllerProvider).user?.id ?? -1;

  String get _myName =>
      _ref.read(sessionControllerProvider).user?.nickname ?? '#$_meId';
  String? get _myAvatar =>
      _ref.read(sessionControllerProvider).user?.avatarUrl;

  // ---------------- 发起者 ----------------

  Future<void> startRoom(int convId) async {
    if (isActive) return;
    if (_ref.read(callControllerProvider).isActive) {
      final l = await _loadL();
      _toast(l.groupCallBusy);
      return;
    }
    if (!kIsWeb && !await Permission.microphone.request().isGranted) {
      final l = await _loadL();
      _toast(l.callMicPermissionDenied);
      return;
    }
    final conv =
        await _ref.read(conversationsDaoProvider).findById(convId);
    if (conv == null) return;

    _callId = _uuid.v4().replaceAll('-', '');
    _convId = convId;
    _groupName = conv.title ?? '';
    _groupAvatar = conv.groupAvatarUrl;
    _micOn = true;
    _speakerOn = true;
    _members.clear();
    _members[_meId] = GroupCallMember(
      id: _meId,
      name: _myName,
      avatar: _myAvatar,
    );
    _phase = GroupCallPhase.inRoom;
    _joinedAt = DateTime.now();
    notifyListeners();
    _openRoute();
    unawaited(FgKeepAlive.enterCallMode());
    _startTick();
    _send('g_start', {'convId': convId});
  }

  // ---------------- 响铃者 ----------------

  Future<void> acceptRing() async {
    if (_phase != GroupCallPhase.ringing) return;
    _stopRingTone();
    unawaited(Notifications.cancel(Notifications.callNotificationId));
    if (!kIsWeb && !await Permission.microphone.request().isGranted) {
      _send('g_decline', {'convId': _convId});
      await _teardown('no_permission', joined: false);
      return;
    }
    _phase = GroupCallPhase.inRoom;
    _joinedAt = DateTime.now();
    _members[_meId] = GroupCallMember(
      id: _meId,
      name: _myName,
      avatar: _myAvatar,
    );
    notifyListeners();
    unawaited(FgKeepAlive.enterCallMode());
    _startTick();
    // 进入房间后等老成员的 offer（g_sdp），自己作为新成员不主动发 offer。
    _send('g_accept', {'convId': _convId});
  }

  Future<void> declineRing() async {
    if (_phase != GroupCallPhase.ringing) return;
    _send('g_decline', {'convId': _convId});
    await _teardown(null, joined: false);
  }

  // ---------------- 通话中控制 ----------------

  Future<void> toggleMic() async {
    _micOn = !_micOn;
    for (final e in _engines.values) {
      await e.setMicEnabled(_micOn);
    }
    final me = _members[_meId];
    if (me != null) me.micOn = _micOn;
    _send('g_mic', {'convId': _convId, 'micOn': _micOn});
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    for (final e in _engines.values) {
      await e.applyAudioRoute(_speakerOn);
    }
    notifyListeners();
  }

  Future<void> hangUp() async {
    if (_phase == GroupCallPhase.inRoom) {
      _send('g_leave', {'convId': _convId});
    }
    await _teardown('normal', joined: _phase == GroupCallPhase.inRoom);
  }

  // ---------------- 信令入口 ----------------

  Future<void> handleSignal(WsFrame frame) async {
    final d = frame.dataMap;
    final event = d['event'] as String?;
    if (event == null) return;

    if (event == 'error') {
      final code = d['code'] as String? ?? 'failed';
      final cid = d['callId'] as String?;
      // 只处理与当前会话相关或响铃发起阶段的错误。
      if (_callId != null && cid != null && cid != _callId) return;
      final l = await _loadL();
      final msg = switch (code) {
        'ROOM_FULL' => l.groupCallFull,
        'BUSY' => l.groupCallBusy,
        'CALLER_BUSY' => l.groupCallBusy,
        'NOT_MEMBER' => l.groupCallNotMember,
        _ => l.groupCallEnded,
      };
      _toast(msg);
      await _teardown(code, joined: _phase == GroupCallPhase.inRoom);
      return;
    }

    final callId = d['callId'] as String?;
    final from = (d['from'] as num?)?.toInt();

    if (event == 'g_ring') {
      if (from == null || from == _meId) return;
      // 忙线（1v1 通话/其他群通话）：自动拒绝。
      if (_ref.read(callControllerProvider).isActive || isActive) {
        _ref.read(realtimeProvider).sendFrame(WsFrame(
              type: WsType.callSignal,
              data: {
                'event': 'g_decline',
                'callId': callId,
                'convId': (d['convId'] as num?)?.toInt(),
              },
            ));
        return;
      }
      _resetRinging(
        callId: callId,
        convId: (d['convId'] as num?)?.toInt(),
        inviterId: from,
        inviterName: (d['fromName'] as String?) ?? '#$from',
        inviterAvatar: d['fromAvatar'] as String?,
        groupName: (d['groupName'] as String?) ?? '',
      );
      _openRoute();
      _startRingTone();
      final l = await _loadL();
      unawaited(Notifications.showCall(
        title: _inviterName,
        body: l.incomingGroupCall,
        convId: _convId ?? 0,
      ));
      return;
    }

    // 其余事件必须匹配当前房间。
    if (callId == null || callId != _callId) return;

    try {
      switch (event) {
        case 'g_roster':
          _mergeRoster(d['members'] as List<dynamic>? ?? const []);
          break;
        case 'g_newpeer':
          final peer = d['peer'] as Map<String, dynamic>?;
          final id = (peer?['id'] as num?)?.toInt();
          if (id != null && id != _meId) {
            _upsertMember(
              id,
              (peer?['name'] as String?) ?? '#$id',
              peer?['avatar'] as String?,
              micOn: true,
            );
            unawaited(_offerToNewPeer(id));
          }
          break;
        case 'g_sdp':
          if (from != null && from != _meId) {
            await _handleSdp(
                from, d['type'] as String? ?? '', d['sdp'] as String? ?? '');
          }
          break;
        case 'g_ice':
          if (from != null && from != _meId) {
            _handleRemoteIce(from, d);
          }
          break;
        case 'g_mic':
          if (from != null) {
            final m = _members[from];
            if (m != null) {
              m.micOn = d['micOn'] == true;
              notifyListeners();
            }
          }
          break;
        case 'g_decline':
          // 有人拒绝（仅发起者收到）：不做强制 UI 变化。
          break;
        case 'g_leave':
          final id = (d['id'] as num?)?.toInt();
          if (id != null) {
            _members.remove(id);
            await _closePeer(id);
            notifyListeners();
          }
          break;
        case 'g_cancel':
          // 发起者取消 / 45s 超时 / 房间销毁。
          unawaited(Notifications.cancel(Notifications.callNotificationId));
          await _teardown(d['reason'] as String? ?? 'canceled',
              joined: _phase == GroupCallPhase.inRoom);
          break;
      }
    } catch (e) {
      debugPrint('group call signal error: $e');
    }
  }

  // ---------------- Mesh 连接管理 ----------------

  Future<WebRtcAudioEngine> _createEngine(int peerId) async {
    final engine = WebRtcAudioEngine();
    _engines[peerId] = engine;
    engine.onLocalCandidate = (c) {
      _send('g_ice', {
        'convId': _convId,
        'to': peerId,
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex,
      });
    };
    engine.onRemoteStream = (s) {
      _remoteStreams[peerId] = s;
    };
    engine.onFailed = () {
      debugPrint('group call peer $peerId ICE failed');
    };
    await engine.init(() => _ref.read(callRepoProvider).iceServers());
    await engine.applyAudioRoute(_speakerOn);
    return engine;
  }

  /// 老成员收到 g_newpeer：对新成员单向 createOffer（防 glare 规则）。
  Future<void> _offerToNewPeer(int peerId) async {
    if (_engines.containsKey(peerId) || _offering.contains(peerId)) return;
    _offering.add(peerId);
    try {
      final engine = await _createEngine(peerId);
      final offer = await engine.createOffer();
      _send('g_sdp', {
        'convId': _convId,
        'to': peerId,
        'type': 'offer',
        'sdp': offer.sdp,
      });
    } catch (e) {
      debugPrint('offer to new peer $peerId error: $e');
      await _closePeer(peerId);
    } finally {
      _offering.remove(peerId);
    }
  }

  Future<void> _handleSdp(int from, String type, String sdp) async {
    var engine = _engines[from];
    if (type == 'offer') {
      // 新成员收到老成员的 offer。
      engine ??= await _createEngine(from);
      await engine.setRemoteSdp(sdp, 'offer');
      _remoteDescriptionReady.add(from);
      await _flushCandidates(from, engine);
      final answer = await engine.createAnswer();
      _send('g_sdp', {
        'convId': _convId,
        'to': from,
        'type': 'answer',
        'sdp': answer.sdp,
      });
    } else if (type == 'answer') {
      if (engine == null) return;
      await engine.setRemoteSdp(sdp, 'answer');
      _remoteDescriptionReady.add(from);
      await _flushCandidates(from, engine);
    }
  }

  void _handleRemoteIce(int from, Map<String, dynamic> d) {
    final cand = <String, dynamic>{
      'candidate': d['candidate'],
      'sdpMid': d['sdpMid'],
      'sdpMLineIndex': d['sdpMLineIndex'],
    };
    final engine = _engines[from];
    if (engine != null && _remoteDescriptionReady.contains(from)) {
      engine.addRemoteCandidate(cand);
    } else {
      _pendingCandidates.putIfAbsent(from, () => []).add(cand);
    }
  }

  Future<void> _flushCandidates(int from, WebRtcAudioEngine engine) async {
    final list = _pendingCandidates.remove(from) ?? const [];
    for (final c in list) {
      await engine.addRemoteCandidate(c);
    }
  }

  Future<void> _closePeer(int peerId) async {
    final e = _engines.remove(peerId);
    _remoteStreams.remove(peerId);
    _pendingCandidates.remove(peerId);
    _remoteDescriptionReady.remove(peerId);
    _offering.remove(peerId);
    if (e != null) {
      await e.resetAudioMode();
      await e.dispose();
    }
  }

  // ---------------- 名单 ----------------

  void _mergeRoster(List<dynamic> raw) {
    final latest = <int, GroupCallMember>{};
    for (final r in raw) {
      if (r is Map<String, dynamic>) {
        final id = (r['id'] as num?)?.toInt();
        if (id == null) continue;
        final old = _members[id];
        latest[id] = GroupCallMember(
          id: id,
          name: (r['name'] as String?) ?? old?.name ?? '#$id',
          avatar: r['avatar'] as String? ?? old?.avatar,
          micOn: r['micOn'] != false,
        );
      }
    }
    // 关掉已不在房间的对端连接。
    for (final id in _members.keys.toList()) {
      if (!latest.containsKey(id) && id != _meId) {
        unawaited(_closePeer(id));
      }
    }
    _members
      ..clear()
      ..addAll(latest);
    notifyListeners();
  }

  void _upsertMember(int id, String name, String? avatar,
      {required bool micOn}) {
    final existing = _members[id];
    if (existing != null) return;
    _members[id] = GroupCallMember(id: id, name: name, avatar: avatar);
    notifyListeners();
  }

  // ---------------- 状态/清理 ----------------

  void _resetRinging({
    required String? callId,
    required int? convId,
    required int inviterId,
    required String inviterName,
    required String? inviterAvatar,
    required String groupName,
  }) {
    _callId = callId ?? _uuid.v4().replaceAll('-', '');
    _convId = convId;
    _groupName = groupName;
    _inviterId = inviterId;
    _inviterName = inviterName;
    _inviterAvatar = inviterAvatar;
    _endReason = null;
    _duration = Duration.zero;
    _joinedAt = null;
    _micOn = true;
    _speakerOn = true;
    _members.clear();
    _phase = GroupCallPhase.ringing;
    notifyListeners();
  }

  Future<void> _teardown(String? reason, {required bool joined}) async {
    _ringToneTimer?.cancel();
    _tickTimer?.cancel();
    unawaited(Notifications.cancel(Notifications.callNotificationId));
    unawaited(FgKeepAlive.exitCallMode());

    final peerIds = _engines.keys.toList();
    for (final id in peerIds) {
      await _closePeer(id);
    }
    _remoteStreams.clear();
    _pendingCandidates.clear();
    _remoteDescriptionReady.clear();
    _offering.clear();

    _endReason = reason;
    final wasMinimized = !_routeOpen;
    _removeOverlay();
    _phase = GroupCallPhase.ended;
    notifyListeners();

    if (wasMinimized) {
      scheduleMicrotask(_resetIdle);
    }
  }

  /// 结束页关闭/自动关闭后复位到 idle。
  void markIdleAfterClosed() {
    if (_phase == GroupCallPhase.ended) {
      _resetIdle();
    }
  }

  void _resetIdle() {
    _phase = GroupCallPhase.idle;
    _members.clear();
    _inviterId = null;
    _inviterName = '';
    _inviterAvatar = null;
    _callId = null;
    _convId = null;
    _groupName = '';
    _groupAvatar = null;
    _endReason = null;
    _duration = Duration.zero;
    notifyListeners();
  }

  void _send(String event, Map<String, dynamic> extra) {
    final callId = _callId;
    if (callId == null) return;
    _ref.read(realtimeProvider).sendFrame(WsFrame(
          type: WsType.callSignal,
          data: {
            'event': event,
            'callId': callId,
            ...extra,
          },
        ));
  }

  void _toast(String msg) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      AppToast.info(ctx, msg);
    }
  }

  Future<AppL10n> _loadL() async {
    final code = _ref.read(settingsControllerProvider).locale.languageCode;
    return AppL10n.delegate.load(Locale(code));
  }

  // ---------------- 铃声 ----------------

  void _startRingTone() {
    _ringToneTimer?.cancel();
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    _ringToneTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    });
  }

  void _stopRingTone() {
    _ringToneTimer?.cancel();
    _ringToneTimer = null;
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = _joinedAt;
      if (started != null && _phase == GroupCallPhase.inRoom) {
        _duration = DateTime.now().difference(started);
        notifyListeners();
        // 胶囊上的时长随通知器刷新。
      }
    });
  }

  // ---------------- 最小化 / 路由 ----------------

  Future<void> minimize() async {
    if (!_routeOpen) return;
    _routeOpen = false;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && GoRouter.of(ctx).canPop()) {
      GoRouter.of(ctx).pop();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  void onRouteClosedByMinimize() {
    _routeOpen = false;
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showOverlay() {
    if (!isActive || _overlay != null) return;
    final ctx = rootNavigatorKey.currentContext;
    final overlay = ctx?.mounted == true ? Overlay.maybeOf(ctx!) : null;
    if (overlay == null) return;
    final isZh =
        _ref.read(settingsControllerProvider).locale.languageCode == 'zh';
    final String status;
    if (_phase == GroupCallPhase.inRoom) {
      final s = _duration.inSeconds;
      status =
          '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    } else {
      status = isZh ? '群语音邀请…' : 'Group call…';
    }
    _overlay = OverlayEntry(
      builder: (_) => DraggableMiniCallPill(
        name: _groupName.isEmpty ? (isZh ? '群语音通话' : 'Group call') : _groupName,
        avatarUrl: _groupAvatar,
        status: status,
        icon: Icons.groups_rounded,
        onTap: () {
          _removeOverlay();
          _openRoute();
        },
      ),
    );
    overlay.insert(_overlay!);
  }

  void _openRoute() {
    if (_routeOpen) return;
    _removeOverlay();
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      _routeOpen = true;
      GoRouter.of(ctx).push('/group-call');
    }
  }

  void closeRoute() {
    if (!_routeOpen) return;
    _routeOpen = false;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && GoRouter.of(ctx).canPop()) {
      GoRouter.of(ctx).pop();
    }
    if (_phase == GroupCallPhase.ended) {
      _resetIdle();
    }
  }
}
