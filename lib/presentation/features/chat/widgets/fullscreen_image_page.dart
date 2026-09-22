import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../../core/config/env.dart';
import '../../../../core/utils/image_saver.dart';
import '../../../widgets/app_toast.dart';
import '../../qrcode/scan_page.dart' show handleSylphCode;
import 'forward_sheet.dart' show showForwardSheet;
import 'fullscreen_video_page.dart';

/// 媒体条目：图片或视频的 URL 与类型。
class MediaItem {
  final String url;
  final String type; // 'IMAGE' | 'VIDEO'
  const MediaItem({required this.url, required this.type});
}

/// #9 图片/视频查看器：
/// - PageView 左右滑动切换上下文图片/视频
/// - 非全屏遮挡：AppBar 固定在顶部，图片区域从 AppBar 下方开始
/// - 长按弹出菜单：转发 / 识别二维码 / 保存到相册
class FullscreenImagePage extends ConsumerStatefulWidget {
  /// 全部媒体条目（图 + 视频）。
  final List<MediaItem> mediaItems;

  /// 初始展示索引。
  final int initialIndex;

  /// 仅传单个 URL 时兼容旧接口。
  const FullscreenImagePage({
    super.key,
    required this.mediaItems,
    this.initialIndex = 0,
  });

  /// 旧接口兼容：只传单个 url。
  factory FullscreenImagePage.single(String url) =>
      FullscreenImagePage(mediaItems: [MediaItem(url: url, type: 'IMAGE')]);

  @override
  ConsumerState<FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends ConsumerState<FullscreenImagePage> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.mediaItems.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MediaItem> get media => widget.mediaItems;

  Future<void> _save() async {
    final item = media[_index];
    try {
      await ImageSaver.save(context, item.url);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).saveFailedReason('$e'));
      }
    }
  }

  /// #9 长按菜单：转发 / 识别二维码 / 保存。
  void _showLongPressMenu() {
    final l = AppL10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.forward_outlined),
              title: Text(l.forward),
              onTap: () {
                Navigator.pop(sctx);
                final item = media[_index];
                showForwardSheet(
                  context,
                  ref,
                  type: item.type,
                  mediaUrl: item.url,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text(l.scanQrcodeInImage),
              onTap: () {
                Navigator.pop(sctx);
                _recognizeQrCode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: Text(l.saveToGallery),
              onTap: () {
                Navigator.pop(sctx);
                _save();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 下载当前图片到临时文件，用 mobile_scanner 识别二维码（仅 Android/iOS/macOS 支持）。
  Future<void> _recognizeQrCode() async {
    final l = AppL10n.of(context);
    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      AppToast.info(context, l.imageScanUnsupported);
      return;
    }
    final item = media[_index];
    if (item.type != 'IMAGE') {
      AppToast.info(context, l.qrImageOnly);
      return;
    }

    // 1. 下载图片
    Uint8List bytes;
    try {
      final resp = await Dio().get<List<int>>(
        Env.mediaUrl(item.url),
        options: Options(responseType: ResponseType.bytes),
      );
      bytes = Uint8List.fromList(resp.data ?? const []);
    } catch (e) {
      debugPrint('qr recognize download failed: $e');
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).imageDownloadFailed('$e'));
      }
      return;
    }
    if (bytes.isEmpty) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).imageDataEmpty);
      }
      return;
    }

    // 2. 写入临时文件（尽量保留原始扩展名，ML Kit 对 MIME 更敏感的平台更稳）
    String? tempPath;
    try {
      final dir = await getTemporaryDirectory();
      var ext = 'jpg';
      final qIndex = item.url.indexOf('?');
      final pathPart = qIndex >= 0 ? item.url.substring(0, qIndex) : item.url;
      final dot = pathPart.lastIndexOf('.');
      if (dot >= 0 && pathPart.length - dot <= 6) {
        final candidate = pathPart.substring(dot + 1).toLowerCase();
        if (RegExp(r'^[a-z0-9]+$').hasMatch(candidate)) ext = candidate;
      }
      final file = File(
          '${dir.path}/qr_scan_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await file.writeAsBytes(bytes);
      tempPath = file.path;
    } catch (e) {
      debugPrint('qr recognize temp file failed: $e');
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).tempFileWriteFailed('$e'));
      }
      return;
    }

    // 3. 调用 mobile_scanner 识别（不限制码制，提高二维码/其他条码检出率）
    final controller = MobileScannerController();
    try {
      final capture = await controller.analyzeImage(tempPath);

      if (capture == null || capture.barcodes.isEmpty) {
        if (mounted) {
          AppToast.info(context, AppL10n.of(context).qrNotFound);
        }
        return;
      }
      final raw = capture.barcodes.first.rawValue;
      if (raw == null || raw.isEmpty) {
        if (mounted) {
          AppToast.info(context, AppL10n.of(context).qrContentEmpty);
        }
        return;
      }
      if (mounted) {
        // 与扫一扫共用同一套解析/跳转逻辑（用户/群资料页、UID、群号等）。
        await handleSylphCode(context, ref, raw);
      }
    } catch (e) {
      debugPrint('qr recognize analyzeImage failed: $e');
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).imageScanFailedReason('$e'));
      }
    } finally {
      await controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // #9 AppBar 不透明，图片从下方开始，不遮挡按钮
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 页码指示器
          Center(
            child: Text(
              '${_index + 1}/${media.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: AppL10n.of(context).save,
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          itemCount: media.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final item = media[i];
            return GestureDetector(
              onLongPress: _showLongPressMenu,
              // #9 图片居中，四周留白
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: item.type == 'VIDEO'
                    ? _videoPlaceholder(item.url)
                    : PhotoView(
                        imageProvider: CachedNetworkImageProvider(
                            Env.mediaUrl(item.url)),
                        backgroundDecoration:
                            const BoxDecoration(color: Colors.transparent),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4,
                        loadingBuilder: (context, event) => Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              value: event == null ||
                                      event.expectedTotalBytes == null
                                  ? null
                                  : event.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!,
                            ),
                          ),
                        ),
                        errorBuilder: (context, error, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_outlined,
                                  color: Colors.white54, size: 48),
                              const SizedBox(height: 8),
                              Text(AppL10n.of(context).loadFailed,
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 13)),
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

  /// 视频占位：点击进入全屏视频播放页。
  Widget _videoPlaceholder(String url) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FullscreenVideoPage(url: url)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_filled_rounded,
                size: 72, color: Colors.white70),
            const SizedBox(height: 8),
            Text(AppL10n.of(context).videoTapToPlay,
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
