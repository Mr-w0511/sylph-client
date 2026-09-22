import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/time_format.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  @override
  void initState() {
    super.initState();
    // 进入主页即拉一次网络覆盖缓存。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeProvider).refreshConversations();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(realtimeProvider).refreshConversations();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final listAsync = ref.watch(conversationsStreamProvider);
    final myId = ref.watch(sessionControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.conversationsTitle),
        actions: [
          // #5 全局搜索（联系人 + 聊天记录）。
          IconButton(
            tooltip: l.globalSearchTitle,
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          // #5 加号：加好友 / 扫一扫 / 发起群聊 / 我的二维码。
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: l.addMenuTooltip,
            onSelected: (v) {
              switch (v) {
                case 'add':
                  context.push('/add-friend');
                  break;
                case 'scan':
                  context.push('/scan');
                  break;
                case 'group':
                  context.push('/new-group');
                  break;
                case 'qrcode':
                  context.push('/my-qrcode');
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'add',
                child: _PopupMenuItem(
                    icon: Icons.person_add_alt_1, label: l.searchAddFriend),
              ),
              PopupMenuItem(
                value: 'scan',
                child:
                    _PopupMenuItem(icon: Icons.crop_free, label: l.scanEntry),
              ),
              PopupMenuItem(
                value: 'group',
                child: _PopupMenuItem(
                    icon: Icons.groups_2_outlined,
                    label: l.startGroupChat),
              ),
              PopupMenuItem(
                value: 'qrcode',
                child: _PopupMenuItem(
                    icon: Icons.qr_code_2_outlined, label: l.myQrcode),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: listAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(onRetry: _onRefresh),
        data: (rows) {
          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(children: [
                const SizedBox(height: 120),
                _EmptyConversations(refresh: _onRefresh),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: rows.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) => _ConversationTile(
                conv: rows[i],
                myId: myId,
                ref: ref,
                onTap: () => context.push('/chat/${rows[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  final int? myId;
  final VoidCallback onTap;
  final WidgetRef ref;

  const _ConversationTile(
      {required this.conv, required this.myId, required this.onTap, required this.ref});

  String _preview(AppL10n l) {
    // 草稿优先于最后消息预览。
    final draft = conv.draft;
    if (draft != null && draft.isNotEmpty) return draft;
    final type = conv.lastMsgType;
    final encrypted = conv.lastMsgEncrypted;
    String body;
    switch (type) {
      case 'RECALLED':
        body = l.lastMessageRecalled;
        break;
      case 'IMAGE':
        body = l.lastMessageImage;
        break;
      case 'VOICE':
        body = l.lastMessageVoice;
        break;
      case 'VIDEO':
        body = l.lastMessageVideo;
        break;
      case 'FILE':
        body = l.lastMessageFile;
        break;
      case 'LOCATION':
        body = l.lastMessageLocation;
        break;
      case 'MUSIC':
        body = l.lastMessageMusic;
        break;
      case 'CALL':
        body = l.lastMessageCall;
        break;
      case 'SYSTEM':
        body = l.lastMessageSystem;
        break;
      default:
        body = conv.lastMsgContent ?? '';
    }
    if (encrypted) body = l.lastMessageEncrypted;
    // 兜底：残留的撤回原始编码不直接展示。
    if (body.startsWith('RECALL::')) body = l.lastMessageRecalled;
    if (conv.lastMsgSender != null && conv.lastMsgSender == myId) {
      body = '${l.lastMessageYou}$body';
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final title = conv.type == 'SINGLE'
        ? (conv.peerNickname ?? conv.title ?? l.singleChatFallback)
        : (conv.title ?? l.unknownGroup);
    final avatarName = conv.type == 'SINGLE' ? title : (conv.title ?? 'G');
    final timeText = TimeFmt.listLabel(conv.lastMsgTime,
        today: l.today, yesterday: l.yesterday);
    // #8 置顶会话使用浅色背景区分
    final isPinned = conv.pinned;
    final isDark = theme.brightness == Brightness.dark;

    return Slidable(
      key: ValueKey('conv_${conv.id}'),
      // #12 左滑快捷操作：置顶/取消 + 终止会话
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _togglePin(context),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: isPinned ? l.unpinLabel : l.pinToTop,
          ),
          SlidableAction(
            onPressed: (_) => _terminate(context),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: l.terminateAction,
          ),
        ],
      ),
      child: Container(
        color: isPinned
            ? (isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.primary.withValues(alpha: 0.06))
            : null,
        child: ListTile(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Stack(
          children: [
            UserAvatar(
              name: avatarName,
              // 单聊用对端头像，群聊用自存群头像（空则回退首字）。
              avatarUrl: conv.type == 'SINGLE'
                  ? conv.peerAvatarUrl
                  : conv.groupAvatarUrl,
              // 官方助手会话使用专属渐变头像。
              isSystem: conv.type == 'SINGLE' &&
                  title == kSystemAssistantName,
              size: 52,
            ),
            if (conv.privateFlag)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.scaffoldBackgroundColor, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.lock,
                      size: 12, color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            // #8 置顶标识
            if (isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.push_pin,
                    size: 14, color: theme.colorScheme.primary),
              ),
            // #4 免打扰标识（标题前小铃铛）。
            if (conv.muted)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.notifications_off_outlined,
                    size: 14, color: theme.colorScheme.outline),
              ),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            // #8 群聊标记
            if (conv.type != 'SINGLE')
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.groups,
                    size: 14, color: theme.colorScheme.outline),
              ),
            Text(
              timeText,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor, fontSize: 12),
            ),
          ],
        ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            if (conv.lastMsgEncrypted)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.lock_outline,
                    size: 12, color: theme.colorScheme.outline),
              ),
            Expanded(
              child: Builder(builder: (_) {
                final hasDraft = conv.draft?.isNotEmpty == true;
                final baseStyle =
                    theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5);
                return Text.rich(
                  TextSpan(children: [
                    if (hasDraft)
                      TextSpan(
                        text: '[${l.draftLabel}] ',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    TextSpan(text: _preview(l)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle?.copyWith(
                    color: hasDraft
                        ? theme.colorScheme.error.withValues(alpha: 0.85)
                        : theme.hintColor,
                  ),
                );
              }),
            ),
            if (conv.unreadCount > 0) ...[
              const SizedBox(width: 8),
              // 免打扰会话：灰色描边小圆点（无数字），排在红色角标之后。
              if (conv.muted)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  constraints: const BoxConstraints(minWidth: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color:
                            theme.colorScheme.error.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),  // closes ListTile
    ),  // closes Container
  );  // closes Slidable (return statement)
  }

  // ===== D4 会话列表左滑/长按菜单辅助方法 =====

  /// 切换置顶（乐观更新：先写本地 DAO，再调 API；失败回滚并刷新）。
  Future<void> _togglePin(BuildContext context) async {
    final l = AppL10n.of(context);
    final next = !conv.pinned;
    final dao = ref.read(conversationsDaoProvider);
    await dao.setPinned(conv.id, next, next ? DateTime.now() : null);
    try {
      await ref.read(conversationRepoProvider).pin(conv.id, next);
      await ref.read(realtimeProvider).refreshConversations();
      if (context.mounted) {
        AppToast.info(context, next ? l.pinnedOn : l.unpinned);
      }
    } catch (e) {
      await dao.setPinned(conv.id, conv.pinned, conv.pinnedAt);
      await ref.read(realtimeProvider).refreshConversations();
      if (context.mounted) {
        AppToast.error(context, l.errorWithReason('$e'));
      }
    }
  }

  /// 切换消息免打扰。
  Future<void> _toggleMute(BuildContext context) async {
    final l = AppL10n.of(context);
    final next = !conv.muted;
    final dao = ref.read(conversationsDaoProvider);
    await dao.setMuted(conv.id, next);
    try {
      await ref.read(conversationRepoProvider).mute(conv.id, next);
      await ref.read(realtimeProvider).refreshConversations();
      if (context.mounted) {
        AppToast.info(context, next ? l.mutedOn : l.mutedOff);
      }
    } catch (e) {
      await dao.setMuted(conv.id, conv.muted);
      await ref.read(realtimeProvider).refreshConversations();
      if (context.mounted) {
        AppToast.error(context, l.errorWithReason('$e'));
      }
    }
  }

  /// 终止会话：双方软删除，列表中不再显示，无法继续发消息。
  Future<void> _terminate(BuildContext context) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.terminateChatTitle),
        content: Text(l.terminateChatConfirm),
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
            child: Text(l.terminateAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(conversationRepoProvider).terminate(conv.id);
      await ref.read(realtimeProvider).refreshConversations();
      if (context.mounted) {
        AppToast.success(context, l.chatTerminated);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, l.errorWithReason('$e'));
      }
    }
  }

  /// 长按会话弹出底部菜单（与左滑选项保持一致：置顶/免打扰/终止）。
  void _showContextMenu(BuildContext context) {
    final l = AppL10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(conv.pinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin),
              title: Text(conv.pinned ? l.unpinLabel : l.pinToTop),
              onTap: () {
                Navigator.of(sctx).pop();
                _togglePin(context);
              },
            ),
            ListTile(
              leading: Icon(conv.muted
                  ? Icons.notifications_off
                  : Icons.notifications_active),
              title: Text(conv.muted ? l.unmuteConv : l.muteConv),
              onTap: () {
                Navigator.of(sctx).pop();
                _toggleMute(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(sctx).colorScheme.error),
              title: Text(l.terminateChatTitle,
                  style: TextStyle(
                      color: Theme.of(sctx).colorScheme.error)),
              onTap: () {
                Navigator.of(sctx).pop();
                _terminate(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// #5 加号弹出菜单项：图标 + 文案，保持与微信风格一致。
class _PopupMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PopupMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

/// 会话列表空状态：大图标 + 提示 + 引导按钮，居中美观。
class _EmptyConversations extends StatelessWidget {
  final Future<void> Function() refresh;
  const _EmptyConversations({required this.refresh});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_outlined,
                  size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(l.convListEmptyTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              l.convListEmptyHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor, height: 1.5),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
