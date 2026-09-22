import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sylph_client/core/network/ws_frame.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../notify/notifications.dart';
import '../service/foreground_service.dart';
import '../../core/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/router/app_router.dart';
import '../../presentation/state/providers.dart';
import '../../presentation/features/call/mini_call_pill.dart';
import 'webrtc_engine.dart';

/// 通话阶段：主叫呼出、被叫来电、已接通、已结束。
enum CallPhase { idle, outgoing, incoming, connected, ended }

/// #11 一对一语音通话全局状态机：
/// WS CALL_SIGNAL 信令（invite/ringing/answer/ice/reject/cancel/hangup/error）
/// + WebRTC 音频引擎 + 铃声/振动/系统来电通知 + 前台服务通话模式 + 通话记录落库。
class CallController extends ChangeNotifier {
  CallController(this._ref);

  final Ref _ref;
  final Uuid _uuid = const Uuid();
  WebRtcAudioEngine? _engine;
  // 持有远端 MediaStream，防止 Dart 层 GC 导致远端音频轨释放（无声根因）。
  // 字段本身只写不读，作用是保持引用计数。
  // ignore: unused_field
  rtc.MediaStream? _remoteStream;

  CallPhase _phase = CallPhase.idle;
  CallPhase get phase => _phase;

  String? _callId;
  int? _peerId;
  String _peerName = '';
  String? _peerAvatar;
  int? _convId;

  String? get callId => _callId;
  int? get peerId => _peerId;
  String get peerName => _peerName;
  String? get peerAvatar => _peerAvatar;
  int? get convId => _convId;

  bool _micOn = true;
  // 默认听筒（贴近微信通话体验），用户在通话页手动切扬声器；视频通话默认免提。
  bool _speakerOn = false;
  bool get micOn => _micOn;
  bool get speakerOn => _speakerOn;

  bool _video = false;
  bool get isVideoCall => _video;
  bool _cameraOn = true;
  bool get cameraOn => _cameraOn;

  /// 本地/远端媒体流（视频通话页据此绑定 RTCVideoRenderer）。
  rtc.MediaStream? get localStream => _engine?.localStream;
  rtc.MediaStream? get remoteStream => _remoteStream;

  /// 通话结束原因码：normal/busy/offline/noanswer/rejected/canceled/timeout/
  /// accepted_elsewhere/no_permission/failed。
  String? endReason;

  DateTime? _connectedAt;
  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  bool get isActive =>
      _phase != CallPhase.idle && _phase != CallPhase.ended;
  bool get isOutgoing => _phase == CallPhase.outgoing;
  bool get isIncoming => _phase == CallPhase.incoming;
  bool get isConnected => _phase == CallPhase.connected;

  Timer? _ringTimer;
  Timer? _tickTimer;
  Timer? _ringToneTimer;
  final List<Map<String, dynamic>> _pendingRemoteCandidates = [];
  bool _callRouteOpen = false;
  bool _recorded = false;

  /// 最小化后的全局悬浮通话胶囊。
  OverlayEntry? _callOverlay;

  int get _meId => _ref.read(sessionControllerProvider).user?.id ?? -1;

  // ---------------- 主叫 ----------------

