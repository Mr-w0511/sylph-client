// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    nickname,
    avatarUrl,
    gender,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? gender;
  final DateTime updatedAt;
  const User({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    this.gender,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['nickname'] = Variable<String>(nickname);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      nickname: Value(nickname),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      nickname: serializer.fromJson<String>(json['nickname']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      gender: serializer.fromJson<String?>(json['gender']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'nickname': serializer.toJson<String>(nickname),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'gender': serializer.toJson<String?>(gender),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? nickname,
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    username: username ?? this.username,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    gender: gender.present ? gender.value : this.gender,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      gender: data.gender.present ? data.gender.value : this.gender,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('nickname: $nickname, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('gender: $gender, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, username, nickname, avatarUrl, gender, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.nickname == this.nickname &&
          other.avatarUrl == this.avatarUrl &&
          other.gender == this.gender &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> nickname;
  final Value<String?> avatarUrl;
  final Value<String?> gender;
  final Value<DateTime> updatedAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.gender = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String nickname,
    this.avatarUrl = const Value.absent(),
    this.gender = const Value.absent(),
    required DateTime updatedAt,
  }) : username = Value(username),
       nickname = Value(nickname),
       updatedAt = Value(updatedAt);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? nickname,
    Expression<String>? avatarUrl,
    Expression<String>? gender,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (nickname != null) 'nickname': nickname,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (gender != null) 'gender': gender,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? nickname,
    Value<String?>? avatarUrl,
    Value<String?>? gender,
    Value<DateTime>? updatedAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('nickname: $nickname, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('gender: $gender, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<int> peerUserId = GeneratedColumn<int>(
    'peer_user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerNicknameMeta = const VerificationMeta(
    'peerNickname',
  );
  @override
  late final GeneratedColumn<String> peerNickname = GeneratedColumn<String>(
    'peer_nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerAvatarUrlMeta = const VerificationMeta(
    'peerAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> peerAvatarUrl = GeneratedColumn<String>(
    'peer_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupAvatarUrlMeta = const VerificationMeta(
    'groupAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> groupAvatarUrl = GeneratedColumn<String>(
    'group_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSeqMeta = const VerificationMeta(
    'lastSeq',
  );
  @override
  late final GeneratedColumn<int> lastSeq = GeneratedColumn<int>(
    'last_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
    'muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _privateFlagMeta = const VerificationMeta(
    'privateFlag',
  );
  @override
  late final GeneratedColumn<bool> privateFlag = GeneratedColumn<bool>(
    'private_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("private_flag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dissolvedMeta = const VerificationMeta(
    'dissolved',
  );
  @override
  late final GeneratedColumn<bool> dissolved = GeneratedColumn<bool>(
    'dissolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dissolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta(
    'pinnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftMeta = const VerificationMeta('draft');
  @override
  late final GeneratedColumn<String> draft = GeneratedColumn<String>(
    'draft',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMsgIdMeta = const VerificationMeta(
    'lastMsgId',
  );
  @override
  late final GeneratedColumn<String> lastMsgId = GeneratedColumn<String>(
    'last_msg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMsgTypeMeta = const VerificationMeta(
    'lastMsgType',
  );
  @override
  late final GeneratedColumn<String> lastMsgType = GeneratedColumn<String>(
    'last_msg_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMsgContentMeta = const VerificationMeta(
    'lastMsgContent',
  );
  @override
  late final GeneratedColumn<String> lastMsgContent = GeneratedColumn<String>(
    'last_msg_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMsgSenderMeta = const VerificationMeta(
    'lastMsgSender',
  );
  @override
  late final GeneratedColumn<int> lastMsgSender = GeneratedColumn<int>(
    'last_msg_sender',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMsgEncryptedMeta = const VerificationMeta(
    'lastMsgEncrypted',
  );
  @override
  late final GeneratedColumn<bool> lastMsgEncrypted = GeneratedColumn<bool>(
    'last_msg_encrypted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_msg_encrypted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastMsgTimeMeta = const VerificationMeta(
    'lastMsgTime',
  );
  @override
  late final GeneratedColumn<DateTime> lastMsgTime = GeneratedColumn<DateTime>(
    'last_msg_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    peerUserId,
    peerNickname,
    peerAvatarUrl,
    groupAvatarUrl,
    unreadCount,
    lastSeq,
    muted,
    privateFlag,
    dissolved,
    pinned,
    pinnedAt,
    draft,
    lastMsgId,
    lastMsgType,
    lastMsgContent,
    lastMsgSender,
    lastMsgEncrypted,
    lastMsgTime,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('peer_nickname')) {
      context.handle(
        _peerNicknameMeta,
        peerNickname.isAcceptableOrUnknown(
          data['peer_nickname']!,
          _peerNicknameMeta,
        ),
      );
    }
    if (data.containsKey('peer_avatar_url')) {
      context.handle(
        _peerAvatarUrlMeta,
        peerAvatarUrl.isAcceptableOrUnknown(
          data['peer_avatar_url']!,
          _peerAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('group_avatar_url')) {
      context.handle(
        _groupAvatarUrlMeta,
        groupAvatarUrl.isAcceptableOrUnknown(
          data['group_avatar_url']!,
          _groupAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('last_seq')) {
      context.handle(
        _lastSeqMeta,
        lastSeq.isAcceptableOrUnknown(data['last_seq']!, _lastSeqMeta),
      );
    }
    if (data.containsKey('muted')) {
      context.handle(
        _mutedMeta,
        muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta),
      );
    }
    if (data.containsKey('private_flag')) {
      context.handle(
        _privateFlagMeta,
        privateFlag.isAcceptableOrUnknown(
          data['private_flag']!,
          _privateFlagMeta,
        ),
      );
    }
    if (data.containsKey('dissolved')) {
      context.handle(
        _dissolvedMeta,
        dissolved.isAcceptableOrUnknown(data['dissolved']!, _dissolvedMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('pinned_at')) {
      context.handle(
        _pinnedAtMeta,
        pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta),
      );
    }
    if (data.containsKey('draft')) {
      context.handle(
        _draftMeta,
        draft.isAcceptableOrUnknown(data['draft']!, _draftMeta),
      );
    }
    if (data.containsKey('last_msg_id')) {
      context.handle(
        _lastMsgIdMeta,
        lastMsgId.isAcceptableOrUnknown(data['last_msg_id']!, _lastMsgIdMeta),
      );
    }
    if (data.containsKey('last_msg_type')) {
      context.handle(
        _lastMsgTypeMeta,
        lastMsgType.isAcceptableOrUnknown(
          data['last_msg_type']!,
          _lastMsgTypeMeta,
        ),
      );
    }
    if (data.containsKey('last_msg_content')) {
      context.handle(
        _lastMsgContentMeta,
        lastMsgContent.isAcceptableOrUnknown(
          data['last_msg_content']!,
          _lastMsgContentMeta,
        ),
      );
    }
    if (data.containsKey('last_msg_sender')) {
      context.handle(
        _lastMsgSenderMeta,
        lastMsgSender.isAcceptableOrUnknown(
          data['last_msg_sender']!,
          _lastMsgSenderMeta,
        ),
      );
    }
    if (data.containsKey('last_msg_encrypted')) {
      context.handle(
        _lastMsgEncryptedMeta,
        lastMsgEncrypted.isAcceptableOrUnknown(
          data['last_msg_encrypted']!,
          _lastMsgEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('last_msg_time')) {
      context.handle(
        _lastMsgTimeMeta,
        lastMsgTime.isAcceptableOrUnknown(
          data['last_msg_time']!,
          _lastMsgTimeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_user_id'],
      ),
      peerNickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_nickname'],
      ),
      peerAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_avatar_url'],
      ),
      groupAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_avatar_url'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      lastSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seq'],
      ),
      muted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}muted'],
      )!,
      privateFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}private_flag'],
      )!,
      dissolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dissolved'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      pinnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pinned_at'],
      ),
      draft: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft'],
      ),
      lastMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_msg_id'],
      ),
      lastMsgType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_msg_type'],
      ),
      lastMsgContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_msg_content'],
      ),
      lastMsgSender: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_msg_sender'],
      ),
      lastMsgEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_msg_encrypted'],
      )!,
      lastMsgTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_msg_time'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final int id;
  final String type;
  final String? title;
  final int? peerUserId;
  final String? peerNickname;
  final String? peerAvatarUrl;
  final String? groupAvatarUrl;
  final int unreadCount;
  final int? lastSeq;
  final bool muted;
  final bool privateFlag;
  final bool dissolved;
  final bool pinned;
  final DateTime? pinnedAt;
  final String? draft;
  final String? lastMsgId;
  final String? lastMsgType;
  final String? lastMsgContent;
  final int? lastMsgSender;
  final bool lastMsgEncrypted;
  final DateTime? lastMsgTime;
  final DateTime updatedAt;
  const Conversation({
    required this.id,
    required this.type,
    this.title,
    this.peerUserId,
    this.peerNickname,
    this.peerAvatarUrl,
    this.groupAvatarUrl,
    required this.unreadCount,
    this.lastSeq,
    required this.muted,
    required this.privateFlag,
    required this.dissolved,
    required this.pinned,
    this.pinnedAt,
    this.draft,
    this.lastMsgId,
    this.lastMsgType,
    this.lastMsgContent,
    this.lastMsgSender,
    required this.lastMsgEncrypted,
    this.lastMsgTime,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || peerUserId != null) {
      map['peer_user_id'] = Variable<int>(peerUserId);
    }
    if (!nullToAbsent || peerNickname != null) {
      map['peer_nickname'] = Variable<String>(peerNickname);
    }
    if (!nullToAbsent || peerAvatarUrl != null) {
      map['peer_avatar_url'] = Variable<String>(peerAvatarUrl);
    }
    if (!nullToAbsent || groupAvatarUrl != null) {
      map['group_avatar_url'] = Variable<String>(groupAvatarUrl);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || lastSeq != null) {
      map['last_seq'] = Variable<int>(lastSeq);
    }
    map['muted'] = Variable<bool>(muted);
    map['private_flag'] = Variable<bool>(privateFlag);
    map['dissolved'] = Variable<bool>(dissolved);
    map['pinned'] = Variable<bool>(pinned);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    if (!nullToAbsent || draft != null) {
      map['draft'] = Variable<String>(draft);
    }
    if (!nullToAbsent || lastMsgId != null) {
      map['last_msg_id'] = Variable<String>(lastMsgId);
    }
    if (!nullToAbsent || lastMsgType != null) {
      map['last_msg_type'] = Variable<String>(lastMsgType);
    }
    if (!nullToAbsent || lastMsgContent != null) {
      map['last_msg_content'] = Variable<String>(lastMsgContent);
    }
    if (!nullToAbsent || lastMsgSender != null) {
      map['last_msg_sender'] = Variable<int>(lastMsgSender);
    }
    map['last_msg_encrypted'] = Variable<bool>(lastMsgEncrypted);
    if (!nullToAbsent || lastMsgTime != null) {
      map['last_msg_time'] = Variable<DateTime>(lastMsgTime);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      type: Value(type),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      peerUserId: peerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(peerUserId),
      peerNickname: peerNickname == null && nullToAbsent
          ? const Value.absent()
          : Value(peerNickname),
      peerAvatarUrl: peerAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(peerAvatarUrl),
      groupAvatarUrl: groupAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(groupAvatarUrl),
      unreadCount: Value(unreadCount),
      lastSeq: lastSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeq),
      muted: Value(muted),
      privateFlag: Value(privateFlag),
      dissolved: Value(dissolved),
      pinned: Value(pinned),
      pinnedAt: pinnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedAt),
      draft: draft == null && nullToAbsent
          ? const Value.absent()
          : Value(draft),
      lastMsgId: lastMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMsgId),
      lastMsgType: lastMsgType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMsgType),
      lastMsgContent: lastMsgContent == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMsgContent),
      lastMsgSender: lastMsgSender == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMsgSender),
      lastMsgEncrypted: Value(lastMsgEncrypted),
      lastMsgTime: lastMsgTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMsgTime),
      updatedAt: Value(updatedAt),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String?>(json['title']),
      peerUserId: serializer.fromJson<int?>(json['peerUserId']),
      peerNickname: serializer.fromJson<String?>(json['peerNickname']),
      peerAvatarUrl: serializer.fromJson<String?>(json['peerAvatarUrl']),
      groupAvatarUrl: serializer.fromJson<String?>(json['groupAvatarUrl']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      lastSeq: serializer.fromJson<int?>(json['lastSeq']),
      muted: serializer.fromJson<bool>(json['muted']),
      privateFlag: serializer.fromJson<bool>(json['privateFlag']),
      dissolved: serializer.fromJson<bool>(json['dissolved']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      draft: serializer.fromJson<String?>(json['draft']),
      lastMsgId: serializer.fromJson<String?>(json['lastMsgId']),
      lastMsgType: serializer.fromJson<String?>(json['lastMsgType']),
      lastMsgContent: serializer.fromJson<String?>(json['lastMsgContent']),
      lastMsgSender: serializer.fromJson<int?>(json['lastMsgSender']),
      lastMsgEncrypted: serializer.fromJson<bool>(json['lastMsgEncrypted']),
      lastMsgTime: serializer.fromJson<DateTime?>(json['lastMsgTime']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String?>(title),
      'peerUserId': serializer.toJson<int?>(peerUserId),
      'peerNickname': serializer.toJson<String?>(peerNickname),
      'peerAvatarUrl': serializer.toJson<String?>(peerAvatarUrl),
      'groupAvatarUrl': serializer.toJson<String?>(groupAvatarUrl),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'lastSeq': serializer.toJson<int?>(lastSeq),
      'muted': serializer.toJson<bool>(muted),
      'privateFlag': serializer.toJson<bool>(privateFlag),
      'dissolved': serializer.toJson<bool>(dissolved),
      'pinned': serializer.toJson<bool>(pinned),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'draft': serializer.toJson<String?>(draft),
      'lastMsgId': serializer.toJson<String?>(lastMsgId),
      'lastMsgType': serializer.toJson<String?>(lastMsgType),
      'lastMsgContent': serializer.toJson<String?>(lastMsgContent),
      'lastMsgSender': serializer.toJson<int?>(lastMsgSender),
      'lastMsgEncrypted': serializer.toJson<bool>(lastMsgEncrypted),
      'lastMsgTime': serializer.toJson<DateTime?>(lastMsgTime),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Conversation copyWith({
    int? id,
    String? type,
    Value<String?> title = const Value.absent(),
    Value<int?> peerUserId = const Value.absent(),
    Value<String?> peerNickname = const Value.absent(),
    Value<String?> peerAvatarUrl = const Value.absent(),
    Value<String?> groupAvatarUrl = const Value.absent(),
    int? unreadCount,
    Value<int?> lastSeq = const Value.absent(),
    bool? muted,
    bool? privateFlag,
    bool? dissolved,
    bool? pinned,
    Value<DateTime?> pinnedAt = const Value.absent(),
    Value<String?> draft = const Value.absent(),
    Value<String?> lastMsgId = const Value.absent(),
    Value<String?> lastMsgType = const Value.absent(),
    Value<String?> lastMsgContent = const Value.absent(),
    Value<int?> lastMsgSender = const Value.absent(),
    bool? lastMsgEncrypted,
    Value<DateTime?> lastMsgTime = const Value.absent(),
    DateTime? updatedAt,
  }) => Conversation(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title.present ? title.value : this.title,
    peerUserId: peerUserId.present ? peerUserId.value : this.peerUserId,
    peerNickname: peerNickname.present ? peerNickname.value : this.peerNickname,
    peerAvatarUrl: peerAvatarUrl.present
        ? peerAvatarUrl.value
        : this.peerAvatarUrl,
    groupAvatarUrl: groupAvatarUrl.present
        ? groupAvatarUrl.value
        : this.groupAvatarUrl,
    unreadCount: unreadCount ?? this.unreadCount,
    lastSeq: lastSeq.present ? lastSeq.value : this.lastSeq,
    muted: muted ?? this.muted,
    privateFlag: privateFlag ?? this.privateFlag,
    dissolved: dissolved ?? this.dissolved,
    pinned: pinned ?? this.pinned,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    draft: draft.present ? draft.value : this.draft,
    lastMsgId: lastMsgId.present ? lastMsgId.value : this.lastMsgId,
    lastMsgType: lastMsgType.present ? lastMsgType.value : this.lastMsgType,
    lastMsgContent: lastMsgContent.present
        ? lastMsgContent.value
        : this.lastMsgContent,
    lastMsgSender: lastMsgSender.present
        ? lastMsgSender.value
        : this.lastMsgSender,
    lastMsgEncrypted: lastMsgEncrypted ?? this.lastMsgEncrypted,
    lastMsgTime: lastMsgTime.present ? lastMsgTime.value : this.lastMsgTime,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      peerNickname: data.peerNickname.present
          ? data.peerNickname.value
          : this.peerNickname,
      peerAvatarUrl: data.peerAvatarUrl.present
          ? data.peerAvatarUrl.value
          : this.peerAvatarUrl,
      groupAvatarUrl: data.groupAvatarUrl.present
          ? data.groupAvatarUrl.value
          : this.groupAvatarUrl,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      lastSeq: data.lastSeq.present ? data.lastSeq.value : this.lastSeq,
      muted: data.muted.present ? data.muted.value : this.muted,
      privateFlag: data.privateFlag.present
          ? data.privateFlag.value
          : this.privateFlag,
      dissolved: data.dissolved.present ? data.dissolved.value : this.dissolved,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      draft: data.draft.present ? data.draft.value : this.draft,
      lastMsgId: data.lastMsgId.present ? data.lastMsgId.value : this.lastMsgId,
      lastMsgType: data.lastMsgType.present
          ? data.lastMsgType.value
          : this.lastMsgType,
      lastMsgContent: data.lastMsgContent.present
          ? data.lastMsgContent.value
          : this.lastMsgContent,
      lastMsgSender: data.lastMsgSender.present
          ? data.lastMsgSender.value
          : this.lastMsgSender,
      lastMsgEncrypted: data.lastMsgEncrypted.present
          ? data.lastMsgEncrypted.value
          : this.lastMsgEncrypted,
      lastMsgTime: data.lastMsgTime.present
          ? data.lastMsgTime.value
          : this.lastMsgTime,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerNickname: $peerNickname, ')
          ..write('peerAvatarUrl: $peerAvatarUrl, ')
          ..write('groupAvatarUrl: $groupAvatarUrl, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('muted: $muted, ')
          ..write('privateFlag: $privateFlag, ')
          ..write('dissolved: $dissolved, ')
          ..write('pinned: $pinned, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('draft: $draft, ')
          ..write('lastMsgId: $lastMsgId, ')
          ..write('lastMsgType: $lastMsgType, ')
          ..write('lastMsgContent: $lastMsgContent, ')
          ..write('lastMsgSender: $lastMsgSender, ')
          ..write('lastMsgEncrypted: $lastMsgEncrypted, ')
          ..write('lastMsgTime: $lastMsgTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    type,
    title,
    peerUserId,
    peerNickname,
    peerAvatarUrl,
    groupAvatarUrl,
    unreadCount,
    lastSeq,
    muted,
    privateFlag,
    dissolved,
    pinned,
    pinnedAt,
    draft,
    lastMsgId,
    lastMsgType,
    lastMsgContent,
    lastMsgSender,
    lastMsgEncrypted,
    lastMsgTime,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.peerUserId == this.peerUserId &&
          other.peerNickname == this.peerNickname &&
          other.peerAvatarUrl == this.peerAvatarUrl &&
          other.groupAvatarUrl == this.groupAvatarUrl &&
          other.unreadCount == this.unreadCount &&
          other.lastSeq == this.lastSeq &&
          other.muted == this.muted &&
          other.privateFlag == this.privateFlag &&
          other.dissolved == this.dissolved &&
          other.pinned == this.pinned &&
          other.pinnedAt == this.pinnedAt &&
          other.draft == this.draft &&
          other.lastMsgId == this.lastMsgId &&
          other.lastMsgType == this.lastMsgType &&
          other.lastMsgContent == this.lastMsgContent &&
          other.lastMsgSender == this.lastMsgSender &&
          other.lastMsgEncrypted == this.lastMsgEncrypted &&
          other.lastMsgTime == this.lastMsgTime &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<int> id;
  final Value<String> type;
  final Value<String?> title;
  final Value<int?> peerUserId;
  final Value<String?> peerNickname;
  final Value<String?> peerAvatarUrl;
  final Value<String?> groupAvatarUrl;
  final Value<int> unreadCount;
  final Value<int?> lastSeq;
  final Value<bool> muted;
  final Value<bool> privateFlag;
  final Value<bool> dissolved;
  final Value<bool> pinned;
  final Value<DateTime?> pinnedAt;
  final Value<String?> draft;
  final Value<String?> lastMsgId;
  final Value<String?> lastMsgType;
  final Value<String?> lastMsgContent;
  final Value<int?> lastMsgSender;
  final Value<bool> lastMsgEncrypted;
  final Value<DateTime?> lastMsgTime;
  final Value<DateTime> updatedAt;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerNickname = const Value.absent(),
    this.peerAvatarUrl = const Value.absent(),
    this.groupAvatarUrl = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.muted = const Value.absent(),
    this.privateFlag = const Value.absent(),
    this.dissolved = const Value.absent(),
    this.pinned = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.draft = const Value.absent(),
    this.lastMsgId = const Value.absent(),
    this.lastMsgType = const Value.absent(),
    this.lastMsgContent = const Value.absent(),
    this.lastMsgSender = const Value.absent(),
    this.lastMsgEncrypted = const Value.absent(),
    this.lastMsgTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConversationsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.title = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerNickname = const Value.absent(),
    this.peerAvatarUrl = const Value.absent(),
    this.groupAvatarUrl = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.muted = const Value.absent(),
    this.privateFlag = const Value.absent(),
    this.dissolved = const Value.absent(),
    this.pinned = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.draft = const Value.absent(),
    this.lastMsgId = const Value.absent(),
    this.lastMsgType = const Value.absent(),
    this.lastMsgContent = const Value.absent(),
    this.lastMsgSender = const Value.absent(),
    this.lastMsgEncrypted = const Value.absent(),
    this.lastMsgTime = const Value.absent(),
    required DateTime updatedAt,
  }) : type = Value(type),
       updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<int>? peerUserId,
    Expression<String>? peerNickname,
    Expression<String>? peerAvatarUrl,
    Expression<String>? groupAvatarUrl,
    Expression<int>? unreadCount,
    Expression<int>? lastSeq,
    Expression<bool>? muted,
    Expression<bool>? privateFlag,
    Expression<bool>? dissolved,
    Expression<bool>? pinned,
    Expression<DateTime>? pinnedAt,
    Expression<String>? draft,
    Expression<String>? lastMsgId,
    Expression<String>? lastMsgType,
    Expression<String>? lastMsgContent,
    Expression<int>? lastMsgSender,
    Expression<bool>? lastMsgEncrypted,
    Expression<DateTime>? lastMsgTime,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (peerNickname != null) 'peer_nickname': peerNickname,
      if (peerAvatarUrl != null) 'peer_avatar_url': peerAvatarUrl,
      if (groupAvatarUrl != null) 'group_avatar_url': groupAvatarUrl,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (lastSeq != null) 'last_seq': lastSeq,
      if (muted != null) 'muted': muted,
      if (privateFlag != null) 'private_flag': privateFlag,
      if (dissolved != null) 'dissolved': dissolved,
      if (pinned != null) 'pinned': pinned,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (draft != null) 'draft': draft,
      if (lastMsgId != null) 'last_msg_id': lastMsgId,
      if (lastMsgType != null) 'last_msg_type': lastMsgType,
      if (lastMsgContent != null) 'last_msg_content': lastMsgContent,
      if (lastMsgSender != null) 'last_msg_sender': lastMsgSender,
      if (lastMsgEncrypted != null) 'last_msg_encrypted': lastMsgEncrypted,
      if (lastMsgTime != null) 'last_msg_time': lastMsgTime,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConversationsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String?>? title,
    Value<int?>? peerUserId,
    Value<String?>? peerNickname,
    Value<String?>? peerAvatarUrl,
    Value<String?>? groupAvatarUrl,
    Value<int>? unreadCount,
    Value<int?>? lastSeq,
    Value<bool>? muted,
    Value<bool>? privateFlag,
    Value<bool>? dissolved,
    Value<bool>? pinned,
    Value<DateTime?>? pinnedAt,
    Value<String?>? draft,
    Value<String?>? lastMsgId,
    Value<String?>? lastMsgType,
    Value<String?>? lastMsgContent,
    Value<int?>? lastMsgSender,
    Value<bool>? lastMsgEncrypted,
    Value<DateTime?>? lastMsgTime,
    Value<DateTime>? updatedAt,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      peerUserId: peerUserId ?? this.peerUserId,
      peerNickname: peerNickname ?? this.peerNickname,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSeq: lastSeq ?? this.lastSeq,
      muted: muted ?? this.muted,
      privateFlag: privateFlag ?? this.privateFlag,
      dissolved: dissolved ?? this.dissolved,
      pinned: pinned ?? this.pinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      draft: draft ?? this.draft,
      lastMsgId: lastMsgId ?? this.lastMsgId,
      lastMsgType: lastMsgType ?? this.lastMsgType,
      lastMsgContent: lastMsgContent ?? this.lastMsgContent,
      lastMsgSender: lastMsgSender ?? this.lastMsgSender,
      lastMsgEncrypted: lastMsgEncrypted ?? this.lastMsgEncrypted,
      lastMsgTime: lastMsgTime ?? this.lastMsgTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<int>(peerUserId.value);
    }
    if (peerNickname.present) {
      map['peer_nickname'] = Variable<String>(peerNickname.value);
    }
    if (peerAvatarUrl.present) {
      map['peer_avatar_url'] = Variable<String>(peerAvatarUrl.value);
    }
    if (groupAvatarUrl.present) {
      map['group_avatar_url'] = Variable<String>(groupAvatarUrl.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (lastSeq.present) {
      map['last_seq'] = Variable<int>(lastSeq.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (privateFlag.present) {
      map['private_flag'] = Variable<bool>(privateFlag.value);
    }
    if (dissolved.present) {
      map['dissolved'] = Variable<bool>(dissolved.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (draft.present) {
      map['draft'] = Variable<String>(draft.value);
    }
    if (lastMsgId.present) {
      map['last_msg_id'] = Variable<String>(lastMsgId.value);
    }
    if (lastMsgType.present) {
      map['last_msg_type'] = Variable<String>(lastMsgType.value);
    }
    if (lastMsgContent.present) {
      map['last_msg_content'] = Variable<String>(lastMsgContent.value);
    }
    if (lastMsgSender.present) {
      map['last_msg_sender'] = Variable<int>(lastMsgSender.value);
    }
    if (lastMsgEncrypted.present) {
      map['last_msg_encrypted'] = Variable<bool>(lastMsgEncrypted.value);
    }
    if (lastMsgTime.present) {
      map['last_msg_time'] = Variable<DateTime>(lastMsgTime.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerNickname: $peerNickname, ')
          ..write('peerAvatarUrl: $peerAvatarUrl, ')
          ..write('groupAvatarUrl: $groupAvatarUrl, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('muted: $muted, ')
          ..write('privateFlag: $privateFlag, ')
          ..write('dissolved: $dissolved, ')
          ..write('pinned: $pinned, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('draft: $draft, ')
          ..write('lastMsgId: $lastMsgId, ')
          ..write('lastMsgType: $lastMsgType, ')
          ..write('lastMsgContent: $lastMsgContent, ')
          ..write('lastMsgSender: $lastMsgSender, ')
          ..write('lastMsgEncrypted: $lastMsgEncrypted, ')
          ..write('lastMsgTime: $lastMsgTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _msgIdMeta = const VerificationMeta('msgId');
  @override
  late final GeneratedColumn<String> msgId = GeneratedColumn<String>(
    'msg_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _globalIdMeta = const VerificationMeta(
    'globalId',
  );
  @override
  late final GeneratedColumn<int> globalId = GeneratedColumn<int>(
    'global_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _convIdMeta = const VerificationMeta('convId');
  @override
  late final GeneratedColumn<int> convId = GeneratedColumn<int>(
    'conv_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaMetaMeta = const VerificationMeta(
    'mediaMeta',
  );
  @override
  late final GeneratedColumn<String> mediaMeta = GeneratedColumn<String>(
    'media_meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _encryptedMeta = const VerificationMeta(
    'encrypted',
  );
  @override
  late final GeneratedColumn<bool> encrypted = GeneratedColumn<bool>(
    'encrypted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("encrypted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _serverStatusMeta = const VerificationMeta(
    'serverStatus',
  );
  @override
  late final GeneratedColumn<String> serverStatus = GeneratedColumn<String>(
    'server_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientStatusMeta = const VerificationMeta(
    'clientStatus',
  );
  @override
  late final GeneratedColumn<String> clientStatus = GeneratedColumn<String>(
    'client_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SENT'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    msgId,
    globalId,
    convId,
    senderId,
    type,
    content,
    mediaUrl,
    mediaMeta,
    seq,
    encrypted,
    serverStatus,
    clientStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('msg_id')) {
      context.handle(
        _msgIdMeta,
        msgId.isAcceptableOrUnknown(data['msg_id']!, _msgIdMeta),
      );
    } else if (isInserting) {
      context.missing(_msgIdMeta);
    }
    if (data.containsKey('global_id')) {
      context.handle(
        _globalIdMeta,
        globalId.isAcceptableOrUnknown(data['global_id']!, _globalIdMeta),
      );
    }
    if (data.containsKey('conv_id')) {
      context.handle(
        _convIdMeta,
        convId.isAcceptableOrUnknown(data['conv_id']!, _convIdMeta),
      );
    } else if (isInserting) {
      context.missing(_convIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    }
    if (data.containsKey('media_meta')) {
      context.handle(
        _mediaMetaMeta,
        mediaMeta.isAcceptableOrUnknown(data['media_meta']!, _mediaMetaMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('encrypted')) {
      context.handle(
        _encryptedMeta,
        encrypted.isAcceptableOrUnknown(data['encrypted']!, _encryptedMeta),
      );
    }
    if (data.containsKey('server_status')) {
      context.handle(
        _serverStatusMeta,
        serverStatus.isAcceptableOrUnknown(
          data['server_status']!,
          _serverStatusMeta,
        ),
      );
    }
    if (data.containsKey('client_status')) {
      context.handle(
        _clientStatusMeta,
        clientStatus.isAcceptableOrUnknown(
          data['client_status']!,
          _clientStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {msgId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      msgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}msg_id'],
      )!,
      globalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}global_id'],
      ),
      convId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conv_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sender_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      ),
      mediaMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_meta'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      ),
      encrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}encrypted'],
      )!,
      serverStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_status'],
      ),
      clientStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String msgId;
  final int? globalId;
  final int convId;
  final int senderId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final String? mediaMeta;
  final int? seq;
  final bool encrypted;
  final String? serverStatus;
  final String clientStatus;
  final DateTime? createdAt;
  final DateTime updatedAt;
  const Message({
    required this.msgId,
    this.globalId,
    required this.convId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.mediaMeta,
    this.seq,
    required this.encrypted,
    this.serverStatus,
    required this.clientStatus,
    this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['msg_id'] = Variable<String>(msgId);
    if (!nullToAbsent || globalId != null) {
      map['global_id'] = Variable<int>(globalId);
    }
    map['conv_id'] = Variable<int>(convId);
    map['sender_id'] = Variable<int>(senderId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || mediaMeta != null) {
      map['media_meta'] = Variable<String>(mediaMeta);
    }
    if (!nullToAbsent || seq != null) {
      map['seq'] = Variable<int>(seq);
    }
    map['encrypted'] = Variable<bool>(encrypted);
    if (!nullToAbsent || serverStatus != null) {
      map['server_status'] = Variable<String>(serverStatus);
    }
    map['client_status'] = Variable<String>(clientStatus);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      msgId: Value(msgId),
      globalId: globalId == null && nullToAbsent
          ? const Value.absent()
          : Value(globalId),
      convId: Value(convId),
      senderId: Value(senderId),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      mediaMeta: mediaMeta == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaMeta),
      seq: seq == null && nullToAbsent ? const Value.absent() : Value(seq),
      encrypted: Value(encrypted),
      serverStatus: serverStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(serverStatus),
      clientStatus: Value(clientStatus),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      msgId: serializer.fromJson<String>(json['msgId']),
      globalId: serializer.fromJson<int?>(json['globalId']),
      convId: serializer.fromJson<int>(json['convId']),
      senderId: serializer.fromJson<int>(json['senderId']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      mediaMeta: serializer.fromJson<String?>(json['mediaMeta']),
      seq: serializer.fromJson<int?>(json['seq']),
      encrypted: serializer.fromJson<bool>(json['encrypted']),
      serverStatus: serializer.fromJson<String?>(json['serverStatus']),
      clientStatus: serializer.fromJson<String>(json['clientStatus']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'msgId': serializer.toJson<String>(msgId),
      'globalId': serializer.toJson<int?>(globalId),
      'convId': serializer.toJson<int>(convId),
      'senderId': serializer.toJson<int>(senderId),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'mediaMeta': serializer.toJson<String?>(mediaMeta),
      'seq': serializer.toJson<int?>(seq),
      'encrypted': serializer.toJson<bool>(encrypted),
      'serverStatus': serializer.toJson<String?>(serverStatus),
      'clientStatus': serializer.toJson<String>(clientStatus),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Message copyWith({
    String? msgId,
    Value<int?> globalId = const Value.absent(),
    int? convId,
    int? senderId,
    String? type,
    Value<String?> content = const Value.absent(),
    Value<String?> mediaUrl = const Value.absent(),
    Value<String?> mediaMeta = const Value.absent(),
    Value<int?> seq = const Value.absent(),
    bool? encrypted,
    Value<String?> serverStatus = const Value.absent(),
    String? clientStatus,
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? updatedAt,
  }) => Message(
    msgId: msgId ?? this.msgId,
    globalId: globalId.present ? globalId.value : this.globalId,
    convId: convId ?? this.convId,
    senderId: senderId ?? this.senderId,
    type: type ?? this.type,
    content: content.present ? content.value : this.content,
    mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
    mediaMeta: mediaMeta.present ? mediaMeta.value : this.mediaMeta,
    seq: seq.present ? seq.value : this.seq,
    encrypted: encrypted ?? this.encrypted,
    serverStatus: serverStatus.present ? serverStatus.value : this.serverStatus,
    clientStatus: clientStatus ?? this.clientStatus,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      msgId: data.msgId.present ? data.msgId.value : this.msgId,
      globalId: data.globalId.present ? data.globalId.value : this.globalId,
      convId: data.convId.present ? data.convId.value : this.convId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      mediaMeta: data.mediaMeta.present ? data.mediaMeta.value : this.mediaMeta,
      seq: data.seq.present ? data.seq.value : this.seq,
      encrypted: data.encrypted.present ? data.encrypted.value : this.encrypted,
      serverStatus: data.serverStatus.present
          ? data.serverStatus.value
          : this.serverStatus,
      clientStatus: data.clientStatus.present
          ? data.clientStatus.value
          : this.clientStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('msgId: $msgId, ')
          ..write('globalId: $globalId, ')
          ..write('convId: $convId, ')
          ..write('senderId: $senderId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMeta: $mediaMeta, ')
          ..write('seq: $seq, ')
          ..write('encrypted: $encrypted, ')
          ..write('serverStatus: $serverStatus, ')
          ..write('clientStatus: $clientStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    msgId,
    globalId,
    convId,
    senderId,
    type,
    content,
    mediaUrl,
    mediaMeta,
    seq,
    encrypted,
    serverStatus,
    clientStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.msgId == this.msgId &&
          other.globalId == this.globalId &&
          other.convId == this.convId &&
          other.senderId == this.senderId &&
          other.type == this.type &&
          other.content == this.content &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaMeta == this.mediaMeta &&
          other.seq == this.seq &&
          other.encrypted == this.encrypted &&
          other.serverStatus == this.serverStatus &&
          other.clientStatus == this.clientStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> msgId;
  final Value<int?> globalId;
  final Value<int> convId;
  final Value<int> senderId;
  final Value<String> type;
  final Value<String?> content;
  final Value<String?> mediaUrl;
  final Value<String?> mediaMeta;
  final Value<int?> seq;
  final Value<bool> encrypted;
  final Value<String?> serverStatus;
  final Value<String> clientStatus;
  final Value<DateTime?> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.msgId = const Value.absent(),
    this.globalId = const Value.absent(),
    this.convId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaMeta = const Value.absent(),
    this.seq = const Value.absent(),
    this.encrypted = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.clientStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String msgId,
    this.globalId = const Value.absent(),
    required int convId,
    required int senderId,
    required String type,
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaMeta = const Value.absent(),
    this.seq = const Value.absent(),
    this.encrypted = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.clientStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : msgId = Value(msgId),
       convId = Value(convId),
       senderId = Value(senderId),
       type = Value(type),
       updatedAt = Value(updatedAt);
  static Insertable<Message> custom({
    Expression<String>? msgId,
    Expression<int>? globalId,
    Expression<int>? convId,
    Expression<int>? senderId,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? mediaUrl,
    Expression<String>? mediaMeta,
    Expression<int>? seq,
    Expression<bool>? encrypted,
    Expression<String>? serverStatus,
    Expression<String>? clientStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (msgId != null) 'msg_id': msgId,
      if (globalId != null) 'global_id': globalId,
      if (convId != null) 'conv_id': convId,
      if (senderId != null) 'sender_id': senderId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaMeta != null) 'media_meta': mediaMeta,
      if (seq != null) 'seq': seq,
      if (encrypted != null) 'encrypted': encrypted,
      if (serverStatus != null) 'server_status': serverStatus,
      if (clientStatus != null) 'client_status': clientStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? msgId,
    Value<int?>? globalId,
    Value<int>? convId,
    Value<int>? senderId,
    Value<String>? type,
    Value<String?>? content,
    Value<String?>? mediaUrl,
    Value<String?>? mediaMeta,
    Value<int?>? seq,
    Value<bool>? encrypted,
    Value<String?>? serverStatus,
    Value<String>? clientStatus,
    Value<DateTime?>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      msgId: msgId ?? this.msgId,
      globalId: globalId ?? this.globalId,
      convId: convId ?? this.convId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMeta: mediaMeta ?? this.mediaMeta,
      seq: seq ?? this.seq,
      encrypted: encrypted ?? this.encrypted,
      serverStatus: serverStatus ?? this.serverStatus,
      clientStatus: clientStatus ?? this.clientStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (msgId.present) {
      map['msg_id'] = Variable<String>(msgId.value);
    }
    if (globalId.present) {
      map['global_id'] = Variable<int>(globalId.value);
    }
    if (convId.present) {
      map['conv_id'] = Variable<int>(convId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<int>(senderId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaMeta.present) {
      map['media_meta'] = Variable<String>(mediaMeta.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (encrypted.present) {
      map['encrypted'] = Variable<bool>(encrypted.value);
    }
    if (serverStatus.present) {
      map['server_status'] = Variable<String>(serverStatus.value);
    }
    if (clientStatus.present) {
      map['client_status'] = Variable<String>(clientStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('msgId: $msgId, ')
          ..write('globalId: $globalId, ')
          ..write('convId: $convId, ')
          ..write('senderId: $senderId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMeta: $mediaMeta, ')
          ..write('seq: $seq, ')
          ..write('encrypted: $encrypted, ')
          ..write('serverStatus: $serverStatus, ')
          ..write('clientStatus: $clientStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    conversations,
    messages,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String username,
      required String nickname,
      Value<String?> avatarUrl,
      Value<String?> gender,
      required DateTime updatedAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> username,
      Value<String> nickname,
      Value<String?> avatarUrl,
      Value<String?> gender,
      Value<DateTime> updatedAt,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                username: username,
                nickname: nickname,
                avatarUrl: avatarUrl,
                gender: gender,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                required String nickname,
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                required DateTime updatedAt,
              }) => UsersCompanion.insert(
                id: id,
                username: username,
                nickname: nickname,
                avatarUrl: avatarUrl,
                gender: gender,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      required String type,
      Value<String?> title,
      Value<int?> peerUserId,
      Value<String?> peerNickname,
      Value<String?> peerAvatarUrl,
      Value<String?> groupAvatarUrl,
      Value<int> unreadCount,
      Value<int?> lastSeq,
      Value<bool> muted,
      Value<bool> privateFlag,
      Value<bool> dissolved,
      Value<bool> pinned,
      Value<DateTime?> pinnedAt,
      Value<String?> draft,
      Value<String?> lastMsgId,
      Value<String?> lastMsgType,
      Value<String?> lastMsgContent,
      Value<int?> lastMsgSender,
      Value<bool> lastMsgEncrypted,
      Value<DateTime?> lastMsgTime,
      required DateTime updatedAt,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String?> title,
      Value<int?> peerUserId,
      Value<String?> peerNickname,
      Value<String?> peerAvatarUrl,
      Value<String?> groupAvatarUrl,
      Value<int> unreadCount,
      Value<int?> lastSeq,
      Value<bool> muted,
      Value<bool> privateFlag,
      Value<bool> dissolved,
      Value<bool> pinned,
      Value<DateTime?> pinnedAt,
      Value<String?> draft,
      Value<String?> lastMsgId,
      Value<String?> lastMsgType,
      Value<String?> lastMsgContent,
      Value<int?> lastMsgSender,
      Value<bool> lastMsgEncrypted,
      Value<DateTime?> lastMsgTime,
      Value<DateTime> updatedAt,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerNickname => $composableBuilder(
    column: $table.peerNickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerAvatarUrl => $composableBuilder(
    column: $table.peerAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupAvatarUrl => $composableBuilder(
    column: $table.groupAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get privateFlag => $composableBuilder(
    column: $table.privateFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dissolved => $composableBuilder(
    column: $table.dissolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draft => $composableBuilder(
    column: $table.draft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMsgId => $composableBuilder(
    column: $table.lastMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMsgType => $composableBuilder(
    column: $table.lastMsgType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMsgContent => $composableBuilder(
    column: $table.lastMsgContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMsgSender => $composableBuilder(
    column: $table.lastMsgSender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastMsgEncrypted => $composableBuilder(
    column: $table.lastMsgEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMsgTime => $composableBuilder(
    column: $table.lastMsgTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerNickname => $composableBuilder(
    column: $table.peerNickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerAvatarUrl => $composableBuilder(
    column: $table.peerAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupAvatarUrl => $composableBuilder(
    column: $table.groupAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get privateFlag => $composableBuilder(
    column: $table.privateFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dissolved => $composableBuilder(
    column: $table.dissolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draft => $composableBuilder(
    column: $table.draft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMsgId => $composableBuilder(
    column: $table.lastMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMsgType => $composableBuilder(
    column: $table.lastMsgType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMsgContent => $composableBuilder(
    column: $table.lastMsgContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMsgSender => $composableBuilder(
    column: $table.lastMsgSender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastMsgEncrypted => $composableBuilder(
    column: $table.lastMsgEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMsgTime => $composableBuilder(
    column: $table.lastMsgTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerNickname => $composableBuilder(
    column: $table.peerNickname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerAvatarUrl => $composableBuilder(
    column: $table.peerAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupAvatarUrl => $composableBuilder(
    column: $table.groupAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeq =>
      $composableBuilder(column: $table.lastSeq, builder: (column) => column);

  GeneratedColumn<bool> get muted =>
      $composableBuilder(column: $table.muted, builder: (column) => column);

  GeneratedColumn<bool> get privateFlag => $composableBuilder(
    column: $table.privateFlag,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dissolved =>
      $composableBuilder(column: $table.dissolved, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<String> get draft =>
      $composableBuilder(column: $table.draft, builder: (column) => column);

  GeneratedColumn<String> get lastMsgId =>
      $composableBuilder(column: $table.lastMsgId, builder: (column) => column);

  GeneratedColumn<String> get lastMsgType => $composableBuilder(
    column: $table.lastMsgType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMsgContent => $composableBuilder(
    column: $table.lastMsgContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMsgSender => $composableBuilder(
    column: $table.lastMsgSender,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastMsgEncrypted => $composableBuilder(
    column: $table.lastMsgEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMsgTime => $composableBuilder(
    column: $table.lastMsgTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            Conversation,
            BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
          ),
          Conversation,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int?> peerUserId = const Value.absent(),
                Value<String?> peerNickname = const Value.absent(),
                Value<String?> peerAvatarUrl = const Value.absent(),
                Value<String?> groupAvatarUrl = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int?> lastSeq = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<bool> privateFlag = const Value.absent(),
                Value<bool> dissolved = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<String?> draft = const Value.absent(),
                Value<String?> lastMsgId = const Value.absent(),
                Value<String?> lastMsgType = const Value.absent(),
                Value<String?> lastMsgContent = const Value.absent(),
                Value<int?> lastMsgSender = const Value.absent(),
                Value<bool> lastMsgEncrypted = const Value.absent(),
                Value<DateTime?> lastMsgTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                type: type,
                title: title,
                peerUserId: peerUserId,
                peerNickname: peerNickname,
                peerAvatarUrl: peerAvatarUrl,
                groupAvatarUrl: groupAvatarUrl,
                unreadCount: unreadCount,
                lastSeq: lastSeq,
                muted: muted,
                privateFlag: privateFlag,
                dissolved: dissolved,
                pinned: pinned,
                pinnedAt: pinnedAt,
                draft: draft,
                lastMsgId: lastMsgId,
                lastMsgType: lastMsgType,
                lastMsgContent: lastMsgContent,
                lastMsgSender: lastMsgSender,
                lastMsgEncrypted: lastMsgEncrypted,
                lastMsgTime: lastMsgTime,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                Value<String?> title = const Value.absent(),
                Value<int?> peerUserId = const Value.absent(),
                Value<String?> peerNickname = const Value.absent(),
                Value<String?> peerAvatarUrl = const Value.absent(),
                Value<String?> groupAvatarUrl = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int?> lastSeq = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<bool> privateFlag = const Value.absent(),
                Value<bool> dissolved = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<String?> draft = const Value.absent(),
                Value<String?> lastMsgId = const Value.absent(),
                Value<String?> lastMsgType = const Value.absent(),
                Value<String?> lastMsgContent = const Value.absent(),
                Value<int?> lastMsgSender = const Value.absent(),
                Value<bool> lastMsgEncrypted = const Value.absent(),
                Value<DateTime?> lastMsgTime = const Value.absent(),
                required DateTime updatedAt,
              }) => ConversationsCompanion.insert(
                id: id,
                type: type,
                title: title,
                peerUserId: peerUserId,
                peerNickname: peerNickname,
                peerAvatarUrl: peerAvatarUrl,
                groupAvatarUrl: groupAvatarUrl,
                unreadCount: unreadCount,
                lastSeq: lastSeq,
                muted: muted,
                privateFlag: privateFlag,
                dissolved: dissolved,
                pinned: pinned,
                pinnedAt: pinnedAt,
                draft: draft,
                lastMsgId: lastMsgId,
                lastMsgType: lastMsgType,
                lastMsgContent: lastMsgContent,
                lastMsgSender: lastMsgSender,
                lastMsgEncrypted: lastMsgEncrypted,
                lastMsgTime: lastMsgTime,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        Conversation,
        BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
      ),
      Conversation,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String msgId,
      Value<int?> globalId,
      required int convId,
      required int senderId,
      required String type,
      Value<String?> content,
      Value<String?> mediaUrl,
      Value<String?> mediaMeta,
      Value<int?> seq,
      Value<bool> encrypted,
      Value<String?> serverStatus,
      Value<String> clientStatus,
      Value<DateTime?> createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> msgId,
      Value<int?> globalId,
      Value<int> convId,
      Value<int> senderId,
      Value<String> type,
      Value<String?> content,
      Value<String?> mediaUrl,
      Value<String?> mediaMeta,
      Value<int?> seq,
      Value<bool> encrypted,
      Value<String?> serverStatus,
      Value<String> clientStatus,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get msgId => $composableBuilder(
    column: $table.msgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get globalId => $composableBuilder(
    column: $table.globalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get convId => $composableBuilder(
    column: $table.convId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaMeta => $composableBuilder(
    column: $table.mediaMeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get encrypted => $composableBuilder(
    column: $table.encrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientStatus => $composableBuilder(
    column: $table.clientStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get msgId => $composableBuilder(
    column: $table.msgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get globalId => $composableBuilder(
    column: $table.globalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get convId => $composableBuilder(
    column: $table.convId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaMeta => $composableBuilder(
    column: $table.mediaMeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get encrypted => $composableBuilder(
    column: $table.encrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientStatus => $composableBuilder(
    column: $table.clientStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get msgId =>
      $composableBuilder(column: $table.msgId, builder: (column) => column);

  GeneratedColumn<int> get globalId =>
      $composableBuilder(column: $table.globalId, builder: (column) => column);

  GeneratedColumn<int> get convId =>
      $composableBuilder(column: $table.convId, builder: (column) => column);

  GeneratedColumn<int> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get mediaMeta =>
      $composableBuilder(column: $table.mediaMeta, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get encrypted =>
      $composableBuilder(column: $table.encrypted, builder: (column) => column);

  GeneratedColumn<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientStatus => $composableBuilder(
    column: $table.clientStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> msgId = const Value.absent(),
                Value<int?> globalId = const Value.absent(),
                Value<int> convId = const Value.absent(),
                Value<int> senderId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> mediaMeta = const Value.absent(),
                Value<int?> seq = const Value.absent(),
                Value<bool> encrypted = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<String> clientStatus = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                msgId: msgId,
                globalId: globalId,
                convId: convId,
                senderId: senderId,
                type: type,
                content: content,
                mediaUrl: mediaUrl,
                mediaMeta: mediaMeta,
                seq: seq,
                encrypted: encrypted,
                serverStatus: serverStatus,
                clientStatus: clientStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String msgId,
                Value<int?> globalId = const Value.absent(),
                required int convId,
                required int senderId,
                required String type,
                Value<String?> content = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> mediaMeta = const Value.absent(),
                Value<int?> seq = const Value.absent(),
                Value<bool> encrypted = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<String> clientStatus = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                msgId: msgId,
                globalId: globalId,
                convId: convId,
                senderId: senderId,
                type: type,
                content: content,
                mediaUrl: mediaUrl,
                mediaMeta: mediaMeta,
                seq: seq,
                encrypted: encrypted,
                serverStatus: serverStatus,
                clientStatus: clientStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
}

mixin _$UsersDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  UsersDaoManager get managers => UsersDaoManager(this);
}

class UsersDaoManager {
  final _$UsersDaoMixin _db;
  UsersDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
}

mixin _$ConversationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ConversationsTable get conversations => attachedDatabase.conversations;
  ConversationsDaoManager get managers => ConversationsDaoManager(this);
}

class ConversationsDaoManager {
  final _$ConversationsDaoMixin _db;
  ConversationsDaoManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db.attachedDatabase, _db.conversations);
}

mixin _$MessagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $MessagesTable get messages => attachedDatabase.messages;
  MessagesDaoManager get managers => MessagesDaoManager(this);
}

class MessagesDaoManager {
  final _$MessagesDaoMixin _db;
  MessagesDaoManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
}
