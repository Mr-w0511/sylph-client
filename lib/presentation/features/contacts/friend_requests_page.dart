import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// 新的朋友：Tab1 收到的好友申请（接受/拒绝）；Tab2 我发出的申请（可撤回）。
class FriendRequestsPage extends ConsumerStatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  ConsumerState<FriendRequestsPage> createState() =>
      _FriendRequestsPageState();
}

class _FriendRequestsPageState extends ConsumerState<FriendRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Future<List<FriendRequestModel>>? _incoming;
  Future<List<FriendRequestModel>>? _outgoing;

  /// 正在处理（接受/拒绝/撤回）的申请 id 集合。
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _incoming = ref.read(socialRepoProvider).incomingRequests();
    _outgoing = ref.read(socialRepoProvider).outgoingRequests();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reloadIncoming() {
    setState(() {
      _incoming = ref.read(socialRepoProvider).incomingRequests();
    });
  }

  void _reloadOutgoing() {
    setState(() {
      _outgoing = ref.read(socialRepoProvider).outgoingRequests();
    });
  }

  Future<void> _accept(FriendRequestModel r) async {
    if (r.from == null || _busy.contains(r.id)) return;
    setState(() => _busy.add(r.id));
    try {
      await ref.read(socialRepoProvider).acceptRequest(r.id);
      await ref.read(realtimeProvider).refreshConversations();
      if (!mounted) return;
      AppToast.success(context,
          AppL10n.of(context).acceptedRequestFrom(r.from!.displayName));
      _reloadIncoming();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).errorWithReason('$e'));
      }
      setState(() => _busy.remove(r.id));
    }
  }

  Future<void> _reject(FriendRequestModel r) async {
    if (_busy.contains(r.id)) return;
    setState(() => _busy.add(r.id));
    try {
      await ref.read(socialRepoProvider).rejectRequest(r.id);
      _reloadIncoming();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).errorWithReason('$e'));
      }
      setState(() => _busy.remove(r.id));
    }
  }

  /// 撤回我发出的好友申请。
  Future<void> _cancel(FriendRequestModel r) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        content: Text(l.withdrawRequestConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l.rethink)),
          FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l.withdrawRequest)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(r.id));
    try {
      await ref.read(socialRepoProvider).cancelRequest(r.id);
      if (!mounted) return;
      AppToast.success(context, AppL10n.of(context).requestRevoked);
      _reloadOutgoing();
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).recallFailedReason('$e'));
      }
      setState(() => _busy.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    ref.watch(socialTickProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.newFriends),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l.receivedRequests),
            Tab(text: l.sentRequests),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tab,
          children: [
            _buildIncoming(),
            _buildOutgoing(),
          ],
        ),
      ),
    );
  }

  // ---------------- 收到的申请 ----------------

  Widget _buildIncoming() {
    final l = AppL10n.of(context);
    return FutureBuilder<List<FriendRequestModel>>(
      future: _incoming,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return ErrorView(message: '${snap.error}', onRetry: _reloadIncoming);
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return ListView(children: [
            const SizedBox(height: 140),
            EmptyView(
                icon: Icons.person_add_disabled_outlined,
                text: l.noIncomingRequests),
          ]);
        }
        final pending =
            list.where((r) => r.status == 'PENDING' && r.from != null).toList();
        final others = list.where((r) => r.status != 'PENDING').toList();
        return RefreshIndicator(
          onRefresh: () async => _reloadIncoming(),
          child: ListView(
            children: [
              if (pending.isNotEmpty) ...[
                _header(l.pendingCount(pending.length)),
                ...pending.map(_pendingTile),
              ],
              if (others.isNotEmpty) ...[
                _header(l.historySection),
                ...others.map(_incomingHistoryTile),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _pendingTile(FriendRequestModel r) {
    final l = AppL10n.of(context);
    final u = r.from!;
    final loading = _busy.contains(r.id);
    return ListTile(
      leading: UserAvatar(name: u.displayName, avatarUrl: u.avatarUrl, size: 48),
      title: Text(u.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((r.message ?? '').isNotEmpty)
            Text(r.message!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          if (r.createdAt != null)
            Text(TimeFmt.listLabel(r.createdAt,
                today: l.today, yesterday: l.yesterday),
                style: TextStyle(
                    fontSize: 11.5, color: Theme.of(context).hintColor)),
        ],
      ),
      trailing: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                    onPressed: () => _reject(r),
                    child: Text(AppL10n.of(context).decline)),
                FilledButton(
                  onPressed: () => _accept(r),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(AppL10n.of(context).accept),
                ),
              ],
            ),
    );
  }

  Widget _incomingHistoryTile(FriendRequestModel r) {
    final u = r.from;
    final l = AppL10n.of(context);
    final label = switch (r.status) {
      'ACCEPTED' => l.added,
      'REJECTED' => l.requestDeclined,
      'CANCELED' => l.requestCanceled,
      _ => r.status,
    };
    return ListTile(
      leading: UserAvatar(
          name: u?.displayName ?? '?',
          avatarUrl: u?.avatarUrl,
          size: 44),
      title: Text(u?.displayName ?? l.unknownPerson),
      subtitle:
          r.createdAt != null
              ? Text(TimeFmt.listLabel(r.createdAt,
                  today: l.today, yesterday: l.yesterday))
              : null,
      trailing:
          Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
    );
  }

  // ---------------- 我发出的 ----------------

  Widget _buildOutgoing() {
    final l = AppL10n.of(context);
    return FutureBuilder<List<FriendRequestModel>>(
      future: _outgoing,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return ErrorView(message: '${snap.error}', onRetry: _reloadOutgoing);
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return ListView(children: [
            const SizedBox(height: 140),
            EmptyView(
                icon: Icons.outbox_outlined, text: l.noOutgoingRequests),
          ]);
        }
        return RefreshIndicator(
          onRefresh: () async => _reloadOutgoing(),
          child: ListView(
            children: list.map(_outgoingTile).toList(),
          ),
        );
      },
    );
  }

  Widget _outgoingTile(FriendRequestModel r) {
    final u = r.to;
    final l = AppL10n.of(context);
    final (label, color) = switch (r.status) {
      'PENDING' => (l.waitVerify, Colors.orange),
      'ACCEPTED' => (l.added, Colors.green),
      'REJECTED' => (l.requestDeclined, Colors.blueGrey),
      'CANCELED' => (l.requestCanceled, Colors.blueGrey),
      _ => (r.status, Colors.blueGrey),
    };
    final loading = _busy.contains(r.id);
    return ListTile(
      leading: UserAvatar(
          name: u?.displayName ?? '?',
          avatarUrl: u?.avatarUrl,
          uid: u?.uid,
          size: 48),
      title: Text(u?.displayName ?? l.unknownPerson,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((u?.uid ?? '').isNotEmpty)
            Text('UID: ${u!.uid}',
                style: const TextStyle(fontSize: 12.5)),
          if (r.createdAt != null)
            Text(TimeFmt.listLabel(r.createdAt,
                today: l.today, yesterday: l.yesterday),
                style: TextStyle(
                    fontSize: 11.5, color: Theme.of(context).hintColor)),
        ],
      ),
      trailing: r.status == 'PENDING'
          ? (loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : TextButton(
                  onPressed: () => _cancel(r),
                  child: Text(l.recall),
                ))
          : _StatusChip(label: label, color: color),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );
}

/// 状态小标签。
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
    );
  }
}
