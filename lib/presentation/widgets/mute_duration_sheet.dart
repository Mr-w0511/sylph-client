import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

/// #8 禁言时长选择底部弹层。
/// 返回值：
/// - null：用户取消；
/// - 0：解除禁言（仅当前已禁言时出现该入口）；
/// - >0：禁言秒数（自定义时间最长 30 天，与服务端硬顶一致）。
Future<int?> showMuteDurationSheet(
  BuildContext context, {
  required bool currentlyMuted,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (bctx) =>
        _MuteDurationSheet(currentlyMuted: currentlyMuted),
  );
}

class _MuteDurationSheet extends StatelessWidget {
  final bool currentlyMuted;
  const _MuteDurationSheet({required this.currentlyMuted});

  static const int _sec1h = 3600;
  static const int _sec24h = 86400;
  static const int _sec7d = 86400 * 7;
  static const int _sec30d = 86400 * 30;

  Future<void> _pickCustom(BuildContext context) async {
    final l = AppL10n.of(context);
    final now = DateTime.now();
    final maxAt = now.add(const Duration(days: 30));
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: maxAt,
      helpText: l.muteCustomTitle,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: l.muteCustomTitle,
    );
    if (time == null) return;
    var chosen = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (chosen.isBefore(now)) {
      chosen = now.add(const Duration(minutes: 1));
    }
    if (chosen.isAfter(maxAt)) {
      chosen = maxAt;
    }
    final secs = chosen.difference(now).inSeconds;
    if (context.mounted) Navigator.of(context).pop(secs > 0 ? secs : 60);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(l.muteCustomTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1),
          if (currentlyMuted)
            ListTile(
              leading: const Icon(Icons.volume_up_outlined),
              title: Text(l.unmuteNow),
              onTap: () => Navigator.of(context).pop(0),
            ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l.mute1h),
            onTap: () => Navigator.of(context).pop(_sec1h),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l.mute24h),
            onTap: () => Navigator.of(context).pop(_sec24h),
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: Text(l.mute7d),
            onTap: () => Navigator.of(context).pop(_sec7d),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(l.mute30d),
            onTap: () => Navigator.of(context).pop(_sec30d),
          ),
          ListTile(
            leading: const Icon(Icons.edit_calendar_outlined),
            title: Text(l.muteCustom),
            onTap: () => _pickCustom(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
