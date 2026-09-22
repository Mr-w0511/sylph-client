import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/wallpaper_background.dart';

/// 聊天壁纸设置：预览、从相册选择、遮罩浓度调节、恢复默认。
class WallpaperPage extends ConsumerStatefulWidget {
  const WallpaperPage({super.key});

  @override
  ConsumerState<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends ConsumerState<WallpaperPage> {
  bool _saving = false;

  /// 选择图片并拷贝到应用文档目录后写入设置。
  Future<void> _pickWallpaper() async {
    // 网页端无法访问本地文件路径，暂不支持。
    if (kIsWeb) {
      AppToast.info(context, AppL10n.of(context).wallpaperUnsupported);
      return;
    }
    if (_saving) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      setState(() => _saving = true);
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${dir.path}${Platform.pathSeparator}$filename');
      await file.writeAsBytes(bytes, flush: true);
      // 拷贝后校验：个别设备文档目录写入会静默失败，路径却已记录，
      // 后续全局透明 Scaffold 就会透出黑底。校验不过不写入设置。
      if (!await file.exists() || await file.length() == 0) {
        if (mounted) AppToast.error(context, AppL10n.of(context).wallpaperSaveFailed);
        return;
      }

      final oldPath =
          ref.read(settingsControllerProvider).wallpaperPath;
      // 设置前预解码，全局壁纸层立即可显示（Consumer 订阅后本页 UI 同步刷新）。
      if (!kIsWeb && mounted) {
        await precacheImage(FileImage(file), context);
      }
      await ref
          .read(settingsControllerProvider.notifier)
          .setWallpaper(file.path);
      // 删除旧壁纸文件，失败可忽略。
      if (oldPath != null && oldPath != file.path) {
        try {
          final old = File(oldPath);
          if (await old.exists()) await old.delete();
        } catch (_) {}
      }
      if (mounted) AppToast.success(context, AppL10n.of(context).wallpaperSet);
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).setWallpaperFailedReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetWallpaper() async {
    final oldPath = ref.read(settingsControllerProvider).wallpaperPath;
    await ref.read(settingsControllerProvider.notifier).setWallpaper(null);
    if (!kIsWeb && oldPath != null) {
      try {
        final old = File(oldPath);
        if (await old.exists()) await old.delete();
      } catch (_) {}
    }
    if (mounted) AppToast.info(context, AppL10n.of(context).wallpaperReset);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.chatWallpaper)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(12, 8, 12,
            32 + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          // 壁纸 + 遮罩 + 模拟气泡的实时预览（遮罩逻辑与全局壁纸完全一致）。
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 占位渐变（无壁纸时显示），与全局默认背景观感一致。
                  if (settings.wallpaperPath == null ||
                      (!kIsWeb && !File(settings.wallpaperPath!).existsSync()))
                    const WallpaperPlaceholder(),
                  // 全局壁纸层：图片 + 明暗遮罩，与 app.dart 全局挂载完全一致。
                  WallpaperBackground(
                    wallpaperPath: settings.wallpaperPath,
                    overlay: settings.wallpaperOverlay,
                    brightness:
                        isDark ? Brightness.dark : Brightness.light,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: _PreviewBubble(
                            text: l.wallpaperPreview1,
                            color: const Color(0xFF2EA6FF),
                            textColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _PreviewBubble(
                            text: l.wallpaperPreview2,
                            color: isDark
                                ? const Color(0xFF182533)
                                : Colors.white,
                            textColor: isDark
                                ? Colors.white
                                : const Color(0xFF1F2430),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l.pickFromGallery),
                  subtitle: kIsWeb
                      ? Text(l.wallpaperUnsupportedShort)
                      : Text(l.pickLocalImage),
                  trailing: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _saving ? null : _pickWallpaper,
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt_outlined),
                  title: Text(l.resetDefault),
                  trailing: const Icon(Icons.chevron_right),
                  onTap:
                      settings.wallpaperPath == null ? null : _resetWallpaper,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.overlayOpacity,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      const Icon(Icons.light_mode_outlined, size: 18),
                      Expanded(
                        child: Slider(
                          min: 0.25,
                          max: 0.85,
                          divisions: 12,
                          value: settings.wallpaperOverlay,
                          label:
                              '${(settings.wallpaperOverlay * 100).round()}%',
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .setWallpaperOverlay(v),
                        ),
                      ),
                      const Icon(Icons.dark_mode_outlined, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 预览用的聊天气泡。
class _PreviewBubble extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _PreviewBubble({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 14)),
    );
  }
}
