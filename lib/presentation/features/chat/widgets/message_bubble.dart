import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/audio/audio_player_controller.dart';
import '../../../../core/config/env.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/service/sticker_store.dart';
import '../../../../core/utils/image_saver.dart';
import '../../../../core/utils/media_meta.dart';
import '../../../../core/utils/message_reply.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../data/models/models.dart';
import '../../../state/providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/user_avatar.dart';
import '../../contacts/user_profile_page.dart';
import '../chat_controller.dart';
import 'forward_sheet.dart';
import 'fullscreen_image_page.dart';
import 'fullscreen_video_page.dart';

/// Telegram 风格聊天气泡：发出方右对齐蓝色气泡、收到方左对齐白/灰气泡，
/// 气泡带尾巴效果（右下/左下小圆角）；群聊收到消息显示发送者昵称。
class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool mine;
  final bool isGroup;
  /// #9 图片点击回调：由父级 _MessageList 传入，接收当前消息并打开 PageView 查看器。
  final void Function(Message message)? onImageTap;
  // #11 多选转发模式：点按切换选中 + 长按菜单提供"多选"入口。
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onMultiSelect;
  /// #11 群聊长按发送者头像 → 直接 @ 到输入框。
  final void Function(int userId)? onMentionUser;
  /// 引用回复：长按菜单点"回复"后回调（nickname/snippet 已由气泡层解析）。
  final void Function(Message message, String nickname, String snippet)?
      onReply;
  /// 点击气泡内引用块：文本→定位原消息；图片/视频→直接放大查看。
  final void Function(ReplyQuoteData quote)? onQuoteTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.isGroup = false,
    this.onImageTap,
    this.selectionMode = false,
    this.selected = false,
    this.onToggle,
    this.onMultiSelect,
    this.onMentionUser,
    this.onReply,
    this.onQuoteTap,
  });

  /// 是否为收藏贴纸（IMAGE + mediaMeta.sticker）。
  bool get _isSticker {
    if (message.type != 'IMAGE' || message.mediaMeta == null) return false;
    try {
      return (jsonDecode(message.mediaMeta!) as Map)['sticker'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 头像组件：mine 时用 session 用户（relation=SELF），!mine 时用 chatSender 结果。
  Widget _avatarWidget({
    required BuildContext context,
    required AppUser? myUser,
    required User? senderUser,
    required GroupMember? senderMember,
    required String senderName,
  }) {
    final avatarUrl = mine
        ? myUser?.avatarUrl
        : (senderMember?.avatarUrl ?? senderUser?.avatarUrl);
    return GestureDetector(
      onTap: mine
          ? (myUser != null
              ? () => context.push('/user-profile',
                  extra: UserProfileArgs(
                    user: UserBrief(
                      id: myUser.id,
                      nickname: myUser.nickname.isNotEmpty
                          ? myUser.nickname
                          : senderName,
                      avatarUrl: myUser.avatarUrl,
                      relation: 'SELF',
                    ),
                    groupConvId: isGroup ? message.convId : null,
                  ))
              : null)
          : (senderUser == null
              ? null
              : () => context.push('/user-profile',
                  extra: UserProfileArgs(
                    user: UserBrief(
                      id: message.senderId,
                      nickname: senderUser.nickname.isNotEmpty
                          ? senderUser.nickname
                          : senderName,
                      avatarUrl: senderUser.avatarUrl,
                    ),
                    groupConvId: isGroup ? message.convId : null,
                  ))),
      onLongPress: onMentionUser == null
          ? null
          : () => onMentionUser!(message.senderId),
      child: UserAvatar(
        name: senderName,
        avatarUrl: avatarUrl,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blocked = message.serverStatus == 'BLOCKED';

    // 系统消息：名片卡片 / 群通知 / 撤回提示。
    if (message.type == 'SYSTEM') {
      final content = message.content ?? '';
      if (content.startsWith('USER_CARD::') ||
          content.startsWith('GROUP_CARD::')) {
        return _CardSystemBubble(content: content, mine: mine);
      }
      // 撤回本地标记为 SYSTEM + RECALL:: 编码：立即渲染撤回提示，
      // 不能作为普通系统通知展示原始编码。
      if (content.startsWith('RECALL::')) {
        return _RecalledNotice(message: message, mine: mine);
      }
      return _SystemNotice(content: content);
    }

    // #18 消息已撤回：居中灰色胶囊提示（#7 支持具名管理员撤回）。
    if (message.serverStatus == 'RECALLED') {
      return _RecalledNotice(message: message, mine: mine);
    }

    // 收藏贴纸（IMAGE + meta.sticker）：无气泡底色，约 120px 直接贴图。
    if (_isSticker) {
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: GestureDetector(
            onTap: () {
              final url = message.mediaUrl;
              if (url == null || url.isEmpty) return;
              if (onImageTap != null) {
                onImageTap!(message);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenImagePage.single(url),
                  ),
                );
              }
            },
            onLongPress: () => _showMessageSheet(context, ref, theme),
            child: CachedNetworkImage(
              imageUrl: Env.mediaUrl(message.mediaUrl),
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => const SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white54),
                ),
              ),
              placeholder: (_, _) => const SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Telegram 风格颜色：
    // 发出方 = telegramOutgoing 蓝（亮/暗一致），白字。
    // 收到方 = 亮白底深字 / 暗模式 #182533 深底白字。
    final bubbleColor = blocked
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.7)
        : (mine
              ? telegramOutgoing
              : (isDark ? telegramDarkIncoming : Colors.white));
    final fgColor = mine
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF212B36));

    // 尾巴效果：自己的气泡右下角小圆角，对方的气泡左下角小圆角。
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(mine ? 16 : 4),
      bottomRight: Radius.circular(mine ? 4 : 16),
    );

    // 自己的消息从 session 取用户信息，他人消息从 chatSenderProvider 查询。
    final myUser = mine ? ref.watch(sessionControllerProvider).user : null;
    final senderUser = !mine
        ? ref
              .watch(chatSenderProvider(message.senderId))
              .when(data: (u) => u, loading: () => null, error: (_, _) => null)
        : null;
    // 群成员信息：群昵称优先 + 群主/管理员角色（仅群聊非自己消息需要）。
    final groupMembers = (isGroup && !mine)
        ? ref
              .watch(groupMembersProvider(message.convId))
              .when(data: (list) => list, loading: () => null, error: (_, _) => null)
        : null;
    GroupMember? senderMember;
    if (groupMembers != null) {
      for (final m in groupMembers) {
        if (m.userId == message.senderId) {
          senderMember = m;
          break;
        }
      }
    }
    String? senderName;
    if (senderMember != null) {
      final gn = senderMember.groupNickname;
      if (gn != null && gn.isNotEmpty) {
        senderName = gn;
      } else {
        senderName = (senderMember.nickname != null &&
                senderMember.nickname!.isNotEmpty)
            ? senderMember.nickname
            : null;
      }
    }
    if (senderName == null && senderUser != null) {
      final nick = senderUser.nickname;
      senderName = nick.isNotEmpty
          ? nick
          : (senderUser.username.isNotEmpty ? senderUser.username : null);
    }
    // 自己的消息：从当前登录用户取昵称/用户名。
    if (senderName == null && mine && myUser != null) {
      senderName = myUser.nickname.isNotEmpty
          ? myUser.nickname
          : (myUser.username.isNotEmpty ? myUser.username : null);
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        constraints: BoxConstraints(
          maxWidth: 300.w,
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (senderName != null)
              Padding(
                padding: EdgeInsets.only(
                  left: mine ? 0 : 4,
                  right: mine ? 4 : 0,
                  bottom: 4,
                  top: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!mine) ...[
                      _avatarWidget(
                        context: context,
                        myUser: myUser,
                        senderUser: senderUser,
                        senderMember: senderMember,
                        senderName: senderName,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              senderName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          // 群主/管理员标识：精致小巧。
                          if (senderMember?.role == 'OWNER')
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Tooltip(
                                message: l.owner,
                                child: const Icon(Icons.workspace_premium,
                                    size: 13, color: Color(0xFFE8A33D)),
                              ),
                            )
                          else if (senderMember?.role == 'ADMIN')
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Tooltip(
                                message: l.admin,
                                child: Icon(Icons.verified_user,
                                    size: 12,
                                    color: theme.colorScheme.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 8),
                      _avatarWidget(
                        context: context,
                        myUser: myUser,
                        senderUser: senderUser,
                        senderMember: senderMember,
                        senderName: senderName,
                      ),
                    ],
                  ],
                ),
              ),
            // #11 多选模式：气泡横向并排一个选中圆点。
            // Material 必须包 Flexible：min Row 给非弹性子节点的是无界宽度，
            // 长文本 Text 因此不会换行而向右溢出（RenderFlex overflow）。
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Material(
                    color: bubbleColor,
                    borderRadius: bubbleRadius,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    elevation: isDark ? 0 : 0.5,
                    child: InkWell(
                      onTap: selectionMode ? onToggle : null,
                      onLongPress: message.clientStatus == 'FAILED'
                          ? () => ref
                                .read(chatControllerProvider(message.convId)
                                    .notifier)
                                .resend(message.msgId)
                          : () => _showMessageSheet(context, ref, theme),
                      borderRadius: bubbleRadius,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        child: _content(context, ref, fgColor, blocked, l),
                      ),
                    ),
                  ),
                ),
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.hintColor,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.encrypted)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock, size: 11, color: theme.hintColor),
                    ),
                  Text(
                    message.createdAt == null
                        ? ''
                        : TimeFmt.bubble(message.createdAt!),
                    style: TextStyle(fontSize: 11, color: theme.hintColor),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    _statusIcon(theme, l),
                  ],
                ],
              ),
            ),
            if (blocked)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l.statusBlocked,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    Color fg,
    bool blocked,
    AppL10n l,
  ) {
    switch (message.type) {
      case 'IMAGE':
        final failed = message.clientStatus == 'FAILED';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            // 点击：失败消息重发，其余进全屏查看。
            onTap: () {
              if (failed) {
                ref
                    .read(chatControllerProvider(message.convId).notifier)
                    .resend(message.msgId);
                return;
              }
              final url = message.mediaUrl;
              if (url == null || url.isEmpty) return;
              // #9 交给父级打开 PageView 查看器（支持左右滑动）
              if (onImageTap != null) {
                onImageTap!(message);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullscreenImagePage.single(url),
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240, maxHeight: 280),
              child: CachedNetworkImage(
                imageUrl: Env.mediaUrl(message.mediaUrl),
                fit: BoxFit.fitWidth,
                errorWidget: (_, _, _) => SizedBox(
                  width: 200,
                  height: 140,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, color: fg),
                        const SizedBox(height: 6),
                        Text(
                          MediaMetaInfo.parse(message.mediaMeta).name ??
                              'image',
                          style: TextStyle(color: fg, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                placeholder: (_, _) => const SizedBox(
                  width: 200,
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
        );
      case 'VOICE':
        return _VoiceBubbleContent(
          url: message.mediaUrl ?? '',
          meta: message.mediaMeta,
          fgColor: fg,
        );
      case 'VIDEO':
        return _VideoBubbleContent(
          url: message.mediaUrl ?? '',
          meta: message.mediaMeta,
          fgColor: fg,
          onOpen: () {
            final url = message.mediaUrl;
            if (url == null || url.isEmpty) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullscreenVideoPage(url: url),
              ),
            );
          },
        );
      case 'FILE':
        return _FileBubbleContent(
          url: message.mediaUrl ?? '',
          meta: message.mediaMeta,
          fgColor: fg,
        );
      case 'MUSIC':
        return _MusicBubbleContent(
          url: message.mediaUrl ?? '',
          meta: message.mediaMeta,
          fgColor: fg,
        );
      case 'CALL':
        return _CallBubbleContent(message: message, fgColor: fg);
      case 'LOCATION':
        return _LocationBubbleContent(
          meta: message.mediaMeta,
          fgColor: fg,
          l: l,
        );
      default:
        if (message.encrypted) {
          final plain = ref.watch(messagePlaintextProvider(message));
          return plain.when(
            data: (text) {
              if (text == null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 15, color: fg),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l.e2eeEncrypted,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                );
              }
              // 加密消息：解密后可能是 {"text","replyTo"} 信封。
              final env = parsePlainEnvelope(text);
              return _textWithMaybeQuote(
                env.text,
                quote: env.reply,
                fg: fg,
              );
            },
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            ),
            error: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  l.e2eeEncrypted,
                  style: TextStyle(color: fg, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        }
        return _textWithMaybeQuote(
          message.content ?? '',
          quote: readReplyFromMediaMeta(message.mediaMeta),
          fg: fg,
          dim: blocked,
        );
    }
  }

  /// 文本气泡正文 + 可选引用块（引用块在正文上方，点击定位原消息）。
  Widget _textWithMaybeQuote(
    String text, {
    ReplyQuoteData? quote,
    required Color fg,
    bool dim = false,
  }) {
    if (quote == null) return _textBody(text, fg, dim: dim);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReplyQuote(
          quote: quote,
          mine: mine,
          fg: fg,
          onTap: () => onQuoteTap?.call(quote),
        ),
        const SizedBox(height: 6),
        _textBody(text, fg, dim: dim),
      ],
    );
  }

  /// 群聊文本：高亮 @提及（Telegram 风格）；单聊/无 @ 退化为纯文本。
  Widget _textBody(String text, Color fg, {bool dim = false}) {
    final color = dim ? fg.withValues(alpha: 0.7) : fg;
    if (!isGroup || !text.contains('@')) {
      return Text(
        text,
        style: TextStyle(color: color, fontSize: 16, height: 1.35),
      );
    }
    final reg = RegExp(r'@[^\s@]{1,32}');
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in reg.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final token = m.group(0)!;
      final isAll = token == '@所有人' || token.toLowerCase() == '@everyone';
      spans.add(TextSpan(
        text: token,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          // @所有人 用醒目的金色；普通提及蓝底白字气泡用浅蓝，普通底色 Sylph 蓝。
          color: isAll
              ? (fg == Colors.white
                  ? const Color(0xFFFFD66B)
                  : const Color(0xFFE0A32E))
              : (fg == Colors.white
                  ? const Color(0xFFB3DDFF)
                  : const Color(0xFF2EA6FF)),
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return Text.rich(
      TextSpan(
        style: TextStyle(color: color, fontSize: 16, height: 1.35),
        children: spans,
      ),
    );
  }

  /// 引用非文本消息时的类型占位（l10n）。
  String _typeQuoteLabel(String type, AppL10n l) {
    switch (type) {
      case 'IMAGE':
        return l.quoteImage;
      case 'VOICE':
        return l.quoteVoice;
      case 'VIDEO':
        return l.quoteVideo;
      case 'FILE':
        return l.quoteFile;
      case 'MUSIC':
        return l.quoteMusic;
      case 'LOCATION':
        return l.quoteLocation;
      case 'CALL':
        return l.quoteCall;
      default:
        return l.quoteEncrypted;
    }
  }

  /// 长按菜单（所有消息类型统一入口，避免图片出现两个长按焦点）：
  /// 图片=保存图片/转发/撤回；文本=复制/转发/撤回；语音=转发/撤回；
  /// 视频/文件=转发/撤回。底部始终带“取消”。
  void _showMessageSheet(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    final l = AppL10n.of(context);
    final now = DateTime.now();
    // #7 群主/管理员可随时撤回任何人的消息（不受 2 分钟窗口限制）。
    final myRole = isGroup
        ? ref
            .watch(groupDetailProvider(message.convId))
            .valueOrNull
            ?.myRole
        : null;
    final canManage = myRole == 'OWNER' || myRole == 'ADMIN';
    final withinWindow = message.createdAt != null &&
        now.difference(message.createdAt!) < const Duration(seconds: 120);
    final type = message.type;
    final canRecall =
        const ['SENT', 'DELIVERED', 'READ'].contains(message.clientStatus) &&
            message.serverStatus != 'RECALLED' &&
            // #11 通话记录为系统落库消息，不允许撤回。
            type != 'CALL' &&
            ((mine && withinWindow) || canManage);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: Text(l.reply),
                onTap: () async {
                  Navigator.pop(sctx);
                  // 昵称一律取真实昵称（含自己），不能本地化成"你"——
                  // 快照会随消息发给会话所有成员，本地化会导致人人都看到"你"。
                  final String nickname;
                  if (isGroup) {
                    var resolved = '';
                    final members = ref
                        .read(groupMembersProvider(message.convId))
                        .valueOrNull;
                    if (members != null) {
                      for (final mm in members) {
                        if (mm.userId != message.senderId) continue;
                        resolved = mm.groupNickname?.isNotEmpty == true
                            ? mm.groupNickname!
                            : (mm.nickname?.isNotEmpty == true
                                  ? mm.nickname!
                                  : '');
                        break;
                      }
                    }
                    if (resolved.isEmpty) {
                      resolved = ref
                              .read(chatSenderProvider(message.senderId))
                              .valueOrNull
                              ?.nickname ??
                          '';
                    }
                    nickname = resolved.isNotEmpty
                        ? resolved
                        : (mine
                              ? (ref
                                      .read(sessionControllerProvider)
                                      .user
                                      ?.nickname ??
                                  l.unknownUser)
                              : l.unknownUser);
                  } else {
                    // 单聊：对方取会话备注；自己取当前账号昵称。
                    nickname = mine
                        ? ((ref
                                            .read(sessionControllerProvider)
                                            .user
                                            ?.nickname ??
                                        '')
                                    .isNotEmpty
                                ? ref
                                    .read(sessionControllerProvider)
                                    .user!
                                    .nickname
                                : l.unknownUser)
                        : (ref
                                .read(chatConversationProvider(message.convId))
                                .valueOrNull
                                ?.peerNickname ??
                            l.unknownUser);
                  }
                  // 摘要：TEXT 取正文（密文先解密信封）；其余取类型占位。
                  String snippet;
                  if (type == 'TEXT') {
                    var plain = message.content ?? '';
                    if (message.encrypted) {
                      final decrypted = await ref
                          .read(messagePlaintextProvider(message).future);
                      if (decrypted == null) {
                        snippet = l.quoteEncrypted;
                        onReply!(message, nickname, snippet);
                        return;
                      }
                      plain = parsePlainEnvelope(decrypted).text;
                    }
                    snippet =
                        buildQuoteSnippet('TEXT', plain, (_) => '').trim();
                    if (snippet.isEmpty) snippet = l.quoteEncrypted;
                  } else {
                    snippet = _typeQuoteLabel(type, l);
                  }
                  onReply!(message, nickname, snippet);
                },
              ),
            if (type == 'IMAGE')
              ListTile(
                leading: const Icon(Icons.save_alt_outlined),
                title: Text(l.saveImage),
                onTap: () {
                  Navigator.pop(sctx);
                  final url = message.mediaUrl;
                  if (url != null && url.isNotEmpty) {
                    ImageSaver.save(context, url);
                  }
                },
              ),
            if (type == 'TEXT')
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(l.copy),
                onTap: () async {
                  Navigator.pop(sctx);
                  // 密文消息取已解密明文（可能是回复信封，只复制正文）。
                  var text = message.content ?? '';
                  if (message.encrypted) {
                    final plain =
                        await ref.read(messagePlaintextProvider(message).future);
                    if (plain != null) {
                      text = parsePlainEnvelope(plain).text;
                    }
                  }
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    AppToast.info(context, AppL10n.of(context).copied);
                  }
                },
              ),
            // 纯 emoji 文本（或密文消息——点击时解密后再判定）可收藏为文本表情。
            if (type == 'TEXT' &&
                (message.encrypted ||
                    isEmojiOnlyText(message.content ?? '')))
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: Text(l.addToStickers),
                onTap: () async {
                  Navigator.pop(sctx);
                  var text = message.content ?? '';
                  if (message.encrypted) {
                    final plain =
                        await ref.read(messagePlaintextProvider(message).future);
                    if (plain != null) {
                      text = parsePlainEnvelope(plain).text;
                    }
                  }
                  text = text.trim();
                  if (!isEmojiOnlyText(text)) {
                    if (context.mounted) {
                      AppToast.error(context, l.emojiOnlyCannotSave);
                    }
                    return;
                  }
                  await StickerStore.addEmoji(text);
                  if (context.mounted) {
                    AppToast.success(context, l.stickerAdded);
                  }
                },
              ),
            if (type == 'IMAGE')
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: Text(l.addToStickers),
                onTap: () async {
                  Navigator.pop(sctx);
                  final url = message.mediaUrl;
                  if (url == null || url.isEmpty) return;
                  final bytes = await ImageSaver.fetchBytes(url);
                  if (bytes == null) {
                    if (context.mounted) {
                      AppToast.error(context, l.addStickerFailed);
                    }
                    return;
                  }
                  final dot = url.lastIndexOf('.');
                  final ext = dot > 0
                      ? url.substring(dot + 1).split('?').first
                      : 'png';
                  await StickerStore.addFromBytes(bytes, ext: ext);
                  if (context.mounted) {
                    AppToast.success(context, l.stickerAdded);
                  }
                },
              ),
            if (type == 'TEXT' ||
                type == 'IMAGE' ||
                type == 'VOICE' ||
                type == 'VIDEO' ||
                type == 'FILE' ||
                type == 'LOCATION' ||
                type == 'MUSIC')
              ListTile(
                leading: const Icon(Icons.forward_outlined),
                title: Text(l.forward),
                onTap: () {
                  Navigator.pop(sctx);
                  // 密文转发：把明文交给转发面板，按目标会话重新加密。
                  // 回复信封只转发正文，不带引用关系。
                  var content = message.content;
                  if (type == 'TEXT' && message.encrypted) {
                    ref
                        .read(messagePlaintextProvider(message).future)
                        .then((plain) {
                      if (plain != null && context.mounted) {
                        showForwardSheet(
                          context,
                          ref,
                          type: type,
                          content: parsePlainEnvelope(plain).text,
                          mediaUrl: message.mediaUrl,
                          mediaMeta: message.mediaMeta,
                        );
                      }
                    });
                    return;
                  }
                  showForwardSheet(
                    context,
                    ref,
                    type: type,
                    content: content,
                    mediaUrl: message.mediaUrl,
                    mediaMeta: message.mediaMeta,
                  );
                },
              ),
            if (onMultiSelect != null)
              ListTile(
                leading: const Icon(Icons.checklist_rounded),
                title: Text(l.multiSelect),
                onTap: () {
                  Navigator.pop(sctx);
                  onMultiSelect!();
                },
              ),
            if (canRecall)
              ListTile(
                leading: Icon(Icons.undo, color: theme.colorScheme.error),
                title: Text(l.recall,
                    style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  Navigator.pop(sctx);
                  // 撤回失败（如超时/已被限制）要给出明确提示。
                  () async {
                    try {
                      await ref
                          .read(chatControllerProvider(message.convId)
                              .notifier)
                          .recallMessage(message);
                    } catch (e) {
                      if (context.mounted) {
                        AppToast.error(
                            context,
                            e
                                    .toString()
                                    .contains('recall_window_expired')
                                ? l.recallWindowExpired
                                : l.recallFailedReason('$e'));
                      }
                    }
                  }();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l.cancel),
              onTap: () => Navigator.pop(sctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(ThemeData theme, AppL10n l) {
    switch (message.clientStatus) {
      case 'PENDING':
        return Icon(Icons.schedule, size: 14, color: theme.hintColor);
      case 'FAILED':
        return Icon(
          Icons.error_outline,
          size: 14,
          color: theme.colorScheme.error,
        );
      case 'SENT':
        return Icon(Icons.check, size: 14, color: theme.hintColor);
      case 'DELIVERED':
        return Icon(Icons.done_all, size: 15, color: theme.hintColor);
      case 'READ':
        return const Icon(Icons.done_all, size: 15, color: telegramOutgoing);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// #7/#18 撤回提示胶囊：本人/发送者自撤沿用旧文案；
/// 群主管理员撤回他人消息时显示"{昵称}撤回了一条消息"。
class _RecalledNotice extends ConsumerWidget {
  final Message message;
  final bool mine;
  const _RecalledNotice({required this.message, required this.mine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);

    var text = mine ? l.youRecalled : l.peerRecalled;
    final content = message.content ?? '';
    if (content.startsWith('RECALL::')) {
      final parts = content.split('::');
      // 编码格式：RECALL::<撤回者 userId>::<是否管理员 0|1>。
      // 注意 by 在 parts[1]，parts[2] 是管理员标志——索引取错会把 by
      // 解析成 0，从而误显示"管理员撤回了一条消息"。
      final byStr = parts.length > 1 ? parts[1] : '';
      final by = int.tryParse(byStr);
      final byAdmin = parts.length > 2 && parts[2] == '1';
      final me = ref.read(sessionControllerProvider).user?.id;
      if (by == null) {
        text = mine ? l.youRecalled : l.peerRecalled;
      } else if (by == me) {
        text = l.youRecalled;
      } else if (byAdmin || by != message.senderId) {
        // 管理员撤回了别人的消息：具名提示。
        final name = ref.watch(chatSenderProvider(by)).valueOrNull?.nickname;
        text = l.recalledByName(
            (name != null && name.isNotEmpty) ? name : l.adminFallback);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
        ),
      ),
    );
  }
}

/// #14 语音消息气泡内容：播放按钮 + 时长。
class _VoiceBubbleContent extends StatefulWidget {
  final String url;
  final String? meta;
  final Color fgColor;

  const _VoiceBubbleContent({
    required this.url,
    required this.meta,
    required this.fgColor,
  });

  @override
  State<_VoiceBubbleContent> createState() => _VoiceBubbleContentState();
}

class _VoiceBubbleContentState extends State<_VoiceBubbleContent> {
  /// 全局单例：语音与音乐互斥播放。
  final _audio = AudioPlayerController.instance;
  /// meta 中的录制时长（权威展示值）。
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _parseDuration();
    _audio.addListener(_onAudio);
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  void _parseDuration() {
    if (widget.meta == null) return;
    try {
      final json = jsonDecode(widget.meta!);
      _duration = (json['duration'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final url = Env.mediaUrl(widget.url);
    try {
      await _audio.toggle(
          AudioPlayItem(id: widget.url, url: url, kind: AudioItemKind.voice));
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).playFailedReason('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 标签始终显示总时长（meta 权威，缺失才用流时长），播放中不跳动。
    final streamTotal = _audio.duration.inSeconds;
    final total = _duration > 0 ? _duration : streamTotal;
    final active = _audio.isCurrent(widget.url);
    final playing = active && _audio.isPlaying;
    final posSec = active ? _audio.position.inSeconds : 0;
    return GestureDetector(
      onTap: _togglePlay,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _audio.isItemLoading(widget.url)
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: widget.fgColor),
                  ),
                )
              : Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 24,
                  color: widget.fgColor,
                ),
          const SizedBox(width: 6),
          // 简易进度条
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total > 0
                    ? (posSec / total).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: widget.fgColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(widget.fgColor),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${total}s',
            style: TextStyle(fontSize: 13, color: widget.fgColor),
          ),
        ],
      ),
    );
  }
}

