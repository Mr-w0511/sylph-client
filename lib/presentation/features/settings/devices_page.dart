import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_format.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';

final _devicesFutureProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(userRepoProvider).devices());

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final currentDeviceId = ref.watch(sessionControllerProvider).deviceId;
    final devices = ref.watch(_devicesFutureProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.devicesTitle)),
      body: devices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView.separated(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: 16, endIndent: 16),
          itemBuilder: (_, i) {
            final d = list[i];
            final isCurrent = d.deviceId == currentDeviceId;
            return ListTile(
              leading: Icon(
                d.platform == 'WEB'
                    ? Icons.language
                    : Icons.smartphone_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Row(
                children: [
                  Text(d.deviceName ?? d.platform,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l.currentDevice,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${d.platform} · ${d.deviceId.length > 16 ? d.deviceId.substring(0, 16) : d.deviceId}'
                '${d.lastLoginAt != null ? '\n${l.lastLoginAt}: ${TimeFmt.bubble(d.lastLoginAt!)}' : ''}',
              ),
              isThreeLine: d.lastLoginAt != null,
              trailing: isCurrent
                  ? null
                  : IconButton(
                      icon: Icon(Icons.logout,
                          color: Theme.of(context).colorScheme.error),
                      tooltip: l.revokeDevice,
                      onPressed: () => _revoke(context, ref, d.id,
                          d.deviceId == currentDeviceId),
                    ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _revoke(
      BuildContext context, WidgetRef ref, int id, bool current) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        content: Text(l.revokeDeviceConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(l.confirm)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(userRepoProvider).revokeDevice(id);
      if (current) {
        await ref.read(sessionControllerProvider.notifier).handleAuthLost();
      } else {
        ref.invalidate(_devicesFutureProvider);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '$e');
      }
    }
  }
}
