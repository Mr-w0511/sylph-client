import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../core/audio/audio_player_controller.dart';
import '../../../core/crypto/e2ee_service.dart';
import '../../../core/db/app_database.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/misc_repositories.dart';
import '../../../core/network/ws_frame.dart';
import '../../../core/utils/media_meta.dart';
import '../../../core/utils/message_reply.dart';
import '../../state/providers.dart';

class ChatState {
  final bool loading;
  final bool loadingMore;
  final String? error;
  final bool hasMore;
  final bool busy; // 发图 / E2EE 准备等
  final String? busyHint;

  const ChatState({
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.hasMore = true,
    this.busy = false,
    this.busyHint,
  });

  ChatState copyWith({
    bool? loading,
    bool? loadingMore,
    String? error,
    bool? hasMore,
    bool? busy,
    String? busyHint,
  }) => ChatState(
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
    hasMore: hasMore ?? this.hasMore,
    busy: busy ?? this.busy,
    busyHint: busyHint ?? (busy == true ? this.busyHint : null),
  );
}

class ChatController extends AutoDisposeFamilyNotifier<ChatState, int> {
  static const _historyLimit = 30;
  final _uuid = const Uuid();

  late final int convId = arg;

  @override
  ChatState build(int arg) {
    // 同步设置当前会话：关闭"进入页面→_load 微任务"之间的空窗，
    // 该窗口内到达的消息以前会被误判为非当前会话（误弹通知/红点）。
    unawaited(ref.read(realtimeProvider).setActiveConversation(convId));
    Future.microtask(_load);
    ref.onDispose(() {
      // autoDispose：离开聊天页即触发，补发挂起已读后清除当前会话标记。
      if (ref.read(realtimeProvider).activeConvId == convId) {
        unawaited(ref.read(realtimeProvider).clearActiveConversation());
      }
      // #6 离开聊天页停止语音/音乐播放。
      unawaited(AudioPlayerController.instance.stop());
    });
    return const ChatState(loading: true);
  }

  MessagesDao get _dao => ref.read(messagesDaoProvider);

  Future<void> _load() async {
    final realtime = ref.read(realtimeProvider);
    realtime.activeConvId = convId;
    // 先清本地未读，再拉会话列表：避免服务端滞后的 unreadCount 先覆盖 0。
    await ref.read(conversationsDaoProvider).zeroUnread(convId);
    realtime.markJustRead(convId);
    // 会话详情与首屏历史并行拉取（低配服务器下串行往返白等一个 RTT）；
    // 失败也不阻塞本地缓存渲染——watchRecent 立即显示 SQLite 中的历史。
    final convsFut = realtime.refreshConversations();
    final historyFut =
        ref.read(conversationRepoProvider).history(convId, limit: _historyLimit);
    try {
      await convsFut;
      final history = await historyFut;
      final conv = await ref.read(conversationsDaoProvider).findById(convId);
      // 批量落库：30 条消息一次事务，弱网/低配服务器下显著提速。
      await _dao.upsertRemoteAll(history.map(_toRemoteData));
      await _cacheSenders(history);
      // 私密会话：对端可能已开启，本端也提前准备好公钥束。
      if (conv?.privateFlag == true) {
        unawaited(_ensureBundle());
      }
      final maxSeq = history.isEmpty
          ? conv?.lastSeq
          : history
                .map((m) => m.seq ?? 0)
                .fold<int>(0, (a, b) => a > b ? a : b);
      // 进入会话无条件清本地未读红点（#9）；有位点才向服务端上报已读。
      await ref.read(conversationsDaoProvider).zeroUnread(convId);
      if (maxSeq != null && maxSeq > 0) {
        await ref.read(realtimeProvider).reportRead(convId, maxSeq);
      }
      // 服务端还有更早页，或本地缓存里存在窗口外消息 → 均可向上翻页。
      final cap = ref.read(chatWindowCapProvider(convId));
      final localMore = await _dao.localOlder(convId, cap);
      state = state.copyWith(
        loading: false,
        hasMore: history.length >= _historyLimit || localMore.isNotEmpty,
        error: null,
      );
    } catch (e) {
      // 网络失败：本地缓存仍可浏览，仅在完全没有本地消息时显示错误。
      final localCount = await _dao.countInConversation(convId);
      state = state.copyWith(
        loading: false,
        error: localCount == 0 ? '$e' : null,
      );
    }
  }

