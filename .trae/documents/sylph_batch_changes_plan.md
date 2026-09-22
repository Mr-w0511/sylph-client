# Sylph 客户端批次改动实施计划

工作目录：`c:\Users\Mr.Wu\Desktop\sylph\client`（Windows / PowerShell）。不写测试、不提交 git、注释中文；结束标准 `flutter analyze` → No issues found。

## 0. 已确认的项目事实
- Riverpod（Notifier）+ go_router + drift 2.25（drift_flutter，web wasm）+ dio 封装在 ApiClient（get/post/put/delete/requestDynamic/upload）。
- l10n：`lib/l10n/app_zh.arb`、`app_en.arb`，生成类 `AppL10n`（`app_localizations*.dart` 已入库，pub get 触发 gen）。
- 主题 `app_theme.dart`：现有常量 sylphBlue/telegramOutgoing/telegramDark* 全保留。
- KV 仅 getString/setString/getInt/setInt/remove；壁纸遮罩用 double 需加 getDouble/setDouble（或存 String）。
- AppSettings(locale, themeMode) 为位置构造，多处无其它构造点。
- Conversations drift 表无 pinned/pinnedAt；DAO watchAll 以 lastMsgTime/updatedAt desc 排序；upsertAll 为 insertOrReplace。
- SnackBar 分布 14 文件共 105 处匹配（含 ScaffoldMessenger 行）。
- 会话 peer 字段：peerUserId/peerNickname/peerAvatarUrl（drift）；ConversationModel.peer 为 PeerInfo(userId,nickname,avatarUrl)，无 uid → 官方助手按昵称 `Sylph 官方助手` 识别（UserAvatar 加 isSystem）。

## 1. 依赖与原生配置
- pubspec.yaml 增：permission_handler ^11.3.1、photo_view ^0.15.0、gal ^2.3.3、path_provider ^2.1.4、package_info_plus ^8.1.2、url_launcher ^6.3.1；`flutter pub get`。
- ios/Runner/Info.plist 增 NSPhotoLibraryAddUsageDescription（保存图片到相册）。
- gal/photo_view 本批仅加入依赖（后续聊天页保存/查看使用）。

## 2. 主题换肤
- kv_store.dart：常量 `kThemeColor='settings.themeColor'`、`kWallpaper='settings.wallpaper'`、`kWallpaperOverlay='settings.wallpaperOverlay'`；加 getDouble/setDouble。
- providers.dart：AppSettings 增 seedColor(默认 0xFF3B6EF6)、wallpaperPath?(可空)、wallpaperOverlay(默认 0.55)；copyWith 支持（wallpaper 用 Object? 显式传参以区分 null）；SettingsController 增 setSeedColor/setWallpaper/setWallpaperOverlay（clamp 0.25–0.85），build 从 KV 读初值。
- app_theme.dart：`light([int? seed])`、`dark([int? seed])`，ColorScheme.fromSeed(seedColor: Color(seed ?? sylphBlue))，dark brightness 指定；预设色盘 `kSylphSeedColors`（9 色）。
- 视觉微调：Card 圆角16/elevation0/surface；AppBar 底部 0.4 outlineVariant 细边框；NavigationBar 高68、全圆角指示器、0.14 primary；按钮圆角14；FAB 圆角16；Switch primary；Chip 圆角10；InputDecoration contentPadding 14,18,14,12 + isDense:false；scaffold 底色 light 0xFFF7F8FA / dark 0xFF0F151D；气泡常量不动。
- app.dart：theme/darkTheme 传 settings.seedColor；MaterialApp.router 增 builder 安装 AppToast。

## 3. AppToast + 全量替换
- 新建 lib/presentation/widgets/app_toast.dart：Overlay 方式；attach(context) 缓存 OverlayState；success/error/info(context,text)；IgnorePointer+Center，ConstrainedBox(maxWidth 260)，圆角16 白底浅阴影 / dark 0xE6222A35，48 圆形图标（成功 0xFF34C78A / 错误 0xFFFF5A5A / 信息 primary），14.5 w500 居中文字；ScaleTransition 0.85→1 easeOutBack + FadeTransition，1.6s 移除；新调用清旧。
- 替换 14 文件全部 ScaffoldMessenger/SnackBar：成功→success、catch/error/失败/无效/拒绝→error、其余→info；带 action 的改为最接近调用（逐处看代码决定）。chat_page/feedback_page 仅换提示不动业务。

## 4. drift v2
- Conversations 增 pinned(Boolean, default false)、pinnedAt(dateTime nullable)；schemaVersion=2；MigrationStrategy.onCreate 建表、onUpgrade 1→2 addColumn 两列。
- watchAll 排序：pinned DESC, COALESCE(pinned_at,?) 再 lastMsgTime/updatedAt（drift 用 coalesce 表达式）。
- DAO 增 setPinned(id,bool,DateTime?)、setMuted(id,bool)。
- `dart run build_runner build --delete-conflicting-outputs` 重新生成。

## 5. models / repos / providers
- models.dart：AppUser +hasPassword(缺省 false，copyWith 同步)；ConversationModel +pinned/pinnedAt；新 FeedbackMessageModel(id,senderRole,content,createdAt)；FeedbackModel +messages（容错空数组）；FriendRequestModel 已有 id（确认）。
- providers.refreshConversations：写 pinned/pinnedAt；convId==activeConvId 时 unreadCount 强制 0。
- ConversationRepository：mute(id,muted) POST .../mute {muted}；pin(id,pinned) POST .../pin {pinned}，返回 ConversationModel；delete(id) DELETE。
- SocialRepository：block/unblock(uid) POST /api/friends/{uid}/block|unblock；cancelRequest(id) POST /api/friends/requests/{id}/cancel；report(targetType,targetId,reason,detail) POST /api/reports。
- FeedbackRepository：listMessages(id) GET /api/feedback/{id}/messages → List<FeedbackMessageModel>；appendMessage(id,content) POST → FeedbackModel。
- GroupRepository：myJoinRequests() GET /api/groups/join-requests/mine → List<GroupRequestModel>。

