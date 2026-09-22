import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// #16 通讯录黑名单：列出已拉黑的好友，支持解除拉黑。
class BlacklistPage extends ConsumerStatefulWidget {
  const BlacklistPage({super.key});

  @override
  ConsumerState<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends ConsumerState<BlacklistPage> {
  late Future<List<FriendView>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<FriendView>> _load() =>
      ref.read(socialRepoProvider).blockedList();

  Future<void> _refresh() async {
    final list = await _load();
    if (mounted) setState(() => _future = Future.value(list));
  }

  Future<void> _unblock(FriendView f) async {
    try {
      await ref.read(socialRepoProvider).unblock(f.user.id);
      if (mounted) {
        AppToast.success(context, AppL10n.of(context).unblockedOk);
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).errorWithReason('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.blacklistEntry,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<List<FriendView>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorView(
              message: l.loadFailedReason('${snap.error}'),
              onRetry: _refresh,
            );
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.block,
              text: l.blacklistEmpty,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 8 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const Divider(indent: 72, height: 1),
              itemBuilder: (_, i) {
                final f = list[i];
                final name = f.user.nickname.isNotEmpty
                    ? f.user.nickname
                    : f.user.username;
                return ListTile(
                  leading: UserAvatar(
                    name: name,
                    avatarUrl: f.user.avatarUrl,
                    size: 44,
                  ),
                  title: Text(name),
                  subtitle: Text('UID: ${f.user.uid}',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).hintColor)),
                  trailing: TextButton(
                    onPressed: () => _unblock(f),
                    child: Text(l.unblockAction),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
