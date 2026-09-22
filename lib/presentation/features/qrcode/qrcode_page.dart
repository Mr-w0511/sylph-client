import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/user_avatar.dart';

/// 通用二维码展示页（个人名片 / 群名片）。
/// #17 支持：复制链接、保存图片、分享图片/链接（站外）、站内分享。
class QrcodePage extends ConsumerStatefulWidget {
  final String title;
  final String content;
  final String name;
  final String? avatarUrl;
  final String? subtitle;

  /// 重置二维码回调（返回新 content；不传则不展示重置按钮）。
  final Future<String> Function()? onReset;

  /// #17 站内分享回调：传入则显示"站内分享"按钮。
  final Future<void> Function()? onShareInApp;

  const QrcodePage({
    super.key,
    required this.title,
    required this.content,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.onReset,
    this.onShareInApp,
  });

  @override
  ConsumerState<QrcodePage> createState() => _QrcodePageState();
}

class _QrcodePageState extends ConsumerState<QrcodePage> {
  late String _content = widget.content;
  bool _resetting = false;
  final _cardKey = GlobalKey();
  bool _capturing = false;

  Future<void> _reset() async {
    final fn = widget.onReset;
    if (fn == null || _resetting) return;
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.resetQrcode),
        content: Text(l.resetQrcodeConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(dctx).pop(true),
              child: Text(l.resetAction)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _resetting = true);
    try {
      final c = await fn();
      if (!mounted) return;
      setState(() => _content = c);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).resetFailedReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  // #17 捕获二维码卡片为图片字节
  Future<Uint8List?> _captureCard() async {
    final boundary = _cardKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: dpr);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // #17 保存二维码图片到相册
  Future<void> _saveImage() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final bytes = await _captureCard();
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          AppToast.error(context, AppL10n.of(context).imageGenFailed);
        }
        return;
      }
      final name = 'sylph_qr_${DateTime.now().millisecondsSinceEpoch}';
      if (Platform.isAndroid || Platform.isIOS) {
        await Gal.putImageBytes(bytes, album: 'Sylph', name: name);
        if (mounted) AppToast.success(context, AppL10n.of(context).savedToGallery);
      } else {
        // 桌面端：写临时文件
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name.png');
        await file.writeAsBytes(bytes);
        if (mounted) {
          AppToast.success(
              context, AppL10n.of(context).imageSavedWithPath(file.path));
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(context, AppL10n.of(context).saveFailedReason('$e'));
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // #17 分享图片到站外社交平台
  Future<void> _shareImage() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final bytes = await _captureCard();
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          AppToast.error(context, AppL10n.of(context).imageGenFailed);
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/sylph_qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: AppL10n.of(context).qrcodeShareSubject(widget.name),
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).shareFailedReason('$e'));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // #17 分享链接到站外
  Future<void> _shareLink() async {
    try {
      await Share.share(_content);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppL10n.of(context).shareFailedReason('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24)
              .copyWith(bottom: 24 + MediaQuery.viewPaddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.3 : 0.10),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserAvatar(
                              name: widget.name,
                              avatarUrl: widget.avatarUrl,
                              size: 46),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF17212B))),
                                if (widget.subtitle != null)
                                  Text(widget.subtitle!,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF8A97A6))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _resetting
                          ? const SizedBox(
                              width: 220,
                              height: 220,
                              child:
                                  Center(child: CircularProgressIndicator()),
                            )
                          : QrImageView(
                              data: _content,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF17212B),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF17212B),
                              ),
                            ),
                      const SizedBox(height: 14),
                      Text(
                        _content,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A97A6)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.qrcodeScanTip,
                style: TextStyle(fontSize: 13, color: theme.hintColor),
              ),
              const SizedBox(height: 20),
              // #17 按钮组：复制链接 / 保存图片 / 分享图片 / 分享链接 / 站内分享 / 重置
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _content));
                      AppToast.success(context, l.copiedToClipboard);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l.copyLink),
                  ),
                  OutlinedButton.icon(
                    onPressed: _capturing ? null : _saveImage,
                    icon: const Icon(Icons.save_alt_outlined, size: 18),
                    label: Text(l.saveImage),
                  ),
                  OutlinedButton.icon(
                    onPressed: _capturing ? null : _shareImage,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(l.shareImage),
                  ),
                  OutlinedButton.icon(
                    onPressed: _shareLink,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(l.shareLink),
                  ),
                  if (widget.onShareInApp != null)
                    FilledButton.icon(
                      onPressed: widget.onShareInApp,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(l.inAppShare),
                      style: FilledButton.styleFrom(
                        backgroundColor: telegramOutgoing,
                      ),
                    ),
                  if (widget.onReset != null)
                    OutlinedButton.icon(
                      onPressed: _resetting ? null : _reset,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l.resetQrcode),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: telegramOutgoing,
                        side: const BorderSide(color: telegramOutgoing),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
