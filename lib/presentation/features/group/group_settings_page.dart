import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/mute_duration_sheet.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
import '../qrcode/qrcode_page.dart';
import 'invite_friends_page.dart';

/// 角色排序权重：群主 → 管理员 → 成员。
int _roleTier(String role) => switch (role) {
      'OWNER' => 0,
      'ADMIN' => 1,
      _ => 2,
    };

/// 昵称首字拼音首字母（非字母统一排到 Z 之后）。
String _nameSortKey(String name) {
  if (name.trim().isEmpty) return '[';
  final short = PinyinHelper.getShortPinyin(name);
  final c = short[0].toUpperCase();
  return RegExp(r'^[A-Z]$').hasMatch(c) ? c : '[';
}

/// 群管理：资料、群二维码、成员管理（管理员/禁言/踢人）、进群审核、退群/解散。
class GroupSettingsPage extends ConsumerStatefulWidget {
  final int convId;
  const GroupSettingsPage({super.key, required this.convId});

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  GroupModel? _group;
  List<GroupMember> _members = [];
  int? _myId;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _isManager =>
      _group?.myRole == 'OWNER' || _group?.myRole == 'ADMIN';
  bool get _isOwner => _group?.myRole == 'OWNER';

  @override
  void initState() {
    super.initState();
    _myId = ref.read(sessionControllerProvider).user?.id;
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    // #10 静默刷新：仅在首次进入时显示全屏 LoadingView，
    // 后续更新资料后的刷新保持当前 UI 不闪屏。
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final g = await ref.read(groupRepoProvider).detail(widget.convId);
      final m = await ref.read(groupRepoProvider).members(widget.convId);
      // 群主排第一、管理员第二，同角色内按昵称首字拼音首字母 A-Z。
      m.sort((a, b) {
        final byRole = _roleTier(a.role).compareTo(_roleTier(b.role));
        if (byRole != 0) return byRole;
        final na = a.groupNickname?.isNotEmpty == true
            ? a.groupNickname!
            : (a.nickname ?? '用户${a.userId}');
        final nb = b.groupNickname?.isNotEmpty == true
            ? b.groupNickname!
            : (b.nickname ?? '用户${b.userId}');
        return _nameSortKey(na).compareTo(_nameSortKey(nb));
      });
      if (!mounted) return;
      setState(() {
        _group = g;
        _members = m;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() body, {String? okTip}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await body();
      if (okTip != null && mounted) {
        AppToast.success(context, okTip);
      }
      // 静默刷新：不再触发全屏 LoadingView
      await _load(silent: true);
      await ref.read(realtimeProvider).refreshConversations();
      ref.read(socialTickProvider.notifier).state++;
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).errorWithReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- 资料编辑 ----------

  Future<void> _editAvatar() async {
    final l = AppL10n.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      final file = result?.files.single;
      if (file?.bytes == null) return;
      final media = await ref.read(mediaRepoProvider).uploadImage(
            bytes: file!.bytes!,
            filename: file.name,
          );
      await _run(
        () async {
          await ref.read(groupRepoProvider).updateSettings(widget.convId,
              avatarUrl: media.url);
          // 会话列表 DTO 不含群头像，上传成功后立即回写本地缓存。
          await ref
              .read(conversationsDaoProvider)
              .setGroupAvatar(widget.convId, media.url);
        },
        okTip: l.groupAvatarUpdated,
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, l.avatarUploadFailedReason('$e'));
      }
    }
  }

