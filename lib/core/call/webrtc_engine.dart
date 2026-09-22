import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'audio_route.dart';

/// 一对一声音/视频通话 WebRTC 封装：trickle ICE、Opus 优先。
/// 呼叫方与被叫各持一个实例；SDP/候选通过 CallController 的信令通道交换。
class WebRtcAudioEngine {
  WebRtcAudioEngine({this.video = false});

  /// true=视频通话（采集摄像头并在 SDP 中协商视频轨）。
  final bool video;

  rtc.RTCPeerConnection? _pc;
  rtc.MediaStream? _localStream;
  bool _disposed = false;

  /// 本地采集流（视频通话时供 UI 渲染小窗）。
  rtc.MediaStream? get localStream => _localStream;

  /// 远端音轨到达（音频由 WebRTC 自动播放，无需渲染器）。
  void Function(rtc.MediaStream stream)? onRemoteStream;
  void Function(rtc.RTCIceCandidate candidate)? onLocalCandidate;
  void Function()? onConnected;
  void Function()? onFailed;

  bool get isWeb => kIsWeb;

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    try {
      await _pc?.dispose();
    } catch (_) {}
    _localStream = null;
    _pc = null;
  }

  Future<void> init(
      Future<List<Map<String, dynamic>>> Function() iceLoader) async {
    List<Map<String, dynamic>> servers;
    try {
      servers = await iceLoader();
    } catch (_) {
      servers = const [];
    }
    _pc = await rtc.createPeerConnection(
      {
        'iceServers': [
          for (final e in servers)
            {
              'urls': e['urls'],
              if (e['username'] != null) 'username': e['username'],
              if (e['credential'] != null) 'credential': e['credential'],
            },
        ],
        'iceCandidatePoolSize': 4,
        'sdpSemantics': 'unified-plan',
      },
      const {},
    );

    _localStream = await rtc.navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });
    // 切到语音通信音频模式（MODE_IN_COMMUNICATION + VOICE_CALL 流）：
    // 大幅提升听筒/扬声器两路音量差异，并让部分国产 ROM 的音频路由生效。
    if (!kIsWeb) {
      try {
        await rtc.Helper.setAndroidAudioConfiguration(
          rtc.AndroidAudioConfiguration.communication,
        );
      } catch (_) {}
    }
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onIceCandidate = (c) => onLocalCandidate?.call(c);
    _pc!.onIceConnectionState = (state) {
      debugPrint('WebRTC ICE state: $state');
      if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == rtc.RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onConnected?.call();
      } else if (state ==
          rtc.RTCIceConnectionState.RTCIceConnectionStateFailed) {
        onFailed?.call();
      }
      // disconnected：暂态（切扬声器/audio route 易瞬时触发），
      // 不立即终止，等待 WebRTC 自动重连；真失败走 Failed 分支。
    };
    _pc!.onTrack = (event) {
      final streams = event.streams;
      if (streams.isNotEmpty) onRemoteStream?.call(streams.first);
    };
  }

  /// 麦克风开关。
  Future<void> setMicEnabled(bool enabled) async {
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = enabled;
    }
  }

  /// 摄像头画面开关（关闭后对端看到黑屏，但不释放设备）。
  Future<void> setVideoEnabled(bool enabled) async {
    for (final t in _localStream?.getVideoTracks() ?? const []) {
      t.enabled = enabled;
    }
  }

  /// 前后摄像头切换。
  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const [];
    if (tracks.isEmpty) return;
    try {
      await rtc.Helper.switchCamera(tracks.first);
    } catch (e) {
      debugPrint('switchCamera error: $e');
    }
  }

  /// 扬声器/听筒切换（仅移动端生效）。
  /// 优先走原生 AudioManager 通道（国产 ROM 可靠），不可用时回退 webrtc Helper。
  Future<bool> setSpeakerphone(bool on) async {
    if (kIsWeb) return on;
    final native = await AudioRouteChannel.instance.setSpeaker(on);
    if (native != null) return native;
    try {
      await rtc.Helper.setSpeakerphoneOn(on);
    } catch (_) {}
    return on;
  }

  /// 应用音频路由（true=扬声器，false=听筒）。
  /// 部分机型首次调用会被系统音频焦点/模式切换覆盖，采用
  /// 0/350/1000ms 三次补偿，确保免提在所有 ROM 上真正生效。
  Future<void> applyAudioRoute(bool speakerOn) async {
    if (kIsWeb) return;
    await setSpeakerphone(speakerOn);
    for (final delay in const [350, 1000]) {
      Timer(Duration(milliseconds: delay), () async {
        if (_disposed) return;
        await setSpeakerphone(speakerOn);
      });
    }
  }

  /// 通话结束：恢复普通音频模式，避免 MODE_IN_COMMUNICATION
  /// 残留导致后续音乐播放无声/走听筒。
  Future<void> resetAudioMode() async {
    if (kIsWeb) return;
    await AudioRouteChannel.instance.resetAudioMode();
    try {
      await rtc.Helper.setSpeakerphoneOn(false);
    } catch (_) {}
  }

  Future<rtc.RTCSessionDescription> createOffer() async {
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': video,
    });
    await _pc!.setLocalDescription(offer);
    return offer;
  }

  Future<rtc.RTCSessionDescription> createAnswer() async {
    final answer = await _pc!.createAnswer({});
    await _pc!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteSdp(String sdp, String type) =>
      _pc!.setRemoteDescription(rtc.RTCSessionDescription(sdp, type));

  Future<void> addRemoteCandidate(Map<String, dynamic> c) {
    return _pc!.addCandidate(rtc.RTCIceCandidate(
      c['candidate'] as String?,
      c['sdpMid'] as String?,
      (c['sdpMLineIndex'] as num?)?.toInt(),
    ));
  }
}
