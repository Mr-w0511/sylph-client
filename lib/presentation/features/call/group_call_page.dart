import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../presentation/router/app_router.dart';
import '../../state/providers.dart';
import '../../widgets/user_avatar.dart';
import '../../../core/call/group_call_controller.dart';

/// #7 群多人语音通话全屏页：响铃邀请 / 房间内 / 结束三态。
class GroupCallPage extends ConsumerStatefulWidget {
  const GroupCallPage({super.key});

  @override
  ConsumerState<GroupCallPage> createState() => _GroupCallPageState();
}

class _GroupCallPageState extends ConsumerState<GroupCallPage> {
  Timer? _autoClose;

  @override
  void dispose() {
    _autoClose?.cancel();
    final rootCtx = rootNavigatorKey.currentContext;
    if (rootCtx != null) {
      final controller = ProviderScope.containerOf(rootCtx, listen: false)
          .read(groupCallControllerProvider);
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

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final call = ref.watch(groupCallControllerProvider);
    final myId = ref.watch(sessionControllerProvider).user?.id ?? -1;

    if (call.phase == GroupCallPhase.ended && _autoClose == null) {
      _autoClose = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) ref.read(groupCallControllerProvider).closeRoute();
      });
    }

    return PopScope(
      canPop: call.phase == GroupCallPhase.ended,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F2A44), Color(0xFF101522)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _topBar(l, call),
                  const SizedBox(height: 8),
                  if (call.phase == GroupCallPhase.ringing)
                    _ringingHeader(l, call)
                  else
                    _roomHeader(l, call),
                  const SizedBox(height: 20),
                  Expanded(child: _memberGrid(call, myId, l)),
                  _bottomControls(l, call),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(AppL10n l, GroupCallController call) {
    if (call.phase == GroupCallPhase.ended) {
      return const SizedBox(height: 48);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: l.callMinimize,
        onPressed: () => ref.read(groupCallControllerProvider).minimize(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.14),
        ),
      ),
    );
  }

  Widget _ringingHeader(AppL10n l, GroupCallController call) {
    return Column(
      children: [
        UserAvatar(
          name: call.inviterName,
          avatarUrl: call.inviterAvatar,
          size: 92,
        ),
        const SizedBox(height: 14),
        Text(
          call.inviterName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.incomingGroupCall,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_rounded,
                size: 15, color: Colors.white70),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                call.groupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roomHeader(AppL10n l, GroupCallController call) {
    final ended = call.phase == GroupCallPhase.ended;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                call.groupName.isEmpty ? l.groupVoiceCall : call.groupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          ended
              ? l.groupCallEnded
              : '${call.members.length} ${l.groupCallMemberUnit} · ${_fmt(call.duration)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _memberGrid(
      GroupCallController call, int myId, AppL10n l) {
    final members = call.members;
    if (call.phase == GroupCallPhase.ringing || members.isEmpty) {
      return Center(
        child: Text(
          call.phase == GroupCallPhase.ringing
              ? l.groupCallWaitingJoin
              : '',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      );
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: members.length,
      itemBuilder: (context, i) {
        final m = members[i];
        final me = m.id == myId;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(name: m.name, avatarUrl: m.avatar, size: 58),
                if (!m.micOn)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5534D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_off_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              me ? l.meLabel : m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ],
        );
      },
    );
  }

  Widget _bottomControls(AppL10n l, GroupCallController call) {
    if (call.phase == GroupCallPhase.ringing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleBtn(
            icon: Icons.call_end,
            color: const Color(0xFFE5534D),
            label: l.decline,
            onTap: () => ref.read(groupCallControllerProvider).declineRing(),
          ),
          _CircleBtn(
            icon: Icons.groups_rounded,
            color: const Color(0xFF34C759),
            label: l.joinCall,
            onTap: () => ref.read(groupCallControllerProvider).acceptRing(),
          ),
        ],
      );
    }
    if (call.phase == GroupCallPhase.ended) {
      return const SizedBox(height: 64);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleBtn(
          icon: call.micOn ? Icons.mic_none_rounded : Icons.mic_off_rounded,
          color: Colors.white24,
          active: !call.micOn,
          label: call.micOn ? l.callMicOn : l.callMicOff,
          onTap: () => ref.read(groupCallControllerProvider).toggleMic(),
        ),
        const SizedBox(width: 34),
        _CircleBtn(
          icon: call.speakerOn
              ? Icons.volume_up_rounded
              : Icons.headset_mic_outlined,
          color: Colors.white24,
          active: call.speakerOn,
          label:
              call.speakerOn ? l.callSpeakerOn : l.callSpeakerOff,
          onTap: () => ref.read(groupCallControllerProvider).toggleSpeaker(),
        ),
        const SizedBox(width: 34),
        _CircleBtn(
          icon: Icons.call_end,
          color: const Color(0xFFE5534D),
          label: l.hangUp,
          onTap: () => ref.read(groupCallControllerProvider).hangUp(),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _CircleBtn({
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
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
