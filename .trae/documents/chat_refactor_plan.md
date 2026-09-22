# 聊天相关改造实施计划（Flutter / sylph client）

## 调研结论（关键事实）

- `Conversation` drift 模型：`peerUserId int?`（即对端数字 id）、`peerNickname`、`peerAvatarUrl`、`muted`、`pinned`、`pinnedAt`、`lastSeq int?`、`privateFlag`。**无 peerUid 字段**。
- `UserBrief`（models.dart L333-367）字段：id/uid/username/nickname/avatarUrl/bio/gender/relation。**无 region 字段** → 资料页地区行按要求跳过。
- 群身份：`GroupBrief`/`GroupModel` 只有 `convId`（后端群资源全部以 convId 为 key），**无独立 groupId** → 举报群 targetId 只能用 conv.id。
- 官方助手识别：`peerUserId == 10000000` 或 `peerNickname == kSystemAssistantName`（user_avatar.dart 常量）。
- DAO：`setPinned(int id, bool pinned, DateTime? at)` 三参；`setMuted(id, muted)`；`zeroUnread(id)`；`findById`。
- `chat_controller._load` L107-112 **已有** history 为空时用 `conv.lastSeq` 兜底上报逻辑（保留即可）。
- providers.dart Realtime：`activeConvId` 为裸字段；MSG_DELIVER 已判断 activeConvId 但**无生命周期判断**；`reportRead` catch 静默；`_scheduleReadReport` 防抖 timer 在 stop 时仅 cancel 不补发；Realtime 非 WidgetsBindingObserver。
- chat_controller onDispose 已内联清空 activeConvId（保留语义，改调新方法）。
- Gal 2.3.3：`Gal.putImageBytes(Uint8List, {album, name})`，失败抛 `GalException`（`type.message`）。
- file_picker 8.3.7：`FilePicker.platform.saveFile({dialogTitle, fileName, bytes})` 支持 bytes。
- photo_view 0.15 已就位；dio 5 已就位。
- 路由：go_router，extra 传对象；/user-profile extra: UserBrief 已存在。
- socialRepo：block/unblock/cancelRequest/report/setRemark/outgoingRequests 齐备；conversationRepo：mute/pin/delete 齐备；groupRepo.leave(convId)。
- 备注：drift 会话无 remark 字段，设置备注弹窗预填 peerNickname，调 `socialRepo.setRemark(peerUserId, remark)`。

## 任务1：反馈工单多轮对话页

**新建** `lib/presentation/features/feedback/feedback_thread_page.dart`
- `FeedbackThreadPage extends ConsumerStatefulWidget`，构造参数 `FeedbackModel feedback`。
- state：`_feedback`（随追加更新）、`_messages`、`_loading`、输入控制器、`_sending`。
- initState 微任务调 `feedbackRepo.listMessages(id)`：非空用返回值；空则兜底 `feedback.messages`。
- AppBar：标题"反馈详情" + Row 小 chip（类型色标复用 feedback_page 的 BUG 红/建议橙/投诉紫/其他蓝；状态：待处理/处理中/已回复/已关闭）。
- body：正向 ListView（顶部→底部）+ 底部输入条（圆角 TextField + IconButton.filled 发送）。
  - 状态 CLOSED：顶部居中胶囊"工单已关闭，再次发送将重新打开"。
  - 首条：原反馈 `_feedback.content` 右侧 primary 气泡白字 + TimeFmt.bubble 小字时间。
  - 去重：若 _messages 首条 USER 消息 content 与原反馈相同则跳过，避免重复。
  - ADMIN 消息：左侧气泡 `surfaceContainerHighest`（暗色 `telegramDarkIncoming 0xFF182533`）深/浅字，前缀 support_agent 图标小标题"官方回复"；USER 右侧 primary。
- 发送：`appendMessage(id, content)` → 返回的 FeedbackModel 赋给 _feedback；消息列表优先用返回值 messages，空则重新 listMessages；`AppToast.success("已发送")`，失败 `AppToast.error`。

**路由** app_router.dart：新增 `GoRoute(path: '/feedback/thread', builder: FeedbackThreadPage(extra as FeedbackModel))`。

**修改** feedback_page.dart：`_FeedbackCard` 的 Card 改为 `Card(clipBehavior: antiAlias, child: InkWell(onTap: context.push('/feedback/thread', extra: f), child: Padding(...)))`（外层加 go_router import）。

## 任务2：红点与已读时机（providers.dart + chat_controller.dart）

