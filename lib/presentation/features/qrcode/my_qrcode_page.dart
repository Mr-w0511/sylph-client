import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
import 'qrcode_page.dart';

/// 我的个人二维码（sylph://u/{token}，可重置）。
class MyQrcodePage extends ConsumerStatefulWidget {
  const MyQrcodePage({super.key});

  @override
  ConsumerState<MyQrcodePage> createState() => _MyQrcodePageState();
}

class _MyQrcodePageState extends ConsumerState<MyQrcodePage> {
  late Future<({String token, String content})> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(socialRepoProvider).myQrcode();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final me = ref.watch(sessionControllerProvider).user;
    return FutureBuilder<({String token, String content})>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        if (snap.hasError || !snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l.myQrcode)),
            body: ErrorView(
                message: '${snap.error}',
                onRetry: () => setState(() {
                      _future = ref.read(socialRepoProvider).myQrcode();
                    })),
          );
        }
        final nick = me?.nickname ?? '';
        return QrcodePage(
          title: l.myQrcode,
          content: snap.data!.content,
          name: nick.isNotEmpty ? nick : (me?.username ?? l.sylphUser),
          avatarUrl: me?.avatarUrl,
          subtitle: (me?.uid?.isNotEmpty ?? false) ? 'UID: ${me!.uid}' : null,
          onShareInApp: me == null ? null : () => _shareInApp(me.id),
          onReset: () async {
            final r = await ref.read(socialRepoProvider).resetQrcode();
            final updated = ref.read(sessionControllerProvider).user?.copyWith(
                  qrcodeToken: r.token,
                );
            if (updated != null) {
              ref
                  .read(sessionControllerProvider.notifier)
                  .updateUser(updated);
            }
            return r.content;
          },
        );
      },
    );
  }

  /// #17 站内分享个人名片：弹出好友列表，选中后发送 USER_CARD。
  Future<void> _shareInApp(int myUserId) async {
    final friends = await ref.read(socialRepoProvider).friends();
    if (!mounted) return;
    if (friends.isEmpty) {
      AppToast.info(context, AppL10n.of(context).noFriendsToShare);
      return;
    }
    final toUserId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(AppL10n.of(context).shareCardTo,
                  style: Theme.of(ctx).textTheme.titleSmall),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (_, i) {
                  final f = friends[i];
                  final name =
                      f.user.nickname.isNotEmpty ? f.user.nickname : f.user.username;
                  return ListTile(
                    leading: UserAvatar(
                      name: name,
                      avatarUrl: f.user.avatarUrl,
                      size: 44,
                    ),
                    title: Text(name),
                    subtitle: Text('UID: ${f.user.uid}',
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(ctx).hintColor)),
                    onTap: () => Navigator.of(ctx).pop(f.user.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (toUserId == null) return;
    try {
      await ref.read(socialRepoProvider).shareUserCard(myUserId, toUserId);
      if (mounted) AppToast.success(context, AppL10n.of(context).cardShared);
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).shareFailedReason('$e'));
      }
    }
  }
}
