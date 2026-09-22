import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/models/models.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';

/// 反馈工单多轮对话页：原反馈 + 历史消息（用户追问 / 官方回复）+ 继续追问。
class FeedbackThreadPage extends ConsumerStatefulWidget {
  final FeedbackModel feedback;
  const FeedbackThreadPage({super.key, required this.feedback});

  @override
  ConsumerState<FeedbackThreadPage> createState() => _FeedbackThreadPageState();
}

class _FeedbackThreadPageState extends ConsumerState<FeedbackThreadPage> {
  late FeedbackModel _feedback = widget.feedback;
  List<FeedbackMessageModel> _messages = const [];

  /// 老后端在 append 后可能仍不下发 messages，用本地回声兜底展示。
  FeedbackMessageModel? _localEcho;

  bool _loading = true;
  bool _sending = false;

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  /// #8 客服回复不实时：页面打开期间每 4s 轮询一次新消息。
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadMessages);
    // 进入即上报已读（清角标），失败静默。
    scheduleMicrotask(() async {
      try {
        await ref.read(feedbackRepoProvider).markRead();
      } catch (_) {}
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_sending || !mounted) return;
    try {
      final list = await ref
          .read(feedbackRepoProvider)
          .listMessages(_feedback.id);
      if (!mounted || list.isEmpty) return;
      final echo = _localEcho;
      final echoOnServer = echo == null ||
          list.any((m) => m.senderRole == 'USER' && m.content == echo.content);
      final hasAdminReply = list.any((m) => m.senderRole == 'ADMIN');
      setState(() {
        _messages = list;
        if (echoOnServer) _localEcho = null;
        // 无工单详情接口：出现官方回复且未关闭时，本地把状态推进为已回复。
        if (hasAdminReply &&
            _feedback.status != 'REPLIED' &&
            _feedback.status != 'CLOSED') {
          _feedback = _feedback.copyWith(status: 'REPLIED');
        }
      });
      _scrollToBottom();
    } catch (_) {
      /* 轮询失败静默 */
    }
  }

  Future<void> _loadMessages() async {
    try {
      final list = await ref
          .read(feedbackRepoProvider)
          .listMessages(_feedback.id);
      if (!mounted) return;
      setState(() {
        _messages = list.isNotEmpty ? list : _feedback.messages;
        _loading = false;
      });
    } catch (_) {
      // 接口不可用时退化为工单内嵌的回复快照。
      if (!mounted) return;
      setState(() {
        _messages = _feedback.messages;
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final updated = await ref
          .read(feedbackRepoProvider)
          .appendMessage(_feedback.id, text);
      if (!mounted) return;
      _inputCtrl.clear();
      List<FeedbackMessageModel> messages = updated.messages;
      if (messages.isEmpty) {
        // 返回视图未携带消息时再拉一次会话消息。
        try {
          messages = await ref
              .read(feedbackRepoProvider)
              .listMessages(_feedback.id);
        } catch (_) {
          messages = const [];
        }
      }
      if (!mounted) return;
      setState(() {
        _feedback = updated;
        _messages = messages;
        // 服务端始终没有消息流时，本地补一条回声。
        final exists = messages.any(
          (m) => m.senderRole == 'USER' && m.content == text,
        );
        _localEcho = exists
            ? null
            : FeedbackMessageModel(
                id: -DateTime.now().millisecondsSinceEpoch,
                senderRole: 'USER',
                content: text,
                createdAt: DateTime.now(),
              );
      });
      AppToast.success(context, AppL10n.of(context).statusSent);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).sendFailedReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  Color get _typeColor => switch (_feedback.type) {
    'BUG' => const Color(0xFFEB5757),
    'SUGGESTION' => const Color(0xFFF2994A),
    'COMPLAINT' => const Color(0xFF9B51E0),
    _ => const Color(0xFF2D9CDB),
  };

  String _typeLabel(AppL10n l) => switch (_feedback.type) {
    'BUG' => 'Bug',
    'SUGGESTION' => l.fbSuggestion,
    'COMPLAINT' => l.fbComplaint,
    _ => l.fbOther,
  };

  String _statusLabel(AppL10n l) => switch (_feedback.status) {
    'PENDING' => l.fbStatusPending,
    'PROCESSING' => l.fbStatusProcessing,
    'REPLIED' => l.fbStatusReplied,
    'CLOSED' => l.fbStatusClosed,
    _ => _feedback.status,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppL10n.of(context);

    // 去重：消息流首条 USER 消息与原反馈内容一致时不再重复展示。
    var skippedOriginal = false;
    final items = _messages.where((m) {
      if (!skippedOriginal &&
          m.senderRole == 'USER' &&
          m.content == _feedback.content) {
        skippedOriginal = true;
        return false;
      }
      return true;
    }).toList();
    final echo = _localEcho;
    if (echo != null) items.add(echo);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.feedbackDetailTitle),
            const SizedBox(width: 8),
            _chip(_typeLabel(l), _typeColor),
            const SizedBox(width: 6),
            _chip(_statusLabel(l), theme.hintColor),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_feedback.status == 'CLOSED')
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.ticketClosedHint,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      children: [
                        _OriginalBubble(feedback: _feedback),
                        for (final m in items)
                          _MessageBubble(message: m, isDark: isDark),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l.followUpHint,
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
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// 原始反馈：右侧 primary 气泡白字 + 小字时间。
class _OriginalBubble extends StatelessWidget {
  final FeedbackModel feedback;
  const _OriginalBubble({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              feedback.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              feedback.createdAt == null
                  ? ''
                  : TimeFmt.bubble(feedback.createdAt!),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 会话内的一条消息：ADMIN 左侧浅色/暗色气泡，USER 右侧 primary。
class _MessageBubble extends StatelessWidget {
  final FeedbackMessageModel message;
  final bool isDark;
  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.senderRole == 'ADMIN';
    final bg = isAdmin
        ? (isDark
              ? telegramDarkIncoming
              : Theme.of(context).colorScheme.surfaceContainerHighest)
        : Theme.of(context).colorScheme.primary;
    final fg = isAdmin
        ? (isDark ? Colors.white : const Color(0xFF212B36))
        : Colors.white;

    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAdmin ? 4 : 16),
            bottomRight: Radius.circular(isAdmin ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppL10n.of(context).officialReply,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: TextStyle(color: fg, fontSize: 15, height: 1.35),
            ),
            const SizedBox(height: 3),
            Text(
              message.createdAt == null
                  ? ''
                  : TimeFmt.bubble(message.createdAt!),
              style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
