import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/mute_duration_sheet.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/user_avatar.dart';

/// 名片页路由参数：[groupConvId] 非空表示从群聊内打开，
/// 资料页额外展示群主/管理员可用的群管理操作区。
class UserProfileArgs {
  final UserBrief user;
  final int? groupConvId;
  const UserProfileArgs({required this.user, this.groupConvId});
}

/// 用户名片页：搜索结果 / 二维码扫码 / 通讯录点击 / 群聊内头像点击进入。
class UserProfilePage extends ConsumerStatefulWidget {
  final UserBrief user;
  final int? groupConvId;
  const UserProfilePage({super.key, required this.user, this.groupConvId});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  late UserBrief _user = widget.user;
  bool _busy = false;
  // #7 备注展示同步：从好友列表加载并在资料页展示。
  String? _remark;

  @override
  void initState() {
    super.initState();
    // #8 无条件拉一次好友列表校正关系：
    // 群消息/会话里缓存的 relation 可能缺失，导致已是好友仍显示"添加到通讯录"。
    _syncFriendRelation();
  }

  Future<void> _syncFriendRelation() async {
    // 自身检测：查看自己资料时直接标记 SELF，避免误显示"添加到通讯录"。
    final myId = ref.read(sessionControllerProvider).user?.id;
    if (_user.id == myId) {
      if (_user.relation != 'SELF') {
        if (!mounted) return;
        setState(() => _user = _copyRelation('SELF'));
      }
      return;
    }
    try {
      final friends = await ref.read(socialRepoProvider).friends();
      final match = friends
          .where((f) => f.user.id == _user.id)
          .cast<FriendView?>()
          .firstWhere((_) => true, orElse: () => null);
      if (!mounted) return;
      if (match != null) {
        setState(() {
          _remark = match.remark;
          if (_user.relation != 'FRIEND' && _user.relation != 'SELF') {
            _user = UserBrief(
              id: _user.id,
              uid: _user.uid,
              username: _user.username,
              nickname: _user.nickname,
              avatarUrl: _user.avatarUrl,
              bio: _user.bio,
              gender: _user.gender,
              relation: 'FRIEND',
            );
          }
        });
      } else if (_user.relation == 'FRIEND') {
        _loadRemark();
      }
    } catch (_) {
      // 加载失败静默
    }
  }

  Future<void> _loadRemark() async {
    try {
      final friends = await ref.read(socialRepoProvider).friends();
      final match = friends
          .where((f) => f.user.id == _user.id)
          .map((f) => f.remark)
          .firstOrNull;
      if (mounted) setState(() => _remark = match);
    } catch (_) {
      // 加载失败静默
    }
  }

  String get _genderLabel {
    final l = AppL10n.of(context);
    switch (_user.gender) {
      case 'MALE':
        return l.genderMale;
      case 'FEMALE':
        return l.genderFemale;
      default:
        return l.unknownGender; // null / UNKNOWN
    }
  }

  Future<void> _sendRequest() async {
    final l = AppL10n.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.sendFriendRequest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.greetingWithName(
                  ref.read(sessionControllerProvider).user?.nickname ?? ''),
              style: TextStyle(color: Theme.of(dctx).hintColor, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(hintText: l.requestHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l.sendRequestAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref
          .read(socialRepoProvider)
          .sendRequest(
            targetUserId: _user.id,
            message: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
          );
      _toast(l.requestSent);
      setState(
        () => _user = UserBrief(
          id: _user.id,
          uid: _user.uid,
          username: _user.username,
          nickname: _user.nickname,
          avatarUrl: _user.avatarUrl,
          bio: _user.bio,
          gender: _user.gender,
          relation: 'PENDING_SENT',
        ),
      );
      ref.read(socialTickProvider.notifier).state++;
    });
  }

  Future<void> _acceptIncoming() async {
    final l = AppL10n.of(context);
    await _run(() async {
      final list = await ref.read(socialRepoProvider).incomingRequests();
      final req = list
          .where((r) => r.status == 'PENDING' && r.from?.id == _user.id)
          .toList();
      if (req.isEmpty) {
        _toast(l.noPendingRequest, isError: true);
        return;
      }
      await ref.read(socialRepoProvider).acceptRequest(req.first.id);
      _toast(l.friendAdded);
      setState(() => _user = _copyRelation('FRIEND'));
      ref.read(socialTickProvider.notifier).state++;
      await ref.read(realtimeProvider).refreshConversations();
    });
  }

