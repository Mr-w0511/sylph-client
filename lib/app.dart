import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notify/notifications.dart';
import 'presentation/router/app_router.dart';
import 'presentation/state/providers.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/app_toast.dart';
import 'presentation/widgets/wallpaper_background.dart';

class SylphApp extends ConsumerStatefulWidget {
  const SylphApp({super.key});

  @override
  ConsumerState<SylphApp> createState() => _SylphAppState();
}

class _SylphAppState extends ConsumerState<SylphApp> {
  /// 冷启动由通知点击拉起时，待登录态就绪后跳转的会话 id。
  int? _pendingLaunchConvId;

  @override
  void initState() {
    super.initState();
    // #14 点击系统通知 → 跳转对应会话。
    Notifications.onTap = (convId) {
      // 通话通知点击：若处于 active 通话，直接回到 /call 全屏页；
      // 否则 convId<=0（通话通知无会话上下文）时忽略，避免误跳聊天页。
      final call = ref.read(callControllerProvider);
      if (call.isActive) {
        // 语音/视频通话页面已分离：按 isVideoCall 推不同路由。
        ref.read(goRouterProvider)
            .push(call.isVideoCall ? '/call' : '/audio-call');
        return;
      }
      if (convId <= 0) return;
      ref.read(goRouterProvider).push('/chat/$convId');
    };
    // 冷启动（进程被通知拉起）：先记住目标会话，等 bootstrap 认证成功再跳。
    unawaited(Notifications.getLaunchConversationId().then((id) {
      // 通话通知在会话未知时载荷为 0：不跳聊天页（来电页由信令重新拉起）。
      if (id != null && id > 0 && mounted) _pendingLaunchConvId = id;
    }));
    // splash 启动引导（读 token → /users/me）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final settings = ref.watch(settingsControllerProvider);

    // 登录态就绪后执行通知冷启动深链跳转（仅一次）。
    ref.listen(sessionControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated &&
          _pendingLaunchConvId != null) {
        final id = _pendingLaunchConvId!;
        _pendingLaunchConvId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(goRouterProvider).push('/chat/$id');
        });
      }
    });

    // 壁纸路径变化（启动加载/用户更换）后预热解码缓存，
    // 让随后进入的任意页面直接命中缓存，消除壁纸“慢半拍”。
    ref.listen(settingsControllerProvider, (prev, next) {
      final path = next.wallpaperPath;
      if (path == null || path == prev?.wallpaperPath) return;
      if (kIsWeb || !File(path).existsSync()) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 必须与 WallpaperBackground 的降采样宽度一致（ResizeImage 参与缓存键）。
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final w = MediaQuery.sizeOf(context).width;
        var target = (w * dpr).round();
        if (target <= 0) target = 1080;
        if (target > 1440) target = 1440;
        precacheImage(
          ResizeImage(FileImage(File(path)), width: target),
          context,
        ).catchError((_) {});
      });
    });
    // 仅原生平台 + 壁纸文件确实存在时，才启用透明 Scaffold 透出壁纸；
    // 路径失效（文件被清理/拷贝失败/恢复默认后残留）时一律走不透明底色，
    // 否则页面会透出引擎黑底，表现为“全局纯黑”。
    final hasWallpaper = !kIsWeb &&
        settings.wallpaperPath != null &&
        File(settings.wallpaperPath!).existsSync();
    // 壁纸存在时：Scaffold 透明，让全局壁纸层透出；AppBar 使用半透明底色。
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      child: MaterialApp.router(
      onGenerateTitle: (context) => AppL10n.of(context).appTitle,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.seedColor).copyWith(
        scaffoldBackgroundColor: hasWallpaper ? const Color(0x00000000) : null,
        appBarTheme: hasWallpaper
            ? const AppBarTheme(
                backgroundColor: Color(0xCCF7F8FA),
                elevation: 0,
                foregroundColor: Color(0xFF1F2430),
              )
            : null,
      ),
      darkTheme: AppTheme.dark(settings.seedColor).copyWith(
        scaffoldBackgroundColor: hasWallpaper ? const Color(0x00000000) : null,
        appBarTheme: hasWallpaper
            ? const AppBarTheme(
                backgroundColor: Color(0xCC212B36),
                elevation: 0,
                foregroundColor: Colors.white,
              )
            : null,
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      // 在导航器之上挂一层 Overlay 供全局居中 Toast 使用；
      // 同时在最底层挂全局壁纸（仅原生平台且用户已设置时可见）。
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (overlayCtx) {
                AppToast.attach(overlayCtx);
                // 关键：OverlayState 会跨 MaterialApp 重建保留 entry，
                // 闭包捕获的 settings 是旧值（壁纸设置后不生效的根因）；
                // 这里改用 Consumer 订阅，设置变更时本层立即重建。
                return Consumer(
                  builder: (ctx, ref, _) {
                    final s = ref.watch(settingsControllerProvider);
                    final wallpaperPath = s.wallpaperPath;
                    final isDark =
                        Theme.of(ctx).brightness == Brightness.dark;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // #1 全局壁纸背景（与壁纸设置预览遮罩逻辑完全一致）。
                        WallpaperBackground(
                          wallpaperPath: wallpaperPath,
                          overlay: s.wallpaperOverlay,
                          brightness:
                              isDark ? Brightness.dark : Brightness.light,
                        ),
                        // 导航器内容（路由页面）。
                        child!,
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
      ),
    );
  }
}
