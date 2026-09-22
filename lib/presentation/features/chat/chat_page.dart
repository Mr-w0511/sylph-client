import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:record/record.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/db/app_database.dart';
import '../../../core/service/sticker_store.dart';
import '../../../core/utils/message_reply.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
import '../contacts/user_profile_page.dart';
import 'chat_controller.dart';
import 'widgets/connection_banner.dart';
import 'widgets/forward_sheet.dart';
import 'widgets/fullscreen_image_page.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  final int convId;
  /// #5 全局搜索跳转：打开后滚动定位到的消息 id。
  final String? initialMsgId;
  const ChatPage({super.key, required this.convId, this.initialMsgId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  /// #8/#6 输入栏状态（面板、@插入、聚焦键盘）由外部头像长按等入口调用。
  final _inputBarKey = GlobalKey<InputBarState>();
  bool _canSend = false;

  /// 草稿：加载完成前不回写，避免把读到的草稿再"保存"一遍。
  bool _draftLoaded = false;
  Timer? _draftSaveTimer;
  // #11 消息多选转发模式。
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  // #6 进入会话时的未读快照：用于计算"有人@我"左侧胶囊（已读上报后
  // conv.unreadCount 立刻归零，因此必须在首次拿到 conv 时留存）。
  int? _entryLastSeq;
  int? _entryUnread;
  bool _mentionDismissed = false;
  final _mentionKey = GlobalKey();

  // #5 搜索结果跳转定位（只执行一次）。
  final _locateKey = GlobalKey();
  String? _locateMsgId;
  bool _locateDone = false;

  /// 消息列表滚动控制器：引用定位时先粗滚到目标附近，再 ensureVisible 精确定位。
  final ScrollController _msgScrollCtrl = ScrollController();

  /// 定位命中后的短暂高亮消息。
  String? _highlightMsgId;
  Timer? _highlightTimer;

  // 引用回复草稿：长按消息→回复后挂起，随下一条文本发出；✕ 可取消。
  ReplyQuoteData? _replyDraft;

  /// 长按菜单"回复"：挂起引用草稿并聚焦输入框。
  void _onReplyMessage(Message m, String nickname, String snippet) {
    setState(() {
      _replyDraft = ReplyQuoteData(
        msgId: m.msgId,
        senderId: m.senderId,
        nickname: nickname,
        type: m.type,
        snippet: snippet,
      );
    });
    _inputBarKey.currentState?.focusForReply();
  }

  void _cancelReply() {
    setState(() => _replyDraft = null);
  }

  /// 点击气泡内引用块：
  /// - 图片/表情/视频引用：直接打开全屏查看器（与单击消息一致）；
  /// - 文本/其他：滚动定位到原消息；不在已加载窗口内则提示。
  Future<void> _onQuoteTap(ReplyQuoteData quote) async {
    final messages =
        ref.read(chatMessagesProvider(widget.convId)).valueOrNull ??
            const <Message>[];
    var targetIndex = -1;
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].msgId == quote.msgId) {
        targetIndex = i;
        break;
      }
    }
    if ((quote.type == 'IMAGE' || quote.type == 'VIDEO')) {
      if (targetIndex < 0) {
        AppToast.info(context, AppL10n.of(context).messageNotFound);
        return;
      }
      _openMediaViewer(context, messages, messages[targetIndex]);
      return;
    }
    if (targetIndex < 0) {
      AppToast.info(context, AppL10n.of(context).messageNotFound);
      return;
    }
    await _locateMessage(messages.length, targetIndex, quote.msgId);
  }

  /// 两阶段定位：目标在视口外时先按估算高度粗滚，再 ensureVisible 精确定位。
  /// 修复"有时点引用没反应"——ListView 只构建视口附近 item，远的目标
  /// GlobalKey 尚未挂载，单帧 ensureVisible 拿不到 context。
  Future<void> _locateMessage(
      int total, int oldestIndex, String msgId) async {
    setState(() => _locateMsgId = msgId);
    await WidgetsBinding.instance.endOfFrame;
    var ctx = _locateKey.currentContext;
    if (ctx == null && _msgScrollCtrl.hasClients) {
      final pos = _msgScrollCtrl.position;
      // reverse 列表：reverse index = total-1-oldestIndex，从最新端起算。
      final estimated = (total - 1 - oldestIndex) * 72.0;
      final target =
          estimated.clamp(0.0, pos.maxScrollExtent).toDouble();
      if ((pos.pixels - target).abs() > 1) {
        await pos.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await WidgetsBinding.instance.endOfFrame;
      ctx = _locateKey.currentContext;
    }
    if (ctx != null && mounted) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    _highlightTimer?.cancel();
    setState(() => _highlightMsgId = msgId);
    _highlightTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted && _highlightMsgId == msgId) {
        setState(() {
          _highlightMsgId = null;
          _locateMsgId = null;
        });
      }
    });
  }

  /// 打开图片/视频全屏查看器（消息单击与引用块点击共用，见文件底部顶层函数）。

  void _tryLocateMessage(List<Message> messages) {
    final target = widget.initialMsgId;
    if (_locateDone || target == null) return;
    var idx = -1;
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].msgId == target) {
        idx = i;
        break;
      }
    }
    if (idx < 0) return;
    _locateDone = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_locateMessage(messages.length, idx, target)),
    );
  }

  /// 点击消息区空白 / 下滑列表：收起键盘与表情/加号面板。
  void _dismissInput() {
    _inputBarKey.currentState?.dismissAll();
  }

  void _enterSelection(String initialMsgId) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(initialMsgId);
    });
  }

  void _toggleSelection(String msgId) {
    if (!_selectionMode) return;
    setState(() {
      _selectedIds.contains(msgId)
          ? _selectedIds.remove(msgId)
          : _selectedIds.add(msgId);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _forwardSelected(List<Message> all) {
    final picked =
        all.where((m) => _selectedIds.contains(m.msgId)).toList();
    if (picked.isEmpty) return;
    showForwardSheetForMessages(context, ref, picked);
  }

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
    _loadDraft();
  }

  void _onInputChanged() {
    setState(() => _canSend = _input.text.trim().isNotEmpty);
    if (_draftLoaded) _scheduleDraftSave();
  }

  /// 进入聊天页恢复未发送的草稿（光标置末尾，不主动弹键盘）。
  Future<void> _loadDraft() async {
    final conv =
        await ref.read(conversationsDaoProvider).findById(widget.convId);
    final draft = conv?.draft;
    if (!mounted) return;
    if (draft != null && draft.isNotEmpty && _input.text.isEmpty) {
      _input.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    }
    _draftLoaded = true;
  }

  /// 草稿防抖落库（停止输入 800ms 后写）。
  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 800), _persistDraft);
  }

  void _persistDraft() {
    final text = _input.text;
    unawaited(ref
        .read(conversationsDaoProvider)
        .setDraft(widget.convId, text.isEmpty ? null : text));
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    _highlightTimer?.cancel();
    _msgScrollCtrl.dispose();
    // 退出页面立即留存草稿，不等待防抖。
    if (_draftLoaded) {
      final text = _input.text;
      if (text.isNotEmpty) {
        unawaited(ref
            .read(conversationsDaoProvider)
            .setDraft(widget.convId, text));
      }
    }
    _input.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final l = AppL10n.of(context);
    final text = _input.text;
    final draft = _replyDraft;
    final notifier = ref.read(chatControllerProvider(widget.convId).notifier);
    _input.clear();
    // 发送即清草稿：取消防抖并立即置空，避免退出过快时残留。
    _draftSaveTimer?.cancel();
    await ref.read(conversationsDaoProvider).setDraft(widget.convId, null);
    try {
      await notifier.sendText(text, reply: draft);
      // 发送成功才清空引用草稿；失败恢复文本时保留，便于直接重发。
      if (mounted && _replyDraft == draft) {
        setState(() => _replyDraft = null);
      }
    } catch (e) {
      if (!mounted) return;
      _input.text = text;
      final msg = e.toString().contains('peer-bundle-unavailable')
          ? l.e2eePeerNoKeys
          : l.messageSendFailed;
      AppToast.error(context, msg);
    }
  }

  /// #11 长按群成员头像 → 查到群昵称后插入 @并聚焦键盘。
  Future<void> _mentionUserById(int userId) async {
    String? name;
    try {
      final members =
          await ref.read(groupMembersProvider(widget.convId).future);
      for (final m in members) {
        if (m.userId == userId) {
          name = (m.groupNickname != null && m.groupNickname!.isNotEmpty)
              ? m.groupNickname
              : m.nickname;
          break;
        }
      }
    } catch (_) {}
    name ??= ref.read(chatSenderProvider(userId)).valueOrNull?.nickname;
    if (name != null && name.isNotEmpty) {
      _inputBarKey.currentState?.mention(name);
    }
  }

  /// #6 在未读区间里找最早一条@我/@所有人的消息。
  Message? _findUnreadMention(List<Message> messages) {
    if (_mentionDismissed) return null;
    final unread = _entryUnread;
    final lastSeq = _entryLastSeq;
    if (unread == null || unread <= 0 || lastSeq == null) return null;
    final threshold = lastSeq - unread;
    final me = ref.read(sessionControllerProvider).user;
    final groupMe =
        ref.read(groupDetailProvider(widget.convId)).valueOrNull?.myNickname;
    final names = <String>{
      if (me != null && me.nickname.isNotEmpty) me.nickname,
      if (groupMe != null && groupMe.isNotEmpty) groupMe,
    };
    bool hits(String? text) {
      if (text == null || text.isEmpty) return false;
      if (text.contains('@所有人') ||
          text.contains(RegExp('@everyone', caseSensitive: false))) {
        return true;
      }
      for (final n in names) {
        if (text.contains(RegExp('@${RegExp.escape(n)}(?![\\w一-龥])'))) {
          return true;
        }
      }
      return false;
    }

    // messages 为时间正序：取最早一条。
    Message? found;
    for (final m in messages) {
      if (m.seq != null &&
          m.seq! > threshold &&
          m.senderId != me?.id &&
          !m.encrypted &&
          hits(m.content)) {
        found = m;
        break;
      }
    }
    return found;
  }

  Future<void> _jumpToMention() async {
    final ctx = _mentionKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
    if (mounted) setState(() => _mentionDismissed = true);
  }

  Future<void> _togglePrivate(bool flag) async {
    final l = AppL10n.of(context);
    try {
      await ref
          .read(chatControllerProvider(widget.convId).notifier)
          .setPrivate(flag);
      if (!mounted) return;
      AppToast.info(context, flag ? l.privateModeOn : l.privateModeOff);
    } catch (e) {
      // 保留底层异常文本，便于排查密钥准备失败等问题。
      debugPrint('setPrivate failed: $e');
      if (mounted) {
        // #3 端到端加密密钥准备失败：友好主文案 + 底层真实原因（便于定位）。
        final raw = e.toString();
        final msg = raw.contains('e2ee-bundle-unavailable')
            ? l.e2eePrepareFailedReason(
                raw.split('e2ee-bundle-unavailable:').last.trim())
            : (raw.contains('peer-bundle-unavailable')
                ? l.e2eePeerNoKeys
                : '$e');
        AppToast.error(context, msg);
      }
    }
  }

  /// 官方助手：不提供资料/举报/拉黑入口。
  bool _isAssistant(Conversation conv) =>
      conv.peerUserId == 10000000 || conv.peerNickname == kSystemAssistantName;

  /// #11 发起单聊语音通话。
  Future<void> _startVoiceCall(Conversation conv) async {
    final peer = conv.peerUserId;
    if (peer == null || _isAssistant(conv)) return;
    await ref.read(callControllerProvider).startCall(
          peerUserId: peer,
          peerName: conv.peerNickname ?? conv.title ?? '#$peer',
          avatarUrl: conv.peerAvatarUrl,
          convId: conv.id,
        );
  }

  /// 当前群我被禁言的截止时刻（非群聊/未禁言返回 null）。
  DateTime? _mutedUntil(Conversation? conv) {
    if (conv == null || conv.type != 'GROUP') return null;
    final g = ref.watch(groupDetailProvider(widget.convId)).valueOrNull;
    return g?.myMutedUntil;
  }

  bool _isMuted(Conversation? conv) {
    final until = _mutedUntil(conv);
    return until != null && until.isAfter(DateTime.now().toUtc());
  }

  /// 通用乐观更新：先写本地 DAO，再调 API；失败回滚并刷新列表。
  Future<bool> _optimisticUpdate({
    required Conversation conv,
    required Future<void> Function() apiCall,
    required Future<void> Function() applyDao,
    required Future<void> Function() rollbackDao,
    required String successTip,
  }) async {
    final l = AppL10n.of(context);
    await applyDao();
    try {
      await apiCall();
      await ref.read(realtimeProvider).refreshConversations();
      if (mounted) AppToast.success(context, successTip);
      return true;
    } catch (e) {
      await rollbackDao();
      if (mounted) {
        AppToast.error(context, l.errorWithReason('$e'));
        await ref.read(realtimeProvider).refreshConversations();
      }
      return false;
    }
  }

  Future<void> _toggleMute(Conversation conv) async {
    final l = AppL10n.of(context);
    final next = !conv.muted;
    final dao = ref.read(conversationsDaoProvider);
    await _optimisticUpdate(
      conv: conv,
      apiCall: () => ref.read(conversationRepoProvider).mute(conv.id, next),
      applyDao: () => dao.setMuted(conv.id, next),
      rollbackDao: () => dao.setMuted(conv.id, conv.muted),
      successTip: next ? l.mutedOn : l.mutedOff,
    );
  }

  Future<void> _togglePin(Conversation conv) async {
    final l = AppL10n.of(context);
    final next = !conv.pinned;
    final dao = ref.read(conversationsDaoProvider);
    await _optimisticUpdate(
      conv: conv,
      apiCall: () => ref.read(conversationRepoProvider).pin(conv.id, next),
      applyDao: () =>
          dao.setPinned(conv.id, next, next ? DateTime.now() : null),
      rollbackDao: () => dao.setPinned(conv.id, conv.pinned, conv.pinnedAt),
      successTip: next ? l.pinnedOn : l.unpinned,
    );
  }

  Future<void> _editPeerRemark(Conversation conv) async {
    final l = AppL10n.of(context);
    final peerId = conv.peerUserId;
    if (peerId == null) return;
    final ctrl = TextEditingController(text: conv.peerNickname ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.setRemarkTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 64,
          decoration: InputDecoration(hintText: l.setRemarkHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final text = ctrl.text.trim();
      await ref
          .read(socialRepoProvider)
          .setRemark(peerId, text.isEmpty ? null : text);
      if (!mounted) return;
      AppToast.success(context, l.remarkSaved);
      await ref.read(realtimeProvider).refreshConversations();
    } catch (e) {
      if (mounted) AppToast.error(context, l.errorWithReason('$e'));
    }
  }

  Future<void> _deleteConv(Conversation conv) async {
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
      if (!mounted) return;
      AppToast.success(context, l.chatTerminated);
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, l.errorWithReason('$e'));
    }
  }

  Future<void> _blockPeer(Conversation conv) async {
    final l = AppL10n.of(context);
    final peerId = conv.peerUserId;
    if (peerId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.blockUserTitle),
        content: Text(l.blockUserConfirm),
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
            child: Text(l.blockAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(socialRepoProvider).block(peerId);
      ref.read(socialTickProvider.notifier).state++;
      await ref.read(realtimeProvider).refreshConversations();
      if (!mounted) return;
      AppToast.success(context, l.blocked);
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, l.errorWithReason('$e'));
    }
  }

  Future<void> _leaveGroup(Conversation conv) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.leaveGroupTitle),
        content: Text(l.leaveGroupConfirm),
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
            child: Text(l.leaveAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(groupRepoProvider).leave(conv.id);
      ref.read(socialTickProvider.notifier).state++;
      await ref.read(realtimeProvider).refreshConversations();
      if (!mounted) return;
      AppToast.success(context, l.leftGroup);
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, l.errorWithReason('$e'));
    }
  }

  /// #11 群解散后移除会话：仅对自己不可见，不影响其他成员。
  Future<void> _hideDissolved(Conversation conv) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.deleteConvTitle),
        content: Text(l.dissolvedConvDeleteConfirm),
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
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(conversationRepoProvider).hide(conv.id);
      await ref.read(realtimeProvider).refreshConversations();
      if (!mounted) return;
      AppToast.success(context, l.convDeleted);
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, l.errorWithReason('$e'));
    }
  }

  Future<void> _reportConversation(Conversation conv) async {
    if (conv.type == 'SINGLE') {
      final peerId = conv.peerUserId;
      if (peerId == null) return;
      await showReportDialog(
        context,
        ref,
        targetType: 'USER',
        targetId: peerId,
      );
    } else {
      // 群资源全部以 convId 为 key，无独立 groupId。
      await showReportDialog(
        context,
        ref,
        targetType: 'GROUP',
        targetId: conv.id,
      );
    }
  }

  void _viewPeerProfile(Conversation conv) {
    final peerId = conv.peerUserId;
    if (peerId == null) return;
    context.push(
      '/user-profile',
      extra: UserProfileArgs(
        user: UserBrief(
          id: peerId,
          nickname: conv.peerNickname ?? '',
          avatarUrl: conv.peerAvatarUrl,
          relation: 'FRIEND',
        ),
      ),
    );
  }

  void _onMenuSelected(String value, Conversation conv) {
    switch (value) {
      case 'profile':
        _viewPeerProfile(conv);
      case 'mute':
        _toggleMute(conv);
      case 'pin':
        _togglePin(conv);
      case 'remark':
        _editPeerRemark(conv);
      case 'report':
        _reportConversation(conv);
      case 'block':
        _blockPeer(conv);
      case 'delete':
        _deleteConv(conv);
      case 'leave':
        _leaveGroup(conv);
      case 'hide':
        _hideDissolved(conv);
    }
  }

  List<PopupMenuEntry<String>> _menuItems(Conversation conv) {
    final l = AppL10n.of(context);
    Widget row(String text, bool checked) => Row(
      children: [
        Expanded(child: Text(text)),
        if (checked) const Icon(Icons.check, size: 18),
      ],
    );
    // #11 群已解散：仅保留"删除会话"
    if (conv.dissolved) {
      return [
        PopupMenuItem(
          value: 'hide',
          child: Text(
            l.deleteConvTitle,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ];
    }
    if (conv.type == 'SINGLE') {
      final assistant = _isAssistant(conv);
      // #7 官方助手：仅保留置顶，不提供免打扰/备注/举报/拉黑/终止/资料。
      if (assistant) {
        return [
          PopupMenuItem(value: 'pin', child: row(l.pinChat, conv.pinned)),
        ];
      }
      return [
        PopupMenuItem(value: 'profile', child: Text(l.viewProfile)),
        PopupMenuItem(value: 'mute', child: row(l.muteConv, conv.muted)),
        PopupMenuItem(value: 'pin', child: row(l.pinChat, conv.pinned)),
        PopupMenuItem(value: 'remark', child: Text(l.setRemarkTitle)),
        PopupMenuItem(value: 'report', child: Text(l.report)),
        PopupMenuItem(
          value: 'block',
          child: Text(
            l.blockAction,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l.terminateChatTitle,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ];
    }
    return [
      PopupMenuItem(value: 'mute', child: row(l.muteConv, conv.muted)),
      PopupMenuItem(value: 'pin', child: row(l.pinChat, conv.pinned)),
      PopupMenuItem(value: 'report', child: Text(l.reportGroup)),
      // 群聊类型：不在聊天页菜单提供 leave（解散/退出统一从群设置页进入）
      if (conv.type == 'SINGLE')
        PopupMenuItem(
          value: 'leave',
          child: Text(
            l.leaveGroupTitle,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final convAsync = ref.watch(chatConversationProvider(widget.convId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.convId));
    final chatState = ref.watch(chatControllerProvider(widget.convId));
    final me = ref.watch(sessionControllerProvider).user;
    final conv = convAsync.value;
    // #6 首次拿到带未读的会话时留存快照（随后已读上报会立即清零）。
    if (conv != null &&
        _entryUnread == null &&
        conv.unreadCount > 0 &&
        conv.lastSeq != null) {
      _entryUnread = conv.unreadCount;
      _entryLastSeq = conv.lastSeq;
    }

    return Scaffold(
      // #4 壁纸存在时主题已把 scaffoldBackground 设为透明（透出全局壁纸层）；
      // 无壁纸/恢复默认后这里必须回落到主题不透明底色，否则聊天页纯黑。
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              ),
              title: Text(l.selectedCount(_selectedIds.length)),
              actions: [
                TextButton(
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _forwardSelected(
                          messagesAsync.valueOrNull ?? const []),
                  child: Text(l.forward),
                ),
              ],
            )
          : AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // #8 置顶标识
                if (conv?.pinned == true) ...[
                  Icon(Icons.push_pin,
                      size: 13,
                      color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 4),
                ],
                // #8 群聊标记
                if (conv != null && conv.type != 'SINGLE') ...[
                  Icon(Icons.groups,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 4),
                ],
                // #4 免打扰标识
                if (conv?.muted == true) ...[
                  Icon(Icons.notifications_off_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    conv == null
                        ? '#'
                        : (conv.type == 'SINGLE'
                              ? (conv.peerNickname ?? conv.title ?? '#${conv.id}')
                              : (conv.title ?? '#${conv.id}')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            if (conv?.privateFlag == true)
              Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l.e2eeBadge,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          // #11 单聊语音通话入口（官方助手除外）。
          if (conv?.type == 'SINGLE' &&
              !(conv != null && _isAssistant(conv)))
            IconButton(
              tooltip: l.voiceCall,
              icon: const Icon(Icons.call_outlined),
              onPressed: conv == null ? null : () => _startVoiceCall(conv),
            ),
          // #7 官方助手不提供端到端加密开关。
          if (conv?.type == 'SINGLE' &&
              !(conv != null && _isAssistant(conv)))
            IconButton(
              tooltip: l.privateMode,
              icon: Icon(
                (conv?.privateFlag ?? false)
                    ? Icons.lock
                    : Icons.lock_open_outlined,
              ),
              onPressed: chatState.busy
                  ? null
                  : () => _togglePrivate(!(conv?.privateFlag ?? false)),
            )
          else if (conv?.type == 'GROUP')
            IconButton(
              tooltip: l.groupSettings,
              icon: const Icon(Icons.groups_2_outlined),
              // #11 群已解散时禁用群设置入口
              onPressed: (conv?.dissolved ?? false)
                  ? null
                  : () => context.push('/group/${widget.convId}/settings'),
            ),
          if (conv != null)
            PopupMenuButton<String>(
              onSelected: (v) => _onMenuSelected(v, conv),
              itemBuilder: (_) => _menuItems(conv),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBanner(),
            if (chatState.busy)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      chatState.busyHint == 'UPLOAD'
                          ? l.imageUploading
                          : l.e2eePreparing,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  messagesAsync.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorView(
                      message: l.messagesLoadFailed,
                      onRetry: () => ref
                          .read(chatControllerProvider(widget.convId).notifier)
                          .retry(),
                    ),
                    data: (messages) {
                      if (messages.isEmpty && chatState.loading) {
                        return const LoadingView();
                      }
                      if (messages.isEmpty && chatState.error != null) {
                        return ErrorView(
                          message: chatState.error!,
                          onRetry: () => ref
                              .read(
                                chatControllerProvider(widget.convId).notifier,
                              )
                              .retry(),
                        );
                      }
                      final mentionMsg = _findUnreadMention(messages);
                      _tryLocateMessage(messages);
                      // 点消息区空白或下滑：收起键盘/表情/加号面板（需求4）。
                      return GestureDetector(
                        onTap: _dismissInput,
                        child:
                            NotificationListener<UserScrollNotification>(
                          onNotification: (n) {
                            // reverse 列表：手指下滑 → ScrollDirection.forward。
                            if (n.direction == ScrollDirection.forward) {
                              _dismissInput();
                            }
                            return false;
                          },
                          child: _MessageList(
                            convId: widget.convId,
                            convType: conv?.type,
                            messages: messages,
                            myId: me?.id ?? -1,
                            scrollController: _msgScrollCtrl,
                            loadingMore: chatState.loadingMore,
                            hasMore: chatState.hasMore,
                            // #11 多选转发模式
                            selectionMode: _selectionMode,
                            selectedIds: _selectedIds,
                            onToggleSelection: _toggleSelection,
                            onMultiSelect: (m) => _enterSelection(m.msgId),
                            onMentionUser: conv?.type == 'GROUP'
                                ? _mentionUserById
                                : null,
                            onReply: _onReplyMessage,
                            onQuoteTap: _onQuoteTap,
                            highlightMsgId: _highlightMsgId,
                            mentionMsgId: mentionMsg?.msgId,
                            mentionKey: _mentionKey,
                            locateMsgId: _locateMsgId,
                            locateKey: _locateKey,
                          ),
                        ),
                      );
                    },
                  ),
                  // #6 屏幕左缘"有人@我"椭圆胶囊，点击滚动到那条消息。
                  if ((messagesAsync.valueOrNull?.isNotEmpty ?? false) &&
                      _findUnreadMention(messagesAsync.valueOrNull!) != null)
                    Positioned(
                      left: 0,
                      top: 72,
                      child: GestureDetector(
                        onTap: _jumpToMention,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.92),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alternate_email,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                l.mentionMeHint,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // #11 群已解散：用锁定提示替代输入栏
            if (conv?.dissolved ?? false)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16, color: Theme.of(context).hintColor),
                    const SizedBox(width: 8),
                    Text(l.groupDissolved,
                        style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 14)),
                  ],
                ),
              )
            else if (_isMuted(conv))
              _MutedLockBar(
                convId: widget.convId,
                until: _mutedUntil(conv)!,
              )
            else if (!_selectionMode)
              _InputBar(
                key: _inputBarKey,
                convId: widget.convId,
                controller: _input,
                canSend: _canSend,
                busy: chatState.busy,
                onSend: _sendText,
                replyDraft: _replyDraft,
                onCancelReply: _cancelReply,
              ),
          ],
        ),
      ),
    );
  }
}

