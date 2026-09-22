# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-dontwarn io.flutter.embedding.**

# ML Kit 扫码（mobile_scanner 依赖）：
# 插件 consumer 规则为单层 com.google.mlkit.*，R8 full mode 会裁掉
# ComponentRegistrar 导致 BarcodeScanning.getClient() 内部空指针。
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.libraries.barhopper.** { *; }
-keep class com.google.photos.** { *; }

# google_mlkit_barcode_scanning / image_picker 等插件自身类
-keep class com.google.mlkit.vision.barcode.** { *; }

# #11 flutter_webrtc：保留 JNI/反射访问的原生 WebRTC 与通道类。
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class flutter.webrtc.** { *; }
-dontwarn org.webrtc.**
-dontwarn com.cloudwebrtc.webrtc.**
