import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/config/env.dart';
import '../../core/monitor/crash_reporter.dart';

/// Sylph 官方助手的 UID（后端约定）。
const kSystemAssistantUid = '10000000';

/// 官方助手昵称（peer 信息无 uid 时的兜底识别）。
const kSystemAssistantName = 'Sylph 官方助手';

/// 头像：官方账号用品牌渐变头像；有 URL 用网络图；否则用首字母圆形头像。
/// 网络头像解码/下载失败时降级为首字母头像（绝不让一张坏图导致整个页面崩掉）。
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;

  /// 用户 UID，命中官方 UID 时渲染品牌头像。
  final String? uid;

  /// 显式标记为官方账号（拿不到 uid 时使用）。
  final bool isSystem;

  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 44,
    this.uid,
    this.isSystem = false,
  });

  static const _palette = [
    Color(0xFF3B6EF6),
    Color(0xFF19A979),
    Color(0xFFF2994A),
    Color(0xFFEB5757),
    Color(0xFF9B51E0),
    Color(0xFF2D9CDB),
  ];

  /// 是否为官方助手账号。
  bool get _isOfficial =>
      isSystem || uid == kSystemAssistantUid || name == kSystemAssistantName;

  /// 首字母兜底头像（无 URL / 加载失败时使用）。
  Widget _buildFallback(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    final color = _palette[name.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.42,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isOfficial) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B6EF6), Color(0xFF2EA6FF)],
          ),
        ),
        child: Icon(Icons.send_rounded, color: Colors.white, size: size * 0.5),
      );
    }
    final url = avatarUrl;
    if (url != null && url.isNotEmpty) {
      // 兜底：本地缓存可能还存着历史 svg 头像 URL（服务端已迁 png），
      // 这里统一把 dicebear 的 /svg 转成 /png，避免旧缓存反复加载失败。
      final fullUrl = _normalizeDicebear(Env.mediaUrl(url));
      return _NetworkCircleAvatar(
        url: fullUrl,
        size: size,
        fallback: _buildFallback(context),
      );
    }
    return _buildFallback(context);
  }

  /// dicebear 默认头像历史上是 svg（Flutter 无法解码），统一替换为 png。
  static String _normalizeDicebear(String url) {
    if (url.contains('dicebear.com') && url.contains('/svg?')) {
      return url.replaceFirst('/svg?', '/png?');
    }
    return url;
  }
}

/// 圆形网络头像：下载/解码失败降级 fallback，并上报坏图 URL 后清除磁盘缓存，
/// 防止损坏的本地缓存导致"永远加载失败"。
class _NetworkCircleAvatar extends StatefulWidget {
  final String url;
  final double size;
  final Widget fallback;

  const _NetworkCircleAvatar({
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  State<_NetworkCircleAvatar> createState() => _NetworkCircleAvatarState();
}

class _NetworkCircleAvatarState extends State<_NetworkCircleAvatar> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image(
          image: CachedNetworkImageProvider(widget.url),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // Image 的 errorBuilder 会吞掉 ImageStream 解码/HTTP 错误，
          // 不再经 FlutterError.onError 上抛（旧 CircleAvatar.backgroundImage
          // 没有错误通道，坏图直接炸掉整个 framework）。
          errorBuilder: (context, error, stack) {
            _handleError(error);
            return widget.fallback;
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            );
          },
        ),
      ),
    );
  }

  void _handleError(Object error) {
    // 错误类型区分数据源：HttpExceptionWithStatus=文件不存在/服务端错误，
    // Invalid image data/CodecException=字节损坏（上传环节或缓存损坏）。
    CrashReporter.warn('avatar load fail url=${widget.url} '
        'err=${error.runtimeType}: ${error.toString().split('\n').first}');
    if (!mounted) return;
    setState(() => _failed = true);
    scheduleMicrotask(() async {
      try {
        await CachedNetworkImageProvider(widget.url).evict();
        await DefaultCacheManager().removeFile(widget.url);
      } catch (_) {
        // 清缓存失败不影响降级显示。
      }
    });
  }
}
