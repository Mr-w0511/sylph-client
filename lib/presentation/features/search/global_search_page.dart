import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/user_avatar.dart';

/// #5 全局搜索页：顶部搜索框，下方分区展示联系人与聊天记录。
class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<FriendView> _friends = const [];
  List<GroupedHit> _groupedHits = const [];
  Map<int, Conversation> _convCache = {};
  String _keyword = '';
  bool _loading = false;
  bool _friendsLoaded = false;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
    _loadFriends();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final list = await ref.read(socialRepoProvider).friends();
      if (!mounted) return;
      setState(() {
        _friends = list;
        _friendsLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _friendsLoaded = true);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch());
  }

  Future<void> _runSearch() async {
    final kw = _controller.text.trim();
    if (kw.isEmpty) {
      setState(() {
        _keyword = '';
        _groupedHits = const [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _keyword = kw;
    });
    try {
      final hits =
          await ref.read(messagesDaoProvider).searchContentGrouped(kw, limit: 30);
      // 关联会话标题/头像。
      final cache = <int, Conversation>{..._convCache};
      for (final h in hits) {
        if (!cache.containsKey(h.convId)) {
          final conv =
              await ref.read(conversationsDaoProvider).findById(h.convId);
          if (conv != null) cache[h.convId] = conv;
        }
      }
      if (!mounted) return;
      setState(() {
        _groupedHits = hits;
        _convCache = cache;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== 联系人本地过滤 =====

  List<FriendView> _filteredFriends(String kw) {
    if (kw.isEmpty) return const [];
    final lower = kw.toLowerCase();
    bool hit(FriendView f) {
      final u = f.user;
      return (f.remark ?? '').toLowerCase().contains(lower) ||
          u.nickname.toLowerCase().contains(lower) ||
          u.username.toLowerCase().contains(lower) ||
          (u.uid ?? '').toLowerCase().contains(lower);
    }

    return _friends.where(hit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final kw = _keyword;
    final friends = _filteredFriends(kw);
    final showEmpty = kw.isNotEmpty &&
        !_loading &&
        friends.isEmpty &&
        _groupedHits.isEmpty &&
        _friendsLoaded;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(19),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
              border: InputBorder.none,
              hintText: l.globalSearchHint,
              hintStyle: TextStyle(
                  fontSize: 14.5, color: Theme.of(context).hintColor),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: showEmpty
                ? Center(
                    child: Text(l.globalSearchNoResults,
                        style: TextStyle(color: Theme.of(context).hintColor)),
                  )
                : ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.viewPaddingOf(context).bottom),
                    children: [
                      if (friends.isNotEmpty)
                        _SectionHeader(l.globalSearchSectionContacts),
                      ...friends.map((f) => _FriendTile(friend: f)),
                      if (_groupedHits.isNotEmpty) ...[
                        _SectionHeader(l.globalSearchSectionMessages),
                        ..._groupedHits.map((h) => _ConvHitTile(
                              hit: h,
                              keyword: kw,
                              conv: _convCache[h.convId],
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendView friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    final u = friend.user;
    final name = (friend.remark != null && friend.remark!.isNotEmpty)
        ? friend.remark!
        : u.displayName;
    return ListTile(
      dense: true,
      leading: UserAvatar(name: name, avatarUrl: u.avatarUrl, size: 40),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => context.push('/chat-by-user/${u.id}'),
    );
  }
}

class _ConvHitTile extends StatelessWidget {
  final GroupedHit hit;
  final String keyword;
  final Conversation? conv;
  const _ConvHitTile({
    required this.hit,
    required this.keyword,
    required this.conv,
  });

  String _convTitle(AppL10n l) {
    final c = conv;
    if (c == null) return '#${hit.convId}';
    return c.type == 'SINGLE'
        ? (c.peerNickname ?? c.title ?? l.singleChatFallback)
        : (c.title ?? l.unknownGroup);
  }

  /// 关键字高亮片段。
  TextSpan _highlight(String text, TextStyle base, TextStyle hitStyle) {
    final idx = text.toLowerCase().indexOf(keyword.toLowerCase());
    if (idx < 0) return TextSpan(text: text, style: base);
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: text.substring(0, idx)),
        TextSpan(text: text.substring(idx, idx + keyword.length), style: hitStyle),
        TextSpan(text: text.substring(idx + keyword.length)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final title = _convTitle(l);
    final snippet = hit.lastHitContent;
    final timeText = TimeFmt.listLabel(hit.lastHitAt,
        today: l.today, yesterday: l.yesterday);
    return ListTile(
      dense: true,
      leading: UserAvatar(
        name: title,
        avatarUrl: conv?.type == 'SINGLE'
            ? conv?.peerAvatarUrl
            : conv?.groupAvatarUrl,
        size: 40,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          if (hit.hitCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${hit.hitCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(
            timeText,
            style: TextStyle(fontSize: 11.5, color: theme.hintColor),
          ),
        ],
      ),
      subtitle: Text.rich(
        _highlight(
          snippet,
          TextStyle(fontSize: 13.5, color: theme.hintColor),
          TextStyle(
            fontSize: 13.5,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.push('/chat/${hit.convId}'),
    );
  }
}
