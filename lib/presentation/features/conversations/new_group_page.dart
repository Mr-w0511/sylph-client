import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// 建群：群头像 / 群名称 / 我的群昵称 / 进群审核 / 勾选好友。
class NewGroupPage extends ConsumerStatefulWidget {
  const NewGroupPage({super.key});

  @override
  ConsumerState<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends ConsumerState<NewGroupPage> {
  final _nameCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  /// 已选成员（保留简要信息用于底部横条展示）。
  final Map<int, UserBrief> _selectedUsers = {};
  String? _avatarUrl;
  bool _approval = false;
  bool _submitting = false;
  bool _uploading = false;
  String _keyword = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nickCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_uploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (bytes == null) return;
      setState(() => _uploading = true);
      final media = await ref.read(mediaRepoProvider).uploadImage(
            bytes: bytes,
            filename: file!.name,
          );
      setState(() => _avatarUrl = media.url);
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).avatarUploadFailedReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppL10n.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.info(context, l.groupNameRequired);
      return;
    }
    if (_selectedUsers.isEmpty) {
      AppToast.info(context, l.selectAtLeastOne);
      return;
    }
    setState(() => _submitting = true);
    try {
      final g = await ref.read(groupRepoProvider).create(
            name: name,
            memberIds: _selectedUsers.keys.toList(),
            avatarUrl: _avatarUrl,
            joinPolicy: _approval ? 'APPROVAL' : 'OPEN',
            myNickname: _nickCtrl.text.trim(),
          );
      await ref.read(realtimeProvider).refreshConversations();
      ref.read(socialTickProvider.notifier).state++;
      if (!mounted) return;
      context.pushReplacement('/chat/${g.convId}');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '$e');
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final friendsAsync = ref.watch(_friendsProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l.startGroupChat),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(l.createAction,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          _topSection(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _keyword = v.trim()),
              decoration: InputDecoration(
                hintText: l.searchFriendsHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l.selectFriendsCount(_selectedUsers.length),
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            child: friendsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                  message: '$e',
                  onRetry: () => ref.invalidate(_friendsProvider)),
              data: (friends) {
                final kw = _keyword;
                final list = friends
                    .where((f) =>
                        kw.isEmpty ||
                        f.user.displayName.contains(kw) ||
                        (f.user.username).contains(kw) ||
                        (f.user.uid ?? '').contains(kw))
                    .toList();
                if (list.isEmpty) {
                  return EmptyView(
                      icon: Icons.people_outline,
                      text: AppL10n.of(context).noInvitableFriends);
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final u = list[i].user;
                    final checked = _selectedUsers.containsKey(u.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedUsers[u.id] = u;
                        } else {
                          _selectedUsers.remove(u.id);
                        }
                      }),
                      secondary: UserAvatar(
                          name: u.displayName,
                          avatarUrl: u.avatarUrl,
                          uid: u.uid,
                          size: 42),
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
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  /// 底部：已选成员横条 + 创建按钮。
  Widget _bottomBar() {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 74,
              child: _selectedUsers.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l.selectMembersHint,
                          style: TextStyle(
                              color: theme.hintColor, fontSize: 13.5)),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedUsers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final u = _selectedUsers.values.elementAt(i);
                        return _SelectedMemberChip(
                          user: u,
                          onRemove: () =>
                              setState(() => _selectedUsers.remove(u.id)),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B6EF6), Color(0xFF2EA6FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(l.createGroup,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topSection() {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _uploading ? null : _pickAvatar,
                child: Stack(
                  children: [
                    UserAvatar(
                        name: _nameCtrl.text.trim().isEmpty
                            ? l.unknownGroup
                            : _nameCtrl.text.trim(),
                        avatarUrl: _avatarUrl,
                        size: 58),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        child: _uploading
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt,
                                size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() {}),
                  maxLength: 128,
                  decoration: InputDecoration(
                    hintText: l.groupName,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nickCtrl,
            maxLength: 64,
            decoration: InputDecoration(
              hintText: l.myGroupNickHint,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _approval,
            onChanged: (v) => setState(() => _approval = v),
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              _approval ? Icons.verified_user_outlined : Icons.public,
              color: theme.colorScheme.primary,
            ),
            title: Text(l.approvalToggle),
            subtitle: Text(
                _approval ? l.approvalOnSubtitle : l.joinViaQrcode,
                style: TextStyle(fontSize: 12.5, color: theme.hintColor)),
          ),
        ],
      ),
    );
  }
}

/// 底部已选成员小卡片：头像 + 名字 + 右上角移除。
class _SelectedMemberChip extends StatelessWidget {
  final UserBrief user;
  final VoidCallback onRemove;
  const _SelectedMemberChip({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                  name: user.displayName,
                  avatarUrl: user.avatarUrl,
                  uid: user.uid,
                  size: 44),
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: theme.hintColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.scaffoldBackgroundColor, width: 1.5),
                    ),
                    child: const Icon(Icons.close,
                        size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// 好友列表（建群选择用）。#10 过滤掉官方助手，禁止邀请其入群。
final _friendsProvider = FutureProvider.autoDispose<List<FriendView>>(
    (ref) async {
  ref.watch(socialTickProvider);
  final all = await ref.read(socialRepoProvider).friends();
  return all.where((f) => f.user.uid != kSystemAssistantUid).toList();
});
