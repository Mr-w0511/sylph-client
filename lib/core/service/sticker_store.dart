// 收藏表情：图片贴纸（app documents/stickers 目录）+ 文本表情（纯字符串）。
//
// 持久化策略（修复"重进后收藏消失"）：
// 1. 索引只存【文件名】，绝不存绝对路径——iOS 文档目录在备份恢复/系统版本升级
//    后绝对路径会变化，旧版存绝对路径导致 File.exists 失败、被 list() 清空；
// 2. SharedPreferences 索引 + 目录内 _index.json 双保险；
// 3. 每次 list() 扫描目录自愈：prefs 丢失时用磁盘文件重建索引，
//    索引里有但磁盘没有的条目剔除。
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StickerStore {
  StickerStore._();

  static const _keyIndex = 'stickers.index.v1';
  static const _keyEmojis = 'stickers.emojis.v1';
  static const _indexFile = '_index.json';

  static Directory? _dirCache;

  static Future<Directory> _ensureDir() async {
    final cached = _dirCache;
    if (cached != null) return cached;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'stickers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dirCache = dir;
    return dir;
  }

  /// 贴纸【绝对路径】列表（按添加顺序）。
  static Future<List<String>> list() async {
    final dir = await _ensureDir();
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getStringList(_keyIndex) ?? const <String>[];
    // prefs 丢失（重装/清数据）时用目录内 JSON 索引恢复。
    if (raw.isEmpty) {
      final restored = await _readJsonIndex(dir);
      if (restored != null && restored.isNotEmpty) raw = restored;
    }

    // 归一化：旧版可能存的是绝对路径，统一取文件名；去重保序。
    final names = <String>[];
    final seen = <String>{};
    for (final e in raw) {
      final name = p.basename(e);
      if (name.isNotEmpty &&
          name != _indexFile &&
          seen.add(name)) {
        names.add(name);
      }
    }

    // 磁盘自愈：扫出全部贴纸文件（prefs 被清/重装恢复后仍能找回）。
    final onDisk = <String>{};
    try {
      await for (final f in dir.list()) {
        if (f is File) {
          final name = p.basename(f.path);
          if (name != _indexFile && !name.startsWith('.')) {
            onDisk.add(name);
          }
        }
      }
    } catch (_) {}

    // 索引顺序优先；磁盘有但索引没有的（含 JSON 恢复）按文件名排序追加。
    final alive = names.where(onDisk.contains).toList();
    final orphans = onDisk.difference(alive.toSet()).toList()..sort();
    alive.addAll(orphans);

    if (alive.length != names.length ||
        alive.any((n) => !raw.contains(n))) {
      await prefs.setStringList(_keyIndex, alive);
    }
    await _writeJsonIndex(dir, alive);
    return alive.map((n) => p.join(dir.path, n)).toList();
  }

  static Future<void> _writeJsonIndex(Directory dir, List<String> names) async {
    try {
      await File(p.join(dir.path, _indexFile)).writeAsString(
        jsonEncode({'version': 1, 'names': names}),
        flush: true,
      );
    } catch (_) {
      // 双保险写失败忽略，prefs + 目录扫描仍可恢复。
    }
  }

  /// 从 JSON 索引恢复（prefs 与磁盘不一致时的兜底）。
  static Future<List<String>?> _readJsonIndex(Directory dir) async {
    try {
      final f = File(p.join(dir.path, _indexFile));
      if (!await f.exists()) return null;
      final m = jsonDecode(await f.readAsString());
      if (m is Map && m['names'] is List) {
        return (m['names'] as List).whereType<String>().toList();
      }
    } catch (_) {}
    return null;
  }

  /// 把图片字节保存进贴纸库，返回新文件绝对路径。
  static Future<String> addFromBytes(
    List<int> bytes, {
    String ext = 'png',
  }) async {
    final dir = await _ensureDir();
    final cleanExt = ext.startsWith('.') ? ext.substring(1) : ext;
    final name =
        'sticker_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
    final f = File(p.join(dir.path, name));
    await f.writeAsBytes(bytes, flush: true);

    final prefs = await SharedPreferences.getInstance();
    final all = _normalizeNames(prefs.getStringList(_keyIndex) ?? <String>[]);
    all.add(name);
    await prefs.setStringList(_keyIndex, all);
    await _writeJsonIndex(dir, all);
    return f.path;
  }

  /// 复制一个已有本地文件进贴纸库（相册缓存路径可能被清理）。
  static Future<String> addFromFile(File src) async {
    return addFromBytes(
      await src.readAsBytes(),
      ext: p.extension(src.path).isEmpty ? 'png' : p.extension(src.path),
    );
  }

  static Future<void> remove(String pathOrName) async {
    final name = p.basename(pathOrName);
    final dir = await _ensureDir();
    final prefs = await SharedPreferences.getInstance();
    final all = _normalizeNames(prefs.getStringList(_keyIndex) ?? <String>[]);
    all.remove(name);
    await prefs.setStringList(_keyIndex, all);
    await _writeJsonIndex(dir, all);
    try {
      final f = File(p.join(dir.path, name));
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static List<String> _normalizeNames(List<String> raw) {
    final out = <String>[];
    final seen = <String>{};
    for (final e in raw) {
      final name = p.basename(e);
      if (name.isNotEmpty && name != _indexFile && seen.add(name)) {
        out.add(name);
      }
    }
    return out;
  }

  // ---------------- 文本表情（emoji/颜文字）----------------

  /// 收藏的文本表情，保序去重。
  static Future<List<String>> emojis() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyEmojis) ?? const <String>[];
    final out = <String>[];
    final seen = <String>{};
    for (final e in raw) {
      if (e.trim().isNotEmpty && seen.add(e)) out.add(e);
    }
    if (out.length != raw.length) {
      await prefs.setStringList(_keyEmojis, out);
    }
    return out;
  }

  /// 添加文本表情；返回 false 表示已存在。
  static Future<bool> addEmoji(String text) async {
    final t = text.trim();
    if (t.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_keyEmojis) ?? <String>[];
    if (all.contains(t)) return false;
    all.add(t);
    await prefs.setStringList(_keyEmojis, all);
    return true;
  }

  static Future<void> removeEmoji(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_keyEmojis) ?? <String>[];
    all.remove(text);
    await prefs.setStringList(_keyEmojis, all);
  }
}
