// 后端 DTO 的 Dart 映射（字段名严格对齐后端 *Dtos / MessageResponse）。
// 注意：后端 Jackson default-property-inclusion=non_null，缺失字段即 null。

int? _int(dynamic v) => (v as num?)?.toInt();

/// 解析服务端时间。服务端约定所有时间均为 UTC 存储/输出：
/// - 带 `Z` 或偏移量的字符串：正常解析；
/// - 不带时区信息的 ISO 字符串：按 UTC 解析（DateTime.parse 默认会当本地时间，
///   在 UTC+8 环境会导致显示成次日，是 9/19 显示 9/20 bug 的客户端侧防御）。
DateTime? _dt(dynamic v) {
  if (v == null) return null;
  final s = v as String;
  final hasZone = s.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
  return DateTime.tryParse(hasZone ? s : '${s}Z');
}

class AppUser {
  final int id;
  final String? uid; // 8 位 UID（邮箱验证码首次登录后端自动生成）
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String? qrcodeToken;
  final String? phone;
  final String? email;
  final String? region;
  final String? role;
  final String? status;

  /// 是否已设置登录密码（false 时引导“设置初始密码”）。
  final bool hasPassword;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.nickname,
    this.uid,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.qrcodeToken,
    this.phone,
    this.email,
    this.region,
    this.role,
    this.status,
    this.hasPassword = false,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: _int(j['id'])!,
        uid: j['uid'] as String?,
        username: j['username'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        bio: j['bio'] as String?,
        gender: j['gender'] as String?,
        qrcodeToken: j['qrcodeToken'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        region: j['region'] as String?,
        role: j['role'] as String?,
        status: j['status'] as String?,
        hasPassword: j['hasPassword'] == true,
        createdAt: _dt(j['createdAt']),
      );

  AppUser copyWith({
    int? id,
    String? uid,
    String? username,
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? gender,
    String? qrcodeToken,
    String? phone,
    String? email,
    String? region,
    String? role,
    String? status,
    bool? hasPassword,
    DateTime? createdAt,
  }) =>
      AppUser(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        username: username ?? this.username,
        nickname: nickname ?? this.nickname,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        gender: gender ?? this.gender,
        qrcodeToken: qrcodeToken ?? this.qrcodeToken,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        region: region ?? this.region,
        role: role ?? this.role,
        status: status ?? this.status,
        hasPassword: hasPassword ?? this.hasPassword,
        createdAt: createdAt ?? this.createdAt,
      );
}

class DeviceInfo {
  final String deviceId;
  final String platform; // WEB / WINDOWS / ANDROID ...
  final String? deviceName;

  const DeviceInfo({
    required this.deviceId,
    this.platform = 'WEB',
    this.deviceName,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'platform': platform,
        if (deviceName != null) 'deviceName': deviceName,
      };
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory TokenPair.fromJson(Map<String, dynamic> j) => TokenPair(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        user: AppUser.fromJson(Map<String, dynamic>.from(j['user'] as Map)),
      );
}

class UserDevice {
  final int id;
  final String deviceId;
  final String platform;
  final String? deviceName;
  final bool? revoked;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  const UserDevice({
    required this.id,
    required this.deviceId,
    required this.platform,
    this.deviceName,
    this.revoked,
    this.lastLoginAt,
    this.createdAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> j) => UserDevice(
        id: _int(j['id'])!,
        deviceId: j['deviceId'] as String? ?? '',
        platform: j['platform'] as String? ?? '',
        deviceName: j['deviceName'] as String?,
        revoked: j['revoked'] as bool?,
        lastLoginAt: _dt(j['lastLoginAt']),
        createdAt: _dt(j['createdAt']),
      );
}

class MessageModel {
  final int? id;
  final String msgId;
  final int convId;
  final int senderId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final String? mediaMeta;
  final int? seq;
  final bool encrypted;
  final String? status;
  final String? senderNickname;
  final String? senderAvatarUrl;
  final DateTime? createdAt;

