import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../../core/call/call_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/router/app_router.dart';
import '../../state/providers.dart';
import '../../widgets/user_avatar.dart';

/// #11 全屏视频通话页（与语音通话页 [AudioCallPage] 完全分离）。
/// 由 CallController 以根路由 /call 推入；结束态短暂停留后自动关闭。
///
/// 状态判断使用强类型 `CallPhase ==` 而非 `.name` 字符串比较
/// （release 模式下 `.name` getter 会抛 NoSuchMethodError）。
class CallPage extends ConsumerStatefulWidget {
  const CallPage({super.key});

  @override
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {
  Timer? _autoClose;

  // 视频渲染器。
  final rtc.RTCVideoRenderer _localRenderer = rtc.RTCVideoRenderer();
  final rtc.RTCVideoRenderer _remoteRenderer = rtc.RTCVideoRenderer();
  bool _renderersReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initRenderers());
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
    } catch (e) {
      debugPrint('RTCVideoRenderer init failed: $e');
    }
    if (!mounted) {
      await _localRenderer.dispose();
      await _remoteRenderer.dispose();
      return;
    }
    setState(() => _renderersReady = true);
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    // 路由销毁（自动关闭/系统返回/最小化）后同步控制器路由标记。
    // 不能用本页 ref（dispose 后读取会抛异常）：借根 navigator 的
    // ProviderScope 容器取同一个 CallController 单例。
    // 通话仍活跃说明是点了缩小按钮：只标记路由关闭、保留 phase（胶囊接管）；
    // 已结束则复位到 idle。
    final rootCtx = rootNavigatorKey.currentContext;
    if (rootCtx != null) {
      final controller =
          ProviderScope.containerOf(rootCtx, listen: false)
              .read(callControllerProvider);
      final active = controller.isActive;
      Future.microtask(() {
        if (active) {
          controller.onRouteClosedByMinimize();
        } else {
          controller.markIdleAfterClosed();
        }
      });
    }
    unawaited(_localRenderer.dispose());
    unawaited(_remoteRenderer.dispose());
    super.dispose();
  }

  /// 把控制器里的媒体流绑定到渲染器（流可能晚于页面就绪，每次 rebuild 同步）。
  void _syncStreams(CallController call) {
    if (!_renderersReady) return;
    final ls = call.localStream;
    final rs = call.remoteStream;
    if (!identical(_localRenderer.srcObject, ls)) {
      _localRenderer.srcObject = ls;
    }
    if (!identical(_remoteRenderer.srcObject, rs)) {
      _remoteRenderer.srcObject = rs;
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _endText(AppL10n l, String? reason) {
    switch (reason) {
      case 'rejected':
        return l.callRejected;
      case 'canceled':
        return l.callCanceled;
      case 'noanswer':
      case 'timeout':
        return l.callNoAnswer;
      case 'PEER_BUSY':
      case 'CALLER_BUSY':
      case 'busy':
        return l.callBusy;
      case 'PEER_OFFLINE':
      case 'offline':
        return l.callPeerOffline;
      case 'accepted_elsewhere':
        return l.callAcceptedElsewhere;
      case 'no_permission':
        return l.callMicPermissionDenied;
      case 'failed':
        return l.callConnectFailed;
      default:
        return l.callEnded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final CallController call = ref.watch(callControllerProvider);

    if (call.phase == CallPhase.ended && _autoClose == null) {
      _autoClose = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) ref.read(callControllerProvider).closeCallRoute();
      });
    }

    _syncStreams(call);

    return PopScope(
      canPop: call.phase == CallPhase.ended,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildVideoBody(context, l, call),
      ),
    );
  }

  // ================= 视频通话 =================

  Widget _buildVideoBody(BuildContext context, AppL10n l, CallController call) {
    final ended = call.phase == CallPhase.ended;
    final connected = call.phase == CallPhase.connected;
    final incoming = call.phase == CallPhase.incoming;

    // 来电页/结束页：引擎尚未建立或已销毁，用深色信息页。
    if (incoming || ended || !_renderersReady) {
      return Container(
        color: const Color(0xFF101522),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                _topBar(l, call, ended),
                const Spacer(flex: 2),
                UserAvatar(
                  name: call.peerName,
                  avatarUrl: call.peerAvatar,
                  size: 108,
                ),
                const SizedBox(height: 18),
                Text(
                  call.peerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  Icons.videocam_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  ended
                      ? _endText(l, call.endReason)
                      : l.incomingVideoCall,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 15,
                  ),
                ),
                const Spacer(flex: 3),
                if (incoming)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CircleAction(
                        icon: Icons.call_end,
                        color: const Color(0xFFE5534D),
                        label: l.decline,
                        onTap: () =>
                            ref.read(callControllerProvider).decline(),
                      ),
                      _CircleAction(
                        icon: Icons.videocam_rounded,
                        color: const Color(0xFF34C759),
                        label: l.accept,
                        onTap: () =>
                            ref.read(callControllerProvider).accept(),
                      ),
                    ],
                  ),
                const SizedBox(height: 46),
              ],
            ),
          ),
        ),
      );
    }

    final remoteHasVideo = connected &&
        _remoteRenderer.srcObject != null &&
        (_remoteRenderer.srcObject!.getVideoTracks().isNotEmpty);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 远端全屏画面；接通前用本地预览做背景。
        if (remoteHasVideo)
          rtc.RTCVideoView(
            _remoteRenderer,
            mirror: false,
            objectFit: rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else ...[
          if (_localRenderer.srcObject != null && call.cameraOn)
            rtc.RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit:
                  rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          // 预览压暗，突出上层信息。
          Container(color: Colors.black.withValues(alpha: 0.45)),
        ],
        SafeArea(
          child: Column(
            children: [
              _topBar(l, call, false),
              if (!connected) ...[
                const Spacer(),
                UserAvatar(
                  name: call.peerName,
                  avatarUrl: call.peerAvatar,
                  size: 92,
                ),
                const SizedBox(height: 16),
                Text(
                  call.peerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.callWaitingAnswer,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14.5,
                  ),
                ),
              ],
              const Spacer(),
              _videoControls(l, connected),
              const SizedBox(height: 40),
            ],
          ),
        ),
        // 本地小窗：接通后显示在右上。
        if (connected)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            right: 16,
            child: _LocalPiP(
              renderer: _localRenderer,
              cameraOn: call.cameraOn,
              name: call.peerName,
              avatarUrl: call.peerAvatar,
            ),
          ),
        // 接通后的顶部状态：昵称 + 时长。
        if (connected)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 72,
            right: 72,
            child: Column(
              children: [
                Text(
                  call.peerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(call.duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _videoControls(AppL10n l, bool connected) {
    final c = ref.read(callControllerProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (connected) ...[
          _CircleAction(
            icon: c.micOn ? Icons.mic_none_rounded : Icons.mic_off_rounded,
            color: Colors.white24,
            active: !c.micOn,
            label: c.micOn ? l.callMicOn : l.callMicOff,
            onTap: c.toggleMic,
          ),
          const SizedBox(width: 26),
          _CircleAction(
            icon: c.cameraOn
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            color: Colors.white24,
            active: !c.cameraOn,
            label: c.cameraOn ? l.cameraOn : l.cameraOff,
            onTap: c.toggleCamera,
          ),
          const SizedBox(width: 26),
          _CircleAction(
            icon: Icons.cameraswitch_rounded,
            color: Colors.white24,
            label: l.switchCamera,
            onTap: c.switchCamera,
          ),
          const SizedBox(width: 26),
        ],
        _CircleAction(
          icon: Icons.call_end,
          color: const Color(0xFFE5534D),
          label: connected ? l.hangUp : l.cancelCall,
          onTap: c.hangUp,
        ),
      ],
    );
  }

  /// 顶部：左侧最小化按钮（结束态留等高占位）。
  Widget _topBar(AppL10n l, CallController call, bool ended) {
    if (ended) return const SizedBox(height: 48);
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: l.callMinimize,
        onPressed: () => ref.read(callControllerProvider).minimize(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}

/// 视频通话的本地画面小窗（摄像头关闭时显示头像占位）。
class _LocalPiP extends StatelessWidget {
  final rtc.RTCVideoRenderer renderer;
  final bool cameraOn;
  final String name;
  final String? avatarUrl;

  const _LocalPiP({
    required this.renderer,
    required this.cameraOn,
    required this.name,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 104,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2A44),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cameraOn && renderer.srcObject != null)
              rtc.RTCVideoView(
                renderer,
                mirror: true,
                objectFit:
                    rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              Center(
                child: UserAvatar(name: name, avatarUrl: avatarUrl, size: 52),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  /// 激活态：白底 + 深色图标 + 柔光，与未激活（半透深底白图标）形成强对比。
  final bool active;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? Colors.white : color;
    final fg = active ? const Color(0xFF1F2A44) : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x66FFFFFF),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: fg, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
      ],
    );
  }
}