/// 打开图片/视频全屏查看器（消息单击与引用块点击共用）。
void _openMediaViewer(
    BuildContext context, List<Message> messages, Message target) {
  final mediaList = messages
      .where((m) =>
          (m.type == 'IMAGE' || m.type == 'VIDEO') &&
          m.mediaUrl != null &&
          m.mediaUrl!.isNotEmpty &&
          m.clientStatus != 'FAILED')
      .map((m) => MediaItem(url: m.mediaUrl!, type: m.type))
      .toList();
  var realIdx = mediaList.indexWhere((mi) => mi.url == target.mediaUrl);
  if (realIdx < 0) {
    realIdx =
        mediaList.indexWhere((mi) => messages.any((m) => m.mediaUrl == mi.url));
  }
  if (realIdx < 0 || mediaList.isEmpty) return;
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => FullscreenImagePage(
      mediaItems: mediaList,
      initialIndex: realIdx,
    ),
  ));
}

class _MessageList extends ConsumerWidget {
  final int convId;
  final String? convType;
  final List<Message> messages;
  final int myId;
  final bool loadingMore;
  final bool hasMore;
  // #11 多选转发模式。
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String msgId)? onToggleSelection;
  final void Function(Message message)? onMultiSelect;
  /// #11 群聊长按头像 @。
  final void Function(int userId)? onMentionUser;
  /// 引用回复：长按菜单回调 + 点击引用块（文本定位/媒体直开）。
  final void Function(Message message, String nickname, String snippet)?
      onReply;
  final void Function(ReplyQuoteData quote)? onQuoteTap;
  /// 定位命中后短暂高亮的消息 id。
  final String? highlightMsgId;
  /// 消息列表滚动控制器（引用两阶段定位用）。
  final ScrollController? scrollController;
  /// #6 未读@定位：目标消息 id 与包裹它的 GlobalKey。
  final String? mentionMsgId;
  final GlobalKey? mentionKey;
  /// #5 搜索结果定位：目标消息 id 与包裹它的 GlobalKey。
  final String? locateMsgId;
  final GlobalKey? locateKey;

  const _MessageList({
    required this.convId,
    required this.messages,
    required this.myId,
    required this.loadingMore,
    required this.hasMore,
    this.convType,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelection,
    this.onMultiSelect,
    this.onMentionUser,
    this.onReply,
    this.onQuoteTap,
    this.highlightMsgId,
    this.scrollController,
    this.mentionMsgId,
    this.mentionKey,
    this.locateMsgId,
    this.locateKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final n = messages.length;
    // reverse: index 0 为最新（底部）；index n 为顶部“更早”入口。
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: n + 1,
      itemBuilder: (context, i) {
        if (i == n) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: loadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (hasMore
                        ? TextButton(
                            onPressed: () => ref
                                .read(chatControllerProvider(convId).notifier)
                                .loadOlder(),
                            child: Text(l.loadMore),
                          )
                        : Text(
                            l.noMoreMessages,
                            style: Theme.of(context).textTheme.bodySmall,
                          )),
            ),
          );
        }
        final m = messages[n - 1 - i];
        final newer = i == 0 ? null : messages[n - i];
        final showDivider =
            m.createdAt == null ||
            newer?.createdAt == null ||
            !TimeFmt.isSameDay(m.createdAt!, newer!.createdAt!);
        final highlighted = m.msgId == highlightMsgId;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          key: m.msgId == mentionMsgId
              ? mentionKey
              : (m.msgId == locateMsgId
                    ? locateKey
                    : ValueKey('msg-${m.msgId}')),
          color: highlighted
              ? Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.18)
              : Colors.transparent,
          child: Column(
            children: [
            if (showDivider && m.createdAt != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      TimeFmt.dayDivider(
                        m.createdAt!,
                        today: l.today,
                        yesterday: l.yesterday,
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
              ),
            MessageBubble(
              message: m,
              mine: m.senderId == myId,
              isGroup: convType != 'SINGLE',
              // #11 多选模式：点按切换选中。
              selectionMode: selectionMode,
              selected: selectedIds.contains(m.msgId),
              onToggle: onToggleSelection == null
                  ? null
                  : () => onToggleSelection!(m.msgId),
              onMultiSelect: onMultiSelect == null
                  ? null
                  : () => onMultiSelect!(m),
              onMentionUser: onMentionUser,
              onReply: onReply,
              onQuoteTap: onQuoteTap,
              // #9 图片点击：收集所有 IMAGE/VIDEO 消息，打开 PageView 查看器。
              onImageTap: (msg) =>
                  _openMediaViewer(context, messages, msg),
            ),
            ],
          ),
        );
      },
    );
  }
}