  const MessageModel({
    this.id,
    required this.msgId,
    required this.convId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.mediaMeta,
    this.seq,
    this.encrypted = false,
    this.status,
    this.senderNickname,
    this.senderAvatarUrl,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: _int(j['id']),
        msgId: j['msgId'] as String? ?? '',
        // 系统消息投递帧历史键名不一致：convId / conversationId 双兼容。
        convId: _int(j['convId'] ?? j['conversationId'])!,
        senderId: _int(j['senderId'])!,
        type: j['type'] as String? ?? 'TEXT',
        content: j['content'] as String?,
        mediaUrl: j['mediaUrl'] as String?,
        mediaMeta: j['mediaMeta'] as String?,
        seq: _int(j['seq']),
        encrypted: j['encrypted'] == true,
        status: j['status'] as String?,
        senderNickname: j['senderNickname'] as String?,
        senderAvatarUrl: j['senderAvatarUrl'] as String?,
        createdAt: _dt(j['createdAt']),
      );
}

class PeerInfo {
  final int userId;
  final String? nickname;
  final String? avatarUrl;
  final String? remark;

  const PeerInfo({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.remark,
  });

  /// 列表展示名：备注优先，其次昵称。
  String? get displayName => (remark != null && remark!.isNotEmpty)
      ? remark
      : nickname;

  factory PeerInfo.fromJson(Map<String, dynamic> j) => PeerInfo(
        userId: _int(j['userId'])!,
        nickname: j['nickname'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        remark: j['remark'] as String?,
      );
}

class ConversationModel {
  final int id;
  final String type;
  final String? title;

  /// 群头像相对/绝对 URL（群聊会话列表展示用）。
  final String? groupAvatarUrl;
  final PeerInfo? peer;
  final int unreadCount;
  final int? lastSeq;
  final bool muted;
  final bool privateFlag;
  final bool dissolved;

  /// 是否置顶及置顶时间。
  final bool pinned;
  final DateTime? pinnedAt;
  final MessageModel? lastMessage;
  final DateTime? updatedAt;

  const ConversationModel({
    required this.id,
    required this.type,
    this.title,
    this.groupAvatarUrl,
    this.peer,
    this.unreadCount = 0,
    this.lastSeq,
    this.muted = false,
    this.privateFlag = false,
    this.dissolved = false,
    this.pinned = false,
    this.pinnedAt,
    this.lastMessage,
    this.updatedAt,
  });

  bool get isSingle => type == 'SINGLE';

  factory ConversationModel.fromJson(Map<String, dynamic> j) {
    final peer = j['peer'] is Map
        ? PeerInfo.fromJson(Map<String, dynamic>.from(j['peer'] as Map))
        : null;
    final last = j['lastMessage'] is Map
        ? MessageModel.fromJson(
            Map<String, dynamic>.from(j['lastMessage'] as Map))
        : null;
    return ConversationModel(
      id: _int(j['id'])!,
      type: j['type'] as String? ?? 'SINGLE',
      title: j['title'] as String?,
      groupAvatarUrl: j['groupAvatarUrl'] as String?,
      peer: peer,
      unreadCount: _int(j['unreadCount']) ?? 0,
      lastSeq: _int(j['lastSeq']),
      muted: j['muted'] == true,
      privateFlag: j['privateFlag'] == true,
      dissolved: j['dissolved'] == true,
      pinned: j['pinned'] == true,
      pinnedAt: _dt(j['pinnedAt']),
      lastMessage: last,
      updatedAt: _dt(j['updatedAt']),
    );
  }
}

class MediaModel {
  final String url;
  final String key;
  final String name;
  final String? contentType;
  final int size;
  final String? sha256;
  final String type;

  const MediaModel({
    required this.url,
    required this.key,
    required this.name,
    this.contentType,
    required this.size,
    this.sha256,
    required this.type,
  });

  factory MediaModel.fromJson(Map<String, dynamic> j) => MediaModel(
        url: j['url'] as String? ?? '',
        key: j['key'] as String? ?? '',
        name: j['name'] as String? ?? '',
        contentType: j['contentType'] as String?,
        size: _int(j['size']) ?? 0,
        sha256: j['sha256'] as String?,
        type: j['type'] as String? ?? 'FILE',
      );
}

/// 好友模块的精简用户视图（带关系标记）。
/// relation: SELF / FRIEND / PENDING_SENT / PENDING_RECEIVED / NONE
class UserBrief {
  final int id;
  final String? uid;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String relation;

  const UserBrief({
    required this.id,
    this.uid,
    this.username = '',
    this.nickname = '',
    this.avatarUrl,
    this.bio,
    this.gender,
    this.relation = 'NONE',
  });

  String get displayName =>
      nickname.isNotEmpty ? nickname : (username.isNotEmpty ? username : '用户');

