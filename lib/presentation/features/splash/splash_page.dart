import 'package:flutter/material.dart';

import '../../../presentation/theme/app_theme.dart';

/// 启动页：渐变主色背景 + 居中 Logo + 加载指示器。
/// 路由判断由 app_router.dart 基于 sessionControllerProvider 状态驱动。
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [sylphBlue, telegramOutgoing],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sylph',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '轻量、私密的即时通讯',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
