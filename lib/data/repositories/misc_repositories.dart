import '../../core/network/api_client.dart';
import '../models/models.dart';

class GroupRepository {
  final ApiClient api;
  GroupRepository(this.api);

  Future<GroupModel> create({
    required String name,
    required List<int> memberIds,
    String? announcement,
    String? avatarUrl,
    String joinPolicy = 'OPEN',
    String? myNickname,
  }) async {
    final ann =
        (announcement != null && announcement.isNotEmpty) ? announcement : null;
    final avatar = (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null;
    final nick = (myNickname != null && myNickname.isNotEmpty) ? myNickname : null;
    final data = await api.post('/api/groups', data: {
      'name': name,
      'memberIds': memberIds,
      'announcement': ?ann,
      'avatarUrl': ?avatar,
      'joinPolicy': joinPolicy,
      'myNickname': ?nick,
    }) as Map<String, dynamic>;
    return GroupModel.fromJson(data);
  }

  Future<GroupModel> detail(int convId) async {
    final data = await api.get('/api/groups/$convId') as Map<String, dynamic>;
    return GroupModel.fromJson(data);
  }

  Future<List<GroupMember>> members(int convId) async {
    final data =
        await api.requestDynamic('GET', '/api/groups/$convId/members') as List;
    return data
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<GroupBrief>> mine() async {
    final data = await api.requestDynamic('GET', '/api/groups/mine') as List;
    return data
        .map((e) => GroupBrief.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 群二维码解析。
  Future<GroupBrief> resolve(String token) async {
    final data =
        await api.get('/api/groups/resolve', query: {'token': token})
            as Map<String, dynamic>;
    return GroupBrief.fromJson(data);
  }

  /// 群号解析：GET /api/groups/by-number/{groupNumber}。
  Future<GroupBrief> resolveByNumber(String groupNumber) async {
    final data = await api
        .get('/api/groups/by-number/${Uri.encodeComponent(groupNumber)}')
        as Map<String, dynamic>;
    return GroupBrief.fromJson(data);
  }

  /// 主动加入：OPEN 群返回 GroupResponse，APPROVAL 群返回 GroupRequestView。
  /// 返回 (joined, payload)。
  Future<({bool joined, Map<String, dynamic> raw})> join(int convId,
      {String? message}) async {
    final data = await api.post('/api/groups/$convId/join', data: {
      'message': ?message,
    }) as Map<String, dynamic>;
    return (joined: data.containsKey('myRole'), raw: data);
  }

  Future<List<GroupRequestModel>> joinRequests(int convId) async {
    final data = await api.requestDynamic(
        'GET', '/api/groups/$convId/join-requests') as List;
    return data
        .map((e) =>
            GroupRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> approveJoin(int convId, int rid) =>
      api.post('/api/groups/$convId/join-requests/$rid/approve');

  Future<void> declineJoin(int convId, int rid) =>
      api.post('/api/groups/$convId/join-requests/$rid/decline');

  /// 我发起的入群申请（跨全部群）。
  Future<List<GroupRequestModel>> myJoinRequests() async {
    final data =
        await api.requestDynamic('GET', '/api/groups/join-requests/mine')
            as List;
    return data
        .map((e) =>
            GroupRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 群邀请列表；[history] 为 true 时附带已处理（通过/拒绝）的记录。
  Future<List<GroupRequestModel>> invites({bool history = false}) async {
    final data = await api.requestDynamic('GET', '/api/groups/invites',
        queryParameters: history ? {'history': 'true'} : null) as List;
    return data
        .map((e) =>
            GroupRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> acceptInvite(int rid) =>
      api.post('/api/groups/invites/$rid/accept');

  Future<void> declineInvite(int rid) =>
      api.post('/api/groups/invites/$rid/decline');

  /// 邀请好友（对方需确认），返回发出的邀请数。
  Future<int> invite(int convId, List<int> userIds) async {
    final data = await api.post('/api/groups/$convId/invite', data: {
      'userIds': userIds,
    }) as Map<String, dynamic>;
    return (data['invited'] as num?)?.toInt() ?? 0;
  }

  /// 分享群聊名片到目标用户（在单聊中插入一条 GROUP_CARD 系统消息）。
  /// #13 站内分享群聊。
  Future<void> shareGroupCard(int convId, int toUserId) =>
      api.post('/api/groups/$convId/share', data: {'toUserId': toUserId});

  /// 群名片投递给任意会话（群聊/单聊）：POST /api/groups/cards/share。
  Future<void> shareGroupCardToConv({
    required int convId,
    required int targetConvId,
  }) =>
      api.post('/api/groups/cards/share', data: {
        'convId': convId,
        'targetConvId': targetConvId,
      });

  Future<String> qrcode(int convId) async {
    final data =
        await api.get('/api/groups/$convId/qrcode') as Map<String, dynamic>;
    return data['token'] as String? ?? '';
  }

  Future<String> resetQrcode(int convId) async {
    final data = await api
        .post('/api/groups/$convId/qrcode/reset') as Map<String, dynamic>;
    return data['token'] as String? ?? '';
  }

  Future<GroupModel> updateSettings(int convId, {
    String? name,
    String? announcement,
    String? avatarUrl,
    String? joinPolicy,
  }) async {
    final data = await api.put('/api/groups/$convId', data: {
      'name': ?name,
      'announcement': ?announcement,
      'avatarUrl': ?avatarUrl,
      'joinPolicy': ?joinPolicy,
    }) as Map<String, dynamic>;
    return GroupModel.fromJson(data);
  }

  Future<void> kick(int convId, int userId) =>
      api.post('/api/groups/$convId/kick', data: {'userId': userId});

  Future<void> leave(int convId) => api.post('/api/groups/$convId/leave');

  Future<void> dissolve(int convId) =>
      api.post('/api/groups/$convId/dissolve');

  Future<void> setRole(int convId, int userId, String role) =>
      api.post('/api/groups/$convId/role',
          data: {'userId': userId, 'role': role});

  /// durationSeconds 为 null 表示解除禁言。
  Future<void> mute(int convId, int userId, int? durationSeconds) =>
      api.post('/api/groups/$convId/mute', data: {
        'userId': userId,
        'durationSeconds': ?durationSeconds,
      });

  Future<void> setMemberNickname(int convId, int? userId, String? nickname) =>
      api.post('/api/groups/$convId/member-nickname', data: {
        'userId': ?userId,
        'groupNickname': ?nickname,
      });
}

class MediaRepository {
  final ApiClient api;
  MediaRepository(this.api);

  Future<MediaModel> uploadImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await api.upload(
      '/api/media',
      bytes: bytes,
      filename: filename,
      type: 'IMAGE',
    ) as Map<String, dynamic>;
    return MediaModel.fromJson(data);
  }

  /// #14 语音上传：type=VOICE，后端校验 .m4a/.aac/.mp3/.amr/.ogg。
  Future<MediaModel> uploadVoice({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await api.upload(
      '/api/media',
      bytes: bytes,
      filename: filename,
      type: 'VOICE',
    ) as Map<String, dynamic>;
    return MediaModel.fromJson(data);
  }

  /// 视频上传：type=VIDEO，后端校验 .mp4/.mov/.m4v/.webm（≤20MiB）。
  Future<MediaModel> uploadVideo({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await api.upload(
      '/api/media',
      bytes: bytes,
      filename: filename,
      type: 'VIDEO',
    ) as Map<String, dynamic>;
    return MediaModel.fromJson(data);
  }

  /// 通用文件上传（文档/音乐等）：type=FILE，无扩展白名单。
  Future<MediaModel> uploadFile({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await api.upload(
      '/api/media',
      bytes: bytes,
      filename: filename,
      type: 'FILE',
    ) as Map<String, dynamic>;
    return MediaModel.fromJson(data);
  }
}

/// #11 语音通话 REST：ICE 配置下发 + 通话记录落库。
class CallRepository {
  final ApiClient api;
  CallRepository(this.api);

  Future<List<Map<String, dynamic>>> iceServers() async {
    final data =
        await api.requestDynamic('GET', '/api/call/ice-servers') as List;
    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// result ∈ completed/missed/rejected/canceled。
  Future<void> record({
    required int peerUserId,
    required String callId,
    required String result,
    int? durationSec,
  }) =>
      api.post('/api/call/record', data: {
        'peerUserId': peerUserId,
        'callId': callId,
        'result': result,
        'durationSec': ?durationSec,
      });
}

class SyncRepository {
  final ApiClient api;
  SyncRepository(this.api);

  /// REST 增量同步（WS SYNC_REQ 的等价通道，新设备冷启动/重连后调用）。
  Future<SyncBatch> pull({int? cursor, int limit = 100}) async {
    final data = await api.post('/api/sync/pull', data: {
      'cursor': ?cursor,
      'limit': limit,
    }) as Map<String, dynamic>;
    return SyncBatch.fromJson(data);
  }
}

class E2eeRepository {
  final ApiClient api;
  E2eeRepository(this.api);

  Future<Map<String, dynamic>> uploadBundle({
    required int registrationId,
    required String identityKey,
    required String signedPreKey,
    required String signature,
    required List<String> oneTimeKeys,
  }) async {
    return await api.put('/api/e2ee/bundle', data: {
      'registrationId': registrationId,
      'identityKey': identityKey,
      'signedPreKey': signedPreKey,
      'signature': signature,
      'oneTimeKeys': oneTimeKeys,
    }) as Map<String, dynamic>;
  }

  /// 剩余一次性公钥数等。
  Future<Map<String, dynamic>> myBundle() async {
    return await api.get('/api/e2ee/bundle/me') as Map<String, dynamic>;
  }

  /// 发起私密消息前领取对端公钥束（会消耗一个一次性公钥）。
  Future<List<E2eeBundle>> claim(int userId) async {
    final data =
        await api.requestDynamic('POST', '/api/e2ee/claim/$userId') as List;
    return data
        .map((e) => E2eeBundle.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