providers.dart Realtime：
1. `with WidgetsBindingObserver`；`start()` 注册 `WidgetsBinding.instance.addObserver(this)`，`stop()` 移除；字段 `bool _appActive = true`。
2. `didChangeAppLifecycleState`：resumed 且此前非 resumed → `_onResumed()`：若 activeConvId != null，查本地 conv，`unreadCount>0` 时 zeroUnread + `reportRead(convId, conv.lastSeq!)`（lastSeq 为空则只 zeroUnread）。
3. MSG_DELIVER 分支条件加 `&& _appActive`（不活跃只入库+回 ACK_DELIVERED，不清红点不上报）；ACK_DELIVERED 分支不动。
4. `reportRead`：zeroUnread 后 try markRead；catch → 等 1.5s 重试一次，再失败放弃。
5. 防抖：抽出 `_flushPendingRead()`（取 `_pendingReadSeq`，清空，markRead 一次，失败吞掉）；`stop()` 先 flush 再 cancel timer。
6. 新增 `clearActiveConversation()`：先 `_flushPendingRead()`，再置 activeConvId=null。

chat_controller.dart：
- onDispose 改为调 `ref.read(realtimeProvider).clearActiveConversation()`（仅当 activeConvId==convId，语义同现状）。
- `_load` 的 lastSeq 兜底已存在，确认保留。

## 任务3：用户资料页增强（user_profile_page.dart）

- 资料区重构：
  - 大 Card：头像（88，沿用描边）+ 昵称；UID 行 `UID: xxx` + `Icons.copy`（点击 Clipboard.setData + `AppToast.success("UID 已复制")`）。
  - 信息 Card：性别 ListTile（leading Icons.wc_outlined，男/女/未设置——gender null 或 UNKNOWN 显示"未设置"）；bio ListTile（leading Icons.notes_outlined，多行完整展示；空显示灰色"这个人很懒，什么都没留下"）。**无 region 行**（UserBrief 无该字段）。
- AppBar PopupMenuButton（SELF 不显示），onSelected 分发：
  - FRIEND：remark 设置备注（复用现有 `_editRemark`）、block 拉黑、report 举报、delete 删除好友（复用 `_deleteFriend`）。
  - PENDING_SENT：cancel 撤回申请（新方法 `_cancelSentRequest()`：outgoingRequests() 找 `to?.id==_user.id && status=='PENDING'` 的 id → cancelRequest；找不到 toast 提示；成功后 relation 置 NONE + socialTick++）、report。
  - NONE / PENDING_RECEIVED：report。
- 拉黑 `_blockUser()`：确认 dialog → block(_user.id) → AppToast.success("已拉黑") → socialTick++ → `context.pop()`。
- 举报：新建公共组件 `lib/presentation/widgets/report_dialog.dart`，导出
  `Future<bool> showReportDialog(BuildContext, WidgetRef ref, {required String targetType, required int targetId})`：
  AlertDialog，RadioListTile 五选项（SPAM 垃圾营销/ABUSE 辱骂骚扰/PORN 色情低俗/FRAUD 欺诈/OTHER 其他）+ 详情 TextField；确认后调 `socialRepo.report(...)`，成功 AppToast.success("举报已提交") 返回 true，失败 AppToast.error 返回 false。

## 任务4：图片全屏 + 保存

**新建** `lib/core/utils/image_saver.dart`：`ImageSaver.save(BuildContext, String relativeUrl)`
- web（kIsWeb）：`AppToast.info(context, "请长按图片保存")`。
- 移动端（!kIsWeb && Android||iOS）：`Dio().get(Env.mediaUrl(url), options: Options(responseType: ResponseType.bytes))` → `Gal.putImageBytes(bytes, album: 'Sylph', name: 'sylph_<ms>')`；on GalException → error toast（accessDenied 提示无权限）；成功 `AppToast.success("已保存到相册")`。
- 桌面（windows/其他）：`FilePicker.platform.saveFile(dialogTitle:'保存图片', fileName:'sylph_<ms>.jpg', bytes: bytes)`，非空路径 AppToast.success("已保存")。

**新建** `lib/presentation/features/chat/widgets/fullscreen_image_page.dart`：`FullscreenImagePage({required String url})`
- 黑底 Scaffold（extendBodyBehindAppBar），透明 AppBar + 白色返回，actions 保存 IconButton（调 ImageSaver.save，try/catch error toast）。
- body `PhotoView(imageProvider: NetworkImage(Env.mediaUrl(url)), backgroundDecoration: 黑, minScale: PhotoViewComputedScale.contained, maxScale: PhotoViewComputedScale.covered * 4, loadingBuilder 菊花)`。不加 hero（气泡侧无 tag）。

