import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 通话音频路由原生通道（Android 实现于 MainActivity）。
/// - [setSpeaker]：直接操作 AudioManager（MODE_IN_COMMUNICATION +
///   setSpeakerphoneOn + 免提拉满 VOICE_CALL 音量），规避 flutter_webrtc
///   Helper.setSpeakerphoneOn 在国产 ROM 上被音频焦点覆盖的问题；
/// - [resetAudioMode]：通话结束恢复 MODE_NORMAL，避免后续音乐播放异常。
///
/// iOS / 通道不可用时所有方法静默失败，由调用方回退到 flutter_webrtc Helper。
class AudioRouteChannel {
  AudioRouteChannel._();

  static final AudioRouteChannel instance = AudioRouteChannel._();

  static const _channel = MethodChannel('sylph/audio_route');

  /// 切换扬声器；返回系统确认后的真实状态，通道不可用/失败返回 null。
  Future<bool?> setSpeaker(bool on) async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<bool>('setSpeaker', {'on': on});
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 通话结束恢复普通音频模式。
  Future<void> resetAudioMode() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('resetAudioMode');
    } catch (_) {
      // 通道不可用忽略，交给系统自行恢复。
    }
  }
}
