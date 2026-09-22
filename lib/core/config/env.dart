/// 运行环境配置：
///   flutter build web --dart-define=API_BASE=https://api.example.com \
///                     --dart-define=WS_BASE=wss://api.example.com/ws
/// 默认指向本机后端（dev 联调）。
class Env {
  const Env._();

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://113.44.222.195:8080',
  );

  static const String wsBase = String.fromEnvironment(
    'WS_BASE',
    defaultValue: 'ws://113.44.222.195:8080/ws',
  );

  /// 后端返回的媒体地址为 "/media/..." 相对路径，拼上 API origin。
  static String mediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final uri = Uri.parse(apiBase);
    final prefix = '${uri.scheme}://${uri.host}'
        '${uri.hasPort ? ':${uri.port}' : ''}';
    return url.startsWith('/') ? '$prefix$url' : '$prefix/$url';
  }
}