  static RemoteMessageData _toRemoteData(MessageModel m) => RemoteMessageData(
        msgId: m.msgId,
        globalId: m.id,
        convId: m.convId,
        senderId: m.senderId,
        type: m.type,
        content: m.content,
        mediaUrl: m.mediaUrl,
        mediaMeta: m.mediaMeta,
        seq: m.seq,
        encrypted: m.encrypted,
        serverStatus: m.status,
        createdAt: m.createdAt,
        fallbackClientStatus: 'SENT',
      );

  Future<void> retry() async {
    state = state.copyWith(loading: true, error: null);
    await _load();
  }

  Future<void> loadOlder() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      // 优先吃本地缓存（零网络、瞬时）：扩大订阅窗口即可显示更早消息。
      final cap0 = ref.read(chatWindowCapProvider(convId));
      final localMore = await _dao.localOlder(convId, cap0,
          pageSize: _historyLimit);
      // 取满一页说明本地大概率还有，扩窗后直接返回，不打扰服务器。
      if (localMore.length >= _historyLimit) {
        ref.read(chatWindowCapProvider(convId).notifier).state =
            cap0 + localMore.length;
        state = state.copyWith(loadingMore: false, hasMore: true);
        return;
      }

      // 本地不足一页：向服务端兜底翻页，本地/网络新增都要计入扩窗量。
      var extra = localMore.length;
      var serverHasMore = false;
      final earliest = await _dao.earliestSeq(convId);
      if (earliest != null) {
        final older = await ref
            .read(conversationRepoProvider)
            .history(convId, beforeSeq: earliest, limit: _historyLimit);
        await _dao.upsertRemoteAll(older.map(_toRemoteData));
        await _cacheSenders(older);
        extra += older.length;
        serverHasMore = older.length >= _historyLimit;
      }
      if (extra > 0) {
        ref.read(chatWindowCapProvider(convId).notifier).state = cap0 + extra;
      }
      state = state.copyWith(
        loadingMore: false,
        hasMore: serverHasMore,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }

  // ---------------- 发送 ----------------

  Future<void> sendText(String raw, {ReplyQuoteData? reply}) async {
    final text = raw.trim();
    if (text.isEmpty || state.busy) return;
    final me = ref.read(sessionControllerProvider).user!;
    final conv = await ref.read(conversationsDaoProvider).findById(convId);
    final msgId = _uuid.v4().replaceAll('-', '');
    final now = DateTime.now();

    String content = text;
    String? meta;
    var encrypted = false;
    if (conv?.privateFlag == true) {
      state = state.copyWith(busy: true, busyHint: 'E2EE');
      try {
        // 引用回复并入明文信封整体加密：引用摘要绝不能以明文经过服务端。
        final plain = buildEncryptedPlaintext(text, reply);
        final r = await _encryptForPeer(plain, conv!.peerUserId!, msgId);
        content = r.content;
        meta = r.metaJson;
        encrypted = true;
      } catch (e) {
        state = state.copyWith(busy: false);
        rethrow;
      }
    } else {
      // 普通会话：引用块寄生在 mediaMeta（服务端原样透传，无需改后端）。
      meta = buildReplyMediaMeta(reply);
    }

    await _dao.insertPending(
      MessagesCompanion.insert(
        msgId: msgId,
        convId: convId,
        senderId: me.id,
        type: 'TEXT',
        content: Value(content),
        mediaMeta: Value(meta),
        encrypted: Value(encrypted),
        clientStatus: const Value('PENDING'),
        createdAt: Value(now),
        updatedAt: now,
      ),
    );
    _postFrame(msgId, {
      'type': 'TEXT',
      'content': content,
      if (meta != null) 'mediaMeta': jsonDecode(meta),
      'encrypted': encrypted,
    });
    state = state.copyWith(busy: false);
  }

