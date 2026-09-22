import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

class PrivateInfoPage extends StatelessWidget {
  const PrivateInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.privateInfoTitle)),
      body: ListView(
        padding: EdgeInsets.all(20)
            .copyWith(bottom: 20 + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          Icon(Icons.lock_outline,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(l.privateInfoBody,
              style: const TextStyle(height: 1.7, fontSize: 15)),
          const SizedBox(height: 24),
          const _TechList(),
        ],
      ),
    );
  }
}

class _TechList extends StatelessWidget {
  const _TechList();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = [
      ('P-256 ECDH', l.techP256),
      ('HKDF-SHA256', l.techHkdf),
      ('AES-GCM 256', l.techAesGcm),
      ('Base64', l.techBase64),
    ];
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              dense: true,
              leading: const Icon(Icons.verified_outlined, size: 20),
              title: Text(items[i].$1,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(items[i].$2),
            ),
            if (i < items.length - 1)
              const Divider(indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