  Future<void> _startChat() async {
    await _run(() async {
      final conv = await ref
          .read(conversationRepoProvider)
          .createSingle(_user.id);
      await ref.read(realtimeProvider).refreshConversations();
      if (!mounted) return;
      context.pushReplacement('/chat/${conv.id}');
    });
  }

  Future<void> _editRemark() async {
    final l = AppL10n.of(context);
    final cur = _remark;
    if (!mounted) return;
    final ctrl = TextEditingController(text: cur ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.setRemarkTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 64,
          decoration: InputDecoration(hintText: l.setRemarkHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final text = ctrl.text.trim();
      await ref
          .read(socialRepoProvider)
          .setRemark(_user.id, text.isEmpty ? null : text);
      // #7 保存后立即更新本地备注显示，并刷新会话列表展示名。
      setState(() => _remark = text.isEmpty ? null : text);
      await ref.read(realtimeProvider).refreshConversations();
      _toast(l.remarkSaved);
    });
  }

  Future<void> _deleteFriend() async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.deleteFriendTitle),
        content: Text(l.deleteFriendConfirm(_user.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(socialRepoProvider).deleteFriend(_user.id);
      _toast(l.friendDeleted);
      setState(() => _user = _copyRelation('NONE'));
      ref.read(socialTickProvider.notifier).state++;
    });
  }

  Future<void> _copyUid() async {
    final uid = _user.uid;
    if (uid == null || uid.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: uid));
    if (mounted) AppToast.success(context, AppL10n.of(context).uidCopied);
  }

  Future<void> _blockUser() async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.blockUserTitle),
        content: Text(l.blockConfirmName(_user.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l.blockAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(socialRepoProvider).block(_user.id);
      _toast(l.blocked);
      ref.read(socialTickProvider.notifier).state++;
      if (mounted) context.pop();
    });
  }

  /// 撤回我发出的好友申请。
  Future<void> _cancelSentRequest() async {
    final l = AppL10n.of(context);
    await _run(() async {
      final list = await ref.read(socialRepoProvider).outgoingRequests();
      final req = list
          .where((r) => r.status == 'PENDING' && r.to?.id == _user.id)
          .toList();
      if (req.isEmpty) {
        _toast(l.noPendingVerify, isError: true);
        return;
      }
      await ref.read(socialRepoProvider).cancelRequest(req.first.id);
      _toast(l.requestRevoked, isInfo: true);
      setState(() => _user = _copyRelation('NONE'));
      ref.read(socialTickProvider.notifier).state++;
    });
  }

  Future<void> _reportUser() async {
    await showReportDialog(
      context,
      ref,
      targetType: 'USER',
      targetId: _user.id,
    );
  }

  // ===== #8 群管理：设昵称 / 管理员 / 禁言（自定义时长）/ 移除 =====

  bool get _isGroupContext => widget.groupConvId != null;

  Future<void> _groupRun(Future<void> Function() body, String okTip) async {
    await _run(() async {
      await body();
      final cid = widget.groupConvId!;
      ref.invalidate(groupMembersProvider(cid));
      ref.invalidate(groupDetailProvider(cid));
      _toast(okTip);
    });
  }

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
    await _groupRun(
      () => ref.read(groupRepoProvider).setMemberNickname(
          widget.groupConvId!, m.userId, ctrl.text.trim()),
      l.groupNicknameUpdated,
    );
  }

  Future<void> _setRole(GroupMember m, bool makeAdmin) async {
    final l = AppL10n.of(context);
    await _groupRun(
      () => ref.read(groupRepoProvider).setRole(
          widget.groupConvId!, m.userId, makeAdmin ? 'ADMIN' : 'MEMBER'),
      makeAdmin ? l.adminSet : l.adminRemoved,
    );
  }

  Future<void> _muteMember(GroupMember m) async {
    final l = AppL10n.of(context);
    final seconds =
        await showMuteDurationSheet(context, currentlyMuted: m.isMuted);
    if (seconds == null) return;
    await _groupRun(
      () => ref
          .read(groupRepoProvider)
          .mute(widget.groupConvId!, m.userId, seconds == 0 ? null : seconds),
      seconds == 0 ? l.unmutedOk : l.mutedOk,
    );
  }

  Future<void> _kickMember(GroupMember m) async {
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
    await _groupRun(
      () =>
          ref.read(groupRepoProvider).kick(widget.groupConvId!, m.userId),
      l.memberRemoved,
    );
  }

  /// 群管理操作区卡片；当前用户无管理权/目标不可管理时返回 null。
  Widget? _groupManageCard(ThemeData theme) {
    if (!_isGroupContext) return null;
    final convId = widget.groupConvId!;
    final l = AppL10n.of(context);
    final meId = ref.watch(sessionControllerProvider).user?.id;
    final group = ref.watch(groupDetailProvider(convId)).valueOrNull;
    final members = ref.watch(groupMembersProvider(convId)).valueOrNull;
    if (group == null || members == null) return null;
    if (meId == null || meId == _user.id) return null;
    final myRole = group.myRole;
    final iAmManager = myRole == 'OWNER' || myRole == 'ADMIN';
    if (!iAmManager) return null;
    GroupMember? target;
    for (final m in members) {
      if (m.userId == _user.id) {
        target = m;
        break;
      }
    }
    if (target == null) return null;
    // 群主不可被操作；管理员只能被群主操作。
    if (target.role == 'OWNER') return null;
    if (target.role == 'ADMIN' && myRole != 'OWNER') return null;

    Widget tile(IconData icon, String label, VoidCallback onTap,
        {Color? color}) {
      return ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: color == null ? null : TextStyle(color: color)),
        onTap: onTap,
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined,
                    size: 18, color: theme.hintColor),
                const SizedBox(width: 8),
                Text(l.groupManageTitle,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor)),
                const Spacer(),
                if (target.isMuted)
                  Chip(
                    label: Text(l.mutedChip),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          tile(Icons.badge_outlined, l.setMemberNicknameTitle,
              () => _setMemberNickname(target!)),
          if (myRole == 'OWNER')
            target.role == 'ADMIN'
                ? tile(Icons.remove_moderator_outlined, l.removeAdmin,
                    () => _setRole(target!, false))
                : tile(Icons.admin_panel_settings_outlined, l.makeAdmin,
                    () => _setRole(target!, true)),
          tile(
            Icons.volume_off_outlined,
            target.isMuted ? l.unmuteMember : l.muteMember,
            () => _muteMember(target!),
          ),
          tile(
            Icons.person_remove_outlined,
            l.removeMember,
            () => _kickMember(target!),
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'remark':
        _editRemark();
      case 'block':
        _blockUser();
      case 'report':
        _reportUser();
      case 'delete':
        _deleteFriend();
      case 'cancel':
        _cancelSentRequest();
    }
  }

  /// 按关系构建右上角菜单项。
  List<PopupMenuEntry<String>> _menuItems(Color errorColor) {
    final l = AppL10n.of(context);
    switch (_user.relation) {
      case 'FRIEND':
        return [
          PopupMenuItem(value: 'remark', child: Text(l.setRemarkTitle)),
          PopupMenuItem(value: 'block', child: Text(l.blockAction)),
          PopupMenuItem(value: 'report', child: Text(l.report)),
          PopupMenuItem(
            value: 'delete',
            child: Text(l.deleteFriendTitle,
                style: TextStyle(color: errorColor)),
          ),
        ];
      case 'PENDING_SENT':
        return [
          PopupMenuItem(value: 'cancel', child: Text(l.withdrawRequest)),
          PopupMenuItem(value: 'report', child: Text(l.report)),
        ];
      default:
        // NONE / PENDING_RECEIVED 等：仅可举报。
        return [PopupMenuItem(value: 'report', child: Text(l.report))];
    }
  }

  Future<void> _run(Future<void> Function() body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await body();
    } catch (e) {
      if (mounted) {
        _toast(AppL10n.of(context).errorWithReason('$e'), isError: true);
      }
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

  UserBrief _copyRelation(String r) => UserBrief(
    id: _user.id,
    uid: _user.uid,
    username: _user.username,
    nickname: _user.nickname,
    avatarUrl: _user.avatarUrl,
    bio: _user.bio,
    gender: _user.gender,
    relation: r,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // #8 群管理卡片在 build 中只构建一次（内部会 watch 群详情/成员）。
    final groupManageCard = _groupManageCard(theme);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? telegramOutgoing : sylphBlue;
    final l = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.detailTitle),
        actions: [
          if (_user.relation != 'SELF')
            PopupMenuButton<String>(
              onSelected: _onMenuSelected,
              itemBuilder: (_) => _menuItems(theme.colorScheme.error),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                // 头像 + 昵称 + UID（可复制）。
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 26,
                      horizontal: 16,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                                width: 2,
                              ),
                            ),
                            child: UserAvatar(
                              name: _user.displayName,
                              avatarUrl: _user.avatarUrl,
                              uid: _user.uid,
                              size: 88,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _user.displayName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // #7 备注展示同步：好友关系时显示备注（如有）。
                          if (_user.relation == 'FRIEND') ...[
                            const SizedBox(height: 6),
                            if ((_remark ?? '').isNotEmpty)
                              Text(
                                l.remarkWithColon(_remark!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.hintColor,
                                ),
                              )
                            else
                              Text(
                                l.noRemark,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.hintColor,
                                ),
                              ),
                          ],
                          const SizedBox(height: 8),
                          if (_user.uid?.isNotEmpty == true)
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _copyUid,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'UID: ${_user.uid}',
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.copy,
                                      size: 15,
                                      color: theme.hintColor,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_user.username.isNotEmpty)
                            Text(
                              '@${_user.username}',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 13.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 性别 + 简介（UserBrief 无 region 字段，不展示地区）。
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.wc_outlined),
                        title: Text(l.gender),
                        trailing: Text(
                          _genderLabel,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                      ListTile(
                        leading: const Icon(Icons.notes_outlined),
                        title: Text(l.bio),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            (_user.bio ?? '').isEmpty
                                ? l.bioEmptyHint
                                : _user.bio!,
                            style: TextStyle(
                              height: 1.4,
                              color: (_user.bio ?? '').isEmpty
                                  ? theme.hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // #8 群聊内：群主/管理员管理操作区。
                if (groupManageCard != null) ...[
                  const SizedBox(height: 12),
                  groupManageCard,
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
        strokeWidth: 2.4,
        color: theme.colorScheme.onPrimary,
      ),
    );
    switch (_user.relation) {
      case 'SELF':
        // 自己的名片：直接给自己发消息（自聊会话，后端支持单成员单聊）。
        return FilledButton.icon(
          onPressed: _busy ? null : _startChat,
          icon: _busy ? loading : const Icon(Icons.chat_bubble_outline),
          label: Text(l.messageSelf),
        );
      case 'FRIEND':
        return FilledButton.icon(
          onPressed: _busy ? null : _startChat,
          icon: _busy ? loading : const Icon(Icons.chat_bubble_outline),
          label: Text(l.sendMessage),
        );
      case 'PENDING_SENT':
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule),
          label: Text(l.requestPendingLabel),
        );
      case 'PENDING_RECEIVED':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        // 忽略：直接拒绝该申请
                        await _run(() async {
                          final list = await ref
                              .read(socialRepoProvider)
                              .incomingRequests();
                          final req = list
                              .where(
                                (r) =>
                                    r.status == 'PENDING' &&
                                    r.from?.id == _user.id,
                              )
                              .toList();
                          if (req.isNotEmpty) {
                            await ref
                                .read(socialRepoProvider)
                                .rejectRequest(req.first.id);
                            setState(() => _user = _copyRelation('NONE'));
                            _toast(l.requestIgnored, isInfo: true);
                          }
                        });
                      },
                child: Text(l.ignore),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _acceptIncoming,
                child: _busy ? loading : Text(l.acceptFriendRequest),
              ),
            ),
          ],
        );
      default:
        return FilledButton.icon(
          onPressed: _busy ? null : _sendRequest,
          icon: _busy ? loading : const Icon(Icons.person_add_alt_1),
          label: Text(l.addToContacts),
        );
    }
  }
}
