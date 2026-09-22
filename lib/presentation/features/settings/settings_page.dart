import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'change_password_page.dart';

/// 个人主页（底部导航"我的"）。Telegram/WhatsApp 风格：圆角分组卡片 + 灰色分组标题。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final session = ref.watch(sessionControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final user = session.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileSection, style: const TextStyle(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          _ProfileCard(
            name: user?.nickname ?? '',
            username: user?.username ?? '',
            uid: user?.uid ?? '',
            avatarUrl: user?.avatarUrl,
            onTap: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, l.accountSettings),
          _card([
            // 仅在尚未设置密码时展示"设置初始密码"，避免悬空分割线。
            if (user?.hasPassword != true) ...[
              ListTile(
                leading: const _IconBadge(
                    icon: Icons.lock_outline, color: Color(0xFFF2994A)),
                title: Text(l.setInitialPassword),
                subtitle: Text(l.setInitialPasswordTip,
                    style: TextStyle(fontSize: 12, color: theme.hintColor)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pushSetInitialPassword(context),
              ),
              const Divider(indent: 70, endIndent: 16, height: 1),
            ],
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.key_outlined, color: Color(0xFF3B6EF6)),
              title: Text(l.changePassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ChangePasswordPage(),
              )),
            ),
            const Divider(indent: 70, endIndent: 16, height: 1),
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.devices_other_outlined,
                  color: Color(0xFF2EA6FF)),
              title: Text(l.devices),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/devices'),
            ),
            const Divider(indent: 70, endIndent: 16, height: 1),
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.shield_outlined, color: Color(0xFF34C78A)),
              title: Text(l.privateEntry),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/private-info'),
            ),
          ]),
          const SizedBox(height: 16),
          _sectionLabel(context, l.socialFeedbackSection),
          _card([
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.qr_code_2_outlined, color: Color(0xFF9B7EDE)),
              title: Text(l.myQrcode),
              subtitle: Text(l.myQrcodeSubtitle,
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my-qrcode'),
            ),
            const Divider(indent: 70, endIndent: 16, height: 1),
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.feedback_outlined, color: Color(0xFFFF6F61)),
              title: Text(l.feedbackEntry),
              subtitle: Text(l.feedbackSubtitle,
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/feedback'),
            ),
            const Divider(indent: 70, endIndent: 16, height: 1),
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.block_outlined, color: Color(0xFFEB5757)),
              title: Text(l.blacklistEntry),
              subtitle: Text(l.blacklistSubtitle,
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/blacklist'),
            ),
          ]),
          const SizedBox(height: 16),
          _sectionLabel(context, l.personalizationSection),
          _card([
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.palette_outlined, color: Color(0xFFFFA94D)),
              title: Text(l.themeColor),
              trailing: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Color(settings.seedColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.hintColor.withValues(alpha: 0.3),
                      width: 1),
                ),
              ),
              onTap: () => _showColorPicker(context, ref),
            ),
            const Divider(indent: 70, endIndent: 16, height: 1),
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.wallpaper_outlined,
                  color: Color(0xFF9B7EDE)),
              title: Text(l.chatWallpaper),
              subtitle: Text(settings.wallpaperPath == null
                  ? l.defaultWallpaper
                  : l.customWallpaper,
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/wallpaper'),
            ),
          ]),
          const SizedBox(height: 16),
          _sectionLabel(context, l.preferences),
          _card([
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.dark_mode_outlined, color: Color(0xFF5B6472)),
              title: Text(l.themeDark),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text(l.themeSystem)),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text(l.themeLight)),
                  DropdownMenuItem(
                      value: ThemeMode.dark, child: Text(l.themeDark)),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(v);
                  }
                },
              ),
            ),
            const Divider(indent: 70, endIndent: 16, height: 1),
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.language, color: Color(0xFF34C78A)),
              title: Text(l.language),
              trailing: DropdownButton<String>(
                value: settings.locale.languageCode,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: 'zh', child: Text(l.languageZh)),
                  DropdownMenuItem(value: 'en', child: Text(l.languageEn)),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setLocale(Locale(v));
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _sectionLabel(context, l.about),
          _card([
            ListTile(
              leading: const _IconBadge(
                  icon: Icons.info_outline, color: Color(0xFF2EA6FF)),
              title: Text(l.aboutSylph),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about'),
            ),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5)),
              ),
              icon: const Icon(Icons.logout),
              label: Text(l.logout),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  // 必须使用 dialogCtx 关闭弹窗本身；用外层 context 会 pop 掉
                  // StatefulNavigationShell 的根分支，触发"弹空栈"黑屏崩溃。
                  builder: (dialogCtx) => AlertDialog(
                    content: Text(l.logoutConfirm),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          child: Text(l.cancel)),
                      FilledButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          child: Text(l.confirm)),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(sessionControllerProvider.notifier).logout();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Sylph · v1.0.0',
                style: TextStyle(color: theme.hintColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _pushSetInitialPassword(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ChangePasswordPage(initialMode: true),
    ));
  }

  /// 主题色选择底部弹层：9 个种子色圆点。
  void _showColorPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsControllerProvider).seedColor;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppL10n.of(sheetCtx).pickThemeColor,
                    style: Theme.of(sheetCtx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final c in kSylphSeedColors)
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setSeedColor(c);
                          Navigator.of(sheetCtx).pop();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                          ),
                          child: c == current
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card(List<Widget> children) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      );

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Text(text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600)),
      );
}

/// 列表项前置的圆角彩底图标。
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

/// 顶部用户卡片：头像 + 昵称 + UID + email，点击跳编辑页。
class _ProfileCard extends StatelessWidget {
  final String name;
  final String username;
  final String uid;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.name,
    required this.username,
    required this.uid,
    required this.onTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    final displayName = name.isEmpty ? username : name;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.35),
                        width: 2),
                  ),
                  child: UserAvatar(
                    name: displayName.isEmpty ? '?' : displayName,
                    avatarUrl: avatarUrl,
                    uid: uid,
                    size: 60,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isEmpty ? l.noNickname : displayName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (uid.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('UID: $uid',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor)),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