  Future<void> startCall({
    required int peerUserId,
    required String peerName,
    String? avatarUrl,
    int? convId,
    bool video = false,
  }) async {
    if (isActive) return;
    _reset(peerUserId, peerName, avatarUrl, convId, video: video);
    _phase = CallPhase.outgoing;
    notifyListeners();

    // FGS microphone 类型必须先有录音权限：呼出前申请，拒绝则直接结束。
    if (!kIsWeb && !await Permission.microphone.request().isGranted) {
      await _finish('no_permission', record: false);
      return;
    }
    // 视频通话还需摄像头权限。
    if (video && !kIsWeb && !await Permission.camera.request().isGranted) {
      await _finish('no_permission', record: false);
      return;
    }

    try {
      final engine = WebRtcAudioEngine(video: video);
      _engine = engine;
      engine.onLocalCandidate = (c) {
        _send('ice', {
          'to': _peerId,
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      };
      engine.onConnected = () {
        // ICE 真正连通（answer 已先把 UI 切到通话中）。
        // 协商/音频焦点过程中系统可能把路由改回听筒，按用户当前选择
        // 再强制应用一次（内部含 0/350/1000ms 三次补偿）。
        unawaited(engine.applyAudioRoute(_speakerOn));
      };
      engine.onFailed = () {
        if (isActive) _finish('failed');
      };
      // 持有远端流，防止 GC 释放远端轨；视频轨晚于音频到达，每次都通知 UI 重绑渲染器。
      engine.onRemoteStream = (s) {
        _remoteStream = s;
        notifyListeners();
      };
      await engine.init(() => _ref.read(callRepoProvider).iceServers());
      await engine.applyAudioRoute(_speakerOn);

      final offer = await engine.createOffer();
      _send('invite', {'to': _peerId, 'sdp': offer.sdp, 'video': video});
      _openCallRoute();
      _startRingback();
      // 30s 振铃由服务端兜底，客户端 35s 本地超时双保险。
      _ringTimer = Timer(const Duration(seconds: 35), () {
        if (!isConnected) _onLocalNoAnswer();
      });
    } catch (e) {
      debugPrint('startCall error: $e');
      await _finish('failed', record: false);
    }
  }

  Future<void> _onLocalNoAnswer() async {
    // 清理信令（cancel）由 _finish 的 _sendCleanupSignal 发出。
    await _finish('noanswer', result: 'canceled');
  }

  // ---------------- 被叫 ----------------

  Future<void> accept() async {
    if (_phase != CallPhase.incoming) return;
    _stopRingTone();
    if (!kIsWeb && !await Permission.microphone.request().isGranted) {
      // reject 清理由 _finish 的 _sendCleanupSignal 发出。
      await _finish('no_permission', result: 'rejected');
      return;
    }
    if (_video && !kIsWeb && !await Permission.camera.request().isGranted) {
      await _finish('no_permission', result: 'rejected');
      return;
    }
    try {
      final engine = WebRtcAudioEngine(video: _video);
      _engine = engine;
      engine.onLocalCandidate = (c) {
        _send('ice', {
          'to': _peerId,
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      };
      engine.onConnected = () {
        // ICE 连通后重新固化用户选择的音频路由（国产 ROM 协商期可能被重置）。
        unawaited(engine.applyAudioRoute(_speakerOn));
      };
      engine.onFailed = () {
        if (isActive) _finish('failed');
      };
      // 持有远端流，防止 GC 释放远端轨；视频轨晚于音频到达，每次都通知 UI 重绑渲染器。
      engine.onRemoteStream = (s) {
        _remoteStream = s;
        notifyListeners();
      };
      await engine.init(() => _ref.read(callRepoProvider).iceServers());
      final offerSdp = _offerSdp;
      if (offerSdp == null) {
        await _finish('failed', result: 'completed');
        return;
      }
      await engine.setRemoteSdp(offerSdp, 'offer');
      for (final c in _pendingRemoteCandidates) {
        await engine.addRemoteCandidate(c);
      }
      _pendingRemoteCandidates.clear();
      await engine.applyAudioRoute(_speakerOn);
      final answer = await engine.createAnswer();
      _send('answer', {'to': _peerId, 'sdp': answer.sdp});
      await _enterConnected(asCaller: false);
    } catch (e) {
      debugPrint('accept error: $e');
      // reject 清理由 _finish 的 _sendCleanupSignal 发出。
      await _finish('failed', result: 'rejected');
    }
  }

  Future<void> decline() async {
    if (_phase != CallPhase.incoming) return;
    await _finish('rejected', result: 'rejected');
  }

  // ---------------- 通话中控制 ----------------

  Future<void> toggleMic() async {
    _micOn = !_micOn;
    await _engine?.setMicEnabled(_micOn);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await _engine?.applyAudioRoute(_speakerOn);
    notifyListeners();
  }

  /// 摄像头开关（视频通话）。
  Future<void> toggleCamera() async {
    if (!_video) return;
    _cameraOn = !_cameraOn;
    await _engine?.setVideoEnabled(_cameraOn);
    notifyListeners();
  }

  /// 前后摄像头切换（视频通话）。
  Future<void> switchCamera() async {
    if (!_video) return;
    await _engine?.switchCamera();
  }

  /// 挂断按钮：按阶段选择落库结果，清理信令统一由 _finish 的 _sendCleanupSignal 发出。
  Future<void> hangUp() async {
    switch (_phase) {
      case CallPhase.outgoing:
        await _finish('normal', result: 'canceled');
      case CallPhase.incoming:
        await _finish('normal', result: 'rejected');
      case CallPhase.connected:
        await _finish('normal', result: 'completed');
      case CallPhase.ended:
        closeCallRoute();
      case CallPhase.idle:
        break;
    }
  }

  // ---------------- 信令入口（Realtime 调用） ----------------

  String? _offerSdp;

  Future<void> handleSignal(WsFrame frame) async {
    final d = frame.dataMap;
    final event = d['event'] as String?;
    if (event == null) return;

    if (event == 'error') {
      final code = (d['code'] as String?) ?? 'failed';
      // 只响应当前这通呼叫的错误。
      if (d['callId'] != null && d['callId'] != _callId) return;
      // 服务端错误（PEER_OFFLINE/PEER_BUSY 等）已由后端处理 session，本端不再发清理信令。
      await _finish(code, record: false, sendCleanup: false);
      return;
    }

    final callId = d['callId'] as String?;
    final from = (d['from'] as num?)?.toInt();

    // invite：被叫端接受新会话，必须在 callId 校验之前处理。
    // 否则被叫端 idle 时 _callId==null，invite 会被 callId 校验丢弃，
    // 导致被叫端永远不进入来电态、不 push /call、不响铃、不回 ringing。
    if (event == 'invite') {
      if (from == null || from == _meId) return;
      if (isActive) {
        // 本机忙线：服务端通常已 PEER_BUSY 拦截，这里兜底回 reject，
        // 让主叫端立即落库 rejected 而非干等 30s 超时落 canceled。
        _ref.read(realtimeProvider).sendFrame(WsFrame(
          type: WsType.callSignal,
          data: {
            'event': 'reject',
            'callId': callId,
            'to': from,
          },
        ));
        return;
      }
      await _onIncomingInvite(
          from,
          (d['sdp'] as String?) ?? '',
          (d['to'] as num?)?.toInt(),
          callId,
          d['video'] == true);
      return;
    }

    // 其余事件必须匹配当前会话，防止串线。
    if (callId != _callId) return;

    switch (event) {
      case 'ringing':
        // 对端已开始振铃：保持呼出页（文案可区分）。
        notifyListeners();
      case 'answer':
        if (!isOutgoing) break;
        try {
          await _engine?.setRemoteSdp((d['sdp'] as String?) ?? '', 'answer');
          await _enterConnected(asCaller: true);
        } catch (e) {
          debugPrint('setRemoteAnswer error: $e');
          await _finish('failed');
        }
      case 'ice':
        final cand = <String, dynamic>{
          'candidate': d['candidate'],
          'sdpMid': d['sdpMid'],
          'sdpMLineIndex': d['sdpMLineIndex'],
        };
        if (_engine == null) {
          _pendingRemoteCandidates.add(cand);
        } else {
          await _engine!.addRemoteCandidate(cand);
        }
      case 'reject':
        // 对端主动拒绝，已由对端发 reject 清理后端，本端不再重复发。
        await _finish('rejected', result: 'rejected', sendCleanup: false);
      case 'cancel':
        final reason = (d['reason'] as String?) ?? 'canceled';
        if (reason == 'accepted_elsewhere') {
          await _finish('accepted_elsewhere',
              record: false, sendCleanup: false);
        } else if (isIncoming) {
          // 主叫取消或振铃超时：被叫记一条未接来电。对端已发 cancel 清理后端。
          await _finish(reason == 'timeout' ? 'timeout' : 'canceled',
              result: 'missed', sendCleanup: false);
        } else {
          await _finish(reason == 'timeout' ? 'noanswer' : 'canceled',
              result: 'canceled', sendCleanup: false);
        }
      case 'hangup':
        // 对端主动挂断，已由对端发 hangup 清理后端，本端不再重复发。
        await _finish('normal', result: 'completed', sendCleanup: false);
    }
  }

  Future<void> _onIncomingInvite(int from, String sdp, int? to, String? callId,
      bool video) async {
    // 解析本地会话，拿昵称/头像/会话 id（找不到再查好友列表兜底）。
    String name = '';
    String? avatar;
    int? convId;
    try {
      final convs = _ref.read(conversationsStreamProvider).valueOrNull;
      for (final c in convs ?? const <Conversation>[]) {
        if (c.peerUserId == from) {
          name = c.peerNickname ?? c.title ?? '';
          avatar = c.peerAvatarUrl ?? c.groupAvatarUrl;
          convId = c.id;
          break;
        }
      }
    } catch (_) {}
    if (name.isEmpty) {
      try {
        final friends = await _ref.read(socialRepoProvider).friends();
        for (final e in friends) {
          if (e.user.id != from) continue;
          final remark = e.remark ?? '';
          name = (remark.isNotEmpty)
              ? remark
              : e.user.nickname;
          avatar = e.user.avatarUrl;
          break;
        }
      } catch (_) {}
    }
    if (name.isEmpty) name = '#$from';

    _reset(from, name, avatar, convId, callId: callId, video: video);
    _offerSdp = sdp;
    _phase = CallPhase.incoming;
    notifyListeners();
    _openCallRoute();
    _startRingTone();
    // 回 ringing，让主叫停止"等待接听"前的呼叫提示音切换。
    _send('ringing', {'to': from});
    final localeCode = _ref.read(settingsControllerProvider).locale.languageCode;
    final l = await AppL10n.delegate.load(Locale(localeCode));
    Notifications.showCall(
      title: name,
      body: video ? l.incomingVideoCall : l.incomingVoiceCall,
      convId: convId ?? 0,
    );
  }

  // ---------------- 内部流程 ----------------

  void _reset(int peerId, String name, String? avatar, int? convId,
      {String? callId, bool video = false}) {
    _ringTimer?.cancel();
    _tickTimer?.cancel();
    _stopRingTone();
    _pendingRemoteCandidates.clear();
    _offerSdp = null;
    endReason = null;
    _recorded = false;
    _duration = Duration.zero;
    _connectedAt = null;
    _micOn = true;
    _video = video;
    _cameraOn = true;
    // 视频通话默认扬声器外放；语音通话默认听筒。
    _speakerOn = video;
    // 被叫端复用主叫端发来的 callId，保证后续 ringing/answer/ice/reject/hangup
    // 的 callId 双向匹配；主叫端 startCall 路径不传 callId，自己生成。
    _callId = callId ?? _uuid.v4().replaceAll('-', '');
    _peerId = peerId;
    _peerName = name;
    _peerAvatar = avatar;
    _convId = convId;
  }

  Future<void> _enterConnected({required bool asCaller}) async {
    _ringTimer?.cancel();
    _stopRingTone();
    await Notifications.cancel(Notifications.callNotificationId);
    _phase = CallPhase.connected;
    _connectedAt = DateTime.now();
    notifyListeners();
    // 部分机型在 SDP 协商完成后会把音频路由重置回扬声器，接通时再强制一次。
    unawaited(_engine?.applyAudioRoute(_speakerOn));
    unawaited(_video
        ? FgKeepAlive.enterVideoCallMode()
        : FgKeepAlive.enterCallMode());
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = _connectedAt;
      if (started != null) {
        _duration = DateTime.now().difference(started);
        notifyListeners();
      }
    });
  }

  /// 按 phase 发清理信令，保证后端 session/busy 释放（异常结束路径也调用）。
  /// 必须在 phase 还未被改为 ended 之前调用。
  void _sendCleanupSignal() {
    switch (_phase) {
      case CallPhase.connected:
        _send('hangup', {});
      case CallPhase.outgoing:
        _send('cancel', {'to': _peerId, 'reason': 'caller_cancel'});
      case CallPhase.incoming:
        _send('reject', {});
      case CallPhase.ended:
      case CallPhase.idle:
        break;
    }
  }

  /// 结束并清理。
  /// - [sendCleanup]：是否发清理信令给对端/后端。主动结束传 true（默认），
  ///   被动结束（收到对端 reject/cancel/hangup 或服务端 error）传 false。
  /// - [result]：落库结果。failed 路径不传时按角色自动推断，保证未接通也有 CALL 消息。
  /// - [record]：是否落库。
  Future<void> _finish(String reason,
      {String? result, bool record = true, bool sendCleanup = true}) async {
    if (_phase == CallPhase.idle || _phase == CallPhase.ended) return;
    endReason = reason;
    _ringTimer?.cancel();
    _tickTimer?.cancel();
    _stopRingTone();
    // 异常结束也要通知后端清理 session，否则 busyUsers 拘留导致重拨忙线。
    if (sendCleanup) _sendCleanupSignal();
    unawaited(FgKeepAlive.exitCallMode());
    unawaited(Notifications.cancel(Notifications.callNotificationId));

    final wasConnected = _phase == CallPhase.connected;
    if (wasConnected) {
      _duration = _connectedAt == null
          ? Duration.zero
          : DateTime.now().difference(_connectedAt!);
    }
    // failed 路径自动推断落库 result，让未接通也产生 CALL 消息卡片 + 回拨按钮。
    String? effectiveResult = result;
    if (effectiveResult == null && record && reason == 'failed') {
      if (wasConnected) {
        effectiveResult = 'completed'; // 已接通后中断，记时长
      } else if (isOutgoing) {
        effectiveResult = 'canceled'; // 主叫未接通
      } else if (isIncoming) {
        effectiveResult = 'missed'; // 被叫未接通
      }
    }
    final callId = _callId;
    final peer = _peerId;
    final secs = _duration.inSeconds;

    _phase = CallPhase.ended;
    // 最小化状态下结束：没有全屏页展示结束态，移除胶囊后直接复位 idle，
    // 否则状态机会卡在 ended 且无任何入口。
    final endedWhileMinimized = !_callRouteOpen;
    _removeMiniOverlay();
    notifyListeners();

    final engine = _engine;
    _engine = null;
    _remoteStream = null; // 释放远端流引用
    // 恢复普通音频模式（必须在 engine dispose 前调用）。
    unawaited(engine?.resetAudioMode());
    unawaited(engine?.dispose());
    if (endedWhileMinimized) {
      scheduleMicrotask(markIdleAfterClosed);
    }

    if (record &&
        effectiveResult != null &&
        callId != null &&
        peer != null &&
        !_recorded) {
      _recorded = true;
      try {
        await _ref.read(callRepoProvider).record(
              peerUserId: peer,
              callId: callId,
              result: effectiveResult,
              durationSec: effectiveResult == 'completed' ? secs : 0,
            );
        // 记录落库会插入 CALL 消息；刷新会话列表预览。
        unawaited(_ref.read(realtimeProvider).refreshConversations());
      } catch (_) {}
    }
  }

  /// 供 UI 在结束页点击关闭/自动关闭时调用。
  void markIdleAfterClosed() {
    _phase = CallPhase.idle;
    notifyListeners();
  }

  void _send(String event, Map<String, dynamic> extra) {
    final callId = _callId;
    final peer = _peerId;
    if (callId == null || peer == null) return;
    _ref.read(realtimeProvider).sendFrame(WsFrame(
          type: WsType.callSignal,
          data: {
            'event': event,
            'callId': callId,
            'to': peer,
            ...extra,
          },
        ));
  }

  // ---------------- 铃声（系统提示音循环 + 振动，无需自带音频资源） ----------------

  void _startRingback() => _startTone(incoming: false);
  void _startRingTone() => _startTone(incoming: true);

  void _startTone({required bool incoming}) {
    _ringToneTimer?.cancel();
    SystemSound.play(SystemSoundType.alert);
    if (incoming) HapticFeedback.heavyImpact();
    _ringToneTimer = Timer.periodic(
      Duration(milliseconds: incoming ? 1600 : 2200),
      (_) {
        SystemSound.play(SystemSoundType.alert);
        if (incoming) HapticFeedback.heavyImpact();
      },
    );
  }

  void _stopRingTone() {
    _ringToneTimer?.cancel();
    _ringToneTimer = null;
  }

  // ---------------- 最小化悬浮胶囊 ----------------

  /// 通话页缩小按钮：仅关闭全屏页，通话继续，底部出现悬浮胶囊。
  Future<void> minimize() async {
    if (!_callRouteOpen) return;
    _callRouteOpen = false;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && GoRouter.of(ctx).canPop()) {
      GoRouter.of(ctx).pop();
    }
    // 等 CallPage dispose 完成后再插胶囊，避免同帧 Overlay 状态异常。
    WidgetsBinding.instance.addPostFrameCallback((_) => _showMiniOverlay());
  }

  /// CallPage 因最小化关闭时的 dispose 回调：保持 phase，不做 idle 复位。
  void onRouteClosedByMinimize() {
    _callRouteOpen = false;
  }

  void _removeMiniOverlay() {
    _callOverlay?.remove();
    _callOverlay = null;
  }

  void _showMiniOverlay() {
    if (!isActive || _callOverlay != null) return;
    final ctx = rootNavigatorKey.currentContext;
    final overlay = ctx?.mounted == true ? Overlay.maybeOf(ctx!) : null;
    if (overlay == null) return;
    final localeCode = _ref.read(settingsControllerProvider).locale.languageCode;
    final isZh = localeCode == 'zh';
    final String status;
    if (isConnected) {
      final s = _duration.inSeconds;
      final mm = (s ~/ 60).toString().padLeft(2, '0');
      final ss = (s % 60).toString().padLeft(2, '0');
      status = '$mm:$ss';
    } else if (isIncoming) {
      status = isZh ? '来电中…' : 'Incoming…';
    } else {
      status = isZh ? '等待接听…' : 'Calling…';
    }
    final entry = OverlayEntry(
      builder: (_) => DraggableMiniCallPill(
        name: _peerName,
        avatarUrl: _peerAvatar,
        status: status,
        icon: _video ? Icons.videocam_rounded : Icons.call_rounded,
        onTap: () {
          _removeMiniOverlay();
          _openCallRoute();
        },
      ),
    );
    _callOverlay = entry;
    overlay.insert(entry);
  }

  // ---------------- 全屏通话路由 ----------------

  void _openCallRoute() {
    if (_callRouteOpen) return;
    // 从胶囊回到全屏页：胶囊先移除。
    _removeMiniOverlay();
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      _callRouteOpen = true;
      // 语音/视频通话页面分离：视频推 /call，语音推 /audio-call。
      GoRouter.of(ctx).push(_video ? '/call' : '/audio-call');
    }
  }

  void closeCallRoute() {
    if (!_callRouteOpen) return;
    _callRouteOpen = false;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && GoRouter.of(ctx).canPop()) {
      GoRouter.of(ctx).pop();
    }
    // 自动关闭路径下路由不再有 dispose 回调，直接把状态复位到 idle。
    if (_phase == CallPhase.ended) {
      _phase = CallPhase.idle;
      notifyListeners();
    }
  }
}
