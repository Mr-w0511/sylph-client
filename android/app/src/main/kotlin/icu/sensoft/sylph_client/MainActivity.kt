package icu.sensoft.sylph_client

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 通话音频路由原生通道：
 * flutter_webrtc 的 Helper.setSpeakerphoneOn 在部分国产 ROM 上
 * 会被音频焦点/模式切换覆盖，导致免提打不开或声音极小。
 * 这里直接操作 AudioManager：MODE_IN_COMMUNICATION + setSpeakerphoneOn，
 * 并在免提时把 VOICE_CALL 音量拉满；通话结束恢复 MODE_NORMAL。
 */
class MainActivity : FlutterActivity() {

    private val channelName = "sylph/audio_route"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val am = applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                try {
                    when (call.method) {
                        "setSpeaker" -> {
                            val on = call.argument<Boolean>("on") ?: false
                            applySpeaker(am, on)
                            result.success(am.isSpeakerphoneOn)
                        }
                        "resetAudioMode" -> {
                            try {
                                am.stopBluetoothSco()
                            } catch (_: Exception) {
                            }
                            am.isBluetoothScoOn = false
                            am.isSpeakerphoneOn = false
                            am.mode = AudioManager.MODE_NORMAL
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("AUDIO_ROUTE_ERROR", e.message, null)
                }
            }
    }

    private fun applySpeaker(am: AudioManager, on: Boolean) {
        // 语音通话必须在 MODE_IN_COMMUNICATION 下，扬声器切换才在所有机型生效。
        am.mode = AudioManager.MODE_IN_COMMUNICATION
        // 先断开蓝牙 SCO，避免输出仍走已连接的蓝牙设备。
        try {
            am.stopBluetoothSco()
        } catch (_: Exception) {
        }
        am.isBluetoothScoOn = false
        am.isSpeakerphoneOn = on
        // 部分 ROM 需要重复设置一次才能固化。
        am.isSpeakerphoneOn = on
        if (on) {
            // 免提时拉满通话音量，解决"声音太小"。
            try {
                val max = am.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
                val cur = am.getStreamVolume(AudioManager.STREAM_VOICE_CALL)
                if (cur < max) {
                    am.setStreamVolume(AudioManager.STREAM_VOICE_CALL, max, 0)
                }
            } catch (_: Exception) {
            }
        }
    }
}
