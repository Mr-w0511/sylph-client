import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../qrcode/scan_page.dart' show checkClipboardDeepLink;

/// 主页底部导航：聊天 / 联系人 / 我的（Telegram 风格 3-tab）。
/// 三个 tab 均带未读红点，红点可拖动销毁（拖动超过阈值松手即清除）。
class HomeShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  /// 静态标记：每个 App 进程仅检查一次剪贴板深链，避免反复跳转。
  static bool _deepLinkChecked = false;

  @override
  void initState() {
    super.initState();
    if (!_deepLinkChecked) {
      _deepLinkChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        checkClipboardDeepLink(context, ref);
      });
    }
  }

  /// 消息红点拖除：本地全部清零 + 逐条上报服务端已读。
  Future<void> _clearAllMessageUnread() async {
    final dao = ref.read(conversationsDaoProvider);
    final repo = ref.read(conversationRepoProvider);
    final realtime = ref.read(realtimeProvider);
    final list = await dao.watchAll().first;
    for (final c in list) {
      if (c.unreadCount <= 0) continue;
      await dao.zeroUnread(c.id);
      realtime.markJustRead(c.id);
      final seq = c.lastSeq;
      if (seq != null) {
        try {
          await repo.markRead(c.id, seq: seq);
        } catch (_) {
          /* 单条失败不阻塞其余已读 */
        }
      }
    }
  }

  Future<void> _clearFeedbackUnread() async {
    try {
      await ref.read(feedbackRepoProvider).markRead();
    } catch (_) {
      /* 即使上报失败也清本地角标 */
    }
    ref.invalidate(feedbackUnreadProvider);
  }

  NavigationDestination _badged({
    required Widget icon,
    required Widget selectedIcon,
    required String label,
    required int count,
    Future<void> Function()? onCleared,
  }) {
    return NavigationDestination(
      icon: _TabIcon(icon: icon, count: count, onCleared: onCleared),
      selectedIcon:
          _TabIcon(icon: selectedIcon, count: count, onCleared: onCleared),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    // 免打扰（muted）会话的未读不计入底部导航红点，避免被静音群打扰。
    final msgCount = ref
            .watch(conversationsStreamProvider)
            .valueOrNull
            ?.where((c) => !c.muted)
            .fold<int>(0, (sum, c) => sum + c.unreadCount) ??
        0;
    final contactsCount = ref.watch(contactsBadgeProvider).valueOrNull ?? 0;
    final feedbackCount = ref.watch(feedbackUnreadProvider).valueOrNull ?? 0;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (i) {
          // 进入通讯录 tab：好友申请/群邀请视为已浏览，角标清除。
          if (i == 1 && i != widget.navigationShell.currentIndex) {
            unawaited(ref.read(contactsBadgeProvider.notifier).markSeen());
          }
          widget.navigationShell.goBranch(
            i,
            initialLocation: i == widget.navigationShell.currentIndex,
          );
        },
        destinations: [
          _badged(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l.navChats,
            count: msgCount,
            onCleared: _clearAllMessageUnread,
          ),
          _badged(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.contacts),
            label: l.navContacts,
            count: contactsCount,
            onCleared: () =>
                ref.read(contactsBadgeProvider.notifier).markSeen(),
          ),
          _badged(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.account_circle),
            label: l.navProfile,
            count: feedbackCount,
            onCleared: _clearFeedbackUnread,
          ),
        ],
      ),
    );
  }
}

/// 角标（未读数小红点）；按住拖出阈值后松手即可清除全部对应未读。
class DraggableBadge extends StatefulWidget {
  final int count;
  final Future<void> Function()? onCleared;

  const DraggableBadge({
    super.key,
    required this.count,
    this.onCleared,
  });

  @override
  State<DraggableBadge> createState() => _DraggableBadgeState();
}

class _DraggableBadgeState extends State<DraggableBadge>
    with SingleTickerProviderStateMixin {
  static const double _clearRadius = 58;

  Offset _offset = Offset.zero;
  bool _dragging = false;
  bool _popping = false;
  late final AnimationController _backCtrl;
  Animation<Offset>? _backAnim;

  @override
  void initState() {
    super.initState();
    _backCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() => setState(() {
            _offset = _backAnim?.value ?? Offset.zero;
          }));
  }

  @override
  void dispose() {
    _backCtrl.dispose();
    super.dispose();
  }

  bool get _willClear => _offset.distance > _clearRadius;

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _offset += d.delta);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_willClear) {
      // 小红点爆开消失，然后执行业务清除。
      setState(() {
        _dragging = false;
        _popping = true;
      });
      final task = widget.onCleared?.call();
      unawaited(Future.wait([
        Future<void>.delayed(const Duration(milliseconds: 220)),
        task ?? Future<void>.value(),
      ]).whenComplete(() {
        if (mounted) {
          setState(() {
            _popping = false;
            _offset = Offset.zero;
          });
        }
      }));
    } else {
      // 弹回原位。
      _backAnim = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
        CurvedAnimation(parent: _backCtrl, curve: Curves.easeOutBack),
      );
      _backCtrl.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _dragging = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();

    final text = widget.count > 99 ? '99+' : '${widget.count}';
    final badge = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => setState(() {
        _dragging = true;
        _backCtrl.stop();
      }),
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedScale(
        scale: _popping
            ? 0.2
            : _dragging
                ? 1.25
                : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _popping ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          child: Container(
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            padding: const EdgeInsets.symmetric(horizontal: 4.5),
            decoration: BoxDecoration(
              color: const Color(0xFFE5484D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Theme.of(context).colorScheme.surface, width: 1.6),
              boxShadow: _dragging
                  ? [
                      BoxShadow(
                          color: const Color(0x66E5484D),
                          blurRadius: 8,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );

    // 拖动时在原位显示目标圈：进入清除半径后高亮，松手红点即爆开。
    final target = _dragging
        ? IgnorePointer(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _willClear
                      ? const Color(0xFFE5484D)
                      : Theme.of(context).hintColor.withValues(alpha: 0.5),
                  width: 1.6,
                ),
                color: _willClear
                    ? const Color(0x33E5484D)
                    : Colors.transparent,
              ),
              child: Icon(Icons.close,
                  size: 13,
                  color: _willClear
                      ? const Color(0xFFE5484D)
                      : Theme.of(context).hintColor.withValues(alpha: 0.5)),
            ),
          )
        : const SizedBox.shrink();

    return SizedBox(
      width: 0,
      height: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -8,
            right: -17,
            child: target,
          ),
          Positioned(
            top: -8,
            right: 0,
            child: Transform.translate(
              offset: _offset,
              child: badge,
            ),
          ),
        ],
      ),
    );
  }
}

/// tab 图标 + 右上角可拖拽角标的组合。
class _TabIcon extends StatelessWidget {
  final Widget icon;
  final int count;
  final Future<void> Function()? onCleared;

  const _TabIcon({
    required this.icon,
    required this.count,
    this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          icon,
          if (count > 0)
            Positioned(
              top: -2,
              right: -6,
              child: DraggableBadge(count: count, onCleared: onCleared),
            ),
        ],
      ),
    );
  }
}
