import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';
import 'ws_frame.dart';

/// WebSocket 长连接客户端。
/// - 握手 query 参数 token（浏览器无法设置 Authorization 头，与后端
///   WsAuthInterceptor 对齐）；
/// - 服务端在建连后主动下发 AUTH_OK，无需客户端再发 AUTH；
/// - 断线指数退避自动重连（0.5s→1s→…→15s 封顶）；
/// - 心跳：服务端 90s 空闲回收，客户端每 25s 发 PING，服务端回 PONG；
/// - 重连成功后触发 [onReconnected]（增量同步 + 待发队列补发）。
class WsClient {
  static const _heartbeat = Duration(seconds: 25);
  static const _initialBackoff = Duration(milliseconds: 500);
  static const _maxBackoff = Duration(seconds: 15);
  /// PING 发出后等待 PONG 的最长时间；超时判定 TCP 半开假死并强制重连。
  static const _pongTimeout = Duration(seconds: 5);

  final String Function() tokenProvider;
  final void Function()? onReconnected;

  /// 致命关闭（设备被远程下线 4001 / 账号停用 4003 / 握手 401）：
  /// 不再重连，交由上层清登录态回到登录页。
  final void Function(int? closeCode)? onFatalClose;
  final _uuid = const Uuid();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeatTimer;
  Timer? _pongWatchdog;
  Timer? _backoffTimer;

  WsStatus _status = WsStatus.disconnected;
  WsStatus get status => _status;

  bool _active = false;
  Duration _backoff = _initialBackoff;
  int _generation = 0;

  final _statusCtrl = StreamController<WsStatus>.broadcast();
  final _framesCtrl = StreamController<WsFrame>.broadcast();

  Stream<WsStatus> get statusStream => _statusCtrl.stream;
  Stream<WsFrame> get frames => _framesCtrl.stream;
  bool get isOpen => _status == WsStatus.open;

  /// 服务端以策略码关闭（4001 设备吊销 / 4003 账号停用）：立即停止一切重连。
  static const _fatalCloseCodes = [4001, 4003];

  WsClient({
    required this.tokenProvider,
    this.onReconnected,
    this.onFatalClose,
  });

  Stream<WsFrame> framesOf(String type) =>
      frames.where((f) => f.type == type);

  Stream<WsFrame> framesOfConv(String type, int convId) => frames
      .where((f) => f.type == type && f.convId == convId);

  void start() {
    if (_active) return;
    _active = true;
    _backoff = _initialBackoff;
    _setStatus(WsStatus.connecting);
    _connect();
  }

  /// 取消退避等待，立即发起一次连接（App 回前台时调用，缩短重连耗时）。
  Future<void> reconnectNow() => forceReconnect(onlyIfNotOpen: true);

  /// 强制重建连接，即使当前状态仍为 open（TCP 半开假死 / App 回前台主动探活）。
  Future<void> forceReconnect({bool onlyIfNotOpen = false}) async {
    if (!_active) return;
    if (onlyIfNotOpen && isOpen) return;
    _heartbeatTimer?.cancel();
    _pongWatchdog?.cancel();
    _backoffTimer?.cancel();
    _generation++;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _backoff = _initialBackoff;
    _setStatus(WsStatus.connecting);
    _connect();
  }

  Future<void> stop() async {
    _active = false;
    _backoffTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pongWatchdog?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setStatus(WsStatus.disconnected);
  }

  void _setStatus(WsStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }

  void _connect() {
    if (!_active) return;
    final gen = ++_generation;
    final token = tokenProvider();
    final uri = Uri.parse('${Env.wsBase}?token=${Uri.encodeComponent(token)}');
    WebSocketChannel ch;
    try {
      ch = WebSocketChannel.connect(uri);
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    _channel = ch;

    ch.ready.then((_) {
      if (gen != _generation || !_active) return;
      _setStatus(WsStatus.open);
      _backoff = _initialBackoff;
      _startHeartbeat();
      onReconnected?.call();
    }).catchError((Object e) {
      if (gen != _generation || !_active) return;
      // 握手被服务端以 HTTP 401 拒绝（token 失效）：致命，不重连。
      if ('$e'.contains('401')) {
        _handleFatal(null);
      } else {
        _scheduleReconnect();
      }
    });

    _sub = ch.stream.listen(
      (event) {
        try {
          final json = jsonDecode(event as String) as Map<String, dynamic>;
          final frame = WsFrame.fromJson(json);
          if (frame.type == WsType.pong) {
            // 收到 PONG：连接存活，取消看门狗。
            _pongWatchdog?.cancel();
            return;
          }
          _framesCtrl.add(frame);
        } catch (_) {
          // 忽略无法解析的帧。
        }
      },
      onError: (Object _) {
        if (gen == _generation) _scheduleReconnect();
      },
      onDone: () {
        if (gen != _generation || !_active) return;
        final code = _channel?.closeCode;
        if (code != null && _fatalCloseCodes.contains(code)) {
          _handleFatal(code);
        } else {
          _scheduleReconnect();
        }
      },
      cancelOnError: true,
    );
  }

  /// 致命关闭处理：停心跳/退避，标记失活并通知上层（回登录页）。
  void _handleFatal(int? code) {
    _active = false;
    _heartbeatTimer?.cancel();
    _backoffTimer?.cancel();
    _setStatus(WsStatus.disconnected);
    onFatalClose?.call(code);
  }

  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    _pongWatchdog?.cancel();
    if (!_active) return;
    _setStatus(WsStatus.reconnecting);
    _backoffTimer?.cancel();
    _backoffTimer = Timer(_backoff, () {
      _setStatus(WsStatus.connecting);
      _connect();
    });
    final next = _backoff * 2;
    _backoff = next > _maxBackoff ? _maxBackoff : next;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _pongWatchdog?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) {
      if (!isOpen) return;
      send(WsFrame(type: WsType.ping, msgId: _uuid.v4()));
      // PONG 看门狗：5 秒内无响应视为 TCP 半开假死（状态仍 open 但链路已断），
      // 立即强制重建，避免回前台后等待数十秒 TCP 超时。
      _pongWatchdog?.cancel();
      _pongWatchdog = Timer(_pongTimeout, () {
        if (_active) {
          forceReconnect();
        }
      });
    });
  }

  /// 发送一帧（未连接时由上层待发队列负责补发，这里直接返回 false）。
  bool send(WsFrame frame) {
    if (!isOpen) return false;
    try {
      _channel?.sink.add(jsonEncode(frame.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    stop();
    _statusCtrl.close();
    _framesCtrl.close();
  }
}
