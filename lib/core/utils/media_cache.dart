import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 媒体文件本地缓存（音乐播放用）：下载到临时目录，按 URL sha1 去重。
///
/// 关键设计（修复"无法播放 + 反复下载"）：
/// 1. 目录内 `_index.json` 记录 URL → 实际文件名（含真实扩展名），
///    内存 Map 为一级缓存；旧版无扩展名的 `sha1` 文件无法被 Android
///    MediaPlayer 识别（MEDIA_ERROR_UNKNOWN what:1）；
/// 2. 扩展名三级判定：URL 白名单 → 响应 Content-Type → 文件头魔数，
///    兜底 `.mp3`；
/// 3. 下载完整校验（HTTP 200 / 非空 / 非 HTML）+ `.part` 原子 rename，
///    半成品不会污染缓存（旧逻辑遇到错误响应也会落盘，导致反复重下）；
/// 4. 兼容旧版 `sha1+扩展名` 文件：命中时直接收养进索引，无需重下。
class MediaCache {
  MediaCache._();
  static final MediaCache instance = MediaCache._();

  Directory? _dir;
  Map<String, String>? _index;
  final Map<String, Future<File>> _inflight = {};

  static const _indexName = '_index.json';

  static const _urlExtWhitelist = {
    '.mp3', '.m4a', '.aac', '.ogg', '.opus', '.wav',
    '.flac', '.amr', '.webm', '.3gp',
  };

  static const _contentTypeExt = {
    'audio/mpeg': '.mp3',
    'audio/mp3': '.mp3',
    'audio/mp4': '.m4a',
    'audio/aac': '.m4a',
    'audio/aacp': '.aac',
    'audio/x-m4a': '.m4a',
    'audio/m4a': '.m4a',
    'audio/ogg': '.ogg',
    'audio/opus': '.ogg',
    'application/ogg': '.ogg',
    'audio/wav': '.wav',
    'audio/x-wav': '.wav',
    'audio/wave': '.wav',
    'audio/flac': '.flac',
    'audio/x-flac': '.flac',
    'audio/webm': '.webm',
    'audio/amr': '.amr',
    'audio/3gpp': '.3gp',
  };

  Future<Directory> _cacheDir() async {
    final d = _dir;
    if (d != null) return d;
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'media_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  Future<Map<String, String>> _ensureIndex() async {
    final cached = _index;
    if (cached != null) return cached;
    final dir = await _cacheDir();
    final f = File(p.join(dir.path, _indexName));
    var map = <String, String>{};
    if (await f.exists()) {
      try {
        final raw = jsonDecode(await f.readAsString());
        if (raw is Map) {
          map = {
            for (final e in raw.entries)
              if (e.key is String && e.value is String) e.key as String: e.value as String,
          };
        }
      } catch (_) {
        map = {}; // 索引损坏则重建
      }
    }
    _index = map;
    return map;
  }

  Future<void> _persistIndex() async {
    final dir = _dir;
    final index = _index;
    if (dir == null || index == null) return;
    try {
      await File(p.join(dir.path, _indexName)).writeAsString(
        jsonEncode(index),
        flush: true,
      );
    } catch (_) {
      // 索引写失败不影响播放，下次重新下载即可。
    }
  }

  static String _keyOf(String url) =>
      sha1.convert(url.codeUnits).toString();