  /// 媒体文件大小上限（与后端 sylph.media.max-size-bytes 对齐：20MiB）。
  static const _maxMediaBytes = 20 * 1024 * 1024;

  /// #12 相册选择（图片+视频混合）：移动端走 image_picker（可见视频），
  /// 桌面/web 回退 FilePicker（图片）。
  Future<void> pickAndSendMedia() async {
    if (kIsWeb) {
      await pickAndSendImages();
      return;
    }
    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    if (files.isEmpty) return;
    for (final f in files) {
      final mime = (f.mimeType ?? '').toLowerCase();
      final isVideo = mime.startsWith('video/') ||
          RegExp(r'\.(mp4|mov|m4v|webm)$').hasMatch(f.name.toLowerCase());
      await _sendPickedFile(
        path: f.path,
        filename: f.name,
        isVideo: isVideo,
      );
    }
  }

  /// #12 拍摄：拍照或录像后直接发送。
  Future<void> captureMedia({required bool video}) async {
    final picker = ImagePicker();
    final XFile? f = video
        ? await picker.pickVideo(source: ImageSource.camera)
        : await picker.pickImage(source: ImageSource.camera);
    if (f == null) return;
    await _sendPickedFile(
      path: f.path,
      filename: f.name,
      isVideo: video,
    );
  }

