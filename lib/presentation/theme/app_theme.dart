import 'package:flutter/material.dart';

/// Sylph 品牌主色（保留兼容旧引用，同时是默认主题种子色）。
const sylphBlue = Color(0xFF3B6EF6);

/// Telegram 风格的发送气泡蓝色（亮主题）。
const telegramOutgoing = Color(0xFF2EA6FF);

/// Telegram dark 背景色。
const telegramDarkBg = Color(0xFF17212B);

/// Telegram dark 顶栏 / 输入区背景。
const telegramDarkSurface = Color(0xFF212B36);

/// Telegram dark 接收气泡色。
const telegramDarkIncoming = Color(0xFF182533);

/// Telegram dark 二级背景（导航栏）。
const telegramDarkNavBar = Color(0xFF17212B);

/// 可换肤的预设种子色盘（设置页“个性化-主题色”使用）。
const List<int> kSylphSeedColors = [
  0xFF3B6EF6, // 默认蓝
  0xFF2EA6FF, // 天空蓝
  0xFFFF6F61, // 珊瑚红
  0xFFFF9FB2, // 柔粉
  0xFF9B7EDE, // 淡紫
  0xFFFFA94D, // 暖橙
  0xFF34C78A, // 薄荷绿
  0xFF5B6472, // 深灰
  0xFFF5C451, // 鹅黄
];

class AppTheme {
  const AppTheme._();

  static ThemeData light([int? seed]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(seed ?? 0xFF3B6EF6),
      brightness: Brightness.light,
    );
    return _base(scheme, brightness: Brightness.light);
  }

  static ThemeData dark([int? seed]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(seed ?? 0xFF3B6EF6),
      brightness: Brightness.dark,
    );
    return _base(scheme, brightness: Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, {required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      // CanvasKit 无法访问 Google Fonts 回落服务，内置中文字体保证 CJK 正常显示
      fontFamily: 'SylphZh',
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0F151D) : const Color(0xFFF7F8FA),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? telegramDarkSurface : scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        // 细底部边框，区分内容区而不投影。
        shape: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: false,
        fillColor: isDark
            ? const Color(0xFF182533)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        // 上 18 / 下 12：修复登录页浮动 label 裁切问题。
        contentPadding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // 开关：选中态轨道跟随主题色。
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: 0.55)
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        space: 1,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: isDark ? telegramDarkNavBar : scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? scheme.primary
                : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
