import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
import 'user_profile_page.dart';

/// 通讯录总览（WS 事件自动刷新）。
final contactsOverviewProvider =
    FutureProvider.autoDispose<ContactsOverview>((ref) {
  ref.watch(socialTickProvider);
  return ref.read(contactsRepoProvider).overview();
});

/// 联系人页：新的朋友 / 群邀请 / 好友 / 群聊 四分区。
class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeProvider).refreshConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final async = ref.watch(contactsOverviewProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.contactsPageTitle),
        actions: [
          IconButton(
            tooltip: l.addFriendTooltip,
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => context.push('/add-friend'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            message: '$e',
            onRetry: () => ref.invalidate(contactsOverviewProvider)),
        data: (o) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(contactsOverviewProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _shortcutRow(o)),
              _header(l.friendsCountHeader(o.friends.length)),
              if (o.friends.isEmpty)
                SliverToBoxAdapter(child: _EmptyLine(l.noFriendsHint))
              else
                SliverList.builder(
                  itemCount: o.friends.length,
                  itemBuilder: (_, i) {
                    final f = o.friends[i];
                    return _FriendTile(
                      friend: f,
                      onTap: () => context.push('/user-profile',
                          extra: UserProfileArgs(user: f.user)),
                      onChat: () =>
                          context.push('/chat-by-user/${f.user.id}'),
                    );
                  },
                ),
              _header(l.groupsCountHeader(o.groups.length)),
              if (o.groups.isEmpty)
                SliverToBoxAdapter(child: _EmptyLine(l.noGroupsHint))
              else
                SliverList.builder(
                  itemCount: o.groups.length,
                  itemBuilder: (_, i) {
                    final g = o.groups[i];
                    return ListTile(
                      leading: UserAvatar(
                          name: g.name, avatarUrl: g.avatarUrl, size: 46),
                      title: Text(g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l.memberCount(g.memberCount),
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).hintColor)),
                      onTap: () => context.push('/chat/${g.convId}'),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutRow(ContactsOverview o) {
    final l = AppL10n.of(context);
    final invites =
        o.groupInvites.where((r) => r.status == 'PENDING').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: _ShortcutCard(
              icon: Icons.person_add_alt_1,
              label: l.newFriends,
              color: const Color(0xFF2EA6FF),
              badge: o.incomingCount,
              onTap: () => context.push('/friend-requests'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ShortcutCard(
              icon: Icons.group_outlined,
              label: l.groupInvitesEntry,
              color: const Color(0xFF19A979),
              badge: invites,
              onTap: () => context.push('/group-invites'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ShortcutCard(
              icon: Icons.qr_code_scanner_rounded,
              label: l.scanEntry,
              color: const Color(0xFF9B51E0),
              onTap: () => context.push('/scan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Text(text,
            style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 23),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendView friend;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const _FriendTile({
    required this.friend,
    required this.onTap,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final u = friend.user;
    final name = (friend.remark?.isNotEmpty ?? false)
        ? friend.remark!
        : u.displayName;
    return ListTile(
      leading: UserAvatar(
          name: u.displayName,
          avatarUrl: u.avatarUrl,
          uid: u.uid,
          size: 46),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: u.uid?.isNotEmpty == true
          ? Text('UID: ${u.uid}',
              style: TextStyle(
                  fontSize: 12.5, color: Theme.of(context).hintColor))
          : null,
      trailing: IconButton(
        tooltip: AppL10n.of(context).sendMessage,
        icon: const Icon(Icons.chat_bubble_outline, size: 21),
        onPressed: onChat,
      ),
      onTap: onTap,
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Text(text,
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
    );
  }
}