/// #8 输入栏：语音 | 输入框 | 表情/键盘 | 加号/发送（末位合并）。
/// 表情面板（Unicode 表情 + 收藏贴纸）与加号面板从底部向上弹出，和键盘互斥。
class _InputBar extends ConsumerStatefulWidget {
  final int convId;
  final TextEditingController controller;
  final bool canSend;
  final bool busy;
  final VoidCallback onSend;
  // 引用回复草稿：非空时输入框上方显示可取消的回复预览条。
  final ReplyQuoteData? replyDraft;
  final VoidCallback? onCancelReply;

  const _InputBar({
    super.key,
    required this.convId,
    required this.controller,
    required this.canSend,
    required this.busy,
    required this.onSend,
    this.replyDraft,
    this.onCancelReply,
  });

  @override
  ConsumerState<_InputBar> createState() => InputBarState();
}

enum _PanelKind { none, emoji, plus }

class InputBarState extends ConsumerState<_InputBar>
    with WidgetsBindingObserver {
  bool _voiceMode = false;
  _PanelKind _panel = _PanelKind.none;
  final _focus = FocusNode();

  // 加号面板分页（单聊 2 页：第 2 页放视频通话；群聊 1 页）。
  final PageController _plusPageCtrl = PageController();
  int _plusPageIndex = 0;

  // 录音状态。
  bool _recording = false;
  bool _cancelArmed = false;
  AudioRecorder? _recorder;
  String? _recordPath;
  Timer? _durationTimer;
  int _durationSec = 0;
  DateTime? _recordStartAt;

  // 会话信息。
  bool _isGroup = false;
  bool _groupLoaded = false;

  // #6 @ 提及。
  bool _mentionExpanded = false;

  // 收藏贴纸 + 收藏的文本表情。
  List<String> _stickers = const [];
  List<String> _savedEmojis = const [];

  /// 20 个内置小黄脸表情。
  static const _emojis = [
    '😀', '😢', '😮', '😍', '😎', '😭', '😡', '👍',
    '❤', '🙏', '🎉', '🌹', '☕', '🔥', '😴', '🤔',
    '😅', '😘', '🙈', '😊',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConvType();
    _loadStickers();
    widget.controller.addListener(_onTextChanged);
  }

  Future<void> _loadConvType() async {
    final conv =
        await ref.read(conversationsDaoProvider).findById(widget.convId);
    if (mounted && conv != null) {
      setState(() {
        _isGroup = conv.type == 'GROUP';
        _groupLoaded = true;
      });
    }
  }

  /// #11 加号发起语音通话（仅单聊）。
  Future<void> _startVoiceCallFromPanel() async {
    final conv =
        await ref.read(conversationsDaoProvider).findById(widget.convId);
    if (conv == null || conv.type != 'SINGLE' || !mounted) return;
    final peer = conv.peerUserId;
    if (peer == null) return;
    await ref.read(callControllerProvider).startCall(
          peerUserId: peer,
          peerName: conv.peerNickname ?? conv.title ?? '#$peer',
          avatarUrl: conv.peerAvatarUrl,
          convId: conv.id,
        );
  }

  /// 视频通话（仅单聊，加号面板第 2 页）。
  Future<void> _startVideoCallFromPanel() async {
    final conv =
        await ref.read(conversationsDaoProvider).findById(widget.convId);
    if (conv == null || conv.type != 'SINGLE' || !mounted) return;
    final peer = conv.peerUserId;
    if (peer == null) return;
    await ref.read(callControllerProvider).startCall(
          peerUserId: peer,
          peerName: conv.peerNickname ?? conv.title ?? '#$peer',
          avatarUrl: conv.peerAvatarUrl,
          convId: conv.id,
          video: true,
        );
  }

  /// 群多人语音通话（仅群聊，加号面板第 1 页末格）。
  Future<void> _startGroupVoiceCallFromPanel() async {
    await ref
        .read(groupCallControllerProvider)
        .startRoom(widget.convId);
  }

  /// 每次打开表情面板都重新加载：保证从消息长按收藏后面板立即可见。
  Future<void> _loadStickers() async {
    final results = await Future.wait([
      StickerStore.list(),
      StickerStore.emojis(),
    ]);
    if (mounted) {
      setState(() {
        _stickers = results[0];
        _savedEmojis = results[1];
      });
    }
  }

  @override
  void didChangeMetrics() {
    // 键盘弹起（任意面板打开时）→ 收起面板，保证键盘/面板互斥。
    if (!mounted) return;
    final bottom = WidgetsBinding.instance.platformDispatcher.views.first
        .viewInsets.bottom;
    if (bottom > 60 && _panel != _PanelKind.none) {
      setState(() => _panel = _PanelKind.none);
    }
  }

  void _onTextChanged() {
    // 输入文字后末位按钮变为发送：加号面板自动收起。
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText && _panel == _PanelKind.plus) {
      setState(() => _panel = _PanelKind.none);
    }
    // @ 检测依赖文本/光标变化，触发一次重建。
    if (_isGroup && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onTextChanged);
    _durationTimer?.cancel();
    _recorder?.dispose();
    _plusPageCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// #11 长按头像入口：插入 @昵称 并聚焦键盘。
  void mention(String name) {
    setState(() {
      _voiceMode = false;
      _panel = _PanelKind.none;
    });
    final c = widget.controller;
    final text = c.text;
    final sel = c.selection;
    final pos = (sel.isValid && sel.extentOffset >= 0 &&
            sel.extentOffset <= text.length)
        ? sel.extentOffset
        : text.length;
    final insert = '@$name ';
    final newText = text.replaceRange(pos, pos, insert);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
    _focus.requestFocus();
  }

  void _insertAtCaret(String s) {
    final c = widget.controller;
    final text = c.text;
    final sel = c.selection;
    final start = (sel.isValid && sel.start >= 0) ? sel.start : text.length;
    final end = (sel.isValid && sel.end >= 0) ? sel.end : start;
    final newText = text.replaceRange(start, end, s);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + s.length),
    );
  }

  void _togglePanel(_PanelKind kind) {
    setState(() {
      if (_panel == kind) {
        _panel = _PanelKind.none;
        _focus.requestFocus();
      } else {
        _panel = kind;
        _voiceMode = false;
        FocusScope.of(context).unfocus();
        if (kind == _PanelKind.emoji) {
          // 打开时刷新收藏（贴纸/文本表情可能来自其他页面的长按收藏）。
          _loadStickers();
        }
      }
    });
  }

  void _closePanelKeepKeyboard() {
    if (_panel == _PanelKind.none) return;
    setState(() => _panel = _PanelKind.none);
  }

  /// 收起键盘并关闭表情/加号面板（点消息区空白或下滑时由 ChatPage 调用）。
  void dismissAll() {
    if (_panel == _PanelKind.none && !_focus.hasFocus) return;
    _focus.unfocus();
    FocusScope.of(context).unfocus();
    if (_panel != _PanelKind.none) {
      setState(() => _panel = _PanelKind.none);
    }
  }

  /// 引用回复：切回文本输入并聚焦键盘（供 ChatPage 通过 GlobalKey 调用）。
  void focusForReply() {
    setState(() {
      _voiceMode = false;
      _panel = _PanelKind.none;
    });
    _focus.requestFocus();
  }

  // ---------------- 录音 ----------------

  Future<void> _ensureRecorder() async {
    _recorder ??= AudioRecorder();
  }

  Future<bool> _checkPermission() async {
    if (!await _recorder!.hasPermission()) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).micPermissionDenied);
      }
      return false;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (widget.busy) return;
    await _ensureRecorder();
    if (!await _checkPermission()) return;

    final dir = await path_provider.getTemporaryDirectory();
    _recordPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: _recordPath!,
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).recordStartFailedReason('$e'));
      }
      return;
    }
    final startedAt = DateTime.now();
    _recordStartAt = startedAt;
    setState(() {
      _recording = true;
      _cancelArmed = false;
      _durationSec = 0;
    });
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _recordStartAt == null) return;
      setState(() {
        _durationSec =
            DateTime.now().difference(_recordStartAt!).inSeconds;
      });
    });
  }

  Future<void> _stopAndSend() async {
    _durationTimer?.cancel();
    final path = await _recorder?.stop();
    final start = _recordStartAt;
    final dur = start == null
        ? _durationSec
        : (DateTime.now().difference(start).inMilliseconds / 1000).ceil();
    _recordStartAt = null;
    setState(() => _recording = false);
    if (path == null || _cancelArmed) {
      _cancelArmed = false;
      return;
    }
    if (dur < 1) {
      if (mounted) {
        AppToast.info(context, AppL10n.of(context).voiceTooShort);
      }
      return;
    }
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      await ref
          .read(chatControllerProvider(widget.convId).notifier)
          .sendVoice(
            bytes: bytes,
            filename: 'voice.m4a',
            durationSec: dur,
          );
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).voiceSendFailedReason('$e'));
      }
    }
  }

  Future<void> _cancelRecording() async {
    _durationTimer?.cancel();
    _recordStartAt = null;
    await _recorder?.stop();
    setState(() {
      _recording = false;
      _cancelArmed = false;
    });
  }

  // ---------------- 加号面板动作 ----------------

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('FILE_TOO_LARGE')
          ? AppL10n.of(context).fileTooLarge
          : '$e';
      AppToast.error(context, msg);
    }
  }

  void _onAlbum() =>
      _guard(() => ref
          .read(chatControllerProvider(widget.convId).notifier)
          .pickAndSendMedia());

  void _onCapture() async {
    final l = AppL10n.of(context);
    final video = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.cameraTakePhoto),
              onTap: () => Navigator.pop(ctx, false),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l.cameraTakeVideo),
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    if (video == null) return;
    await _guard(() => ref
        .read(chatControllerProvider(widget.convId).notifier)
        .captureMedia(video: video));
  }

  void _onFile() => _guard(() => ref
      .read(chatControllerProvider(widget.convId).notifier)
      .pickAndSendFile());

  void _onMusic() => _guard(() => ref
      .read(chatControllerProvider(widget.convId).notifier)
      .pickAndSendMusic());

  /// 名片选择：个人名片（好友）/ 群聊名片（我加入的群）两段。
  Future<void> _pickCard() async {
    final conv =
        await ref.read(conversationsDaoProvider).findById(widget.convId);
    if (conv == null) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).convLoadFailed);
      }
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CardPickerSheet(conv: conv),
    );
  }

  /// 位置：定位 → 反查地址 → 确认后发送。
  Future<void> _pickLocation() async {
    final l = AppL10n.of(context);
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) AppToast.error(context, l.locationPermissionDenied);
      return;
    }
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      if (mounted) AppToast.error(context, '$e');
      return;
    }
    final coordText =
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    String address = '';
    try {
      final marks = await Geocoding().placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (marks.isNotEmpty) {
        final m = marks.first;
        address = [
          m.country,
          m.administrativeArea,
          m.locality,
          m.subLocality,
          m.street,
        ].where((s) => s != null && s.trim().isNotEmpty).join(' ');
      }
    } catch (_) {
      // 国内环境反查可能失败：退化为经纬度文案。
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.sendLocationTitle),
        content: Row(
          children: [
            Icon(Icons.location_on_outlined,
                color: Theme.of(dctx).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address.isEmpty ? l.locationFallback(coordText) : address,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(l.send),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _guard(() => ref
        .read(chatControllerProvider(widget.convId).notifier)
        .sendLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          address: address,
        ));
  }

  // ---------------- 收藏贴纸 ----------------

  Future<void> _addSticker() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) return;
      final path = await StickerStore.addFromFile(File(picked.path));
      if (mounted) {
        setState(() => _stickers = [..._stickers, path]);
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).addStickerFailed);
      }
    }
  }

  Future<void> _sendSticker(String path) async {
    await _guard(() async {
      final f = File(path);
      final bytes = await f.readAsBytes();
      final name = f.path.split(Platform.pathSeparator).last;
      await ref
          .read(chatControllerProvider(widget.convId).notifier)
          .sendSticker(bytes: bytes, filename: name);
    });
  }

  Future<void> _confirmDeleteSticker(String path) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        content: Text(l.deleteStickerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await StickerStore.remove(path);
    if (mounted) {
      setState(() => _stickers = [..._stickers]..remove(path));
    }
  }

  Future<void> _confirmDeleteEmoji(String emoji) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        content: Text(l.deleteStickerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await StickerStore.removeEmoji(emoji);
    if (mounted) {
      setState(() => _savedEmojis = [..._savedEmojis]..remove(emoji));
    }
  }

  // ---------------- @ 提及面板 ----------------

  /// 光标前正在输入的 @token；无则 null。
  ({int start, int caret, String query})? _activeMention() {
    if (!_isGroup) return null;
    final c = widget.controller;
    final text = c.text;
    final sel = c.selection;
    final caret = (sel.isValid && sel.extentOffset >= 0)
        ? sel.extentOffset
        : text.length;
    if (caret > text.length) return null;
    final head = text.substring(0, caret);
    final m = RegExp(r'@([^\s@]{0,32})$').firstMatch(head);
    if (m == null) return null;
    return (start: m.start, caret: caret, query: m.group(1)!);
  }

  void _applyMention({required int start, required int caret, required String name}) {
    final c = widget.controller;
    final insert = '@$name ';
    final newText = c.text.replaceRange(start, caret, insert);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    setState(() => _mentionExpanded = false);
  }

  // ---------------- 构建 ----------------

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final mention = _activeMention();

    Widget? mentionPanel;
    if (_isGroup && _groupLoaded && mention != null) {
      final membersAsync = ref.watch(groupMembersProvider(widget.convId));
      final detail =
          ref.watch(groupDetailProvider(widget.convId)).valueOrNull;
      final iCanAll = detail?.myRole == 'OWNER' ||
          detail?.myRole == 'ADMIN';
      final members = membersAsync.valueOrNull ?? const <GroupMember>[];
      final q = mention.query.toLowerCase();
      final list = q.isEmpty
          ? members.take(50).toList()
          : members.where((m) {
              final gn = m.groupNickname?.toLowerCase() ?? '';
              final nn = m.nickname?.toLowerCase() ?? '';
              return gn.contains(q) || nn.contains(q);
            }).take(50).toList();
      // 输入了昵称但无匹配：收起面板（用户可能是在发普通消息）。
      final showAll = q.isEmpty && iCanAll;
      if (q.isEmpty || list.isNotEmpty) {
        mentionPanel = _MentionPanel(
          candidates: list,
          showAllEntry: showAll,
          expanded: _mentionExpanded,
          onExpand: () => setState(() => _mentionExpanded = true),
          onCollapse: () => setState(() => _mentionExpanded = false),
          onSelectAll: () =>
              _applyMention(start: mention.start, caret: mention.caret, name: l.mentionAll),
          onSelect: (m) {
            final name = (m.groupNickname != null &&
                    m.groupNickname!.isNotEmpty)
                ? m.groupNickname!
                : (m.nickname ?? '');
            if (name.isEmpty) return;
            _applyMention(start: mention.start, caret: mention.caret, name: name);
          },
        );
      }
    }

    return Material(
      elevation: 2,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?mentionPanel,
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: widget.replyDraft == null
                ? const SizedBox(width: double.infinity, height: 0)
                : _buildReplyDraftBar(theme, l),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: _voiceMode
                ? _buildVoiceMode(theme, l)
                : _buildTextMode(theme, l),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _panel == _PanelKind.none
                ? const SizedBox(width: double.infinity, height: 0)
                : (_panel == _PanelKind.emoji
                      ? _buildEmojiPanel(theme, l)
                      : _buildPlusPanel(theme, l)),
          ),
        ],
      ),
    );
  }

  /// 引用回复预览条：发送前可点右侧 ✕ 取消。
  Widget _buildReplyDraftBar(ThemeData theme, AppL10n l) {
    final draft = widget.replyDraft!;
    final dim = theme.brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 34, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.replyToNamed(draft.nickname),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  draft.snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: dim),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.cancelReplyDraft,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            icon: Icon(Icons.close_rounded, size: 18, color: dim),
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildTextMode(ThemeData theme, AppL10n l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          tooltip: l.voice,
          onPressed: widget.busy
              ? null
              : () => setState(() {
                    _voiceMode = true;
                    _panel = _PanelKind.none;
                    FocusScope.of(context).unfocus();
                  }),
          icon: const Icon(Icons.mic_none_rounded),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            onTap: _closePanelKeepKeyboard,
            // 必须开启交互选择，否则无法点击/拖动移动光标，打错字只能全删。
            enableInteractiveSelection: true,
            decoration: InputDecoration(
              hintText: l.chatInputHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
          ),
        ),
        const SizedBox(width: 2),
        // 表情 / 键盘 切换。
        IconButton(
          tooltip: l.emoji,
          onPressed: widget.busy
              ? null
              : () => _togglePanel(_PanelKind.emoji),
          icon: Icon(
            _panel == _PanelKind.emoji
                ? Icons.keyboard_outlined
                : Icons.emoji_emotions_outlined,
          ),
        ),
        // 末位合并：无文字=加号；有文字=发送。
        if (widget.canSend)
          IconButton.filled(
            onPressed: widget.busy ? null : widget.onSend,
            icon: const Icon(Icons.send_rounded),
          )
        else
          IconButton(
            tooltip: l.more,
            onPressed:
                widget.busy ? null : () => _togglePanel(_PanelKind.plus),
            icon: Icon(
              Icons.add_rounded,
              color: _panel == _PanelKind.plus
                  ? theme.colorScheme.primary
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceMode(ThemeData theme, AppL10n l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l.keyboard,
          onPressed: () => setState(() => _voiceMode = false),
          icon: const Icon(Icons.keyboard_outlined),
        ),
        Expanded(
          child: GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) {
              if (_cancelArmed) {
                _cancelRecording();
              } else {
                _stopAndSend();
              }
            },
            onLongPressMoveUpdate: (details) {
              final arm = details.localPosition.dy < -60;
              if (arm != _cancelArmed) {
                setState(() => _cancelArmed = arm);
              }
            },
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _recording
                    ? (_cancelArmed
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.error.withValues(alpha: 0.12))
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                _recording
                    ? (_cancelArmed
                          ? l.releaseToCancel
                          : l.slideUpCancel(_durationSec))
                    : l.holdToTalk,
                style: TextStyle(
                  fontSize: 14,
                  color: _recording && _cancelArmed
                      ? theme.colorScheme.error
                      : theme.hintColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
        const SizedBox(width: 48),
      ],
    );
  }

  /// 表情面板：上半 20 个小黄脸；下半收藏贴纸（首格 + 号添加）。
  Widget _buildEmojiPanel(ThemeData theme, AppL10n l) {
    return Container(
      height: 272,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(l.emojiSection,
                style: TextStyle(fontSize: 12, color: theme.hintColor)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              children: [
                for (final e in _emojis)
                  SizedBox(
                    width: 37,
                    height: 38,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(37, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _insertAtCaret(e),
                      child: Text(e,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 14, color: theme.dividerColor.withValues(alpha: 0.5)),
          if (_savedEmojis.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(l.savedEmojiSection,
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                children: [
                  for (final e in _savedEmojis)
                    SizedBox(
                      width: 44,
                      height: 42,
                      child: GestureDetector(
                        onLongPress: () => _confirmDeleteEmoji(e),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 42),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _insertAtCaret(e),
                          child: Text(e,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(
                height: 14,
                color: theme.dividerColor.withValues(alpha: 0.5)),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(l.stickerSection,
                style: TextStyle(fontSize: 12, color: theme.hintColor)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _StickerAddCell(onTap: _addSticker),
                for (final p in _stickers)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _sendSticker(p),
                      onLongPress: () => _confirmDeleteSticker(p),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(p),
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 68,
                            height: 68,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.broken_image_outlined,
                                size: 26, color: theme.hintColor),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 加号面板：4 列 × 2 行。
  Widget _buildPlusPanel(ThemeData theme, AppL10n l) {
    Widget cell(IconData icon, String label, VoidCallback onTap,
        {String? badge, Color? tint}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (tint ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon,
                      color: tint ?? theme.colorScheme.primary, size: 26),
                ),
                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0A02E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      );
    }

    // 每页固定 4 列 × 2 行 = 8 格；单聊 2 页（第 2 页放视频通话），群聊 1 页。
    final pages = <List<Widget?>>[];
    pages.add([
      cell(Icons.photo_library_outlined, l.album, _onAlbum),
      cell(Icons.photo_camera_outlined, l.capture, _onCapture),
      cell(Icons.contact_page_outlined, l.card, _pickCard),
      cell(Icons.location_on_outlined, l.location, _pickLocation),
      cell(Icons.card_giftcard_outlined, l.redPacket,
          () => AppToast.info(context, l.redPacketDeveloping),
          badge: l.developingBadge, tint: theme.hintColor),
      cell(Icons.insert_drive_file_outlined, l.file, _onFile),
      cell(Icons.music_note_outlined, l.music, _onMusic),
      // 单聊=语音通话；群聊=多人语音（G）。
      if (_isGroup)
        cell(Icons.groups_rounded, l.groupVoiceCall,
            _startGroupVoiceCallFromPanel,
            tint: const Color(0xFF34C759))
      else
        cell(Icons.call_outlined, l.voiceCall, _startVoiceCallFromPanel),
    ]);
    if (!_isGroup) {
      pages.add([
        cell(Icons.videocam_rounded, l.videoCall, _startVideoCallFromPanel,
            tint: const Color(0xFF34C759)),
      ]);
    }
    // 切会话类型后越界保护。
    if (_plusPageIndex >= pages.length) _plusPageIndex = 0;

    return Container(
      height: 252,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _plusPageCtrl,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _plusPageIndex = i),
              itemBuilder: (context, pi) {
                final items = pages[pi];
                return GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.94,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < 8; i++)
                      i < items.length
                          ? (items[i] ?? const SizedBox.shrink())
                          : const SizedBox.shrink(),
                  ],
                );
              },
            ),
          ),
          if (pages.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _plusPageIndex ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _plusPageIndex
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary
                              .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 贴纸收藏"添加"格子。
class _StickerAddCell extends StatelessWidget {
  final VoidCallback onTap;
  const _StickerAddCell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(Icons.add,
              color: theme.colorScheme.primary, size: 28),
        ),
      ),
    );
  }
}

/// #6 @提及浮层：输入框上方弹出，顶部短横柄上滑放大、下滑收回。
class _MentionPanel extends StatelessWidget {
  final List<GroupMember> candidates;
  final bool showAllEntry;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onSelectAll;
  final void Function(GroupMember member) onSelect;

  const _MentionPanel({
    required this.candidates,
    required this.showAllEntry,
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onSelectAll,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final items = <Widget>[
      if (showAllEntry)
        ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE0A32E).withValues(alpha: 0.15),
            child: const Icon(Icons.groups,
                size: 18, color: Color(0xFFE0A32E)),
          ),
          title: Text(
            l.mentionAll,
            style: const TextStyle(
              color: Color(0xFFE0A32E),
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: onSelectAll,
        ),
      for (final m in candidates)
        ListTile(
          dense: true,
          leading: UserAvatar(
            name: m.groupNickname ?? m.nickname ?? '',
            avatarUrl: m.avatarUrl,
            size: 36,
          ),
          title: Text(m.groupNickname ?? m.nickname ?? ''),
          trailing: m.role == 'OWNER'
              ? const Icon(Icons.workspace_premium,
                  size: 15, color: Color(0xFFE8A33D))
              : (m.role == 'ADMIN'
                  ? Icon(Icons.verified_user,
                      size: 14, color: theme.colorScheme.primary)
                  : null),
          onTap: () => onSelect(m),
        ),
    ];

    return Container(
      height: expanded ? 380 : 240,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -120) {
                onExpand();
              } else if (v > 120) {
                onCollapse();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.hintColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 16,
                    color: theme.hintColor,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

/// 名片发送选择面板：上半段好友（个人名片），下半段我的群聊（群聊名片）。
class _CardPickerSheet extends ConsumerStatefulWidget {
  final Conversation conv;
  const _CardPickerSheet({required this.conv});

  @override
  ConsumerState<_CardPickerSheet> createState() => _CardPickerSheetState();
}

class _CardPickerSheetState extends ConsumerState<_CardPickerSheet> {
  bool _sending = false;

  Future<void> _sendUserCard(int sharedUserId) async {
    final l = AppL10n.of(context);
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final conv = widget.conv;
      if (conv.type == 'SINGLE' && conv.peerUserId != null) {
        await ref
            .read(socialRepoProvider)
            .shareUserCard(sharedUserId, conv.peerUserId!);
      } else {
        await ref.read(socialRepoProvider).shareUserCardToConv(
              sharedUserId: sharedUserId,
              convId: conv.id,
            );
      }
      await ref.read(realtimeProvider).refreshConversations();
      if (mounted) {
        AppToast.success(context, l.cardSent);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) AppToast.error(context, l.sendFailedReason('$e'));
      setState(() => _sending = false);
    }
  }

  Future<void> _sendGroupCard(int groupConvId) async {
    final l = AppL10n.of(context);
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final conv = widget.conv;
      if (conv.type == 'SINGLE' && conv.peerUserId != null) {
        await ref
            .read(groupRepoProvider)
            .shareGroupCard(groupConvId, conv.peerUserId!);
      } else {
        await ref.read(groupRepoProvider).shareGroupCardToConv(
              convId: groupConvId,
              targetConvId: conv.id,
            );
      }
      await ref.read(realtimeProvider).refreshConversations();
      if (mounted) {
        AppToast.success(context, l.cardSent);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) AppToast.error(context, l.sendFailedReason('$e'));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.contact_page_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(l.pickCardTitle,
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
              child: ListView(
                controller: scrollController,
                children: [
                  _SectionLabel(l.userCard),
                  FutureBuilder<List<FriendView>>(
                    future: ref.read(socialRepoProvider).friends(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final friends = snap.data ?? const [];
                      if (friends.isEmpty) {
                        return _SectionEmpty(l.noFriends);
                      }
                      return Column(
                        children: [
                          for (final f in friends)
                            ListTile(
                              leading: UserAvatar(
                                name: f.remark ?? f.user.displayName,
                                avatarUrl: f.user.avatarUrl,
                                size: 40,
                              ),
                              title: Text(f.remark ?? f.user.displayName),
                              subtitle: f.user.uid == null
                                  ? null
                                  : Text('UID ${f.user.uid}',
                                      style: const TextStyle(fontSize: 12)),
                              onTap: _sending
                                  ? null
                                  : () => _sendUserCard(f.user.id),
                            ),
                        ],
                      );
                    },
                  ),
                  _SectionLabel(l.groupCard),
                  FutureBuilder<List<GroupBrief>>(
                    future: ref.read(groupRepoProvider).mine(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final groups = (snap.data ?? const [])
                        ..removeWhere((g) =>
                            widget.conv.type == 'GROUP' &&
                            g.convId == widget.conv.id);
                      if (groups.isEmpty) {
                        return _SectionEmpty(l.noGroupsToShare);
                      }
                      return Column(
                        children: [
                          for (final g in groups)
                            ListTile(
                              leading: const CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.groups_2_outlined),
                              ),
                              title: Text(g.name),
                              subtitle: g.groupNumber == null
                                  ? null
                                  : Text(l.groupNumberLabel(g.groupNumber!),
                                      style: const TextStyle(fontSize: 12)),
                              onTap: _sending
                                  ? null
                                  : () => _sendGroupCard(g.convId),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      );
}

class _SectionEmpty extends StatelessWidget {
  final String text;
  const _SectionEmpty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.grey)),
        ),
      );
}

/// 被禁言时替代输入栏的锁定条：输入框及两侧按钮均不可点，显示剩余时间。
class _MutedLockBar extends ConsumerStatefulWidget {
  final int convId;
  final DateTime until;
  const _MutedLockBar({required this.convId, required this.until});

  @override
  ConsumerState<_MutedLockBar> createState() => _MutedLockBarState();
}

class _MutedLockBarState extends ConsumerState<_MutedLockBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = widget.until.toLocal().difference(DateTime.now());
      if (remaining <= Duration.zero) {
        // 到期：刷新群详情，输入栏自动回来。
        ref.invalidate(groupDetailProvider(widget.convId));
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemaining(AppL10n l, Duration d) {
    if (d.inDays > 360) return l.youAreMuted;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) return l.mutedRemainingDh(days, hours);
    if (hours > 0) return l.mutedRemainingHm(hours, mins);
    if (mins > 0) return l.mutedRemainingMs(mins, secs);
    return l.mutedRemainingS(secs);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final remaining = widget.until.toLocal().difference(DateTime.now());
    final hint = remaining > Duration.zero
        ? _formatRemaining(l, remaining)
        : l.youAreMuted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volume_off_outlined,
              size: 16, color: Theme.of(context).hintColor),
          const SizedBox(width: 8),
          Text(hint,
              style:
                  TextStyle(color: Theme.of(context).hintColor, fontSize: 14)),
        ],
      ),
    );
  }
}