  Future<void> _sendPickedFile({
    required String path,
    required String filename,
    required bool isVideo,
  }) async {
    final me = ref.read(sessionControllerProvider).user!;
    final bytes = await File(path).readAsBytes();
    if (bytes.length > _maxMediaBytes) {
      throw StateError('FILE_TOO_LARGE');
    }
    state = state.copyWith(busy: true, busyHint: 'UPLOAD');
    try {
      final msgId = _uuid.v4().replaceAll('-', '');
      final now = DateTime.now();
      String type;
      MediaModel media;
      String meta;
      if (isVideo) {
        // 探测时长/分辨率（失败用空 meta 兜底）。
        int? durationSec;
        int? width;
        int? height;
        try {
          final probe = VideoPlayerController.file(File(path));
          await probe.initialize();
          durationSec = probe.value.duration.inSeconds;
          width = probe.value.size.width.round();
          height = probe.value.size.height.round();
          await probe.dispose();
        } catch (_) {}
        media = await ref
            .read(mediaRepoProvider)
            .uploadVideo(bytes: bytes, filename: filename);
        type = 'VIDEO';
        meta = jsonEncode({
          'name': media.name,
          'size': media.size,
          'duration': ?durationSec,
          'width': ?width,
          'height': ?height,
        });
      } else {
        media = await ref
            .read(mediaRepoProvider)
            .uploadImage(bytes: bytes, filename: filename);
        type = 'IMAGE';
        meta = MediaMetaInfo.imageMeta(name: media.name, size: media.size);
      }
      await _dao.insertPending(
        MessagesCompanion.insert(
          msgId: msgId,
          convId: convId,
          senderId: me.id,
          type: type,
          content: const Value(''),
          mediaUrl: Value(media.url),
          mediaMeta: Value(meta),
          clientStatus: const Value('PENDING'),
          createdAt: Value(now),
          updatedAt: now,
        ),
      );
      _postFrame(msgId, {
        'type': type,
        'content': '',
        'mediaUrl': media.url,
        'mediaMeta': jsonDecode(meta),
        'encrypted': false,
      });
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// 加号-文件：任意文件 → FILE 消息。
  Future<void> pickAndSendFile() async {
    final me = ref.read(sessionControllerProvider).user!;
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.length > _maxMediaBytes) {
      throw StateError('FILE_TOO_LARGE');
    }
    state = state.copyWith(busy: true, busyHint: 'UPLOAD');
    try {
      final media = await ref
          .read(mediaRepoProvider)
          .uploadFile(bytes: bytes, filename: file.name);
      final msgId = _uuid.v4().replaceAll('-', '');
      final now = DateTime.now();
      final meta = jsonEncode({'name': media.name, 'size': media.size});
      await _dao.insertPending(
        MessagesCompanion.insert(
          msgId: msgId,
          convId: convId,
          senderId: me.id,
          type: 'FILE',
          content: const Value(''),
          mediaUrl: Value(media.url),
          mediaMeta: Value(meta),
          clientStatus: const Value('PENDING'),
          createdAt: Value(now),
          updatedAt: now,
        ),
      );
      _postFrame(msgId, {
        'type': 'FILE',
        'content': '',
        'mediaUrl': media.url,
        'mediaMeta': jsonDecode(meta),
        'encrypted': false,
      });
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// 加号-音乐：选择本地音频文件，按 FILE 类别上传，消息类型 MUSIC。
  Future<void> pickAndSendMusic() async {
    final me = ref.read(sessionControllerProvider).user!;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.length > _maxMediaBytes) {
      throw StateError('FILE_TOO_LARGE');
    }
    state = state.copyWith(busy: true, busyHint: 'UPLOAD');
    try {
      final media = await ref
          .read(mediaRepoProvider)
          .uploadFile(bytes: bytes, filename: file.name);
      final msgId = _uuid.v4().replaceAll('-', '');
      final now = DateTime.now();
      final title = file.name.contains('.')
          ? file.name.substring(0, file.name.lastIndexOf('.'))
          : file.name;
      final meta = jsonEncode({
        'name': media.name,
        'size': media.size,
        'title': title,
        'duration': 0,
      });
      await _dao.insertPending(
        MessagesCompanion.insert(
          msgId: msgId,
          convId: convId,
          senderId: me.id,
          type: 'MUSIC',
          content: const Value(''),
          mediaUrl: Value(media.url),
          mediaMeta: Value(meta),
          clientStatus: const Value('PENDING'),
          createdAt: Value(now),
          updatedAt: now,
        ),
      );
      _postFrame(msgId, {
        'type': 'MUSIC',
        'content': '',
        'mediaUrl': media.url,
        'mediaMeta': jsonDecode(meta),
        'encrypted': false,
      });
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// 加号-位置：lat/lng/address 放在 mediaMeta，无 mediaUrl。
  Future<void> sendLocation({
    required double lat,
    required double lng,
    required String address,
  }) async {
    final me = ref.read(sessionControllerProvider).user!;
    final msgId = _uuid.v4().replaceAll('-', '');
    final now = DateTime.now();
    final meta = jsonEncode({
      'lat': lat,
      'lng': lng,
      'address': address,
    });
    await _dao.insertPending(
      MessagesCompanion.insert(
        msgId: msgId,
        convId: convId,
        senderId: me.id,
        type: 'LOCATION',
        content: const Value(''),
        mediaMeta: Value(meta),
        clientStatus: const Value('PENDING'),
        createdAt: Value(now),
        updatedAt: now,
      ),
    );
    _postFrame(msgId, {
      'type': 'LOCATION',
      'content': '',
      'mediaMeta': jsonDecode(meta),
      'encrypted': false,
    });
  }

  /// 收藏贴纸：贴纸以 IMAGE 消息发送，mediaMeta 标记 sticker。
  Future<void> sendSticker({
    required List<int> bytes,
    required String filename,
  }) async {
    final me = ref.read(sessionControllerProvider).user!;
    state = state.copyWith(busy: true, busyHint: 'UPLOAD');
    try {
      final media = await ref
          .read(mediaRepoProvider)
          .uploadImage(bytes: bytes, filename: filename);
      final msgId = _uuid.v4().replaceAll('-', '');
      final now = DateTime.now();
      final meta = jsonEncode({
        'name': media.name,
        'size': media.size,
        'sticker': true,
      });
      await _dao.insertPending(
        MessagesCompanion.insert(
          msgId: msgId,
          convId: convId,
          senderId: me.id,
          type: 'IMAGE',
          content: const Value(''),
          mediaUrl: Value(media.url),
          mediaMeta: Value(meta),
          clientStatus: const Value('PENDING'),
          createdAt: Value(now),
          updatedAt: now,
        ),
      );
      _postFrame(msgId, {
        'type': 'IMAGE',
        'content': '',
        'mediaUrl': media.url,
        'mediaMeta': jsonDecode(meta),
        'encrypted': false,
      });
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// #15 多图选择：allowMultiple=true，逐张上传逐条发送。
  Future<void> pickAndSendImages() async {
    final me = ref.read(sessionControllerProvider).user!;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    state = state.copyWith(busy: true, busyHint: 'UPLOAD');
    try {
      for (final file in picked.files) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        final media = await ref
            .read(mediaRepoProvider)
            .uploadImage(bytes: bytes, filename: file.name);
        final msgId = _uuid.v4().replaceAll('-', '');
        final now = DateTime.now();
        final meta = MediaMetaInfo.imageMeta(name: media.name, size: media.size);
        await _dao.insertPending(
          MessagesCompanion.insert(
            msgId: msgId,
            convId: convId,
            senderId: me.id,
            type: 'IMAGE',
            content: const Value(''),
            mediaUrl: Value(media.url),
            mediaMeta: Value(meta),
            clientStatus: const Value('PENDING'),
            createdAt: Value(now),
            updatedAt: now,
          ),
        );
        _postFrame(msgId, {
          'type': 'IMAGE',
          'content': '',
          'mediaUrl': media.url,
          'mediaMeta': jsonDecode(meta),
          'encrypted': false,
        });
      }
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// #14 发送语音消息：bytes + duration（秒）。
  Future<void> sendVoice({
    required List<int> bytes,
    required String filename,
    required int durationSec,
  }) async {
    final me = ref.read(sessionControllerProvider).user!;
    state = state.copyWith(busy: true, busyHint: 'UPLOAD');
    try {
      final media = await ref
          .read(mediaRepoProvider)
          .uploadVoice(bytes: bytes, filename: filename);
      final msgId = _uuid.v4().replaceAll('-', '');
      final now = DateTime.now();
      final meta = jsonEncode({
        'duration': durationSec,
        'name': media.name,
        'size': media.size,
      });
      await _dao.insertPending(
        MessagesCompanion.insert(
          msgId: msgId,
          convId: convId,
          senderId: me.id,
          type: 'VOICE',
          content: const Value(''),
          mediaUrl: Value(media.url),
          mediaMeta: Value(meta),
          clientStatus: const Value('PENDING'),
          createdAt: Value(now),
          updatedAt: now,
        ),
      );
      _postFrame(msgId, {
        'type': 'VOICE',
        'content': '',
        'mediaUrl': media.url,
        'mediaMeta': jsonDecode(meta),
        'encrypted': false,
      });
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// 断线重发（复用 msgId，服务端幂等）。
  Future<void> resend(String msgId) async {
    final m = await _dao.byMsgId(msgId);
    if (m == null) return;
    await _dao.updateClientStatus(msgId, 'PENDING');
    _postFrame(msgId, {
      'type': m.type,
      'content': m.content ?? '',
      if (m.mediaUrl != null) 'mediaUrl': m.mediaUrl,
      if (m.mediaMeta != null) 'mediaMeta': jsonDecode(m.mediaMeta!),
      'encrypted': m.encrypted,
    });
  }

  void _postFrame(String msgId, Map<String, dynamic> data) {
    final sent = ref
        .read(realtimeProvider)
        .sendFrame(
          WsFrame(
            type: WsType.msgSend,
            msgId: msgId,
            convId: convId,
            data: data,
          ),
        );
    if (!sent) {
      // 离线：保留 PENDING，重连后由待发队列补发。
    }
  }

  /// #18 撤回消息：调用后端 recall API，成功后本地转换为撤回系统提示。
  /// 失败会抛出异常，由 UI 层提示。
  Future<void> recallMessage(Message message) async {
    final msgId = message.msgId;
    final globalId = message.globalId;
    if (globalId == null) {
      // 消息尚未在服务端落库（PENDING），无法撤回。
      throw StateError('消息尚未送达，暂时无法撤回');
    }
    await ref.read(conversationRepoProvider).recall(globalId);
    // 本地转换为统一的“已撤回”系统提示（同时写 RECALLED 状态）。
    final meId = ref.read(sessionControllerProvider).user?.id;
    final role =
        ref.read(groupDetailProvider(convId)).valueOrNull?.myRole;
    final byAdmin = (role == 'OWNER' || role == 'ADMIN') &&
        message.senderId != meId;
    await _dao.markRecalled(msgId, by: meId, byAdmin: byAdmin);
    // 撤回的若是最后一条，列表预览同步为"撤回了一条消息"。
    await ref
        .read(conversationsDaoProvider)
        .markLastRecalled(convId, msgId);
    ref.invalidate(chatMessagesProvider(convId));
    await ref.read(realtimeProvider).refreshConversations();
  }

  /// 批量缓存群聊消息发送者昵称/头像到 Users 表（按 userId 去重，
  /// 同一批 30 条通常只有几个发送者），供 [chatSenderProvider] 展示。
  Future<void> _cacheSenders(List<MessageModel> msgs) async {
    final byUser = <int, MessageModel>{};
    for (final m in msgs) {
      final nick = m.senderNickname;
      if (nick == null || nick.isEmpty) continue;
      byUser.putIfAbsent(m.senderId, () => m);
    }
    final usersDao = ref.read(usersDaoProvider);
    final now = DateTime.now();
    for (final m in byUser.values) {
      await usersDao.upsert(
        UsersCompanion.insert(
          id: Value(m.senderId),
          username: m.senderNickname!,
          nickname: m.senderNickname!,
          avatarUrl: Value(m.senderAvatarUrl),
          updatedAt: now,
        ),
      );
    }
  }

  // ---------------- 私密会话 ----------------

  Future<void> _ensureBundle() async {
    // 不再使用"一次性永久就绪"标志：ensureBundleUploaded 内部做轻量 GET 校验，
    // 服务端束缺失（404）/身份不一致/OTK 池过低都会自愈重传。
    await ref.read(e2eeServiceProvider).ensureBundleUploaded();
  }

  Future<E2eeCryptoResult> _encryptForPeer(
    String plaintext,
    int peerUserId,
    String msgId,
  ) {
    return encryptE2eeMessage(
      e2ee: ref.read(e2eeServiceProvider),
      e2eeRepo: ref.read(e2eeRepoProvider),
      sentCache: ref.read(e2eeSentCacheProvider.notifier),
      plaintext: plaintext,
      peerUserId: peerUserId,
      msgId: msgId,
    );
  }

  /// 聊天页开关：POST /conversations/{id}/private。
  /// #3 修复：开启私密模式时若密钥束准备失败，给出明确提示而不是裸 UnimplementedError。
  Future<void> setPrivate(bool flag) async {
    if (flag) {
      state = state.copyWith(busy: true, busyHint: 'E2EE');
    }
    try {
      if (flag) {
        try {
          await _ensureBundle();
        } catch (e) {
          // 密钥束上传失败：向用户给出明确错误，而不是直接抛出底层异常。
          throw StateError('e2ee-bundle-unavailable: ${e.toString()}');
        }
      }
      await ref.read(conversationRepoProvider).setPrivate(convId, flag);
      await ref.read(conversationsDaoProvider).setPrivate(convId, flag);
      await ref.read(realtimeProvider).refreshConversations();
    } finally {
      state = state.copyWith(busy: false);
    }
  }
}

final chatControllerProvider =
    AutoDisposeNotifierProvider.family<ChatController, ChatState, int>(
      ChatController.new,
    );

// ---------------- 数据流 ----------------

/// 聊天页订阅窗口容量：默认最新 300 条走本地 SQLite，
/// 低配服务器下进页面零网络即可秒开；上滑翻页时按页扩大。
final chatWindowCapProvider = StateProvider.autoDispose.family<int, int>(
  (ref, id) => 300,
);

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, int>((ref, id) {
      final cap = ref.watch(chatWindowCapProvider(id));
      return ref.watch(messagesDaoProvider).watchRecent(id, cap);
    });

final chatConversationProvider = StreamProvider.autoDispose
    .family<Conversation?, int>((ref, id) {
      return ref.watch(conversationsDaoProvider).watchById(id);
    });

/// 群聊消息发送者昵称（按 userId 查本地缓存）。
final chatSenderProvider = FutureProvider.autoDispose.family<User?, int>((
  ref,
  userId,
) {
  return ref.watch(usersDaoProvider).findById(userId);
});

/// 自己已发送密文的明文缓存（密文存 DB，明文仅本机备查）。
class E2eeSentCacheNotifier extends Notifier<Map<String, String>> {
  static const _key = 'e2ee.sentcache';
  static const _max = 300;

  @override
  Map<String, String> build() {
    final store = ref.read(secureStoreProvider);
    () async {
      final raw = await store.read(_key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        state = m.map((k, v) => MapEntry(k, v as String));
      }
    }();
    return const {};
  }

  String? get(String msgId) => state[msgId];

  Future<void> put(String msgId, String plaintext) async {
    final next = Map<String, String>.from(state);
    next[msgId] = plaintext;
    // 简单 LRU：超量丢弃最早写入的若干条。
    if (next.length > _max) {
      final excess = next.length - _max;
      next.removeWhere((k, _) => next.keys.toList().indexOf(k) < excess);
    }
    state = next;
    await ref.read(secureStoreProvider).write(_key, jsonEncode(next));
  }
}

final e2eeSentCacheProvider =
    NotifierProvider<E2eeSentCacheNotifier, Map<String, String>>(
      E2eeSentCacheNotifier.new,
    );

/// E2EE 发送编排（聊天发送 / 转发共用，避免两份实现漂移）：
/// 预热并自愈公钥束 → claim 对端束 → 加密 → 明文入本机缓存 → 异步补充 OTK 池。
Future<E2eeCryptoResult> encryptE2eeMessage({
  required E2eeService e2ee,
  required E2eeRepository e2eeRepo,
  required E2eeSentCacheNotifier sentCache,
  required String plaintext,
  required int peerUserId,
  required String msgId,
}) async {
  await e2ee.ensureBundleUploaded();
  final bundles = await e2eeRepo.claim(peerUserId);
  if (bundles.isEmpty) {
    throw StateError('peer-bundle-unavailable');
  }
  final result = await e2ee.encrypt(plaintext, bundles.first);
  await sentCache.put(msgId, plaintext);
  unawaited(e2ee.replenishIfLow());
  return result;
}

/// 气泡明文解析（加密消息异步解密；失败/无密钥返回 null → 占位文案）。
final messagePlaintextProvider = FutureProvider.autoDispose
    .family<String?, Message>((ref, m) async {
      if (!m.encrypted) return m.content;
      final me = ref.read(sessionControllerProvider).user?.id;
      if (m.senderId == me) {
        // 等待本机已发缓存水合。
        for (var i = 0; i < 20; i++) {
          final cached = ref.read(e2eeSentCacheProvider)[m.msgId];
          if (cached != null) return cached;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return ref.read(e2eeSentCacheProvider)[m.msgId];
      }
      try {
        return await ref
            .read(e2eeServiceProvider)
            .decrypt(m.content ?? '', m.mediaMeta);
      } catch (_) {
        return null;
      }
    });
