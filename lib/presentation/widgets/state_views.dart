import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

class LoadingView extends StatelessWidget {
  final String? hint;
  const LoadingView({super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(hint!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off,
              size: 44, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 10),
          Text(message ?? l.loadFailed,
              style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l.retry)),
          ],
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyView({super.key, this.icon = Icons.inbox_rounded, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
