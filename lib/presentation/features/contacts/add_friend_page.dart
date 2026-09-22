import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
import 'user_profile_page.dart';

/// 添加好友页：搜索用户 + 扫一扫 + 我的二维码 + 发起群聊。
class AddFriendPage extends ConsumerStatefulWidget {
  const AddFriendPage({super.key});

  @override
  ConsumerState<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends ConsumerState<AddFriendPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<UserBrief>>? _future;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300),
        () => _runSearch(_controller.text.trim()));
  }

  void _runSearch(String keyword) {
    setState(() {
      _keyword = keyword;
      _future = ref.read(socialRepoProvider).search(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionControllerProvider).user?.id;
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.addFriendTooltip)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.searchUserFullHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _runSearch('');
                        },
                      ),
              ),
            ),
          ),
          _quickActions(),
          Expanded(
            child: FutureBuilder<List<UserBrief>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: '${snap.error}',
                    onRetry: () => _runSearch(_keyword),
                  );
                }
                final users = (snap.data ?? const [])
                    .where((u) => u.id != myId && u.relation != 'SELF')
                    .toList();
                if (users.isEmpty) {
                  return _SearchEmpty(keyword: _keyword);
                }
                return ListView.separated(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: 4 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  itemCount: users.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 74),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: UserAvatar(
                          name: u.displayName,
                          avatarUrl: u.avatarUrl,
                          size: 48),
                      title: Text(u.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          u.uid?.isNotEmpty == true
                              ? 'UID: ${u.uid}'
                              : (u.username.isNotEmpty
                                  ? '@${u.username}'
                                  : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).hintColor),
                        ),
                      ),
                      trailing: _relationChip(u),
                      onTap: () => context.push('/user-profile',
                          extra: UserProfileArgs(user: u)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final l = AppL10n.of(context);
    final items = [
      (Icons.qr_code_scanner_rounded, l.scanEntry, telegramOutgoing, () {
        context.push('/scan').then((_) {
          // 返回后允许再次扫描同一张二维码。
        });
      }),
      (Icons.badge_outlined, l.myQrcode, const Color(0xFF19A979),
          () => context.push('/my-qrcode')),
      (Icons.groups_2_outlined, l.startGroupChat, const Color(0xFF9B51E0),
          () => context.push('/new-group')),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: it.$4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: it.$3.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(it.$1, color: it.$3, size: 22),
                          ),
                          const SizedBox(height: 7),
                          Text(it.$2,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _relationChip(UserBrief u) {
    final l = AppL10n.of(context);
    switch (u.relation) {
      case 'FRIEND':
        return Chip(
          label: Text(l.friendsSection),
          visualDensity: VisualDensity.compact,
        );
      case 'PENDING_SENT':
        return Chip(
          label: Text(l.waitVerify),
          visualDensity: VisualDensity.compact,
        );
      case 'PENDING_RECEIVED':
        return Chip(
          label: Text(l.pendingAccept),
          visualDensity: VisualDensity.compact,
          backgroundColor: telegramOutgoing.withValues(alpha: 0.12),
          labelStyle: const TextStyle(color: telegramOutgoing),
          side: BorderSide.none,
        );
      default:
        return const Icon(Icons.person_add_alt_1, size: 20);
    }
  }
}

class _SearchEmpty extends StatelessWidget {
  final String keyword;
  const _SearchEmpty({required this.keyword});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    final hasKeyword = keyword.isNotEmpty;
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    hasKeyword
                        ? Icons.person_search_outlined
                        : Icons.person_add_alt_1,
                    size: 40,
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(hasKeyword ? l.searchEmpty : l.searchEmptyNoKeyword,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(hasKeyword ? l.searchEmptyKeywordHint : l.searchEmptyNoKeywordHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