/// 居中浅色系统通知胶囊（时间分割线式提示、撤回提示、入群/禁言通知等）。
class _SystemNotice extends StatelessWidget {
  final String content;
  const _SystemNotice({required this.content});

  /// 禁言时长（秒）转本地化文本。
  static String _durationText(AppL10n l, int secs) {
    if (secs >= 86400) {
      final d = secs ~/ 86400;
      final h = (secs % 86400) ~/ 3600;
      return h > 0 ? l.durationDaysHours(d, h) : l.durationDays(d);
    }
    if (secs >= 3600) {
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      return m > 0 ? l.durationHoursMinutes(h, m) : l.durationHours(h);
    }
    if (secs >= 60) return l.durationMinutes(secs ~/ 60);
    return l.durationSeconds(secs);
  }

  /// 解析群通知内容，返回富文本；非通知格式返回 null（走纯文本）。
  InlineSpan? _span(BuildContext context, Color base) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    final accent = theme.colorScheme.primary;
    name(String s) => TextSpan(
          text: s,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        );
    plain(String s) => TextSpan(text: s, style: TextStyle(fontSize: 12, color: base));

    if (content.startsWith('JOIN::')) {
      final p = content.split('::');
      final nick = p.length > 2 && p[2].isNotEmpty ? p[2] : l.newMember;
      return TextSpan(children: [name(nick), plain(l.joinedGroupNotice)]);
    }
    if (content.startsWith('MUTE::')) {
      final p = content.split('::');
      if (p.length >= 4) {
        final actor = p[1].isNotEmpty ? p[1] : l.admin;
        final target = p[2].isNotEmpty ? p[2] : l.theMember;
        final secs = int.tryParse(p[3]) ?? 0;
        return TextSpan(children: [
          name(target),
          plain(l.mutedBy),
          name(actor),
          plain(l.mutedForDuration(_durationText(l, secs))),
        ]);
      }
    }
    if (content.startsWith('UNMUTE::')) {
      final p = content.split('::');
      if (p.length >= 3) {
        final actor = p[1].isNotEmpty ? p[1] : l.admin;
        final target = p[2].isNotEmpty ? p[2] : l.theMember;
        return TextSpan(children: [
          name(target),
          plain(l.unmutedBy),
          name(actor),
          plain(l.unmutedSuffix),
        ]);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.hintColor;
    final span = _span(context, base);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.75,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text.rich(
            span ??
                TextSpan(
                  text: content,
                  style: TextStyle(fontSize: 12, color: base),
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// 名片消息（个人名片 / 群聊名片）：按发送方左右对齐的卡片气泡，点击进资料页。
/// 内容格式（后端 insertSystem 生成，裸 :: 拼接）：
/// USER_CARD::{userId}::{nickname}::{uid}::{qrcodeToken}
/// GROUP_CARD::{convId}::{name}::{groupNumber}::{token}
class _CardSystemBubble extends ConsumerWidget {
  final String content;
  final bool mine;
  const _CardSystemBubble({required this.content, required this.mine});

  /// 点击名片：先按 token 拉取完整资料（头像/关系/成员数/公告）再进详情页，
  /// 避免只带 id+昵称导致详情页头像空、好友也显示"添加通讯录"。
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final parts = content.split('::');
    final isUser = parts.first == 'USER_CARD';
    final id = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    final name = parts.length > 2 && parts[2].isNotEmpty
        ? parts[2]
        : (isUser ? l.unknownUser : l.unknownGroup);
    final number = parts.length > 3 ? parts[3] : '';
    final token = parts.length > 4 ? parts[4] : '';
    if (id == 0) return;
    try {
      if (isUser) {
        final brief = token.isEmpty
            ? UserBrief(
                id: id,
                uid: number.isEmpty ? null : number,
                nickname: name,
              )
            : await ref.read(socialRepoProvider).resolveUser(token);
        if (!context.mounted) return;
        context.push('/user-profile', extra: UserProfileArgs(user: brief));
      } else {
        final brief = token.isEmpty
            ? GroupBrief(
                convId: id,
                name: name,
                groupNumber: number.isEmpty ? null : number,
              )
            : await ref.read(groupRepoProvider).resolve(token);
        if (!context.mounted) return;
        context.push('/group-profile', extra: brief);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
            context, AppL10n.of(context).openCardFailedReason('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parts = content.split('::');
    final isUser = parts.first == 'USER_CARD';
    final id = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    final name = parts.length > 2 && parts[2].isNotEmpty
        ? parts[2]
        : (isUser ? l.unknownUser : l.unknownGroup);
    final number = parts.length > 3 ? parts[3] : '';

    final cardColor = mine
        ? telegramOutgoing
        : (isDark ? telegramDarkIncoming : Colors.white);
    final fgColor = mine
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF212B36));
    final subColor = mine
        ? Colors.white.withValues(alpha: 0.75)
        : theme.hintColor;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        constraints: BoxConstraints(
          maxWidth: 270.w,
        ),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: id == 0 ? null : () => _open(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUser)
                    UserAvatar(name: name, size: 40)
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.groups_2_outlined,
                          size: 22, color: theme.colorScheme.primary),
                    ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: fgColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isUser
                              ? (number.isEmpty
                                  ? l.userCard
                                  : l.userCardWithUid(number))
                              : (number.isEmpty
                                  ? l.groupCard
                                  : l.groupCardWithNumber(number)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: subColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// #12 视频气泡：首帧 + 中央播放键 + 右下角时长，点击进全屏播放页。
class _VideoBubbleContent extends StatefulWidget {
  final String url;
  final String? meta;
  final Color fgColor;
  final VoidCallback onOpen;

  const _VideoBubbleContent({
    required this.url,
    required this.meta,
    required this.fgColor,
    required this.onOpen,
  });

  @override
  State<_VideoBubbleContent> createState() => _VideoBubbleContentState();
}

class _VideoBubbleContentState extends State<_VideoBubbleContent> {
  VideoPlayerController? _c;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.meta != null) {
      try {
        _duration =
            (jsonDecode(widget.meta!)['duration'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    if (widget.url.isNotEmpty) {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(Env.mediaUrl(widget.url)),
      );
      _c = c;
      c.initialize().then((_) {
        if (!mounted) {
          c.dispose();
          return;
        }
        if (_duration == 0) {
          _duration = c.value.duration.inSeconds;
        }
        // 静音取首帧，避免列表里多个视频同时出声。
        c.setVolume(0);
        setState(() {});
      }).catchError((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  String get _durationText {
    final d = _duration;
    final m = d ~/ 60;
    final s = (d % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    return GestureDetector(
      onTap: widget.onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 220,
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ready)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                )
              else
                Container(color: Colors.black54),
              const Center(
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 34),
                ),
              ),
              if (_duration > 0)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _durationText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 文件消息卡片：图标 + 文件名 + 大小，点击调系统浏览器/下载器打开。
class _FileBubbleContent extends StatelessWidget {
  final String url;
  final String? meta;
  final Color fgColor;

  const _FileBubbleContent({
    required this.url,
    required this.meta,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    final m = MediaMetaInfo.parse(meta);
    final sub = MediaMetaInfo.humanSize(m.size);
    return GestureDetector(
      onTap: url.isEmpty
          ? null
          : () async {
              final uri = Uri.parse(Env.mediaUrl(url));
              final ok = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!ok && context.mounted) {
                AppToast.error(context,
                    AppL10n.of(context).openFileFailed);
              }
            },
      child: SizedBox(
        width: 230,
        child: Row(
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 34, color: fgColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.name ?? 'file',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        color: fgColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.download_outlined, size: 20, color: fgColor),
          ],
        ),
      ),
    );
  }
}

/// 音乐消息卡片：音符播放键 + 标题 + 时长。
class _MusicBubbleContent extends StatefulWidget {
  final String url;
  final String? meta;
  final Color fgColor;

  const _MusicBubbleContent({
    required this.url,
    required this.meta,
    required this.fgColor,
  });

  @override
  State<_MusicBubbleContent> createState() => _MusicBubbleContentState();
}

class _MusicBubbleContentState extends State<_MusicBubbleContent> {
  final _audio = AudioPlayerController.instance;
  String _title = '';
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.meta != null) {
      try {
        final j = jsonDecode(widget.meta!) as Map;
        _title = (j['title'] ?? j['name'] ?? '').toString();
        _duration = (j['duration'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    _audio.addListener(_onAudio);
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    super.dispose();
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggle() async {
    try {
      await _audio.toggle(AudioPlayItem(
        id: widget.url,
        url: Env.mediaUrl(widget.url),
        kind: AudioItemKind.music,
      ));
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).playFailedReason('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _audio.isCurrent(widget.url);
    final playing = active && _audio.isPlaying;
    final loading = _audio.isItemLoading(widget.url);
    final hasError = _audio.errorId == widget.url;
    final totalSec = active
        ? (_audio.duration.inSeconds > 0
            ? _audio.duration.inSeconds
            : _duration)
        : _duration;
    final pos = active ? _audio.position : Duration.zero;
    final dur = active && _audio.duration.inSeconds > 0
        ? _audio.duration
        : Duration(seconds: _duration);
    final posClamped = pos.inMilliseconds > dur.inMilliseconds &&
            dur.inMilliseconds > 0
        ? dur
        : pos;

    Widget buttonIcon;
    if (loading) {
      buttonIcon = SizedBox(
        width: 22,
        height: 22,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: widget.fgColor),
        ),
      );
    } else if (hasError) {
      buttonIcon = Icon(Icons.error_outline_rounded,
          size: 22, color: widget.fgColor);
    } else {
      buttonIcon = Icon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 26,
        color: widget.fgColor,
      );
    }

    return SizedBox(
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: loading ? null : _toggle,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      widget.fgColor.withValues(alpha: 0.15),
                  child: buttonIcon,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title.isEmpty
                          ? AppL10n.of(context).musicCard
                          : _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: widget.fgColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.music_note_rounded,
                            size: 12,
                            color:
                                widget.fgColor.withValues(alpha: 0.65)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            loading
                                ? AppL10n.of(context).musicDownloading
                                : AppL10n.of(context).musicCard,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  widget.fgColor.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (totalSec > 0)
                Text(
                  _fmt(totalSec),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.fgColor.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          // 播放中展示可拖动进度条。
          if (active && dur.inMilliseconds > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(_fmt(posClamped.inSeconds),
                    style: TextStyle(
                        fontSize: 10.5,
                        color: widget.fgColor.withValues(alpha: 0.7))),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      min: 0,
                      max: dur.inMilliseconds.toDouble(),
                      value: posClamped.inMilliseconds
                          .clamp(0, dur.inMilliseconds)
                          .toDouble(),
                      activeColor: widget.fgColor,
                      inactiveColor:
                          widget.fgColor.withValues(alpha: 0.25),
                      onChanged: (v) =>
                          _audio.seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                ),
                Text(_fmt(dur.inSeconds),
                    style: TextStyle(
                        fontSize: 10.5,
                        color: widget.fgColor.withValues(alpha: 0.7))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 位置消息卡片：定位图标 + 地址 + 经纬度，点击调起地图应用。
class _LocationBubbleContent extends StatelessWidget {
  final String? meta;
  final Color fgColor;
  final AppL10n l;

  const _LocationBubbleContent({
    required this.meta,
    required this.fgColor,
    required this.l,
  });

  Map<String, dynamic> get _j {
    if (meta == null) return const {};
    try {
      return jsonDecode(meta!) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Future<void> _openMap(BuildContext context, double lat, double lng) async {
    final Uri uri;
    if (kIsWeb) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else if (Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
    } else {
      uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    }
    final ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.error(context, l.openLocationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = _j;
    final lat = (j['lat'] as num?)?.toDouble() ?? 0;
    final lng = (j['lng'] as num?)?.toDouble() ?? 0;
    final address = (j['address'] as String?)?.trim();
    final coordText =
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    return GestureDetector(
      onTap: () => _openMap(context, lat, lng),
      child: SizedBox(
        width: 230,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on_outlined,
                  size: 22, color: fgColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (address == null || address.isEmpty)
                        ? l.locationFallback(coordText)
                        : address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    coordText,
                    style: TextStyle(
                      fontSize: 12,
                      color: fgColor.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 20, color: fgColor),
          ],
        ),
      ),
    );
  }
}

/// #11 语音通话记录卡片：展示结果/时长，点击直接回拨。
class _CallBubbleContent extends ConsumerWidget {
  final Message message;
  final Color fgColor;
  const _CallBubbleContent({required this.message, required this.fgColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    int seconds = 0;
    final meta = message.mediaMeta;
    if (meta != null) {
      try {
        seconds =
            (jsonDecode(meta) as Map)['durationSec'] as int? ?? 0;
      } catch (_) {}
    }
    final result = message.content ?? 'completed';
    final title = switch (result) {
      'completed' =>
        l.callRecordCompleted(_fmtDuration(seconds)),
      'rejected' => l.callRecordRejected,
      'canceled' => l.callRecordCanceled,
      _ => l.callRecordMissed,
    };
    final completed = result == 'completed';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final convs = ref.read(conversationsStreamProvider).valueOrNull;
        Conversation? conv;
        for (final c in convs ?? const <Conversation>[]) {
          if (c.id == message.convId) {
            conv = c;
            break;
          }
        }
        final peer = conv?.peerUserId;
        if (peer == null) return;
        await ref.read(callControllerProvider).startCall(
              peerUserId: peer,
              peerName: conv!.peerNickname ?? conv.title ?? '#$peer',
              avatarUrl: conv.peerAvatarUrl,
              convId: conv.id,
            );
      },
      child: SizedBox(
        width: 216,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                completed ? Icons.call_outlined : Icons.call_missed_outgoing,
                size: 22,
                color: fgColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l.callBack,
                style: TextStyle(fontSize: 12, color: fgColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// 气泡内的引用回复块：左竖条 + 昵称 + 摘要（单行省略），点击定位原消息。
class _ReplyQuote extends StatelessWidget {
  final ReplyQuoteData quote;
  final bool mine;
  final Color fg;
  final VoidCallback? onTap;

  const _ReplyQuote({
    required this.quote,
    required this.mine,
    required this.fg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 我方蓝底白字气泡 → 白色半透风格；对方浅底气泡 → 主色浅底风格。
    final barColor = mine ? Colors.white70 : theme.colorScheme.primary;
    final blockColor =
        mine ? Colors.white.withValues(alpha: 0.16) : const Color(0x0F2EA6FF);
    final nameColor = mine ? Colors.white : theme.colorScheme.primary;
    final snippetColor =
        mine ? Colors.white.withValues(alpha: 0.82) : fg.withValues(alpha: 0.62);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: blockColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      quote.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      quote.snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: snippetColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 判断一段文本是否"纯 emoji"（含 ZWJ 组合、肤色、旗标、变体选择符、键帽组合）。
/// 用于长按消息时显示"添加到表情"。使用显式码点区间，兼容 Dart RegExp
/// 对部分 Unicode 属性名（如 Regional_Indicator）不识别的问题。
bool isEmojiOnlyText(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  final stripped = t.replaceAll(
    RegExp(
      // 空白 / ZWJ / 变体选择符 / 键帽组合符
      r'[\s\u200D\uFE00-\uFE0F\u20D0-\u20FF'
      // 各种箭头、技术符号、几何、杂项符号、装饰符
      r'\u2190-\u21FF\u2300-\u23FF\u25A0-\u25FF\u2600-\u27BF\u2B00-\u2BFF'
      // 旗标区域指示符 / 肤色修饰 / emoji 与扩展图形主区间
      r'\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1FAFF}\u{1F3FB}-\u{1F3FF}'
      // 键帽底数：0-9 # *
      r'0-9#*]',
      unicode: true,
    ),
    '',
  );
  return stripped.isEmpty;
}
