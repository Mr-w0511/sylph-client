import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_database.dart';
import '../../../state/providers.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/user_avatar.dart';
import '../chat_controller.dart';

/// 转发选择面板：列出最近会话 + 尚无会话的好友，
/// 选中后通过 WS MSG_SEND 跨会话发送（媒体透传 mediaUrl，不重新上传；
/// 目标为私密单聊时文本会按对端公钥重新端到端加密）。
Future<void> showForwardSheet(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  String? content,
  String? mediaUrl,
  String? mediaMeta,
}) {
  return showForwardSheetForPayloads(context, ref, [
    ForwardPayload(
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      mediaMeta: mediaMeta,
    ),
  ]);
}

/// #11 多选转发：将多条消息依次转发到目标会话。
Future<void> showForwardSheetForMessages(
  BuildContext context,
  WidgetRef ref,
  List<Message> messages,
) {
  return showForwardSheetForPayloads(
    context,
    ref,
    messages
        .map((m) => ForwardPayload(
              type: m.type,
              content: m.content,
              mediaUrl: m.mediaUrl,
              mediaMeta: m.mediaMeta,
            ))
        .toList(),
  );
}

Future<void> showForwardSheetForPayloads(
  BuildContext context,
  WidgetRef ref,
  List<ForwardPayload> payloads,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ForwardSheet(payloads: payloads),
  );
}

class ForwardPayload {
  final String type;
  final String? content;
  final String? mediaUrl;
  final String? mediaMeta;
  const ForwardPayload({
    required this.type,
    this.content,
    this.mediaUrl,
    this.mediaMeta,
  });
}

class _ForwardSheet extends ConsumerStatefulWidget {
  final List<ForwardPayload> payloads;
  const _ForwardSheet({required this.payloads});

  @override
  ConsumerState<_ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends ConsumerState<_ForwardSheet> {
  bool _sending = false;
  int _sentCount = 0;

  /// 将全部待转发消息依次发到目标会话；任一条失败即中止并提示已发条数。
  Future<void> _sendTo(Conversation conv) async {
    final l = AppL10n.of(context);
    if (_sending) return;
    setState(() => _sending = true);
    try {
      for (final p in widget.payloads) {
        final msgId = const Uuid().v4().replaceAll('-', '');
        var outContent = p.content ?? '';
        var outMeta = p.mediaMeta;
        var encrypted = false;

        // 文本转发到私密单聊：用对端公钥重新加密（媒体消息与普通发送一致，不走 E2EE）。
        if (p.type == 'TEXT' &&
            conv.privateFlag &&
            conv.type == 'SINGLE' &&
            conv.peerUserId != null) {
          try {
            final r = await encryptE2eeMessage(
              e2ee: ref.read(e2eeServiceProvider),
              e2eeRepo: ref.read(e2eeRepoProvider),
              sentCache: ref.read(e2eeSentCacheProvider.notifier),
              plaintext: p.content ?? '',
              peerUserId: conv.peerUserId!,
              msgId: msgId,
            );
            outContent = r.content;
            outMeta = r.metaJson;
            encrypted = true;
          } catch (e) {
            if (mounted) {
              AppToast.error(context,
                  e.toString().contains('peer-bundle-unavailable')
                      ? l.e2eePeerNoKeysForward
                      : l.encryptFailedReason('$e'));
            }
            setState(() => _sending = false);
            return;
          }
        }

        await ref.read(realtimeProvider).sendMessageTo(
              convId: conv.id,
              msgId: msgId,
              type: p.type,
              content: outContent,
              mediaUrl: p.mediaUrl,
              mediaMeta: outMeta,
              encrypted: encrypted,
            );
        _sentCount++;
      }
      if (mounted) {
        AppToast.success(
          context,
          widget.payloads.length > 1
              ? l.forwardedCount(_sentCount)
              : l.forwarded,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context,
            widget.payloads.length > 1
                ? l.forwardedPartialFail(_sentCount, '$e')
                : l.forwardFailedReason('$e'));
      }
      setState(() => _sending = false);
    }
  }

  /// 好友无现存会话：先创建/取回单聊会话，再转发。
  Future<void> _sendToFriend(int userId) async {
    final l = AppL10n.of(context);
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final model =
          await ref.read(conversationRepoProvider).createSingle(userId);
      unawaited(ref.read(realtimeProvider).refreshConversations());
      final conv = await ref.read(conversationsDaoProvider).findById(model.id);
      if (conv == null) {
        // DAO 尚未刷新完成时的兜底：构造临时会话对象。
        if (!mounted) return;
        AppToast.info(context, l.convCreating);
        Navigator.of(context).pop();
        return;
      }
      await _sendTo(conv);
    } catch (e) {
      if (mounted) AppToast.error(context, l.forwardFailedReason('$e'));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final convsAsync = ref.watch(conversationsStreamProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.forward_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(l.forwardTo,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_sending)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Expanded(
              child: convsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text(l.loadFailedReason('$e'))),
                data: (convs) {
                  final visible =
                      convs.where((c) => !c.dissolved).toList();
                  final peerIds = visible
                      .map((c) => c.peerUserId)
                      .whereType<int>()
                      .toSet();
                  return FutureBuilder(
                    future: ref.read(socialRepoProvider).friends(),
                    builder: (context, snap) {
                      final friends = (snap.data ?? const [])
                        ..retainWhere(
                            (f) => !peerIds.contains(f.user.id));
                      return ListView(
                        controller: scrollController,
                        children: [
                          for (final c in visible)
                            _tile(
                              name: c.type == 'GROUP'
                                  ? (c.title ?? l.unknownGroup)
                                  : (c.peerNickname ?? l.chatFallback),
                              avatarUrl: c.peerAvatarUrl,
                              subtitle:
                                  c.type == 'GROUP' ? l.unknownGroup : null,
                              onTap: () => _sendTo(c),
                            ),
                          if (friends.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(l.friendsSection,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ),
                          for (final f in friends)
                            _tile(
                              name: f.remark ?? f.user.displayName,
                              avatarUrl: f.user.avatarUrl,
                              subtitle: null,
                              onTap: () => _sendToFriend(f.user.id),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  Widget _tile({
    required String name,
    required String? avatarUrl,
    required String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: UserAvatar(name: name, avatarUrl: avatarUrl, size: 40),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: _sending ? null : onTap,
    );
  }
}
