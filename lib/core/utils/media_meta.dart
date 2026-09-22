import 'dart:convert';

class MediaMetaInfo {
  final String? name;
  final int? size;

  /// E2EE：随机 nonce(base64)、发送方身份公钥、使用的一次性公钥、对端设备。
  final String? nonce;
  final String? identityKey;
  final String? oneTimeKey;
  final String? deviceId;

  const MediaMetaInfo({
    this.name,
    this.size,
    this.nonce,
    this.identityKey,
    this.oneTimeKey,
    this.deviceId,
  });

  factory MediaMetaInfo.parse(String? raw) {
    if (raw == null || raw.isEmpty) return const MediaMetaInfo();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return MediaMetaInfo(
        name: j['name'] as String?,
        size: (j['size'] as num?)?.toInt(),
        nonce: j['nonce'] as String?,
        identityKey: j['ik'] as String?,
        oneTimeKey: j['otk'] as String?,
        deviceId: j['dev'] as String?,
      );
    } catch (_) {
      return const MediaMetaInfo();
    }
  }

  static String imageMeta({required String name, required int size}) =>
      jsonEncode({'name': name, 'size': size});

  static String humanSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
