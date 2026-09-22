/// 服务端 WS 信封（与后端 WsFrame / WsType 对齐）：
/// {type,msgId,convId,seq,to,ts,data}
class WsFrame {
  final String type;
  final String? msgId;
  final int? convId;
  final int? seq;
  final int? to;
  final int? ts;
  final Object? data;

  const WsFrame({
    required this.type,
    this.msgId,
    this.convId,
    this.seq,
    this.to,
    this.ts,
    this.data,
  });

  factory WsFrame.fromJson(Map<String, dynamic> json) {
    return WsFrame(
      type: json['type'] as String,
      msgId: json['msgId'] as String?,
      convId: (json['convId'] as num?)?.toInt(),
      seq: (json['seq'] as num?)?.toInt(),
      to: (json['to'] as num?)?.toInt(),
      ts: (json['ts'] as num?)?.toInt(),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (msgId != null) 'msgId': msgId,
      if (convId != null) 'convId': convId,
      if (seq != null) 'seq': seq,
      if (to != null) 'to': to,
      'ts': ts ?? DateTime.now().millisecondsSinceEpoch,
      if (data != null) 'data': data,
    };
  }

  /// 业务 data 转 Map。
  Map<String, dynamic> get dataMap =>
      (data is Map) ? Map<String, dynamic>.from(data as Map) : const {};

  @override
  String toString() => 'WsFrame($type, msgId=$msgId, convId=$convId, seq=$seq)';
}

/// 帧类型常量（与后端 icu.sensoft.backend.modules.ws.protocol.WsType 一致）。
class WsType {
  static const auth = 'AUTH';
  static const authOk = 'AUTH_OK';
  static const ping = 'PING';
  static const pong = 'PONG';
  static const error = 'ERROR';

  static const msgSend = 'MSG_SEND';
  static const msgDeliver = 'MSG_DELIVER';
  static const msgAck = 'MSG_ACK';
  static const ackDelivered = 'ACK_DELIVERED';
  static const ackRead = 'ACK_READ';

  static const syncReq = 'SYNC_REQ';
  static const syncResp = 'SYNC_RESP';

  static const groupEvent = 'GROUP_EVENT';
  static const friendEvent = 'FRIEND_EVENT';
  static const msgEvent = 'MSG_EVENT';
  /// #11 一对一语音通话信令中继。
  static const callSignal = 'CALL_SIGNAL';
  static const presence = 'PRESENCE';
  static const presenceSub = 'PRESENCE_SUB';
  static const typing = 'TYPING';
}

enum WsStatus { connecting, open, reconnecting, disconnected }
