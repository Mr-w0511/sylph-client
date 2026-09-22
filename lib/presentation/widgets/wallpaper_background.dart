import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 统一的壁纸背景层：图片 + 明暗遮罩。
///
/// 全局在 [SylphApp] 的 MaterialApp.builder 中挂载，所有 Scaffold 透过
/// 透明背景显示此层；聊天页不再各自渲染，避免遮罩浓度不一致。
///
/// 性能要点：
/// * 按屏幕物理宽降采样解码（cacheWidth），大图（4000px+）不再全量进内存，
///   既加快首次解码，也避免 ImageCache 在内存紧张时把它挤出导致页面切换
///   重新解码出现“壁纸慢半拍”；
/// * 外层 [RepaintBoundary] 隔离，页面转场/列表滚动不触发壁纸图层重绘。
class WallpaperBackground extends StatelessWidget {
  final String? wallpaperPath;
  final double overlay;
  final Brightness brightness;

  const WallpaperBackground({
    super.key,
    this.wallpaperPath,
    this.overlay = 0.55,
    this.brightness = Brightness.light,
  });

  /// 降采样后的目标解码宽度（物理像素，封顶 1440，足够覆盖绝大多数手机）。
  static int? decodeWidthFor(BuildContext context) {
    if (kIsWeb) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = MediaQuery.sizeOf(context).width;
    final target = (w * dpr).round();
    if (target <= 0) return null;
    return target > 1440 ? 1440 : target;
  }

  /// 是否实际存在可用的壁纸文件。
  bool get hasWallpaper {
    if (kIsWeb || wallpaperPath == null) return false;
    return File(wallpaperPath!).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    // 不透明兜底底色：壁纸缺失/解码失败时绝不能透出引擎黑底，
    // 否则透明 Scaffold 的页面（含页面返回过渡中的上一页）会整页发黑。
    final fallback = ColoredBox(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
    );
    if (!hasWallpaper) return fallback;
    final file = File(wallpaperPath!);
    final cacheWidth = decodeWidthFor(context);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          fallback,
          // gaplessPlayback：路径未变时复用旧帧，避免页面切换/主题切换瞬间闪空白。
          Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          // 遮罩色与浓度与壁纸设置预览完全一致：亮主题白底、暗主题黑底。
          ColoredBox(
            color:
                (isDark ? Colors.black : Colors.white).withValues(alpha: overlay),
          ),
        ],
      ),
    );
  }
}

/// 默认占位渐变（无壁纸时作为底图）。
class WallpaperPlaceholder extends StatelessWidget {
  final Brightness brightness;

  const WallpaperPlaceholder({super.key, this.brightness = Brightness.light});

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF1B2735), Color(0xFF0F151D)]
              : const [Color(0xFFDCE8F5), Color(0xFFF2F6FB)],
        ),
      ),
    );
  }
}