  static String? _extFromUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    var ext = path.substring(dot).toLowerCase();
    final q = ext.indexOf(RegExp(r'[^a-z0-9.]'));
    if (q >= 0) ext = ext.substring(0, q);
    if (_urlExtWhitelist.contains(ext)) return ext;
    return null;
  }

  static String? _extFromContentType(String? contentType) {
    if (contentType == null) return null;
    final base = contentType.split(';').first.trim().toLowerCase();
    if (base == 'text/html' || base.isEmpty) return null;
    return _contentTypeExt[base];
  }

  /// 按文件头魔数判定音频容器；bytes 至少 12 字节。
  static String? _extFromMagic(List<int> b) {
    bool match(int i, int v) => i < b.length && b[i] == v;
    bool asciiAt(int i, String s) {
      for (var j = 0; j < s.length; j++) {
        if (!match(i + j, s.codeUnitAt(j))) return false;
      }
      return true;
    }

    if (b.length >= 3 && asciiAt(0, 'ID3')) return '.mp3';
    if (b.length >= 4 && asciiAt(0, 'fLaC')) return '.flac';
    if (b.length >= 4 && asciiAt(0, 'OggS')) return '.ogg';
    if (b.length >= 4 && asciiAt(4, 'ftyp')) {
      // MP4 族：音频（m4a）与极少数音频 mp4 统一用 .m4a。
      return '.m4a';
    }
    if (b.length >= 12 &&
        asciiAt(0, 'RIFF') &&
        asciiAt(8, 'WAVE')) {
      return '.wav';
    }
    if (b.length >= 2 && b[0] == 0xFF) {
      // 11 位帧同步（0xFFE）= MP3；更严格的 12 位（0xFFF0）= ADTS AAC。
      if ((b[1] & 0xF6) == 0xF0) return '.aac';
      if ((b[1] & 0xE0) == 0xE0) return '.mp3';
    }
    return null;
  }

  /// 返回缓存文件；已存在直接命中，否则下载。同一 URL 并发合并。
  Future<File> ensureFile(String absoluteUrl) {
    final key = _keyOf(absoluteUrl);
    final existing = _inflight[key];
    if (existing != null) return existing;
    final fut = _download(key, absoluteUrl);
    _inflight[key] = fut;
    return fut.whenComplete(() => _inflight.remove(key));
  }

  /// 查找已缓存文件（索引 → 旧版命名），存在且非空才返回。
  Future<File?> _lookup(String url) async {
    final dir = await _cacheDir();
    final index = await _ensureIndex();
    final key = _keyOf(url);

    final named = index[url];
    if (named != null) {
      final f = File(p.join(dir.path, named));
      if (await f.exists() && await f.length() > 0) return f;
    }
    // 旧版命名：sha1 + URL 扩展名；或纯 sha1（无扩展名，收养后补扩展名）。
    final legacyExt = _extFromUrl(url) ?? '';
    final legacy = File(p.join(dir.path, '$key$legacyExt'));
    if (await legacy.exists() && await legacy.length() > 0) return legacy;
    final bare = File(p.join(dir.path, key));
    if (await bare.exists() && await bare.length() > 0) return bare;
    return null;
  }

  Future<File> _download(String key, String url) async {
    // 双重检查：进 inflight 后可能已被其他路径写入。
    final hit = await _lookup(url);
    if (hit != null) return _adoptIfNeeded(url, hit);

    final dir = await _cacheDir();
    final tmp = File(p.join(dir.path, '$key.part'));

    final dio = Dio();
    late Response<List<int>> resp;
    try {
      resp = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
    } finally {
      dio.close(force: true);
    }

    if (resp.statusCode != 200) {
      throw HttpException('媒体下载失败: HTTP ${resp.statusCode}');
    }
    final bytes = resp.data;
    if (bytes == null || bytes.isEmpty) {
      throw const HttpException('媒体内容为空');
    }
    // 网关/鉴权失败常返回 HTML 登录页，落盘后必播放失败。
    final ct = resp.headers.value(HttpHeaders.contentTypeHeader);
    if (ct != null && ct.split(';').first.trim().toLowerCase() == 'text/html') {
      throw const HttpException('媒体地址返回了 HTML 而非音频');
    }

    final ext = _extFromUrl(url) ??
        _extFromContentType(ct) ??
        _extFromMagic(bytes) ??
        '.mp3'; // 兜底：音乐消息默认按 mp3 容器交给播放器

    await tmp.writeAsBytes(bytes, flush: true);
    final target = File(p.join(dir.path, '$key$ext'));
    if (await target.exists()) await target.delete();
    await tmp.rename(target.path);

    final index = await _ensureIndex();
    index[url] = p.basename(target.path);
    await _persistIndex();
    return target;
  }

  /// 旧版缓存文件（无/错扩展名）首次命中时：按魔数补扩展名并登记索引。
  Future<File> _adoptIfNeeded(String url, File file) async {
    final index = await _ensureIndex();
    final currentExt = p.extension(file.path).toLowerCase();
    if (currentExt.isNotEmpty && index[url] == p.basename(file.path)) {
      return file;
    }
    try {
      final head = await file.openRead(0, 16).first;
      final ext = _extFromUrl(url) ?? _extFromMagic(head) ?? '.mp3';
      if (p.extension(file.path).toLowerCase() != ext) {
        // p.withoutExtension 对纯 sha1（无扩展名）原样返回，不会误裁。
        final target = File('${p.withoutExtension(file.path)}$ext');
        if (file.path != target.path) {
          if (await target.exists()) await target.delete();
          final moved = await file.rename(target.path);
          index[url] = p.basename(moved.path);
          await _persistIndex();
          return moved;
        }
      }
      index[url] = p.basename(file.path);
      await _persistIndex();
    } catch (_) {
      // 收养失败不阻塞播放。
    }
    return file;
  }

  /// 是否已缓存（用于展示"下载/播放"状态）。
  Future<bool> isCached(String absoluteUrl) async {
    if (kIsWeb) return false;
    try {
      return await _lookup(absoluteUrl) != null;
    } catch (_) {
      return false;
    }
  }
}