  factory UserBrief.fromJson(Map<String, dynamic> j) => UserBrief(
        id: _int(j['id'])!,
        uid: j['uid'] as String?,
        username: j['username'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        bio: j['bio'] as String?,
        gender: j['gender'] as String?,
        relation: j['relation'] as String? ?? 'NONE',
      );
}

class FriendView {
  final UserBrief user;
  final String? remark;
  final DateTime? createdAt;

  const FriendView({required this.user, this.remark, this.createdAt});

  factory FriendView.fromJson(Map<String, dynamic> j) => FriendView(
        user: UserBrief.fromJson(
            Map<String, dynamic>.from(j['user'] as Map)),
        remark: j['remark'] as String?,
        createdAt: _dt(j['createdAt']),
      );
}

class FriendRequestModel {
  final int id;
  final UserBrief? from;
  final UserBrief? to;
  final String? message;
  final String status; // PENDING / ACCEPTED / REJECTED / CANCELED
  final DateTime? createdAt;
  final DateTime? handledAt;

  const FriendRequestModel({
    required this.id,
    this.from,
    this.to,
    this.message,
    required this.status,
    this.createdAt,
    this.handledAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> j) =>
      FriendRequestModel(
        id: _int(j['id'])!,
        from: j['from'] is Map
            ? UserBrief.fromJson(Map<String, dynamic>.from(j['from'] as Map))
            : null,
        to: j['to'] is Map
            ? UserBrief.fromJson(Map<String, dynamic>.from(j['to'] as Map))
            : null,
        message: j['message'] as String?,
        status: j['status'] as String? ?? 'PENDING',
        createdAt: _dt(j['createdAt']),
        handledAt: _dt(j['handledAt']),
      );
}

class GroupModel {
  final int convId;
  final String name;
  final String? groupNumber;
  final String? avatarUrl;
  final String? announcement;
  final String joinPolicy; // OPEN / APPROVAL
  final String? qrcodeToken;
  final int memberCount;
  final int? ownerId;
  final bool dissolved;
  final String? myRole; // OWNER / ADMIN / MEMBER
  final String? myNickname;
  /// 我在此群的禁言截止时刻（null=未被禁言）。
  final DateTime? myMutedUntil;
  final DateTime? createdAt;

  const GroupModel({
    required this.convId,
    required this.name,
    this.groupNumber,
    this.avatarUrl,
    this.announcement,
    this.joinPolicy = 'OPEN',
    this.qrcodeToken,
    this.memberCount = 0,
    this.ownerId,
    this.dissolved = false,
    this.myRole,
    this.myNickname,
    this.myMutedUntil,
    this.createdAt,
  });

  bool get approvalRequired => joinPolicy == 'APPROVAL';

  factory GroupModel.fromJson(Map<String, dynamic> j) => GroupModel(
        convId: _int(j['convId'])!,
        name: j['name'] as String? ?? '',
        groupNumber: j['groupNumber'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        announcement: j['announcement'] as String?,
        joinPolicy: j['joinPolicy'] as String? ?? 'OPEN',
        qrcodeToken: j['qrcodeToken'] as String?,
        memberCount: _int(j['memberCount']) ?? 0,
        ownerId: _int(j['ownerId']),
        dissolved: j['dissolved'] == true,
        myRole: j['myRole'] as String?,
        myNickname: j['myNickname'] as String?,
        myMutedUntil: _dt(j['myMutedUntil']),
        createdAt: _dt(j['createdAt']),
      );
}

/// 通讯录中的群简要（/api/groups/mine, /api/groups/resolve）。
class GroupBrief {
  final int convId;
  final String name;
  final String? groupNumber;
  final String? avatarUrl;
  final String? announcement;
  final String joinPolicy;
  final int memberCount;
  final String relation; // MEMBER / PENDING / INVITED / NONE

  // 群主资料（群名片页展示群主卡片；旧后端响应可能缺省）。
  final int? ownerId;
  final String? ownerNickname;
  final String? ownerAvatarUrl;
  final String? ownerRelation;

  const GroupBrief({
    required this.convId,
    required this.name,
    this.groupNumber,
    this.avatarUrl,
    this.announcement,
    this.joinPolicy = 'OPEN',
    this.memberCount = 0,
    this.relation = 'NONE',
    this.ownerId,
    this.ownerNickname,
    this.ownerAvatarUrl,
    this.ownerRelation,
  });

