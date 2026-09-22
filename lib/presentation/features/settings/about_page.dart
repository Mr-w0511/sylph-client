import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_toast.dart';

/// 关于 Sylph：品牌标识、版本信息、介绍、开发者与联系方式。
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  /// 反馈/联系邮箱。
  static const _contactEmail = 'wuhaosen@xscloud.top';

  Future<void> _contact(BuildContext context) async {
    final l = AppL10n.of(context);
    final uri = Uri.parse('mailto:$_contactEmail?subject=${l.feedbackEmailSubject}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.error(context, l.cannotOpenMail);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.aboutSylph)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(12, 8, 12,
            32 + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          const SizedBox(height: 20),
          // 品牌标识：渐变圆角纸飞机。
          Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B6EF6), Color(0xFF2EA6FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Sylph',
                style:
                    TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final info = snap.data;
              final version = info == null
                  ? 'v1.0.0'
                  : 'v${info.version}'
                      '${info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})'}';
              return Center(
                child: Text(version,
                    style: TextStyle(
                        color: theme.hintColor, fontSize: 13.5)),
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.aboutBody,
                style: TextStyle(
                    fontSize: 14.5,
                    height: 1.7,
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFFC6CDD6)
                        : const Color(0xFF4A5260)),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const _IconBadge(
                    icon: Icons.wb_twilight_outlined,
                    color: Color(0xFFF2994A),
                  ),
                  title: Text(l.developer),
                  subtitle: Text(l.developerName),
                ),
                const Divider(indent: 70, endIndent: 16, height: 1),
                ListTile(
                  leading: const _IconBadge(
                    icon: Icons.mail_outline_rounded,
                    color: Color(0xFF34C78A),
                  ),
                  title: Text(l.contactEmailLabel),
                  subtitle: const Text(_contactEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _contact(context),
                ),
                const Divider(indent: 70, endIndent: 16, height: 1),
                ListTile(
                  leading: const _IconBadge(
                    icon: Icons.system_update_outlined,
                    color: Color(0xFF2EA6FF),
                  ),
                  title: Text(l.checkUpdate),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      AppToast.success(context, l.alreadyLatest),
                ),
                const Divider(indent: 70, endIndent: 16, height: 1),
                ListTile(
                  leading: const _IconBadge(
                    icon: Icons.description_outlined,
                    color: Color(0xFF9B7EDE),
                  ),
                  title: Text(l.openSourceLicenses),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    PackageInfo.fromPlatform().then((info) {
                      if (!context.mounted) return;
                      showLicensePage(
                        context: context,
                        applicationName: 'Sylph',
                        applicationVersion: info.version,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置/关于页使用的圆角彩底图标。
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
