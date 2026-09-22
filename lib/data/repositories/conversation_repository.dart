import '../../core/network/api_client.dart';
import '../models/models.dart';

class ConversationRepository {
  final ApiClient api;
  ConversationRepository(this.api);

  Future<List<ConversationModel>> list() async {
    final data = await api.requestDynamic('GET', '/api/conversations') as List;
    return data
        .map((e) =>
            ConversationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ConversationModel> createSingle(int targetUserId) async {
    final data = await api.post('/api/conversations/single',
        data: {'targetUserId': targetUserId}) as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  Future<ConversationModel> detail(int id) async {
    final data =
        await api.get('/api/conversations/$id') as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// 历史消息（服务端返回 seq 升序；分页游标 beforeSeq，默认 20 条）。
  Future<List<MessageModel>> history(int id,
      {int? beforeSeq, int? limit}) async {
    final data = await api.requestDynamic(
      'GET',
      '/api/conversations/$id/messages',
      queryParameters: {
        'beforeSeq': ?beforeSeq,
        'limit': ?limit,
      },
    ) as List;
    return data
        .map((e) =>
            MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 已读上报（seq 不传表示读到最新；服务端同时向其他成员扇出 ACK_READ）。
  Future<void> markRead(int id, {int? seq}) => api.post(
        '/api/conversations/$id/read',
        data: {'seq': ?seq},
      );

  Future<ConversationModel> setPrivate(int id, bool privateFlag) async {
    final data = await api.post('/api/conversations/$id/private',
        data: {'privateFlag': privateFlag}) as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// 免打扰开关。
  Future<ConversationModel> mute(int id, bool muted) async {
    final data = await api.post('/api/conversations/$id/mute',
        data: {'muted': muted}) as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// 置顶 / 取消置顶。
  Future<ConversationModel> pin(int id, bool pinned) async {
    final data = await api.post('/api/conversations/$id/pin',
        data: {'pinned': pinned}) as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// 删除会话（旧接口，后端等同 terminate）。
  Future<void> delete(int id) => api.delete('/api/conversations/$id');

  /// 终止会话（#4）：双方软删除，会话不再显示，历史保留用于审计。仅单聊。
  Future<void> terminate(int id) =>
      api.post('/api/conversations/$id/terminate');

  /// #11 隐藏已解散群聊：群解散后，非群主成员可从此处移除会话（仅自己不可见）。
  Future<void> hide(int id) => api.post('/api/conversations/$id/hide');

  /// #18 撤回消息：仅本人发送且 2 分钟内可撤回。
  Future<void> recall(int messageId) =>
      api.post('/api/messages/$messageId/recall');
}