  factory GroupBrief.fromJson(Map<String, dynamic> j) => GroupBrief(
        convId: _int(j['convId'])!,
        name: j['name'] as String? ?? '',
        groupNumber: j['groupNumber'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        announcement: j['announcement'] as String?,
        joinPolicy: j['joinPolicy'] as String? ?? 'OPEN',
        memberCount: _int(j['memberCount']) ?? 0,
        relation: j['relation'] as String? ?? 'NONE',
        ownerId: _int(j['ownerId']),
        ownerNickname: j['ownerNickname'] as String?,
        ownerAvatarUrl: j['ownerAvatarUrl'] as String?,
        ownerRelation: j['ownerRelation'] as String?,
      );
}

class GroupMember {
  final int userId;
  final String? nickname;
  final String? avatarUrl;
  final String? groupNickname;
  final String role; // OWNER / ADMIN / MEMBER
  final String status; // ACTIVE / KICKED / LEFT
  final DateTime? mutedUntil;

  const GroupMember({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.groupNickname,
    required this.role,
    this.status = 'ACTIVE',
    this.mutedUntil,
  });

  bool get isMuted =>
      mutedUntil != null && mutedUntil!.isAfter(DateTime.now().toUtc());

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        userId: _int(j['userId'])!,
        nickname: j['nickname'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        groupNickname: j['groupNickname'] as String?,
        role: j['role'] as String? ?? 'MEMBER',
        status: j['status'] as String? ?? 'ACTIVE',
        mutedUntil: _dt(j['mutedUntil']),
      );
}

/// 进群申请 / 群邀请（kind=JOIN / INVITE）。
class GroupRequestModel {
  final int id;
  final int convId;
  final String? groupName;
  final String? groupAvatarUrl;
  final int? userId;
  final String? userNickname;
  final String? userAvatarUrl;
  final int? inviterId;
  final String? inviterNickname;
  final String kind;
  final String? message;
  final String status;
  final DateTime? createdAt;
  final DateTime? handledAt;

  const GroupRequestModel({
    required this.id,
    required this.convId,
    this.groupName,
    this.groupAvatarUrl,
    this.userId,
    this.userNickname,
    this.userAvatarUrl,
    this.inviterId,
    this.inviterNickname,
    required this.kind,
    this.message,
    required this.status,
    this.createdAt,
    this.handledAt,
  });

  factory GroupRequestModel.fromJson(Map<String, dynamic> j) =>
      GroupRequestModel(
        id: _int(j['id'])!,
        convId: _int(j['convId'])!,
        groupName: j['groupName'] as String?,
        groupAvatarUrl: j['groupAvatarUrl'] as String?,
        userId: _int(j['userId']),
        userNickname: j['userNickname'] as String?,
        userAvatarUrl: j['userAvatarUrl'] as String?,
        inviterId: _int(j['inviterId']),
        inviterNickname: j['inviterNickname'] as String?,
        kind: j['kind'] as String? ?? 'JOIN',
        message: j['message'] as String?,
        status: j['status'] as String? ?? 'PENDING',
        createdAt: _dt(j['createdAt']),
        handledAt: _dt(j['handledAt']),
      );
}

/// 反馈会话内的一条消息（用户追问 / 官方回复）。
class FeedbackMessageModel {
  final int id;
  final String senderRole; // USER / ADMIN
  final String content;
  final DateTime? createdAt;

  const FeedbackMessageModel({
    required this.id,
    required this.senderRole,
    required this.content,
    this.createdAt,
  });

  factory FeedbackMessageModel.fromJson(Map<String, dynamic> j) =>
      FeedbackMessageModel(
        id: _int(j['id'])!,
        senderRole: j['senderRole'] as String? ?? 'USER',
        content: j['content'] as String? ?? '',
        createdAt: _dt(j['createdAt']),
      );
}

class FeedbackModel {
  final int id;
  final int? userId;
  final String? userUid;
  final String? userNickname;
  final String? userEmail;
  final String type; // BUG / COMPLAINT / SUGGESTION / OTHER
  final String content;
  final String? contact;
  final int priority;
  final String status; // PENDING / PROCESSING / REPLIED / CLOSED
  final String? reply;
  final bool emailSent;
  final bool readFlag;

