import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/user_avatar.dart';
import '../contacts/user_profile_page.dart';

/// 群名片页：扫群二维码进入，可直接加入（OPEN）或提交申请（APPROVAL）。
class GroupProfilePage extends ConsumerStatefulWidget {
  final GroupBrief group;
  const GroupProfilePage({super.key, required this.group});

  @override
  ConsumerState<GroupProfilePage> createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends ConsumerState<GroupProfilePage> {
  late GroupBrief _group = widget.group;
  bool _busy = false;

  Future<void> _join() async {
    final l = AppL10n.of(context);
    if (_group.joinPolicy == 'APPROVAL') {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: Text(l.applyJoinGroup),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(hintText: l.applyJoinHint),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dctx).pop(false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.of(dctx).pop(true),
                child: Text(l.submitApplication)),
          ],
        ),
      );
      if (ok != true) return;
      await _run(() async {
        await ref.read(groupRepoProvider).join(_group.convId,
            message: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
        _toast(l.joinRequestSubmitted);
        setState(() {
          _group = GroupBrief(
            convId: _group.convId,
            name: _group.name,
            groupNumber: _group.groupNumber,
            avatarUrl: _group.avatarUrl,
            announcement: _group.announcement,
            joinPolicy: _group.joinPolicy,
            memberCount: _group.memberCount,
            relation: 'PENDING',
          );
        });
      });
      return;
    }
    await _run(() async {
      final r = await ref.read(groupRepoProvider).join(_group.convId);
      if (r.joined) {
        final g = GroupModel.fromJson(r.raw);
        await ref.read(realtimeProvider).refreshConversations();
        if (!mounted) return;
        context.pushReplacement('/chat/${g.convId}');
      }
    });
  }

  Future<void> _acceptInvite() async {
    final l = AppL10n.of(context);
    await _run(() async {
      final invites = await ref.read(groupRepoProvider).invites();
      final req = invites
          .where((r) => r.status == 'PENDING' && r.convId == _group.convId)
          .toList();
      if (req.isEmpty) {
        _toast(l.noPendingInvite, isError: true);
        return;
      }
      await ref.read(groupRepoProvider).acceptInvite(req.first.id);
      _toast(l.joinedGroupToast);
      await ref.read(realtimeProvider).refreshConversations();
      if (!mounted) return;
      context.pushReplacement('/chat/${_group.convId}');
    });
  }

  Future<void> _declineInvite() async {
    final l = AppL10n.of(context);
    await _run(() async {
      final invites = await ref.read(groupRepoProvider).invites();
      final req = invites
          .where((r) => r.status == 'PENDING' && r.convId == _group.convId)
          .toList();
      if (req.isNotEmpty) {
        await ref.read(groupRepoProvider).declineInvite(req.first.id);
      }
      setState(() {
        _group = GroupBrief(
          convId: _group.convId,
          name: _group.name,
          groupNumber: _group.groupNumber,
          avatarUrl: _group.avatarUrl,
          announcement: _group.announcement,
          joinPolicy: _group.joinPolicy,
          memberCount: _group.memberCount,
          relation: 'NONE',
        );
      });
      _toast(l.inviteIgnored, isInfo: true);
    });
  }

  Future<void> _run(Future<void> Function() body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await body();
    } catch (e) {
      if (mounted) _toast(AppL10n.of(context).errorWithReason('$e'), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m, {bool isError = false, bool isInfo = false}) {
    if (!mounted) return;
    if (isError) {
      AppToast.error(context, m);
    } else if (isInfo) {
      AppToast.info(context, m);
    } else {
      AppToast.success(context, m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.groupCardPageTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                          name: _group.name,
                          avatarUrl: _group.avatarUrl,
                          size: 88),
                      const SizedBox(height: 14),
                      Text(_group.name,
                          style: const TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('${l.memberCount(_group.memberCount)} · '
                          '${_group.joinPolicy == 'APPROVAL' ? l.approvalRequiredPolicy : l.openGroup}',
                          style: TextStyle(
                              color: theme.hintColor, fontSize: 13.5)),
                      if ((_group.groupNumber ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: _group.groupNumber!));
                            if (mounted) {
                              AppToast.info(context, l.groupNumberCopied);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tag_outlined,
                                    size: 13, color: Color(0xFF2EA6FF)),
                                const SizedBox(width: 3),
                                Text(l.groupNumberLabel('${_group.groupNumber}'),
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF2EA6FF),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if ((_group.announcement ?? '').isNotEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.campaign_outlined),
                      title: Text(l.groupAnnouncement),
                      subtitle: Text(_group.announcement!),
                    ),
                  ),
                // 群主卡片：点击跳转群主的名片资料页。
                if (_group.ownerId != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      onTap: () => context.push(
                        '/user-profile',
                        extra: UserProfileArgs(
                          user: UserBrief(
                            id: _group.ownerId!,
                            nickname: _group.ownerNickname ?? l.owner,
                            avatarUrl: _group.ownerAvatarUrl,
                            relation: _group.ownerRelation ?? 'NONE',
                          ),
                        ),
                      ),
                      leading: UserAvatar(
                        name: _group.ownerNickname ?? l.owner,
                        avatarUrl: _group.ownerAvatarUrl,
                        size: 44,
                      ),
                      title: Text(_group.ownerNickname ?? l.owner),
                      subtitle: Text(l.owner),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: _actionBar(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar(ThemeData theme) {
    final l = AppL10n.of(context);
    final loading = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
          strokeWidth: 2.4, color: theme.colorScheme.onPrimary),
    );
    switch (_group.relation) {
      case 'MEMBER':
        return FilledButton.icon(
          onPressed: () => context.pushReplacement('/chat/${_group.convId}'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(l.enterGroup),
        );
      case 'PENDING':
        return OutlinedButton(
            onPressed: null, child: Text(l.appliedPending));
      case 'INVITED':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
                onPressed: _busy ? null : _declineInvite,
                child: Text(l.ignore)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
                onPressed: _busy ? null : _acceptInvite,
                child: _busy ? loading : Text(l.acceptInvite)),
          ),
        ]);
      default:
        return FilledButton.icon(
          onPressed: _busy ? null : _join,
          icon: _busy ? loading : const Icon(Icons.group_add_outlined),
          label: Text(
              _group.joinPolicy == 'APPROVAL' ? l.applyJoinGroup : l.joinGroup),
        );
    }
  }
}
