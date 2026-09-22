import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../../presentation/widgets/app_toast.dart';
import '../config/env.dart';
import '../monitor/crash_reporter.dart';

/// 聊天图片保存：移动端入相册、桌面弹保存对话框、Web 提示长按保存。
class ImageSaver {
  const ImageSaver._();

  /// 下载媒体字节（贴纸收藏等复用）；失败返回 null。
  static Future<Uint8List?> fetchBytes(String relativeUrl) async {
    try {
      final resp = await Dio().get<List<int>>(
        Env.mediaUrl(relativeUrl),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(resp.data ?? const []);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(BuildContext context, String relativeUrl) async {
    // Web：无法直接写本地，提示用户长按/右键保存。
    if (kIsWeb) {
      AppToast.info(context, '请长按图片保存');
      return;
    }

    Uint8List bytes;
    try {
      final resp = await Dio().get<List<int>>(
        Env.mediaUrl(relativeUrl),
        options: Options(responseType: ResponseType.bytes),
      );
      bytes = Uint8List.fromList(resp.data ?? const []);
      if (bytes.isEmpty) {
        if (context.mounted) AppToast.error(context, '保存失败：图片数据为空');
        return;
      }
    } catch (e) {
      if (context.mounted) AppToast.error(context, '下载图片失败：$e');
      return;
    }

    final name = 'sylph_${DateTime.now().millisecondsSinceEpoch}';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // 移动端：写入系统相册 Sylph 相册。
      CrashReporter.b('Gal.putImageBytes begin (${bytes.length}B)');
      try {
        await Gal.putImageBytes(bytes, album: 'Sylph', name: name);
        CrashReporter.b('Gal.putImageBytes ok');
        if (context.mounted) AppToast.success(context, '已保存到相册');
      } on GalException catch (e) {
        CrashReporter.b('Gal exception: ${e.type}');
        if (!context.mounted) return;
        AppToast.error(
          context,
          e.type == GalExceptionType.accessDenied
              ? '保存失败：没有相册访问权限'
              : '保存失败：${e.type.message}',
        );
      } catch (e) {
        CrashReporter.b('Gal unknown error: $e');
        if (context.mounted) AppToast.error(context, '保存失败：$e');
      }
      return;
    }

    // 桌面端：弹系统保存对话框（file_picker 直接写 bytes）。
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '保存图片',
        fileName: '$name.jpg',
        bytes: bytes,
      );
      if (path != null && context.mounted) {
        AppToast.success(context, '已保存');
      }
    } catch (e) {
      if (context.mounted) AppToast.error(context, '保存失败：$e');
    }
  }
}
