import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/state_views.dart';

final _myFeedbackProvider = FutureProvider.autoDispose<List<FeedbackModel>>((
  ref,
) {
  ref.watch(socialTickProvider);
  return ref.read(feedbackRepoProvider).mine();
});

/// 意见反馈 / 我的工单：提交反馈，查看官方回复。
class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  List<(String, String, IconData, Color)> _types(AppL10n l) => [
    ('BUG', l.fbTypeBug, Icons.bug_report_outlined, const Color(0xFFEB5757)),
    (
      'SUGGESTION',
      l.fbTypeSuggestion,
      Icons.lightbulb_outline,
      const Color(0xFFF2994A),
    ),
    ('COMPLAINT', l.fbTypeComplaint, Icons.report_outlined, const Color(0xFF9B51E0)),
    ('OTHER', l.fbOther, Icons.help_outline, const Color(0xFF2D9CDB)),
  ];

  final _contentCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _type = 'BUG';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _contactCtrl.text = ref.read(sessionControllerProvider).user?.email ?? '';
    // 进入反馈页即清除“我的”tab 红点。
    Future(() async {
      try {
        await ref.read(feedbackRepoProvider).markRead();
      } catch (_) {/* 忽略已读上报失败 */}
      ref.invalidate(feedbackUnreadProvider);
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(feedbackRepoProvider)
          .submit(
            type: _type,
            content: content,
            contact: _contactCtrl.text.trim().isEmpty
                ? null
                : _contactCtrl.text.trim(),
          );
      _contentCtrl.clear();
      if (!mounted) return;
      AppToast.success(context, AppL10n.of(context).feedbackSubmitted);
      ref.invalidate(_myFeedbackProvider);
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).submitFailedReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    final types = _types(l);
    final listAsync = ref.watch(_myFeedbackProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.feedbackEntry)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(12, 8, 12,
            28 + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.feedbackType,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final t in types)
                        ChoiceChip(
                          selected: _type == t.$1,
                          onSelected: (_) => setState(() => _type = t.$1),
                          avatar: Icon(
                            t.$3,
                            size: 17,
                            color: _type == t.$1 ? Colors.white : t.$4,
                          ),
                          label: Text(t.$2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 5,
                    minLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: l.feedbackDescHint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contactCtrl,
                    maxLength: 128,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l.contactHint,
                      prefixIcon: const Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(l.submitFeedback),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
            child: Text(
              l.myFeedback,
              style: TextStyle(
                color: theme.hintColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          listAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(
              message: '$e',
              onRetry: () => ref.invalidate(_myFeedbackProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: EmptyView(
                    icon: Icons.feedback_outlined,
                    text: l.noFeedbackYet,
                  ),
                );
              }
              return Column(
                children: list.map((f) => _FeedbackCard(f: f)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackModel f;
  const _FeedbackCard({required this.f});

  Color get _typeColor {
    switch (f.type) {
      case 'BUG':
        return const Color(0xFFEB5757);
      case 'SUGGESTION':
        return const Color(0xFFF2994A);
      case 'COMPLAINT':
        return const Color(0xFF9B51E0);
      default:
        return const Color(0xFF2D9CDB);
    }
  }

  String _typeLabel(AppL10n l) => switch (f.type) {
    'BUG' => 'Bug',
    'SUGGESTION' => l.fbSuggestion,
    'COMPLAINT' => l.fbComplaint,
    _ => l.fbOther,
  };

  String _statusLabel(AppL10n l) => switch (f.status) {
    'PENDING' => l.fbStatusPending,
    'PROCESSING' => l.fbStatusProcessing,
    'REPLIED' => l.fbStatusReplied,
    'CLOSED' => l.fbStatusClosed,
    _ => f.status,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () => context.push('/feedback/thread', extra: f),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _typeLabel(l),
                      style: TextStyle(
                        fontSize: 12,
                        color: _typeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _statusLabel(l),
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                f.content,
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
              if (f.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    TimeFmt.listLabel(f.createdAt,
                        today: l.today, yesterday: l.yesterday),
                    style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                  ),
                ),
              if (f.reply != null && f.reply!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.officialReply,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (f.emailSent) ...[
                            const SizedBox(width: 6),
                            Text(
                              l.syncedByEmail,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.reply!,
                        style: const TextStyle(fontSize: 14, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
