import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
import '../contacts/user_profile_page.dart';

/// #10 全部群成员页：顶部搜索框本地过滤 + 角色排序；
/// 点击成员进入带群上下文的资料页（群主/管理员可见管理操作）。
class GroupMembersPage extends ConsumerStatefulWidget {
  final int convId;
  const GroupMembersPage({super.key, required this.convId});

  @override
  ConsumerState<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends ConsumerState<GroupMembersPage> {
  String _keyword = '';

  int _rank(String role) =>
      role == 'OWNER' ? 0 : (role == 'ADMIN' ? 1 : 2);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final membersAsync = ref.watch(groupMembersProvider(widget.convId));
    final myId = ref.watch(sessionControllerProvider).user?.id ?? -1;

    return Scaffold(
      appBar: AppBar(title: Text(l.allGroupMembers)),
      body: membersAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            message: l.errorWithReason('$e'),
            onRetry: () =>
                ref.invalidate(groupMembersProvider(widget.convId))),
        data: (all) {
          final kw = _keyword.trim().toLowerCase();
          final list = all.where((m) {
            if (kw.isEmpty) return true;
            final name = (m.groupNickname ?? m.nickname ?? '').toLowerCase();
            return name.contains(kw) || '${m.userId}'.contains(kw);
          }).toList()
            ..sort((a, b) {
              final r = _rank(a.role).compareTo(_rank(b.role));
              return r != 0 ? r : a.userId.compareTo(b.userId);
            });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _keyword = v),
                    style: const TextStyle(fontSize: 14.5),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 11),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      hintText: l.searchGroupMembers,
                      hintStyle: TextStyle(
                          fontSize: 14, color: Theme.of(context).hintColor),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.only(
                    top: 6,
                    bottom: 6 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final name = m.groupNickname?.isNotEmpty == true
                        ? m.groupNickname!
                        : (m.nickname ?? l.userFallbackId('${m.userId}'));
                    return ListTile(
                      leading: UserAvatar(
                          name: name, avatarUrl: m.avatarUrl, size: 44),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (m.role == 'OWNER')
                            _badge(l.owner, const Color(0xFFF2994A)),
                          if (m.role == 'ADMIN')
                            _badge(l.admin, const Color(0xFF2EA6FF)),
                          if (m.userId == myId)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(l.meMarker,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).hintColor)),
                            ),
                        ],
                      ),
                      trailing: m.isMuted
                          ? const Icon(Icons.volume_off_outlined, size: 18)
                          : null,
                      onTap: () => context.push(
                        '/user-profile',
                        extra: UserProfileArgs(
                          user: UserBrief(
                            id: m.userId,
                            nickname: m.nickname ?? name,
                            avatarUrl: m.avatarUrl,
                            relation:
                                m.userId == myId ? 'SELF' : 'NONE',
                          ),
                          groupConvId: widget.convId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 10.5,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ),
      );
}