  /// 反馈会话消息（老后端可能不下发，容错为空数组）。
  final List<FeedbackMessageModel> messages;
  final DateTime? createdAt;
  final DateTime? repliedAt;

  const FeedbackModel({
    required this.id,
    this.userId,
    this.userUid,
    this.userNickname,
    this.userEmail,
    required this.type,
    required this.content,
    this.contact,
    this.priority = 0,
    required this.status,
    this.reply,
    this.emailSent = false,
    this.readFlag = true,
    this.messages = const [],
    this.createdAt,
    this.repliedAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> j) => FeedbackModel(
        id: _int(j['id'])!,
        userId: _int(j['userId']),
        userUid: j['userUid'] as String?,
        userNickname: j['userNickname'] as String?,
        userEmail: j['userEmail'] as String?,
        type: j['type'] as String? ?? 'OTHER',
        content: j['content'] as String? ?? '',
        contact: j['contact'] as String?,
        priority: _int(j['priority']) ?? 0,
        status: j['status'] as String? ?? 'PENDING',
        reply: j['reply'] as String?,
        emailSent: j['emailSent'] == true,
        readFlag: j['readFlag'] != false,
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) => FeedbackMessageModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: _dt(j['createdAt']),
        repliedAt: _dt(j['repliedAt']),
      );

  /// 轮询时仅更新状态/已读标记（其余字段服务端该视图不变）。
  FeedbackModel copyWith({String? status, bool? readFlag}) => FeedbackModel(
        id: id,
        userId: userId,
        userUid: userUid,
        userNickname: userNickname,
        userEmail: userEmail,
        type: type,
        content: content,
        contact: contact,
        priority: priority,
        status: status ?? this.status,
        reply: reply,
        emailSent: emailSent,
        readFlag: readFlag ?? this.readFlag,
        messages: messages,
        createdAt: createdAt,
        repliedAt: repliedAt,
      );
}

/// /api/contacts/overview 聚合。
class ContactsOverview {
  final List<FriendView> friends;
  final List<FriendRequestModel> friendRequests;
  final List<GroupBrief> groups;
  final List<GroupRequestModel> groupInvites;
  final int incomingCount;

  const ContactsOverview({
    required this.friends,
    required this.friendRequests,
    required this.groups,
    required this.groupInvites,
    required this.incomingCount,
  });

  factory ContactsOverview.fromJson(Map<String, dynamic> j) {
    List<T> listOf<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] as List?) ?? const [])
            .map((e) => f(Map<String, dynamic>.from(e as Map)))
            .toList();
    final requests = listOf('friendRequests', FriendRequestModel.fromJson);
    return ContactsOverview(
      friends: listOf('friends', FriendView.fromJson),
      friendRequests: requests,
      groups: listOf('groups', GroupBrief.fromJson),
      groupInvites: listOf('groupInvites', GroupRequestModel.fromJson),
      incomingCount:
          requests.where((r) => r.status == 'PENDING').toList().length,
    );
  }
}

class SyncBatch {
  final List<MessageModel> messages;
  final int nextCursor;
  final bool hasMore;

  const SyncBatch({
    required this.messages,
    required this.nextCursor,
    required this.hasMore,
  });

  factory SyncBatch.fromJson(Map<String, dynamic> j) => SyncBatch(
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) =>
                MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        nextCursor: _int(j['nextCursor']) ?? 0,
        hasMore: j['hasMore'] == true,
      );
}

/// E2EE claim 返回的对端设备公钥束（oneTimeKey 耗尽时为 null，见后端）。
class E2eeBundle {
  final int userId;
  final String deviceId;
  final int? registrationId;
  final String identityKey;
  final String signedPreKey;
  final String? signature;
  final String? oneTimeKey;

  const E2eeBundle({
    required this.userId,
    required this.deviceId,
    this.registrationId,
    required this.identityKey,
    required this.signedPreKey,
    this.signature,
    this.oneTimeKey,
  });

  factory E2eeBundle.fromJson(Map<String, dynamic> j) => E2eeBundle(
        userId: _int(j['userId'])!,
        deviceId: j['deviceId'] as String? ?? '',
        registrationId: _int(j['registrationId']),
        identityKey: j['identityKey'] as String? ?? '',
        signedPreKey: j['signedPreKey'] as String? ?? '',
        signature: j['signature'] as String?,
        oneTimeKey: j['oneTimeKey'] as String?,
      );
}