  Future<void> _editNameAnnouncement() async {
    final l = AppL10n.of(context);
    final g = _group;
    if (g == null) return;
    final nameCtrl = TextEditingController(text: g.name);
    final annCtrl = TextEditingController(text: g.announcement ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.editGroupProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              maxLength: 128,
              decoration: InputDecoration(labelText: l.groupName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: annCtrl,
              maxLines: 3,
              maxLength: 512,
              decoration: InputDecoration(labelText: l.groupAnnouncement),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(dctx).pop(true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    await _run(
      () => ref.read(groupRepoProvider).updateSettings(widget.convId,
          name: name,
          announcement: annCtrl.text.trim().isEmpty
              ? ''
              : annCtrl.text.trim()),
      okTip: l.groupProfileUpdated,
    );
  }

  Future<void> _editMyNickname() async {
    final l = AppL10n.of(context);
    final ctrl = TextEditingController(text: _group?.myNickname ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.myNicknameInGroup),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 64,
          decoration:
              InputDecoration(hintText: l.nicknameLeaveEmptyHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(dctx).pop(true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => ref
          .read(groupRepoProvider)
          .setMemberNickname(widget.convId, _myId, ctrl.text.trim()),
      okTip: l.groupNicknameUpdated,
    );
  }

  // ---------- 二维码 ----------

  Future<void> _showQrcode() async {
    final g = _group;
    if (g == null) return;
    final l = AppL10n.of(context);
    String token = g.qrcodeToken ?? '';
    if (token.isEmpty) {
      token = await ref.read(groupRepoProvider).qrcode(widget.convId);
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QrcodePage(
        title: l.groupQrcode,
        content: 'sylph://g/$token',
        name: g.name,
        avatarUrl: g.avatarUrl,
        subtitle: l.memberCount(g.memberCount),
        onShareInApp: _showShareGroup,
        onReset: _isManager
            ? () async {
                final t =
                    await ref.read(groupRepoProvider).resetQrcode(widget.convId);
                return 'sylph://g/$t';
              }
            : null,
      ),
    ));
  }

  // ---------- 分享群聊 ----------

  /// #13 站内分享群聊：从好友列表中挑选一位，发送 GROUP_CARD 名片到该单聊。
  /// 官方助手不列入可选范围。
  Future<void> _showShareGroup() async {
    final g = _group;
    if (g == null) return;
    final l = AppL10n.of(context);
    final existingMemberIds =
        _members.map((m) => m.userId).toSet();
    List<FriendView> friends;
    try {
      friends = await ref.read(socialRepoProvider).friends();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, l.loadFriendsFailedReason('$e'));
      }
      return;
    }
    if (!mounted) return;
    // 过滤掉已在群内、官方助手
    final list = friends
        .where((f) =>
            !existingMemberIds.contains(f.user.id) &&
            f.user.uid != kSystemAssistantUid)
        .toList();
    if (list.isEmpty) {
      AppToast.info(context, l.noFriendsToShare);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sctx) => FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.shareGroupToFriend,
                  style: Theme.of(sctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(sctx).bottom),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final f = list[i];
                  final u = f.user;
                  return ListTile(
                    leading: UserAvatar(
                        name: u.displayName,
                        avatarUrl: u.avatarUrl,
                        uid: u.uid,
                        size: 44),
                    title: Text(u.displayName),
                    subtitle: u.uid?.isNotEmpty == true
                        ? Text('UID: ${u.uid}')
                        : null,
                    onTap: () async {
                      Navigator.pop(sctx);
                      try {
                        await ref
                            .read(groupRepoProvider)
                            .shareGroupCard(widget.convId, u.id);
                        await ref
                            .read(realtimeProvider)
                            .refreshConversations();
                        if (mounted) {
                          AppToast.success(context, l.sharedTo(u.displayName));
                        }
                      } catch (e) {
                        if (mounted) {
                          AppToast.error(context, l.shareFailedReason('$e'));
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 成员操作 ----------

  Future<void> _memberSheet(GroupMember m) async {
    final l = AppL10n.of(context);
    final isMe = m.userId == _myId;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bctx) {
        final name = m.groupNickname?.isNotEmpty == true
            ? m.groupNickname!
            : (m.nickname ?? l.userFallbackId('${m.userId}'));
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    UserAvatar(
                        name: name, avatarUrl: m.avatarUrl, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text(_roleLabel(l, m.role),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Theme.of(bctx).hintColor)),
                        ],
                      ),
                    ),
                    if (m.isMuted)
                      Chip(
                          label: Text(l.mutedChip),
                          visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
              const Divider(height: 1),
              // #9 设群昵称仅群主/管理员可用；#8 管理操作统一走权限矩阵：
              // OWNER 不可被操作；ADMIN 只能被 OWNER 操作。
              if (isMe && _isManager)
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l.editMyGroupNickname),
                  onTap: () {
                    Navigator.pop(bctx);
                    _editMyNickname();
                  },
                ),
              if (!isMe &&
                  _isManager &&
                  m.role != 'OWNER' &&
                  (m.role != 'ADMIN' || _isOwner)) ...[
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l.setMemberNicknameTitle),
                  onTap: () {
                    Navigator.pop(bctx);
                    _setMemberNickname(m);
                  },
                ),
                if (m.role == 'ADMIN')
                  ListTile(
                    leading: const Icon(Icons.remove_moderator_outlined),
                    title: Text(l.removeAdmin),
                    onTap: () {
                      Navigator.pop(bctx);
                      _run(
                        () => ref
                            .read(groupRepoProvider)
                            .setRole(widget.convId, m.userId, 'MEMBER'),
                        okTip: l.adminRemoved,
                      );
                    },
                  )
                else if (_isOwner)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(l.makeAdmin),
                    onTap: () {
                      Navigator.pop(bctx);
                      _run(
                        () => ref
                            .read(groupRepoProvider)
                            .setRole(widget.convId, m.userId, 'ADMIN'),
                        okTip: l.adminSet,
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.volume_off_outlined),
                  title: Text(m.isMuted ? l.unmuteMember : l.muteMember),
                  onTap: () {
                    Navigator.pop(bctx);
                    _muteMenu(m);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_remove_outlined,
                      color: Theme.of(bctx).colorScheme.error),
                  title: Text(l.removeMember,
                      style: TextStyle(
                          color: Theme.of(bctx).colorScheme.error)),
                  onTap: () {
                    Navigator.pop(bctx);
                    _kickConfirm(m);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _roleLabel(AppL10n l, String role) => switch (role) {
        'OWNER' => l.owner,
        'ADMIN' => l.admin,
        _ => l.memberRole,
      };

  Future<void> _setMemberNickname(GroupMember m) async {
    final l = AppL10n.of(context);
    final ctrl = TextEditingController(text: m.groupNickname ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.setNicknameFor(
            m.nickname ?? l.userFallbackId('${m.userId}'))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 64,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(dctx).pop(true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => ref.read(groupRepoProvider).setMemberNickname(
          widget.convId, m.userId, ctrl.text.trim()),
      okTip: l.groupNicknameUpdated,
    );
  }

  Future<void> _muteMenu(GroupMember m) async {
    final l = AppL10n.of(context);
    // #8 统一禁言面板：1 小时 / 24 小时 / 7 天 / 30 天 / 自定义到期时刻。
    final seconds =
        await showMuteDurationSheet(context, currentlyMuted: m.isMuted);
    if (seconds == null) return;
    await _run(
      () => ref
          .read(groupRepoProvider)
          .mute(widget.convId, m.userId, seconds == 0 ? null : seconds),
      okTip: seconds == 0 ? l.unmutedOk : l.mutedOk,
    );
  }

  Future<void> _kickConfirm(GroupMember m) async {
    final l = AppL10n.of(context);
    final name = m.groupNickname?.isNotEmpty == true
        ? m.groupNickname!
        : (m.nickname ?? l.theMember);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.removeMember),
        content: Text(l.removeMemberConfirm(name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dctx).colorScheme.error),
              onPressed: () => Navigator.of(dctx).pop(true),
              child: Text(l.removeAction)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => ref.read(groupRepoProvider).kick(widget.convId, m.userId),
      okTip: l.memberRemoved,
    );
  }

  // ---------- 进群审核 ----------

  Future<void> _joinRequests() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bctx) => _JoinRequestsSheet(
        convId: widget.convId,
        onChanged: () {
          Navigator.pop(bctx);
          _load(silent: true);
        },
      ),
    );
  }

