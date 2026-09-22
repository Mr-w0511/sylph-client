import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// 群邀请：别人邀请我入群的待确认列表。
class GroupInvitesPage extends ConsumerStatefulWidget {
  const GroupInvitesPage({super.key});

  @override
  ConsumerState<GroupInvitesPage> createState() => _GroupInvitesPageState();
}

class _GroupInvitesPageState extends ConsumerState<GroupInvitesPage> {
  late Future<List<GroupRequestModel>> _future;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    // 包含已处理记录：通过/拒绝都会留档；待处理项排序置顶。
    _future = ref.read(groupRepoProvider).invites(history: true);
  }

  void _reload() {
    setState(() {
      _future = ref.read(groupRepoProvider).invites(history: true);
    });
  }

  Future<void> _accept(GroupRequestModel r) async {
    if (_busy.contains(r.id)) return;
    setState(() => _busy.add(r.id));
    try {
      await ref.read(groupRepoProvider).acceptInvite(r.id);
      await ref.read(realtimeProvider).refreshConversations();
      ref.read(socialTickProvider.notifier).state++;
      if (!mounted) return;
      AppToast.success(
          context,
          AppL10n.of(context)
              .joinedGroupWithName(r.groupName ?? AppL10n.of(context).unknownGroup));
      _reload();
    } catch (e) {
      _snack(AppL10n.of(context).errorWithReason('$e'));
      setState(() => _busy.remove(r.id));
    }
  }

  Future<void> _decline(GroupRequestModel r) async {
    if (_busy.contains(r.id)) return;
    setState(() => _busy.add(r.id));
    try {
      await ref.read(groupRepoProvider).declineInvite(r.id);
      ref.read(socialTickProvider.notifier).state++;
      _reload();
    } catch (e) {
      _snack(AppL10n.of(context).errorWithReason('$e'));
      setState(() => _busy.remove(r.id));
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    AppToast.error(context, m);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    ref.watch(socialTickProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.groupInvitesEntry)),
      body: FutureBuilder<List<GroupRequestModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          // 待处理置顶，其余按时间倒序（后端已按 id 倒序返回）。
          final list = [...(snap.data ?? const [])]
            ..sort((a, b) {
              final ap = a.status == 'PENDING' ? 0 : 1;
              final bp = b.status == 'PENDING' ? 0 : 1;
              return ap != bp
                  ? ap - bp
                  : (b.createdAt?.millisecondsSinceEpoch ?? b.id)
                      .compareTo(a.createdAt?.millisecondsSinceEpoch ?? a.id);
            });
          if (list.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 140),
              EmptyView(
                  icon: Icons.mark_email_read_outlined,
                  text: l.noGroupInvites),
            ]);
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom),
              children: list.map((r) {
                final loading = _busy.contains(r.id);
                return ListTile(
                  onTap: r.status == 'PENDING'
                      ? () => context.push('/chat/${r.convId}')
                      : null,
                  leading: UserAvatar(
                      name: r.groupName ?? l.unknownGroup,
                      avatarUrl: r.groupAvatarUrl,
                      size: 48),
                  title: Text(r.groupName ?? l.unknownGroup,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.inviterNickname != null
                          ? l.invitedByToJoin(r.inviterNickname!)
                          : l.receivedGroupInvite),
                      if (r.createdAt != null)
                        Text(TimeFmt.listLabel(r.createdAt,
                            today: l.today, yesterday: l.yesterday),
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Theme.of(context).hintColor)),
                    ],
                  ),
                  trailing: r.status == 'PENDING'
                      ? loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                    onPressed: () => _decline(r),
                                    child: Text(l.decline)),
                                FilledButton(
                                  onPressed: () => _accept(r),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  child: Text(l.joinAction),
                                ),
                              ],
                            )
                      : Text(r.status == 'ACCEPTED' ? l.joinedStatus : l.requestDeclined,
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12.5)),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
