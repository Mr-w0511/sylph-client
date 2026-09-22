import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/monitor/crash_reporter.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/models/models.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/user_avatar.dart';

/// 个人资料编辑页：修复 username 不可编辑、bio 缺失、性别无法保存等问题。
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _username = TextEditingController();
  final _nickname = TextEditingController();
  final _bio = TextEditingController();
  String? _gender;
  String? _avatarUrl;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(sessionControllerProvider).user;
    _username.text = u?.username ?? '';
    _nickname.text = u?.nickname ?? '';
    _bio.text = u?.bio ?? '';
    _avatarUrl = u?.avatarUrl;
    _gender = u?.gender ?? 'UNKNOWN';
  }

  @override
  void dispose() {
    _username.dispose();
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final username = _username.text.trim();
      final updated = await ref.read(userRepoProvider).updateProfile(
            username: username.isEmpty ? null : username,
            nickname: _nickname.text.trim(),
            avatarUrl: _avatarUrl,
            bio: _bio.text,
            gender: _gender,
          );
      ref.read(sessionControllerProvider.notifier).updateUser(updated);
      if (!mounted) return;
      AppToast.success(context, AppL10n.of(context).saved);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg =
          e.code == 40901 ? AppL10n.of(context).usernameTaken : e.message;
      AppToast.error(context, msg);
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, AppL10n.of(context).saveFailedReason('$e'));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(sessionControllerProvider).user;
    final accent = isDark ? telegramOutgoing : sylphBlue;
    final l = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.editProfile),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.save),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 16,
          bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          _avatarSection(_avatarUrl, user, accent),
          const SizedBox(height: 24),
          _sectionLabel(theme, l.accountSection),
          _card(theme, [
            _readOnlyField(theme, 'UID', user?.uid ?? '—', Icons.tag),
            const Divider(indent: 16, endIndent: 16, height: 1),
            _readOnlyField(
                theme, l.emailLabel, user?.email ?? '—', Icons.mail_outline),
          ]),
          const SizedBox(height: 12),
          _sectionLabel(theme, l.profileSection),
          _card(theme, [
            _editableField(
              theme: theme,
              label: l.usernameLabel,
              controller: _username,
              hint: l.usernameEditableHint,
              icon: Icons.alternate_email,
            ),
            const Divider(indent: 16, endIndent: 16, height: 1),
            _editableField(
              theme: theme,
              label: l.nickname,
              controller: _nickname,
              hint: l.nickname,
              icon: Icons.person_outline,
              maxLength: 64,
            ),
            const Divider(indent: 16, endIndent: 16, height: 1),
            _bioField(theme),
            const Divider(indent: 16, endIndent: 16, height: 1),
            _genderRow(theme),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 选择图片并上传，成功后仅更新本地状态，随"保存"一起落库（也可即时持久化）。
  Future<void> _pickAndUploadAvatar() async {
    if (_uploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (bytes == null) return;
      // 鸿蒙等部分 ROM 通过 content URI 读取相册文件时可能返回截断/损坏字节，
      // 上传前先校验 magic + 实际解码，坏图直接拦截，避免坏 URL 落库后
      // 每次启动渲染头像都崩（Invalid image data）。
      final magic = _imageMagic(bytes);
      CrashReporter.b('avatar pick name=${file!.name} '
          'bytes=${bytes.length} magic=$magic');
      if (!_looksLikeImage(bytes)) {
        CrashReporter.warn('avatar rejected: bad magic '
            'name=${file.name} bytes=${bytes.length} magic=$magic');
        if (mounted) {
          AppToast.error(context, '图片文件无法识别，请换一张图片');
        }
        return;
      }
      try {
        final probe = await decodeImageFromList(bytes);
        final w = probe.width;
        final h = probe.height;
        probe.dispose();
        if (w <= 0 || h <= 0) throw const FormatException('zero dimension');
        CrashReporter.b('avatar decode ok ${w}x$h');
      } catch (e) {
        CrashReporter.warn('avatar rejected: undecodable '
            'name=${file.name} bytes=${bytes.length} err=$e');
        if (mounted) {
          AppToast.error(context, '图片已损坏或格式不支持，请换一张图片');
        }
        return;
      }
      setState(() => _uploading = true);
      final media = await ref.read(mediaRepoProvider).uploadImage(
            bytes: bytes,
            filename: file.name,
          );
      CrashReporter.b('avatar upload ok url=${media.url} '
          'serverSize=${media.size} ct=${media.contentType}');
      if (!mounted) return;
      setState(() => _avatarUrl = media.url);
      AppToast.info(context, AppL10n.of(context).avatarSavedHint);
    } catch (e) {
      CrashReporter.warn('avatar pick/upload exception: $e');
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).avatarUploadFailedReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// 常见位图 magic（Flutter 原生解码器只支持 JPEG/PNG/GIF/WebP/BMP）。
  bool _looksLikeImage(Uint8List b) {
    if (b.length < 12) return false;
    bool startsWith(List<int> sig) {
      if (b.length < sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[i] != sig[i]) return false;
      }
      return true;
    }

    return startsWith([0xFF, 0xD8, 0xFF]) // JPEG
        || startsWith([0x89, 0x50, 0x4E, 0x47]) // PNG
        || startsWith([0x47, 0x49, 0x46]) // GIF
        || (startsWith([0x52, 0x49, 0x46, 0x46]) &&
            b[8] == 0x57 &&
            b[9] == 0x45 &&
            b[10] == 0x42 &&
            b[11] == 0x50) // RIFF....WEBP
        || startsWith([0x42, 0x4D]); // BMP
  }

  String _imageMagic(Uint8List b) {
    if (b.length < 4) return 'too-short(${b.length})';
    return b
        .take(4)
        .map((x) => x.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  Widget _avatarSection(String? avatarUrl, AppUser? user, Color accent) {
    final nick = user?.nickname ?? '';
    final name = nick.isNotEmpty ? nick : (user?.username ?? '?');
    return Center(
      child: GestureDetector(
        onTap: _uploading ? null : _pickAndUploadAvatar,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: accent.withValues(alpha: 0.4), width: 2),
              ),
              child: UserAvatar(
                name: name,
                avatarUrl: avatarUrl,
                size: 96,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Text(text,
            style: theme.textTheme.labelLarge?.copyWith(
                color: theme.hintColor, fontWeight: FontWeight.w600)),
      );

  Widget _card(ThemeData theme, List<Widget> children) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _readOnlyField(
      ThemeData theme, String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: theme.hintColor),
      title: Text(label,
          style:
              theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
  }

  Widget _editableField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bioField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppL10n.of(context).bio,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _bio,
            maxLines: 4,
            minLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: AppL10n.of(context).bioHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderRow(ThemeData theme) {
    final l = AppL10n.of(context);
    return ListTile(
      leading: const Icon(Icons.wc_outlined),
      title: Text(l.gender, style: theme.textTheme.bodyLarge),
      trailing: Wrap(
        spacing: 8,
        children: [
          for (final g in const ['MALE', 'FEMALE', 'UNKNOWN'])
            ChoiceChip(
              label: Text(switch (g) {
                'MALE' => l.genderMale,
                'FEMALE' => l.genderFemale,
                _ => l.unknownGender,
              }),
              selected: (_gender ?? 'UNKNOWN') == g,
              onSelected: (_) => setState(() => _gender = g),
            ),
        ],
      ),
    );
  }
}
