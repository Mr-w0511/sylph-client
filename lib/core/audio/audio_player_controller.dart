import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:flutter/services.dart' show PlatformException;

import '../utils/media_cache.dart';

/// 音频条目类型：语音消息与音乐互斥播放（同一时刻只有一个在响）。
enum AudioItemKind { voice, music }

class AudioPlayItem {
  /// 消息唯一 id（msgId），用于气泡判断"当前是不是我在播"。
  final String id;
  final String url;
  final AudioItemKind kind;

  const AudioPlayItem({
    required this.id,
    required this.url,
    required this.kind,
  });
}

/// 全局单例播放器：音乐/语音共用一个 AudioPlayer。
/// - 首次播放先下载到本地缓存（修复在线 URL 在部分机型点击无反应），
///   缓存命中后秒开；
/// - 提供播放/暂停/跳转/进度流，气泡只负责渲染与调用；
/// - 离开聊天页时调用 [stop]。
class AudioPlayerController extends ChangeNotifier {
  AudioPlayerController._() {
    _player.onPlayerStateChanged.listen((s) {
      _playing = s == PlayerState.playing;
      notifyListeners();
    });
    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) {
      _playing = false;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  static final AudioPlayerController instance = AudioPlayerController._();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayItem? current;
  bool _playing = false;
  bool _loading = false;
  String? _errorId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool get isPlaying => _playing;
  bool get isLoading => _loading;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorId => _errorId;

  bool isCurrent(String id) => current?.id == id;
  bool isItemPlaying(String id) => current?.id == id && _playing;
  bool isItemLoading(String id) => current?.id == id && _loading;

  /// 切换播放/暂停；点另一条则切换到新条目并从头播放。
  Future<void> toggle(AudioPlayItem item) async {
    _errorId = null;
    try {
      if (current?.id == item.id) {
        if (_playing) {
          await _player.pause();
        } else {
          await _player.resume();
        }
        return;
      }
      await _start(item);
    } catch (e) {
      _loading = false;
      _errorId = item.id;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _start(AudioPlayItem item) async {
    await _player.stop();
    current = item;
    _position = Duration.zero;
    _duration = Duration.zero;
    _loading = true;
    notifyListeners();
    try {
      if (kIsWeb) {
        await _player.play(UrlSource(item.url));
      } else {
        final file = await MediaCache.instance.ensureFile(item.url);
        // 下载期间用户可能又点了别的条目。
        if (current?.id != item.id) return;
        await _playLocalWithFallback(item.url, file.path);
      }
    } finally {
      if (current?.id == item.id) _loading = false;
      notifyListeners();
    }
  }

  /// 本地文件播放带降级 fallback：
  /// 1. 先尝试 DeviceFileSource（缓存层已按 Content-Type/魔数补好正确扩展名）；
  /// 2. 失败则降级为 UrlSource 直接播远程 URL。
  /// 注意：绝不能在此 rename 缓存文件——会导致缓存索引与磁盘不一致、反复重下。
  Future<void> _playLocalWithFallback(String url, String path) async {
    try {
      await _player.play(DeviceFileSource(path));
    } on PlatformException catch (_) {
      await _player.play(UrlSource(url));
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    current = null;
    _playing = false;
    _loading = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  /// 仅当指定条目正在播放/加载时才停止（离开聊天页用）。
  Future<void> stopItem(String id) async {
    if (current?.id == id) await stop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
