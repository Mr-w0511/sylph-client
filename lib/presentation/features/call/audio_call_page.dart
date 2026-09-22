import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/call/call_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/router/app_router.dart';
import '../../state/providers.dart';
import '../../widgets/user_avatar.dart';

/// #11 纯语音通话全屏页（与视频通话页 [CallPage] 完全分离）。
/// 由 CallController 以根路由 /audio-call 推入；结束态短暂停留后自动关闭。
///
/// 不引入 flutter_webrtc，避免原生渲染管线异常导致白屏；
/// 状态判断使用强类型 `CallPhase ==` 而非 `.name` 字符串比较
/// （release 模式下 `.name` getter 会抛 NoSuchMethodError）。
class AudioCallPage extends ConsumerStatefulWidget {
  const AudioCallPage({super.key});

  @override
  ConsumerState<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends ConsumerState<AudioCallPage> {
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
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
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    final CallController call = ref.watch(callControllerProvider);

    if (call.phase == CallPhase.ended && _autoClose == null) {
      _autoClose = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) ref.read(callControllerProvider).closeCallRoute();
      });
    }

    return PopScope(
      canPop: call.phase == CallPhase.ended,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: _buildAudioBody(context, theme, l, call),
      ),
    );
  }

  // ================= 语音通话 =================

  Widget _buildAudioBody(
      BuildContext context, ThemeData theme, AppL10n l, CallController call) {
    final ended = call.phase == CallPhase.ended;
    final connected = call.phase == CallPhase.connected;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F2A44),
            const Color(0xFF0D1117),
          ],
        ),
      ),
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
              Text(
                connected
                    ? _fmt(call.duration)
                    : ended
                        ? _endText(l, call.endReason)
                        : (call.phase == CallPhase.incoming
                            ? l.callIncomingHint
                            : l.callWaitingAnswer),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                ),
              ),
              const Spacer(flex: 3),
              _audioControls(l, call, connected),
              const SizedBox(height: 46),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audioControls(AppL10n l, CallController call, bool connected) {
    if (call.phase == CallPhase.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleAction(
            icon: Icons.call_end,
            color: const Color(0xFFE5534D),
            label: l.decline,
            onTap: () => ref.read(callControllerProvider).decline(),
          ),
          _CircleAction(
            icon: Icons.call,
            color: const Color(0xFF34C759),
            label: l.accept,
            onTap: () => ref.read(callControllerProvider).accept(),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (connected) ...[
          _CircleAction(
            icon: call.micOn
                ? Icons.mic_none_rounded
                : Icons.mic_off_rounded,
            color: Colors.white12,
            foreground: Colors.white,
            // 静音时高亮：白底深色图标，让"已静音"一眼可见。
            active: !call.micOn,
            label: call.micOn ? l.callMicOn : l.callMicOff,
            onTap: () => ref.read(callControllerProvider).toggleMic(),
          ),
          const SizedBox(width: 34),
          _CircleAction(
            icon: call.speakerOn
                ? Icons.volume_up_rounded
                : Icons.headset_mic_outlined,
            color: Colors.white12,
            foreground: Colors.white,
            // 扬声器开启时高亮；听筒态为暗色半透底。
            active: call.speakerOn,
            label: call.speakerOn
                ? l.callSpeakerOn
                : l.callSpeakerOff,
            onTap: () => ref.read(callControllerProvider).toggleSpeaker(),
          ),
          const SizedBox(width: 34),
        ],
        _CircleAction(
          icon: Icons.call_end,
          color: const Color(0xFFE5534D),
          label: connected ? l.hangUp : l.cancelCall,
          onTap: () => ref.read(callControllerProvider).hangUp(),
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

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color foreground;
  final String label;
  final VoidCallback onTap;

  /// 激活态：白底 + 深色图标 + 柔光，与未激活（半透深底白图标）形成强对比。
  final bool active;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.foreground = Colors.white,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? Colors.white : color;
    final fg = active ? const Color(0xFF1F2A44) : foreground;
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
