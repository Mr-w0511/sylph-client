import 'dart:convert';

/// 引用回复数据（被引用消息的快照）。
///
/// 承载方式（后端 mediaMeta 为不透明 JSON，全链路原样透传，无需改服务端）：
/// - 普通 TEXT 消息：`mediaMeta = {"replyTo": {..本对象..}}`；
/// - 端到端加密消息：为避免摘要以明文经过服务端，回复信息并入**明文信封**
///   整体加密：明文 = `{"text":"...","replyTo":{..}}`，mediaMeta 仍是 E2EE 头。
class ReplyQuoteData {
  /// 被引用消息的 msgId（点击引用块定位用）。
  final String msgId;

  /// 被引用消息发送者 id。
  final int senderId;

  /// 发送者昵称快照（群聊为群昵称/昵称；引用自己消息时本地语言化为"你"）。
  final String nickname;

  /// 被引用消息类型：TEXT/IMAGE/VOICE/VIDEO/FILE/MUSIC/LOCATION/CALL。
  final String type;

  /// 引用摘要：TEXT=正文截断；其他类型=类型占位文案。
  final String snippet;

  const ReplyQuoteData({
    required this.msgId,
    required this.senderId,
    required this.nickname,
    required this.type,
    required this.snippet,
  });

  Map<String, dynamic> toJson() => {
        'msgId': msgId,
        'senderId': senderId,
        'nickname': nickname,
        'type': type,
        'snippet': snippet,
      };

  factory ReplyQuoteData.fromJson(Map<String, dynamic> j) => ReplyQuoteData(
        msgId: j['msgId'] as String? ?? '',
        senderId: (j['senderId'] as num?)?.toInt() ?? 0,
        nickname: j['nickname'] as String? ?? '',
        type: j['type'] as String? ?? 'TEXT',
        snippet: j['snippet'] as String? ?? '',
      );
}

/// TEXT 摘要最大长度（超出单行省略，UI 层还会再做 ellipsis）。
const int _kMaxSnippetLength = 60;

/// 生成引用摘要：TEXT 截取正文前 60 字；非文本类型由 [typeLabel] 给出占位
/// （如 `[图片]`/`[语音]`，由 UI 层按 l10n 提供，保持 core 层不依赖文案）。
String buildQuoteSnippet(
  String type,
  String? text,
  String Function(String type) typeLabel,
) {
  if (type == 'TEXT') {
    final t = (text ?? '').trim();
    if (t.isEmpty) return typeLabel('TEXT');
    return t.length > _kMaxSnippetLength
        ? '${t.substring(0, _kMaxSnippetLength)}…'
        : t;
  }
  return typeLabel(type);
}

/// 普通会话：从消息 mediaMeta 中读取引用块；无则返回 null。
/// 任何解析失败一律返回 null（脏数据不影响消息展示）。
ReplyQuoteData? readReplyFromMediaMeta(String? mediaMeta) {
  if (mediaMeta == null || mediaMeta.isEmpty) return null;
  try {
    final root = jsonDecode(mediaMeta);
    if (root is Map<String, dynamic>) {
      final r = root['replyTo'];
      if (r is Map<String, dynamic>) return ReplyQuoteData.fromJson(r);
    }
  } catch (_) {}
  return null;
}

/// 普通会话：构造写入 mediaMeta 的 JSON 字符串；无引用返回 null。
String? buildReplyMediaMeta(ReplyQuoteData? reply) {
  if (reply == null) return null;
  return jsonEncode({'replyTo': reply.toJson()});
}

/// 加密会话：把正文（+引用）组装为待加密明文。
/// 无引用时直接返回原文，保持与历史版本完全一致。
String buildEncryptedPlaintext(String text, ReplyQuoteData? reply) {
  if (reply == null) return text;
  return jsonEncode({'text': text, 'replyTo': reply.toJson()});
}

/// 加密消息解密后的解析结果。
typedef PlainEnvelope = ({String text, ReplyQuoteData? reply});

/// 解析解密明文：
/// - 信封格式 `{"text": "...", "replyTo": {...}}` → 拆出正文与引用；
/// - 其他任何内容（历史纯文本、脏数据）→ 整体作为正文、无引用。
PlainEnvelope parsePlainEnvelope(String raw) {
  if (raw.isEmpty || raw.codeUnitAt(0) != 0x7B /* '{' */) {
    return (text: raw, reply: null);
  }
  try {
    final j = jsonDecode(raw);
    if (j is Map<String, dynamic> && j['text'] is String) {
      final r = j['replyTo'];
      return (
        text: j['text'] as String,
        reply: r is Map<String, dynamic>
            ? ReplyQuoteData.fromJson(r)
            : null,
      );
    }
  } catch (_) {}
  return (text: raw, reply: null);
}