**改 message_bubble.dart** IMAGE 分支（L187-220）：
- `ConstrainedBox(constraints: BoxConstraints(maxWidth:240,maxHeight:280), child: Image.network(..., fit: BoxFit.fitWidth))`，外包 ClipRRect(12) + GestureDetector：
  - onTap：clientStatus=='FAILED' → 现有 resend；否则 `Navigator.push(MaterialPagePageRoute(builder: FullscreenImagePage(url: message.mediaUrl!)))`。
  - onLongPress：showModalBottomSheet → ["保存到相册" → ImageSaver.save, "取消"]。
- loading/error builder 保留（尺寸随新约束）。

## 任务5：聊天页 AppBar 改造（chat_page.dart）

state 内新增操作方法（乐观更新：先 DAO 写 → API → 失败回滚 DAO + AppToast.error + refreshConversations；成功后 refreshConversations）：
- `_togglePrivate` 保留；新 IconButton icon `conv.privateFlag ? Icons.lock : Icons.lock_open_outlined`，toast info "已开启私密模式"/"已关闭私密模式"。
- `_toggleMute(conv)`：conversationRepo.mute + dao.setMuted。
- `_togglePin(conv)`：conversationRepo.pin + dao.setPinned(id, v, v?DateTime.now():null)。
- `_editPeerRemark(conv)`：弹窗 TextField 预填 peerNickname → socialRepo.setRemark(peerUserId, text) → toast + refresh。
- `_deleteConv(conv)`：红字确认 → conversationRepo.delete → refreshConversations → `context.pop()`。
- `_blockPeer(conv)`：确认 → socialRepo.block(peerUserId) → toast → socialTick++ → refresh → pop。
- 举报复用 showReportDialog。

SINGLE 的 PopupMenu（Icons.more_vert）：
- 查看资料（官方助手 peerUserId==10000000 / 昵称命中官方时**不显示**）：构造 `UserBrief(id: conv.peerUserId!, nickname: conv.peerNickname ?? '', avatarUrl: conv.peerAvatarUrl, relation: 'FRIEND')` → context.push('/user-profile', extra)。
- 消息免打扰（trailing check：conv.muted）
- 置顶聊天（check：conv.pinned）
- 设置备注
- 举报（targetType USER, targetId peerUserId；官方助手不显示）
- 拉黑（官方助手不显示）
- 删除会话（红字 style）

GROUP：保留群设置 IconButton（Icons.groups_2_outlined）+ PopupMenu：消息免打扰、置顶聊天、举报群（targetType GROUP, targetId=conv.id——群只有 convId，无独立 groupId）、退出群聊（红字确认 → groupRepo.leave(convId) → socialTick++/refresh → pop）。

## 任务6：聊天壁纸（chat_page.dart body）

- watch `settingsControllerProvider`（wallpaperPath/wallpaperOverlay）与 `Theme.brightness`。
- body 改 Stack：
  - 非 web 且 wallpaperPath 非空且 `File(path).existsSync()`：`Positioned.fill(Image.file(File(path), fit: cover))` + `Positioned.fill(Container(color: (dark?black:white).withValues(alpha: overlay)))`。
  - 顶层原 SafeArea(Column) 不变；消息区背景自然透明，气泡/输入栏自有底色。
- Scaffold/AppBar 不动（壁纸仅在 body Stack 底层，AppBar 保持自有底色）。

## 任务7

无代码改动（群昵称/头像逻辑与 group_settings 保持不动）。

## 收尾

1. `flutter analyze`（cwd: client）逐轮修复至 **No issues found**。
2. 不写测试、不 build apk、不 git commit。
3. 中文注释；新文案中文硬编码。

## 新增/修改文件清单

新增：
- lib/presentation/features/feedback/feedback_thread_page.dart
- lib/presentation/features/chat/widgets/fullscreen_image_page.dart
- lib/core/utils/image_saver.dart
- lib/presentation/widgets/report_dialog.dart

修改：
- lib/presentation/router/app_router.dart（注册 /feedback/thread）
- lib/presentation/features/feedback/feedback_page.dart（卡片跳转）
- lib/presentation/state/providers.dart（已读健壮性/生命周期）
- lib/presentation/features/chat/chat_controller.dart（clearActiveConversation）
- lib/presentation/features/contacts/user_profile_page.dart（资料重构+菜单+拉黑/举报/撤回）
- lib/presentation/features/chat/widgets/message_bubble.dart（图片交互/尺寸）
- lib/presentation/features/chat/chat_page.dart（AppBar 菜单+壁纸 Stack）
