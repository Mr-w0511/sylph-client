import '../../core/network/api_client.dart';
import '../models/models.dart';

List<T> _listOf<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
    (data as List? ?? const [])
        .map((e) => f(Map<String, dynamic>.from(e as Map)))
        .toList();

/// 好友关系链：/api/friends/**
class SocialRepository {
  final ApiClient api;
  SocialRepository(this.api);

  Future<List<FriendView>> friends() async =>
      _listOf(await api.requestDynamic('GET', '/api/friends'),
          FriendView.fromJson);

  /// #16 通讯录黑名单。
  Future<List<FriendView>> blockedList() async =>
      _listOf(await api.requestDynamic('GET', '/api/friends/blocked'),
          FriendView.fromJson);

  /// 搜索用户（带 relation 标记）。
  Future<List<UserBrief>> search(String keyword, {int limit = 30}) async =>
      _listOf(
        await api.requestDynamic('GET', '/api/friends/search',
            queryParameters: {'keyword': keyword, 'limit': limit}),
        UserBrief.fromJson,
      );

  /// 二维码 token 解析用户。
  Future<UserBrief> resolveUser(String token) async => UserBrief.fromJson(
      await api.get('/api/friends/resolve', query: {'token': token})
          as Map<String, dynamic>);

  Future<({String token, String content})> myQrcode() async {
    final d = await api.get('/api/friends/qrcode') as Map<String, dynamic>;
    return (
      token: d['token'] as String? ?? '',
      content: d['content'] as String? ?? '',
    );
  }

  Future<({String token, String content})> resetQrcode() async {
    final d =
        await api.post('/api/friends/qrcode/reset') as Map<String, dynamic>;
    return (
      token: d['token'] as String? ?? '',
      content: d['content'] as String? ?? '',
    );
  }

  Future<List<FriendRequestModel>> incomingRequests() async => _listOf(
      await api.requestDynamic('GET', '/api/friends/requests/incoming'),
      FriendRequestModel.fromJson);

  Future<List<FriendRequestModel>> outgoingRequests() async => _listOf(
      await api.requestDynamic('GET', '/api/friends/requests/outgoing'),
      FriendRequestModel.fromJson);

  Future<void> sendRequest({
    int? targetUserId,
    String? targetUid,
    String? token,
    String? message,
  }) =>
      api.post('/api/friends/requests', data: {
        'targetUserId': ?targetUserId,
        'targetUid': ?targetUid,
        'token': ?token,
        'message': ?message,
      });

  Future<void> acceptRequest(int id) =>
      api.post('/api/friends/requests/$id/accept');

  Future<void> rejectRequest(int id) =>
      api.post('/api/friends/requests/$id/reject');

  Future<void> deleteFriend(int friendUserId) =>
      api.delete('/api/friends/$friendUserId');

  /// 拉黑用户。
  Future<void> block(int userId) =>
      api.post('/api/friends/$userId/block');

  /// 解除拉黑。
  Future<void> unblock(int userId) =>
      api.post('/api/friends/$userId/unblock');

  /// #17 站内分享个人名片。
  Future<void> shareUserCard(int userId, int toUserId) =>
      api.requestDynamic('POST', '/api/friends/$userId/share',
          queryParameters: {'toUserId': toUserId});

  /// 名片投递给任意会话（群聊/单聊）：POST /api/friends/cards/share。
  Future<void> shareUserCardToConv({
    required int sharedUserId,
    required int convId,
  }) =>
      api.post('/api/friends/cards/share',
          data: {'sharedUserId': sharedUserId, 'convId': convId});

  /// 撤回我发出的好友申请。
  Future<void> cancelRequest(int id) =>
      api.post('/api/friends/requests/$id/cancel');

  /// 举报（targetType: USER / GROUP / MESSAGE 等）。
  Future<void> report({
    required String targetType,
    required int targetId,
    required String reason,
    String? detail,
  }) =>
      api.post('/api/reports', data: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        'detail': ?detail,
      });

  Future<void> setRemark(int friendUserId, String? remark) =>
      api.put('/api/friends/$friendUserId/remark', data: {'remark': ?remark});
}

/// 通讯录聚合：/api/contacts/overview
class ContactsRepository {
  final ApiClient api;
  ContactsRepository(this.api);

  Future<ContactsOverview> overview() async => ContactsOverview.fromJson(
      await api.get('/api/contacts/overview') as Map<String, dynamic>);
}

/// 意见反馈：/api/feedback/**
class FeedbackRepository {
  final ApiClient api;
  FeedbackRepository(this.api);

  Future<void> submit({
    required String type,
    required String content,
    String? contact,
  }) =>
      api.post('/api/feedback', data: {
        'type': type,
        'content': content,
        'contact': ?contact,
      });

  Future<List<FeedbackModel>> mine() async => _listOf(
      await api.requestDynamic('GET', '/api/feedback/mine'),
      FeedbackModel.fromJson);

  Future<void> markRead() => api.post('/api/feedback/read');

  Future<int> unreadCount() async {
    final d = await api.get('/api/feedback/unread-count');
    return (d?['count'] as num?)?.toInt() ?? 0;
  }

  /// 反馈会话消息列表。
  Future<List<FeedbackMessageModel>> listMessages(int id) async => _listOf(
      await api.requestDynamic('GET', '/api/feedback/$id/messages'),
      FeedbackMessageModel.fromJson);

  /// 在反馈会话内追问一条消息，返回更新后的反馈视图。
  Future<FeedbackModel> appendMessage(int id, String content) async {
    final data = await api.post('/api/feedback/$id/messages',
        data: {'content': content}) as Map<String, dynamic>;
    return FeedbackModel.fromJson(data);
  }
}