  /// 我发起的入群申请（跨全部群）。
  Future<void> _myJoinRequests() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bctx) => const _MyJoinRequestsSheet(),
    );
  }

  // ---------- 退群 / 解散 ----------

  Future<void> _leaveOrDissolve() async {
    final l = AppL10n.of(context);
    final dissolve = _isOwner;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(dissolve ? l.dissolveGroup : l.leaveGroupTitle),
        content: Text(dissolve ? l.dissolveConfirm : l.leaveGroupConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dctx).colorScheme.error),
              onPressed: () => Navigator.of(dctx).pop(true),
              child: Text(dissolve ? l.dissolveAction : l.leaveAction)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      if (dissolve) {
        await ref.read(groupRepoProvider).dissolve(widget.convId);
      } else {
        await ref.read(groupRepoProvider).leave(widget.convId);
      }
      await ref.read(realtimeProvider).refreshConversations();
      ref.read(socialTickProvider.notifier).state++;
      if (!mounted) return;
      context.go('/conversations');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, l.errorWithReason('$e'));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(socialTickProvider);
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    final g = _group;
    if (g == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: _error ?? AppL10n.of(context).loadFailed,
            onRetry: _load),
      );
    }
    final theme = Theme.of(context);
    final l = AppL10n.of(context);

    // #11 群已解散：仅展示解散提示 + 删除会话按钮
    if (g.dissolved) {
      return Scaffold(
        appBar: AppBar(title: Text(l.groupSettings)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 64, color: theme.hintColor),
                const SizedBox(height: 16),
                Text(l.groupDissolved,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(l.groupDissolvedHint,
                    style:
                        TextStyle(color: theme.hintColor, fontSize: 13.5)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(conversationRepoProvider)
                          .hide(widget.convId);
                      await ref
                          .read(realtimeProvider)
                          .refreshConversations();
                      if (!mounted) return;
                      context.go('/conversations');
                    } catch (e) {
                      if (mounted) {
                        AppToast.error(context, l.errorWithReason('$e'));
                      }
                    }
                  },
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  label: Text(l.deleteConvTitle,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.groupSettings),
        actions: [
          if (_isManager)
            IconButton(
              tooltip: l.joinRequestsTitle,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              onPressed: _busy ? null : _joinRequests,
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: EdgeInsets.fromLTRB(12, 8, 12,
              32 + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isManager ? _editAvatar : null,
                      child: UserAvatar(
                          name: g.name, avatarUrl: g.avatarUrl, size: 64),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${l.memberCount(g.memberCount)} · '
                              '${g.joinPolicy == 'APPROVAL' ? l.approvalRequiredPolicy : l.openGroup}',
                              style: TextStyle(
                                  fontSize: 12.5, color: theme.hintColor)),
                        ],
                      ),
                    ),
                    if (_isManager)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _editNameAnnouncement,
                      ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.tag_outlined),
                  title: Text(l.groupNumberTitle),
                  subtitle: Text((g.groupNumber ?? '').isEmpty
                      ? l.notAssigned
                      : g.groupNumber!),
                  trailing: (g.groupNumber ?? '').isEmpty
                      ? null
                      : const Icon(Icons.copy_all_outlined, size: 20),
                  onTap: (g.groupNumber ?? '').isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                              ClipboardData(text: g.groupNumber!));
                          if (mounted) {
                            AppToast.info(context, l.groupNumberCopied);
                          }
                        },
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                // #9 "我在本群的昵称"仅群主/管理员可见可用（后端同样强校验）。
                if (_isManager) ...[
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(l.myNicknameInGroup),
                    subtitle: Text(g.myNickname?.isNotEmpty == true
                        ? g.myNickname!
                        : l.useDefaultNickname),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editMyNickname,
                  ),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.qr_code_2_outlined),
                  title: Text(l.groupQrcode),
                  subtitle: Text(l.groupQrcodeSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showQrcode,
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1),
                  title: Text(l.inviteFriendsTitle),
                  subtitle: Text(l.inviteFriendsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          InviteFriendsPage(convId: widget.convId),
                    ));
                    _load(silent: true);
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                // #13 分享群聊（站内分享：向好友单聊发送 GROUP_CARD 名片）
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text(l.shareGroup),
                  subtitle: Text(l.shareGroupSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showShareGroup,
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                ListTile(
                  leading: const Icon(Icons.outbox_outlined),
                  title: Text(l.myJoinRequestsTitle),
                  subtitle: Text(l.myJoinRequestsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _myJoinRequests,
                ),
                if (_isManager) ...[
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SwitchListTile(
                    secondary: Icon(
                        g.approvalRequired
                            ? Icons.verified_user_outlined
                            : Icons.public,
                        color: theme.colorScheme.primary),
                    title: Text(l.approvalToggle),
                    subtitle: Text(
                        g.approvalRequired
                            ? l.approvalOnSubtitle
                            : l.approvalOffSubtitle,
                        style: TextStyle(fontSize: 12.5, color: theme.hintColor)),
                    value: g.approvalRequired,
                    onChanged: (v) => _run(
                      () => ref.read(groupRepoProvider).updateSettings(
                          widget.convId,
                          joinPolicy: v ? 'APPROVAL' : 'OPEN'),
                    ),
                  ),
                ],
              ]),
            ),
            if ((g.announcement ?? '').isNotEmpty)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(l.groupAnnouncement),
                  subtitle: Text(g.announcement!),
                ),
              ),
            _section(l.groupMembersCount(_members.length)),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  // #10 成员超过 8 个时默认只展示前 8 个，其余进全部成员页。
                  for (var i = 0;
                      i < (_members.length > 8 ? 8 : _members.length);
                      i++) ...[
                    if (i > 0)
                      const Divider(indent: 70, endIndent: 16, height: 1),
                    _memberTile(_members[i]),
                  ],
                  if (_members.length > 8) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.groups_2_outlined,
                            color: theme.colorScheme.primary),
                      ),
                      title: Text(l.viewAllMembers(_members.length),
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                          '/group/${widget.convId}/members'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(_isOwner ? Icons.delete_forever : Icons.logout),
              label: Text(_isOwner ? l.dissolveGroup : l.leaveGroupTitle),
              onPressed: _busy ? null : _leaveOrDissolve,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _memberTile(GroupMember m) {
    final l = AppL10n.of(context);
    final isMe = m.userId == _myId;
    final name = m.groupNickname?.isNotEmpty == true
        ? m.groupNickname!
        : (m.nickname ?? l.userFallbackId('${m.userId}'));
    return ListTile(
      leading: UserAvatar(name: name, avatarUrl: m.avatarUrl, size: 44),
      title: Row(
        children: [
          Flexible(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (m.role == 'OWNER')
            _roleBadge(l.owner, const Color(0xFFF2994A)),
          if (m.role == 'ADMIN')
            _roleBadge(l.admin, const Color(0xFF2EA6FF)),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(l.meMarker,
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor)),
            ),
        ],
      ),
      subtitle: m.isMuted
          ? Row(
              children: [
                const Icon(Icons.volume_off_outlined, size: 14),
                const SizedBox(width: 4),
                Text(l.mutedBadge, style: const TextStyle(fontSize: 12.5)),
              ],
            )
          : null,
      trailing: m.role == 'OWNER'
          ? null
          : const Icon(Icons.more_horiz),
      onTap: () => _memberSheet(m),
    );
  }

  /// 名字旁的小角色标签。
  Widget _roleBadge(String text, Color color) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

