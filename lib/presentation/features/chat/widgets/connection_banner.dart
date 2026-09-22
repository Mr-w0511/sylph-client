import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/ws_frame.dart';
import '../../../state/providers.dart';

/// 连接状态横幅：由 WsClient 状态驱动（连接中 / 重连中 / 已断开）。
class ConnectionBanner extends ConsumerStatefulWidget {
  const ConnectionBanner({super.key});

  @override
  ConsumerState<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends ConsumerState<ConnectionBanner> {
  WsStatus _status = WsStatus.connecting;
  StreamSubscription<WsStatus>? _sub;

  @override
  void initState() {
    super.initState();
    final rt = ref.read(realtimeProvider);
    _status = rt.wsStatus;
    _sub = rt.statusController.stream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == WsStatus.open) return const SizedBox.shrink();
    final l = AppL10n.of(context);
    final (text, color, icon) = switch (_status) {
      WsStatus.connecting => (
          l.connectionConnecting,
          Colors.orange.shade700,
          Icons.more_horiz
        ),
      WsStatus.reconnecting => (
          l.connectionReconnecting,
          Colors.orange.shade800,
          Icons.sync
        ),
      WsStatus.disconnected => (
          l.connectionDisconnected,
          Colors.red.shade700,
          Icons.cloud_off
        ),
      WsStatus.open => ('', Colors.transparent, Icons.check),
    };
    return Material(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: _status == WsStatus.connecting
                  ? const CircularProgressIndicator(
                      strokeWidth: 1.8, color: Colors.white)
                  : Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
