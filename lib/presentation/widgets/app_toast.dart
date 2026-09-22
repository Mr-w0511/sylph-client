import 'dart:async';

import 'package:flutter/material.dart';

/// 全局居中 Toast（替代 SnackBar）。
///
/// 用法：在 MaterialApp.router 的 builder 中调用 [AppToast.attach]，
/// 之后任意位置可用 `AppToast.success(context, '...')` 弹出提示。
/// 连续调用时仅保留最新一条。
class AppToast {
  AppToast._();

  static OverlayState? _overlay;

  /// 当前正在展示的 Toast 条目（新的弹出时移除旧的）。
  static _ToastEntry? _current;

  /// 在 MaterialApp 的 builder 中安装：AppToast.attach(context)。
  static void attach(BuildContext context) {
    _overlay = Overlay.maybeOf(context, rootOverlay: true);
  }

  static void success(BuildContext context, String text) =>
      _show(context, _ToastKind.success, text);

  static void error(BuildContext context, String text) =>
      _show(context, _ToastKind.error, text);

  static void info(BuildContext context, String text) =>
      _show(context, _ToastKind.info, text);

  /// 无 context 调用：仅依赖 attach() 安装的 Overlay（用于 Provider/回调层）。
  static void showError(String text) => _show(null, _ToastKind.error, text);
  static void showInfo(String text) => _show(null, _ToastKind.info, text);
  static void showSuccess(String text) => _show(null, _ToastKind.success, text);

  static void _show(
      BuildContext? context, _ToastKind kind, String text) {
    // 兜底：attach 未执行时尝试从传入 context 取 Overlay。
    final overlay = _overlay ??
        (context != null ? Overlay.maybeOf(context, rootOverlay: true) : null);
    if (overlay == null) return;

    _current?.dismiss();
    _current = _ToastEntry(overlay: overlay, kind: kind, text: text)..show();
  }
}

enum _ToastKind { success, error, info }

class _ToastEntry {
  final OverlayState overlay;
  final _ToastKind kind;
  final String text;

  OverlayEntry? _entry;
  Timer? _timer;
  final _progress = ValueNotifier<double>(0);

  _ToastEntry({
    required this.overlay,
    required this.kind,
    required this.text,
  });

  void show() {
    _entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        kind: kind,
        text: text,
        progress: _progress,
      ),
    );
    overlay.insert(_entry!);
    // 弹出动画在首帧后展开。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_entry != null) _progress.value = 1;
    });
    _timer = Timer(const Duration(milliseconds: 1600), dismiss);
  }

  Future<void> dismiss() async {
    _timer?.cancel();
    _timer = null;
    final e = _entry;
    if (e == null) return;
    _entry = null;
    if (AppToast._current == this) AppToast._current = null;
    _progress.value = 0;
    // 等收起/淡出动画结束再从树中移除。
    await Future<void>.delayed(const Duration(milliseconds: 180));
    e.remove();
    _progress.dispose();
  }
}

class _ToastWidget extends StatelessWidget {
  final _ToastKind kind;
  final String text;
  final ValueNotifier<double> progress;

  const _ToastWidget({
    required this.kind,
    required this.text,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (icon, color) = switch (kind) {
      _ToastKind.success => (Icons.check_circle_rounded, const Color(0xFF34C78A)),
      _ToastKind.error => (Icons.error_rounded, const Color(0xFFFF5A5A)),
      _ToastKind.info => (Icons.info_rounded, theme.colorScheme.primary),
    };

    return IgnorePointer(
      child: Center(
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, t, _) {
            final scale = 0.85 + 0.15 * Curves.easeOutBack.transform(t);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xE6222A35)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2430),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