/// 进群申请底部弹层。
class _JoinRequestsSheet extends ConsumerStatefulWidget {
  final int convId;
  final VoidCallback onChanged;
  const _JoinRequestsSheet({required this.convId, required this.onChanged});

  @override
  ConsumerState<_JoinRequestsSheet> createState() =>
      _JoinRequestsSheetState();
}

class _JoinRequestsSheetState extends ConsumerState<_JoinRequestsSheet> {
  late Future<List<GroupRequestModel>> _future;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _future = ref.read(groupRepoProvider).joinRequests(widget.convId);
  }

  void _reload() {
    setState(() {
      _future = ref.read(groupRepoProvider).joinRequests(widget.convId);
    });
  }

  Future<void> _approve(GroupRequestModel r) async {
    setState(() => _busy.add(r.id));
    try {
      await ref.read(groupRepoProvider).approveJoin(widget.convId, r.id);
      _reload();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).errorWithReason('$e'));
      }
      setState(() => _busy.remove(r.id));
    }
  }

  Future<void> _decline(GroupRequestModel r) async {
    setState(() => _busy.add(r.id));
    try {
      await ref.read(groupRepoProvider).declineJoin(widget.convId, r.id);
      _reload();
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).errorWithReason('$e'));
      }
      setState(() => _busy.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: FutureBuilder<List<GroupRequestModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final list = (snap.data ?? const [])
              .where((r) => r.kind == 'JOIN')
              .toList();
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(40),
              child: EmptyView(
                  icon: Icons.inbox_outlined, text: l.noJoinRequests),
            );
          }
          return ListView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom),
            children: list.map((r) {
              final loading = _busy.contains(r.id);
              return ListTile(
                leading: UserAvatar(
                    name: r.userNickname ?? l.unknownUser,
                    avatarUrl: r.userAvatarUrl,
                    size: 44),
                title: Text(r.userNickname ??
                    l.userFallbackId('${r.userId ?? ''}')),
                subtitle: Text((r.message?.isNotEmpty == true)
                    ? r.message!
                    : l.joinRequestDefaultMsg),
                trailing: r.status == 'PENDING'
                    ? loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.2))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                  onPressed: () => _decline(r),
                                  child: Text(l.decline)),
                              FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                  ),
                                  onPressed: () => _approve(r),
                                  child: Text(l.approve)),
                            ],
                          )
                    : Text(
                        r.status == 'ACCEPTED'
                            ? l.requestAccepted
                            : l.requestDeclined,
                        style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12.5)),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// 我发起的入群申请弹层：列出群名、状态与申请时间。