## 6. 登录页裁切
- InputDecorationTheme 调整见 §2；login_page AnimatedSwitcher 去掉 SizeTransition 仅 FadeTransition(220ms)，必要时 layoutBuilder 淡入；卡片底部内边距 ≥20。

## 7. 设置页
- 账号卡：hasPassword!=true 时才插入“设置初始密码”整块（用条件 children 收集，避免悬空 Divider）。
- 新“个性化”分组卡（偏好卡之前）：主题色行（当前色点 → showModalBottomSheet，Wrap 9 个 44 色点，选中白 check，点击 setSeedColor+关弹窗）；聊天壁纸行 → 新页面 wallpaper_page.dart（220 高预览：Stack 壁纸+遮罩+两条模拟气泡，实时刷新；从相册选择 file_picker bytes→path_provider docs 存 wallpaper_<ts>.jpg→setWallpaper，删旧文件容错；恢复默认 setWallpaper(null)；Slider 0.25–0.85 绑 wallpaperOverlay；kIsWeb 禁用相册并 toast）。
- “关于 Sylph” → context.push('/about')，删除 _showAbout。
- 卡片 leading 图标统一 40–44 圆角彩底白图标（每项固定色）。

## 8. 关于页 + 路由
- 新建 about_page.dart：96 渐变圆角纸飞机 Logo（与登录页同款，参照登录页实现）、Sylph 30 粗体、package_info_plus 版本 FutureBuilder（加载中 v1.0.0）；应用介绍卡；开发者（晚霞/独立开发者）；联系邮箱 ListTile → launchUrl mailto externalApplication，失败 toast；检查更新 → toast success；开源许可 → showLicensePage。
- app_router.dart 增 /about。

## 9. 扫码页
- 先 Permission.camera.request()，授权后才创建/启动 MobileScannerController；未授权状态页。
- errorBuilder：按 MobileScannerErrorCode（permissionDenied/permissionDeniedWithoutPermissionMessage/generic；先用 when，不可用则 name.startsWith('permission')）显示“相机权限被拒绝”+重新授权/打开系统设置(openAppSettings)；generic“相机启动失败…”+重试（bool/ValueKey 重建）；桌面端“当前设备相机不可用，请在下方手动输入…”。
- 保留/补充底部手动输入（sylph:// 与纯数字 UID，复用 handleSylphCode）。
- _handled 在导航返回后 finally 复位 false；加 mounted。kIsWeb 不走权限分支。

## 10. 官方头像
- UserAvatar 增 `String? uid` 与 `bool isSystem`；uid=='10000000' 或 isSystem=true → 圆形渐变(0xFF3B6EF6→0xFF2EA6FF) + 白色 Icons.send_rounded(size*0.5)。
- conversations_page 会话 tile：peerNickname=='Sylph 官方助手' 传 isSystem:true；contacts_page 能拿到 uid==10000000 则传 uid（先看数据模型可得性，否则不动）。

## 11. 新建群聊底部按钮
- new_group_page：bottomNavigationBar（SafeArea+Padding）：已选成员横向 ListView（头像/名/右上角 x），无选择“请选择群成员”；52 高渐变 FilledButton“创建群聊”，busy 菊花+禁用，复用 _submit；resizeToAvoidBottomInset。

## 12. 好友申请两个 Tab
- friend_requests_page：DefaultTabController+AppBar bottom 两 Tab（收到的申请/我发出的）；发出列表 socialRepo.outgoingRequests()，对方头像/昵称/UID+状态 chip（PENDING warning/ACCEPTED success/REJECTED info/CANCELED info）；PENDING 尾部“撤回”→确认 dialog→cancelRequest(id)→toast+刷新；socialTick watch 保留。

## 13. 群设置
- group_settings_page：二维码卡附近加“我发起的入群申请”ListTile → showModalBottomSheet 调 groupRepo.myJoinRequests()，列群名/状态/时间，空态“暂无申请”。

## 14. l10n
- arb 增常用键：about 相关、个性化/主题色/聊天壁纸、我发出的/撤回申请、相机权限文案、保存/取消等；新页面次要文案可中文硬编码。pub get 生成。

## 15. 美化收尾
- 通讯录快捷卡保持现有风格；设置页 leading 统一彩底圆角图标（§7）。
- 会话 tile：contentPadding 14/8、头像 52、去 Card 包裹沉浸；时间/红点保留。
- 底部导航指示器/选中色随 seed 生效检查。

## 16. 验证
- `flutter pub get`、`dart run build_runner build --delete-conflicting-outputs`、`flutter analyze`（修到 0 issue，含 info）。不运行 app/build apk。

## 风险/备注
- ColorScheme.fromSeed 新版 Flutter 命名参数 primary/surface 已不支持 → 只用 seedColor+brightness（弃用 API 会触发 info，故不用）。
- MigrationStrategy 需提供 onCreate（drift 默认 m.createAll）。
- gal/photo_view/url_launcher 桌面/Web 可用性：仅在支持平台调用；壁纸选择移动端/桌面（path_provider）可用，Web 禁用。
- MobileScanner 6.0.x errorBuilder 签名与 errorCode 枚举以实际源码为准再写判断。
