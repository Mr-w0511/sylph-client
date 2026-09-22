import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// 用户缓存（自己 + 单聊对端）。
class Users extends Table {
  IntColumn get id => integer()();
  TextColumn get username => text()();
  TextColumn get nickname => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get gender => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 会话列表缓存（含最后消息冗余快照，弱网下先渲染缓存）。
class Conversations extends Table {
  IntColumn get id => integer()();
  TextColumn get type => text()(); // SINGLE / GROUP
  TextColumn get title => text().nullable()();
  IntColumn get peerUserId => integer().nullable()();
  TextColumn get peerNickname => text().nullable()();
  TextColumn get peerAvatarUrl => text().nullable()();

  // v3：群头像（服务端会话列表 DTO 不带群头像，由群事件/上传成功后回写）。
  TextColumn get groupAvatarUrl => text().nullable()();

  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get lastSeq => integer().nullable()();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  BoolColumn get privateFlag => boolean().withDefault(const Constant(false))();
  BoolColumn get dissolved => boolean().withDefault(const Constant(false))();

  // v2：会话置顶。
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get pinnedAt => dateTime().nullable()();

  // v4：输入框草稿（退出聊天页保留，会话列表展示 [草稿]）。
  TextColumn get draft => text().nullable()();

  TextColumn get lastMsgId => text().nullable()();
  TextColumn get lastMsgType => text().nullable()();
  TextColumn get lastMsgContent => text().nullable()();
  IntColumn get lastMsgSender => integer().nullable()();
  BoolColumn get lastMsgEncrypted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastMsgTime => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 消息缓存。
/// - [msgId] 为客户端/服务端共用的幂等主键（信封层 msgId）；
/// - [globalId] 为 t_message 全局自增 id（同步游标），待发期间为空；
/// - [clientStatus] 为端侧状态机：PENDING/SENT/DELIVERED/READ/FAILED。
class Messages extends Table {
  TextColumn get msgId => text()();
  IntColumn get globalId => integer().nullable().unique()();
  IntColumn get convId => integer()();
  IntColumn get senderId => integer()();
  TextColumn get type => text()(); // TEXT/IMAGE/VOICE/VIDEO/FILE
  TextColumn get content => text().nullable()();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaMeta => text().nullable()();
  IntColumn get seq => integer().nullable()();
  BoolColumn get encrypted => boolean().withDefault(const Constant(false))();
  TextColumn get serverStatus => text().nullable()(); // NORMAL/BLOCKED
  TextColumn get clientStatus => text().withDefault(const Constant('SENT'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {msgId};
}

@DriftDatabase(tables: [Users, Conversations, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 → v2：会话表新增置顶字段。
          if (from < 2) {
            await m.addColumn(conversations, conversations.pinned);
            await m.addColumn(conversations, conversations.pinnedAt);
          }
          // v2 → v3：会话表新增群头像列。
          if (from < 3) {
            await m.addColumn(conversations, conversations.groupAvatarUrl);
          }
          // v3 → v4：会话表新增草稿列。
          if (from < 4) {
            await m.addColumn(conversations, conversations.draft);
          }
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'sylph',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}

// ---------------- DAO ----------------

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<void> upsert(UsersCompanion entry) =>
      into(users).insertOnConflictUpdate(entry);

  Future<User?> findById(int id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();
}

@DriftAccessor(tables: [Conversations])
class ConversationsDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationsDaoMixin {
  ConversationsDao(super.db);

  /// 冲突时只更新 companion 中显式携带的列——保留本地自存字段（如 groupAvatarUrl）
  /// 不被服务端列表同步覆盖为空。
  Future<void> upsertAll(Iterable<ConversationsCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(conversations, entries));

  Future<Conversation?> findById(int id) =>
      (select(conversations)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<Conversation?> watchById(int id) =>
      (select(conversations)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  Stream<List<Conversation>> watchAll() {
    // 排序优先级（组内多级）：
    // 1) 置顶；
    // 2) 红色未读（未读>0 且未免打扰）；
    // 3) 任意未读（免打扰的灰色未读排在红色未读之后、无未读之前）；
    // 4) 置顶时间/最后消息时间/更新时间倒序。
    final q = select(conversations)
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.pinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(
            expression:
                t.unreadCount.isBiggerThanValue(0) & t.muted.not(),
            mode: OrderingMode.desc),
        (t) => OrderingTerm(
            expression: t.unreadCount.isBiggerThanValue(0),
            mode: OrderingMode.desc),
        (t) => OrderingTerm(
            expression:
                coalesce([t.pinnedAt, t.lastMsgTime, t.updatedAt]),
            mode: OrderingMode.desc),
        (t) => OrderingTerm(
            expression: t.lastMsgTime, mode: OrderingMode.desc),
        (t) => OrderingTerm(
            expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  Future<void> setPrivate(int id, bool flag) =>
      (update(conversations)..where((t) => t.id.equals(id)))
          .write(ConversationsCompanion(privateFlag: Value(flag)));

  /// 置顶 / 取消置顶（取消时清空 pinnedAt）。
  Future<void> setPinned(int id, bool pinned, DateTime? at) =>
      (update(conversations)..where((t) => t.id.equals(id))).write(
        ConversationsCompanion(
          pinned: Value(pinned),
          pinnedAt: Value(pinned ? at : null),
        ),
      );

  /// 免打扰开关。
  Future<void> setMuted(int id, bool muted) =>
      (update(conversations)..where((t) => t.id.equals(id)))
          .write(ConversationsCompanion(muted: Value(muted)));

  Future<void> zeroUnread(int id) =>
      (update(conversations)..where((t) => t.id.equals(id)))
          .write(const ConversationsCompanion(unreadCount: Value(0)));

  /// 群头像回写：群设置页上传成功 / 收到群资料变更事件时调用。
  Future<void> setGroupAvatar(int id, String? url) =>
      (update(conversations)..where((t) => t.id.equals(id)))
          .write(ConversationsCompanion(groupAvatarUrl: Value(url)));

  /// 群资料回写（改名换头像）：GROUP_EVENT PROFILE 携带时直接更新本地行。
  Future<void> updateGroupMeta(int id,
          {String? title, String? avatarUrl}) =>
      (update(conversations)..where((t) => t.id.equals(id))).write(
        ConversationsCompanion(
          title: title == null ? const Value.absent() : Value(title),
          groupAvatarUrl:
              avatarUrl == null ? const Value.absent() : Value(avatarUrl),
        ),
      );

  /// 删除不在 validIds 中的会话（用于同步后清理已终止/已退群的本地残留）。
  Future<int> deleteAbsent(Set<int> validIds) =>
      (delete(conversations)..where((t) => t.id.isNotIn(validIds))).go();

  /// 保存/清空输入框草稿。
  Future<void> setDraft(int id, String? draft) =>
      (update(conversations)..where((t) => t.id.equals(id)))
          .write(ConversationsCompanion(draft: Value(draft)));

  /// 撤回的消息恰好是会话最后一条时，把列表快照类型置为 RECALLED，
  /// 由会话列表渲染为"撤回了一条消息"（避免显示原文或原始 RECALL:: 编码）。
  Future<void> markLastRecalled(int convId, String msgId) =>
      (update(conversations)
            ..where((t) =>
                t.id.equals(convId) & t.lastMsgId.equals(msgId)))
          .write(const ConversationsCompanion(
        lastMsgType: Value('RECALLED'),
        lastMsgContent: Value(null),
      ));
}

@DriftAccessor(tables: [Messages])
class MessagesDao extends DatabaseAccessor<AppDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(super.db);

  /// 待发队列（断网排队 / 重连补发，已随消息表持久化）。
  /// 注意：只捞 PENDING——发送失败（如拉黑期被拦截）的消息不自动重发，
  /// 否则解除拉黑后会在错误的时间点补发出去。
  Future<List<Message>> pending() => (select(messages)
        ..where((t) => t.clientStatus.equals('PENDING'))
        ..orderBy([(t) => OrderingTerm(expression: t.updatedAt)]))
      .get();

  Future<Message?> byMsgId(String msgId) =>
      (select(messages)..where((t) => t.msgId.equals(msgId)))
          .getSingleOrNull();

  /// #5 全局搜索：仅检索本地可见的文本消息（未加密、未被拦截），
  /// 按时间倒序限量返回；会话标题由调用方关联 ConversationsDao 解析。
  Future<List<Message>> searchContent(String keyword,
      {int limit = 50}) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return const [];
    final like = '%$kw%';
    final q = select(messages)
      ..where((t) =>
          t.type.equals('TEXT') &
          t.encrypted.equals(false) &
          t.content.like(like) &
          (t.serverStatus.isNull() |
              t.serverStatus.equals('NORMAL')))
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return q.get();
  }

  /// #5 全局搜索（按会话聚合）：返回每个会话的匹配数量 + 最近一条命中内容。
  /// 先按消息级拉 200 条命中，Dart 层按 convId 分组统计。
  Future<List<GroupedHit>> searchContentGrouped(String keyword,
      {int limit = 30}) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return const [];
    final like = '%$kw%';
    final hits = await (select(messages)
          ..where((t) =>
              t.type.equals('TEXT') &
              t.encrypted.equals(false) &
              t.content.like(like) &
              (t.serverStatus.isNull() |
                  t.serverStatus.equals('NORMAL')))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ])
          ..limit(200))
        .get();

    // Dart 层按 convId 分组统计
    final grouped = <int, GroupedHit>{};
    for (final m in hits) {
      final existing = grouped[m.convId];
      if (existing == null) {
        grouped[m.convId] = GroupedHit(
          convId: m.convId,
          hitCount: 1,
          lastHitContent: m.content ?? '',
          lastHitAt: m.updatedAt,
        );
      } else {
        existing.hitCount++;
        // 保持最近一条命中的内容
        if (existing.lastHitAt.isBefore(m.updatedAt)) {
          existing.lastHitContent = m.content ?? '';
          existing.lastHitAt = m.updatedAt;
        }
      }
    }
    final list = grouped.values.toList()
      ..sort((a, b) => b.lastHitAt.compareTo(a.lastHitAt))
      ..take(limit);
    return list;
  }

  Future<int?> maxGlobalId() async {
    final row = await (messages.selectOnly()
          ..addColumns([messages.globalId.max()]))
        .getSingle();
    return row.read(messages.globalId.max());
  }

  /// 聊天页消息流：按消息真实时间（createdAt 缺失时退回 updatedAt）升序。
  /// 这样发送失败/被拦截（无 seq）的消息也停留在它发送时的位置，
  /// 而不是被钉在列表最后；时间相同再按 seq 稳定排序。
  Stream<List<Message>> watchConversation(int convId) {
    final q = select(messages)
      ..where((t) => t.convId.equals(convId))
      ..orderBy([
        (t) => OrderingTerm(
            expression: coalesce([t.createdAt, t.updatedAt]),
            mode: OrderingMode.asc),
        (t) => OrderingTerm(
            expression: t.seq.isNull(), mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.seq, mode: OrderingMode.asc),
      ]);
    return q.watch();
  }

  Future<int?> earliestSeq(int convId) async {
    final row = await (messages.selectOnly()
          ..where(messages.convId.equals(convId) & messages.seq.isNotNull())
          ..addColumns([messages.seq.min()]))
        .getSingle();
    return row.read(messages.seq.min());
  }

  /// 本地某会话的消息总数（网络失败时判断是否有缓存可浏览）。
  Future<int> countInConversation(int convId) async {
    final countExp = messages.msgId.count();
    final row = await (messages.selectOnly()
          ..where(messages.convId.equals(convId))
          ..addColumns([countExp]))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  /// 聊天页消息窗口：仅订阅最新 [cap] 条，避免长会话全量映射；
  /// 查询按时间倒序取窗口，Dart 层 reverse 回升序供 ListView 直接使用。
  Stream<List<Message>> watchRecent(int convId, int cap) {
    final q = select(messages)
      ..where((t) => t.convId.equals(convId))
      ..orderBy([
        (t) => OrderingTerm(
            expression: coalesce([t.createdAt, t.updatedAt]),
            mode: OrderingMode.desc),
        // 时间相同时，有 seq 的排前面（desc 取窗口时优先保留）。
        (t) => OrderingTerm(expression: t.seq.isNull(), mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.seq, mode: OrderingMode.desc),
      ])
      ..limit(cap);
    return q.watch().map((rows) => rows.reversed.toList());
  }

  /// 取当前窗口（最新 [cap] 条）之前更早的本地消息，最多 [pageSize] 条，
  /// 返回顺序为时间升序。无更多本地数据时返回空列表（调用方再走网络分页）。
  Future<List<Message>> localOlder(int convId, int cap,
      {int pageSize = 30}) async {
    final windowQ = select(messages)
      ..where((t) => t.convId.equals(convId))
      ..orderBy([
        (t) => OrderingTerm(
            expression: coalesce([t.createdAt, t.updatedAt]),
            mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.seq.isNull(), mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.seq, mode: OrderingMode.desc),
      ])
      ..limit(cap);
    final window = await windowQ.get();
    if (window.length < cap) return const []; // 本地总量未超窗口，无更早数据。
    final anchor = window.last; // 倒序窗口的最后一条 = 最早可见消息。
    final anchorTime = anchor.createdAt ?? anchor.updatedAt;
    final q = select(messages)
      ..where((t) =>
          t.convId.equals(convId) &
          coalesce([t.createdAt, t.updatedAt]).isSmallerThanValue(anchorTime))
      ..orderBy([
        (t) => OrderingTerm(
            expression: coalesce([t.createdAt, t.updatedAt]),
            mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.seq.isNull(), mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.seq, mode: OrderingMode.desc),
      ])
      ..limit(pageSize);
    final rows = await q.get();
    return rows.reversed.toList();
  }

  /// 写入待发消息。
  Future<void> insertPending(MessagesCompanion entry) =>
      into(messages).insert(entry, mode: InsertMode.insertOrReplace);

  /// 合并服务端消息（历史 / 同步 / 投递 / ACK）。按 msgId 幂等：
  /// 已存在则只更新服务端字段，且不把端侧状态降级。
  Future<void> upsertRemote({
    required String msgId,
    int? globalId,
    required int convId,
    required int senderId,
    required String type,
    String? content,
    String? mediaUrl,
    String? mediaMeta,
    int? seq,
    bool encrypted = false,
    String? serverStatus,
    DateTime? createdAt,
    required String fallbackClientStatus,
  }) async {
    final existing = await byMsgId(msgId);
    final now = DateTime.now();
    final data = RemoteMessageData(
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
      createdAt: createdAt,
      fallbackClientStatus: fallbackClientStatus,
    );
    if (existing == null) {
      await into(messages)
          .insertOnConflictUpdate(_insertCompanion(data, now));
      return;
    }
    await (update(messages)..where((t) => t.msgId.equals(msgId)))
        .write(_updateCompanion(data, existing, now));
  }

  /// 批量合并服务端消息（历史分页）：一次查询 + 单事务写入，
  /// 合并规则与 [upsertRemote] 完全一致，把弱网下首屏 30 条的
  /// 60+ 次 SQLite 往返压缩为 1 次。
  Future<void> upsertRemoteAll(Iterable<RemoteMessageData> items) async {
    final list = items.toList();
    if (list.isEmpty) return;
    final ids = list.map((e) => e.msgId).toList();
    final existingRows = await (select(messages)
          ..where((t) => t.msgId.isIn(ids)))
        .get();
    final existingMap = {for (final m in existingRows) m.msgId: m};
    final now = DateTime.now();
    await batch((b) {
      for (final d in list) {
        final ex = existingMap[d.msgId];
        if (ex == null) {
          b.insert(messages, _insertCompanion(d, now),
              mode: InsertMode.insertOrReplace);
        } else {
          b.update(messages, _updateCompanion(d, ex, now),
              where: (t) => t.msgId.equals(d.msgId));
        }
      }
    });
  }

  MessagesCompanion _insertCompanion(RemoteMessageData d, DateTime now) =>
      MessagesCompanion.insert(
        msgId: d.msgId,
        globalId: Value(d.globalId),
        convId: d.convId,
        senderId: d.senderId,
        type: d.type,
        content: Value(d.content),
        mediaUrl: Value(d.mediaUrl),
        mediaMeta: Value(d.mediaMeta),
        seq: Value(d.seq),
        encrypted: Value(d.encrypted),
        serverStatus: Value(d.serverStatus),
        clientStatus: Value(d.fallbackClientStatus),
        createdAt: Value(d.createdAt),
        updatedAt: now,
      );

  MessagesCompanion _updateCompanion(
      RemoteMessageData d, Message existing, DateTime now) {
    return MessagesCompanion(
      globalId: Value(d.globalId ?? existing.globalId),
      type: Value(d.type),
      content: Value(d.content ?? existing.content),
      mediaUrl: Value(d.mediaUrl ?? existing.mediaUrl),
      mediaMeta: Value(d.mediaMeta ?? existing.mediaMeta),
      seq: Value(d.seq ?? existing.seq),
      encrypted: Value(d.encrypted),
      serverStatus: Value(d.serverStatus ?? existing.serverStatus),
      clientStatus:
          Value(_mergeStatus(existing.clientStatus, d.fallbackClientStatus)),
      // 保留本地更早的发送时间：服务端历史回补的 createdAt 可能晚于
      // 端侧实际发送时刻，若直接覆盖会造成消息在列表中“跳位”。
      createdAt: Value(_earlier(existing.createdAt, d.createdAt)),
      updatedAt: Value(now),
    );
  }

  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  Future<void> updateClientStatus(String msgId, String status,
      {String? serverStatus}) {
    return (update(messages)..where((t) => t.msgId.equals(msgId))).write(
      MessagesCompanion(
        clientStatus: Value(status),
        serverStatus: Value(serverStatus),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 收到 ACK_DELIVERED / ACK_READ：把“我发给该会话、seq<=位点”的消息推进。
  Future<void> advanceMyStatus({
    required int convId,
    required int toSeq,
    required int myUserId,
    required String status,
  }) async {
    final affected = await (select(messages)
          ..where((t) =>
              t.convId.equals(convId) &
              t.senderId.equals(myUserId) &
              t.seq.isNotNull() &
              t.seq.isSmallerOrEqualValue(toSeq)))
        .get();
    await batch((b) {
      for (final m in affected) {
        final next = _mergeStatus(m.clientStatus, status);
        if (next != m.clientStatus) {
          b.replace(
              messages, m.copyWith(clientStatus: next, updatedAt: DateTime.now()));
        }
      }
    });
  }

  /// 管理/撤回：本地将消息替换为系统提示。
  /// #7 [by] 撤回操作者用户 id；[byAdmin] 是否为群主/管理员撤回他人消息。
  /// content 编码为 `RECALL::<byUserId>::<byAdmin>`，由气泡解析出具名提示。
  Future<void> markRecalled(String msgId,
      {int? by, bool byAdmin = false}) async {
    final existing = await byMsgId(msgId);
    if (existing == null) return;
    await (update(messages)..where((t) => t.msgId.equals(msgId))).write(
      MessagesCompanion(
        type: const Value('SYSTEM'),
        content: Value(by == null
            ? '该消息已被撤回'
            : 'RECALL::$by::${byAdmin ? 1 : 0}'),
        mediaUrl: const Value(null),
        mediaMeta: const Value(null),
        // 同步服务端状态，撤回消息在任何合并路径下都保持统一文案。
        serverStatus: const Value('RECALLED'),
        clientStatus: const Value('SENT'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 管理删除：本地物理移除。
  Future<void> removeByMsgId(String msgId) =>
      (delete(messages)..where((t) => t.msgId.equals(msgId))).go();

  static const _rank = {
    'PENDING': 0,
    'FAILED': 0,
    'SENT': 1,
    'DELIVERED': 2,
    'READ': 3,
  };

  String _mergeStatus(String current, String incoming) {
    final a = _rank[current] ?? 1;
    final b = _rank[incoming] ?? 1;
    return b > a ? incoming : current;
  }
}

/// #5 全局搜索按会话聚合结果。
class GroupedHit {
  final int convId;
  int hitCount;
  String lastHitContent;
  DateTime lastHitAt;

  GroupedHit({
    required this.convId,
    required this.hitCount,
    required this.lastHitContent,
    required this.lastHitAt,
  });
}

/// 服务端消息的纯数据载体（历史批量入库用），字段与 Messages 表对齐。
class RemoteMessageData {
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
  final DateTime? createdAt;
  final String fallbackClientStatus;

  const RemoteMessageData({
    required this.msgId,
    this.globalId,
    required this.convId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.mediaMeta,
    this.seq,
    this.encrypted = false,
    this.serverStatus,
    this.createdAt,
    this.fallbackClientStatus = 'SENT',
  });
}