class _MyJoinRequestsSheet extends ConsumerStatefulWidget {
  const _MyJoinRequestsSheet();

  @override
  ConsumerState<_MyJoinRequestsSheet> createState() =>
      _MyJoinRequestsSheetState();
}

class _MyJoinRequestsSheetState
    extends ConsumerState<_MyJoinRequestsSheet> {
  late Future<List<GroupRequestModel>> _future = _load();

  Future<List<GroupRequestModel>> _load() =>
      ref.read(groupRepoProvider).myJoinRequests();

  void _retry() => setState(() => _future = _load());

  ({String text, Color color}) _statusStyle(
          AppL10n l, String status, ThemeData theme) =>
      switch (status) {
        'PENDING' => (text: l.statusPendingReview, color: const Color(0xFFF2994A)),
        'ACCEPTED' => (text: l.requestAccepted, color: const Color(0xFF34C78A)),
        'REJECTED' => (text: l.requestDeclined, color: theme.colorScheme.error),
        'CANCELED' => (text: l.requestCanceled, color: theme.hintColor),
        _ => (text: status, color: theme.hintColor),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return FutureBuilder<List<GroupRequestModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snap.hasError) {
              return ErrorView(
                message: '${snap.error}',
                onRetry: _retry,
              );
            }
            final list = (snap.data ?? const [])
                .where((r) => r.kind == 'JOIN')
                .toList();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: EmptyView(
                    icon: Icons.outbox_outlined, text: l.noMyRequests),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l.myJoinRequestsTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.viewPaddingOf(context).bottom),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final r = list[i];
                      final st = _statusStyle(l, r.status, theme);
                      return ListTile(
                        leading: UserAvatar(
                          name: r.groupName ?? l.unknownGroup,
                          avatarUrl: r.groupAvatarUrl,
                          size: 44,
                        ),
                        title: Text(r.groupName ??
                            l.groupFallbackId('${r.convId}'),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          r.createdAt != null
                              ? TimeFmt.bubble(r.createdAt!)
                              : '',
                          style: TextStyle(
                              fontSize: 12.5, color: theme.hintColor),
                        ),
                        trailing: Text(st.text,
                            style: TextStyle(
                                color: st.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
