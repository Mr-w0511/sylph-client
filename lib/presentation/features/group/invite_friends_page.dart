import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// 群设置 → 邀请好友：多选好友后发送群邀请（对方需确认）。
class InviteFriendsPage extends ConsumerStatefulWidget {
  final int convId;
  const InviteFriendsPage({super.key, required this.convId});

  @override
  ConsumerState<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends ConsumerState<InviteFriendsPage> {
  final Set<int> _selected = {};
  bool _sending = false;
  String _keyword = '';

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final n = await ref
          .read(groupRepoProvider)
          .invite(widget.convId, _selected.toList());
      ref.read(socialTickProvider.notifier).state++;
      if (!mounted) return;
      AppToast.success(
          context, AppL10n.of(context).inviteSentCount(n));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).sendFailedReason('$e'));
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final friendsAsync = ref.watch(_invitableFriends(widget.convId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.inviteFriends),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _keyword = v.trim()),
              decoration: InputDecoration(
                hintText: l.searchFriendsHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: friendsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                  message: '$e',
                  onRetry: () =>
                      ref.invalidate(_invitableFriends(widget.convId))),
              data: (friends) {
                final list = friends
                    .where((f) =>
                        _keyword.isEmpty ||
                        f.user.displayName.contains(_keyword))
                    .toList();
                if (list.isEmpty) {
                  return EmptyView(
                      icon: Icons.people_outline, text: l.noInvitableFriends);
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final u = list[i].user;
                    return CheckboxListTile(
                      value: _selected.contains(u.id),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selected.add(u.id);
                        } else {
                          _selected.remove(u.id);
                        }
                      }),
                      secondary: UserAvatar(
                          name: u.displayName,
                          avatarUrl: u.avatarUrl,
                          uid: u.uid,
                          size: 44),
                      title: Text(u.displayName),
                      subtitle: u.uid?.isNotEmpty == true
                          ? Text('UID: ${u.uid}')
                          : null,
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      (_selected.isEmpty || _sending) ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l.inviteWithCount(_selected.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 可邀请好友 = 全部好友 - 已在群成员 - 已待处理。#10 同时过滤官方助手。
final _invitableFriends = FutureProvider.autoDispose
    .family<List<FriendView>, int>((ref, convId) async {
  final all = await ref.read(socialRepoProvider).friends();
  List<GroupMember> members;
  try {
    members = await ref.read(groupRepoProvider).members(convId);
  } catch (_) {
    members = const [];
  }
  final existing = members.map((m) => m.userId).toSet();
  return all
      .where((f) =>
          !existing.contains(f.user.id) &&
          f.user.uid != kSystemAssistantUid)
      .toList();
});
