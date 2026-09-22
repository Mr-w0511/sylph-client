import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../state/providers.dart';
import 'app_toast.dart';

/// 举报理由选项（reason 取值对齐后端枚举）。
List<(String, String)> _reportReasons(AppL10n l) => [
  ('SPAM', l.reportSpam),
  ('ABUSE', l.reportAbuse),
  ('PORN', l.reportPorn),
  ('FRAUD', l.reportFraud),
  ('OTHER', l.fbOther),
];

/// 通用举报弹窗。
///
/// [targetType] 举报对象类型（USER / GROUP / MESSAGE 等），
/// [targetId] 对象 id（群聊使用 convId）。
/// 用户确认并提交成功返回 true，取消/失败返回 false。
Future<bool> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String targetType,
  required int targetId,
}) async {
  final result = await showDialog<_ReportForm>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
  if (result == null) return false;
  try {
    await ref
        .read(socialRepoProvider)
        .report(
          targetType: targetType,
          targetId: targetId,
          reason: result.reason,
          detail: result.detail.isEmpty ? null : result.detail,
        );
    if (context.mounted) {
      AppToast.success(context, AppL10n.of(context).reportSubmitted);
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, AppL10n.of(context).reportFailedReason('$e'));
    }
    return false;
  }
}

class _ReportForm {
  final String reason;
  final String detail;
  _ReportForm(this.reason, this.detail);
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _reason = 'SPAM';
  final _detailCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    Navigator.of(context).pop(_ReportForm(_reason, _detailCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return AlertDialog(
      title: Text(l.report),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (v) {
                if (_submitting) return;
                setState(() => _reason = v ?? 'OTHER');
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final r in _reportReasons(l))
                    RadioListTile<String>(
                      value: r.$1,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(r.$2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _detailCtrl,
              maxLines: 3,
              maxLength: 300,
              enabled: !_submitting,
              decoration: InputDecoration(hintText: l.reportDetailHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l.submitReport),
        ),
      ],
    );
  }
}
