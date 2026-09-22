// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppL10nZh extends AppL10n {
  AppL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Sylph';

  @override
  String get appSlogan => '轻风即时通讯';

  @override
  String get navChats => '消息';

  @override
  String get navContacts => '通讯录';

  @override
  String get navSettings => '我的';

  @override
  String get loginTitle => '登录 Sylph';

  @override
  String get registerTitle => '注册账号';

  @override
  String get tabPasswordLogin => '密码登录';

  @override
  String get tabPhoneLogin => '验证码登录';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get nickname => '昵称';

  @override
  String get phone => '手机号';

  @override
  String get verificationCode => '验证码';

  @override
  String get sendCode => '发送验证码';

  @override
  String get phoneLoginUnavailable => '验证码登录暂未开放，请使用用户名密码登录';

  @override
  String get loginSubmit => '登 录';

  @override
  String get registerSubmit => '注 册';

  @override
  String get toRegister => '没有账号？去注册';

  @override
  String get toLogin => '已有账号？去登录';

  @override
  String get registerSuccess => '注册成功，请登录';

  @override
  String get usernameHint => '3-64 位字母、数字或下划线';

  @override
  String get passwordHint => '至少 6 位';

  @override
  String get fieldRequired => '该项不能为空';

  @override
  String get sessionExpired => '登录已过期，请重新登录';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirm => '确定要退出当前账号吗？';

  @override
  String get loginFailed => '登录失败，请检查用户名或密码';

  @override
  String get conversationsTitle => '消息';

  @override
  String get newChat => '发起新聊';

  @override
  String get newSingleChat => '新建单聊';

  @override
  String get newGroupChat => '新建群聊';

  @override
  String get searchUserHint => '搜索用户名 / 昵称';

  @override
  String get searchEmpty => '未找到相关用户';

  @override
  String get groupName => '群名称';

  @override
  String get groupNameHint => '给群聊起个名字';

  @override
  String get selectMembers => '选择成员';

  @override
  String get createGroup => '创建群聊';

  @override
  String get selectAtLeastTwo => '请至少选择 2 位成员';

  @override
  String get conversationEmpty => '还没有会话，点击右上角发起新聊';

  @override
  String get pullToRefresh => '下拉刷新';

  @override
  String get refreshing => '刷新中…';

  @override
  String get refreshDone => '刷新完成';

  @override
  String get lastMessageImage => '[图片]';

  @override
  String get lastMessageVoice => '[语音]';

  @override
  String get lastMessageVideo => '[视频]';

  @override
  String get lastMessageFile => '[文件]';

  @override
  String get lastMessageSystem => '[系统消息]';

  @override
  String get lastMessageEncrypted => '端到端加密消息';

  @override
  String get lastMessageYou => '你: ';

  @override
  String get settingsTitle => '我的';

  @override
  String get profileSection => '个人资料';

  @override
  String get editProfile => '编辑资料';

  @override
  String get accountSettings => '账号与安全';

  @override
  String get preferences => '偏好设置';

  @override
  String get language => '语言';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get devices => '登录设备管理';

  @override
  String get privateEntry => '私密会话说明';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get delete => '删除';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中…';

  @override
  String get loadFailed => '加载失败';

  @override
  String get emptyData => '暂无数据';

  @override
  String get updateSuccess => '更新成功';

  @override
  String get operationFailed => '操作失败';

  @override
  String get gender => '性别';

  @override
  String get genderUnknown => '未设置';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get usernameLabel => '用户名';

  @override
  String get devicesTitle => '登录设备';

  @override
  String get currentDevice => '本设备';

  @override
  String get revokeDevice => '远程下线';

  @override
  String get revokeDeviceConfirm => '确定将该设备下线吗？该设备需要重新登录。';

  @override
  String get revokedCurrent => '当前设备已被下线';

  @override
  String get lastLoginAt => '最近登录';

  @override
  String get privateInfoTitle => '私密会话（端到端加密）';

  @override
  String get privateInfoBody =>
      '私密会话仅支持单聊。开启后，消息采用 P-256 (ECDH) 协商密钥，HKDF-SHA256 派生、AES-GCM 加密后再发送。服务端只可见密文，无法读取内容。\n\n密钥仅保存在本设备浏览器中，更换设备后将无法读取历史密文。';

  @override
  String get chatInputHint => '发送消息…';

  @override
  String get send => '发送';

  @override
  String get sendImage => '发送图片';

  @override
  String get pickImage => '选择图片';

  @override
  String get imagePicking => '图片处理中…';

  @override
  String get imageUploading => '图片上传中…';

  @override
  String get messageSending => '发送中…';

  @override
  String get messageSendFailed => '发送失败，将在重连后重试';

  @override
  String get e2eeEncrypted => '端到端加密消息，无法解密';

  @override
  String get e2eeBadge => '端到端加密';

  @override
  String get privateSwitch => '私密会话';

  @override
  String get privateEnableTip => '开启后将生成本设备密钥并上传公钥束，消息会以端到端加密发送';

  @override
  String get privateDisableTip => '已关闭端到端加密，后续消息将以明文发送';

  @override
  String get e2eePreparing => '正在准备端到端加密密钥…';

  @override
  String get e2eePeerNoKeys => '对方尚未启用端到端加密，请让对方先开启私密会话';

  @override
  String get resend => '重发';

  @override
  String get loadMore => '加载更早的消息';

  @override
  String get noMoreMessages => '没有更多消息了';

  @override
  String get messagesLoading => '消息加载中…';

  @override
  String get messagesLoadFailed => '消息加载失败';

  @override
  String get connectionConnecting => '正在连接…';

  @override
  String get connectionReconnecting => '连接已断开，正在重连…';

  @override
  String get connectionDisconnected => '连接已断开';

  @override
  String get connectionConnected => '已连接';

  @override
  String get statusPending => '发送中';

  @override
  String get statusSent => '已发送';

  @override
  String get statusDelivered => '已送达';

  @override
  String get statusRead => '已读';

  @override
  String get statusBlocked => '消息被风控拦截';

  @override
  String get statusFailed => '发送失败';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String memberCount(Object count) {
    return '$count 人';
  }

  @override
  String get sendEmailCode => '发送验证码';

  @override
  String get codeSent => '验证码已发送至邮箱';

  @override
  String resendIn(Object seconds) {
    return '${seconds}s 后重发';
  }

  @override
  String get loginByEmail => '登录';

  @override
  String get emailFieldLabel => '邮箱';

  @override
  String get emailHint => '请输入邮箱';

  @override
  String get codeHint => '6 位验证码';

  @override
  String get emailLoginTip => '未注册的邮箱将自动创建账号';

  @override
  String get switchToUidLogin => '使用 UID + 密码登录';

  @override
  String get switchToEmailLogin => '使用邮箱验证码登录';

  @override
  String get uidFieldLabel => 'UID';

  @override
  String get uidHint => '8 位数字 UID';

  @override
  String get loginByEmailFailed => '登录失败，请检查验证码';

  @override
  String get loginByUidFailed => '登录失败，请检查 UID 或密码';

  @override
  String get setInitialPassword => '设置初始密码';

  @override
  String get changePassword => '修改密码';

  @override
  String get oldPassword => '原密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmPassword => '确认新密码';

  @override
  String get newPasswordHint => '至少 8 位，需含字母和数字';

  @override
  String get passwordMismatch => '两次输入的密码不一致';

  @override
  String get passwordSetSuccess => '初始密码已设置';

  @override
  String get passwordChanged => '密码已修改';

  @override
  String get setInitialPasswordTip => '邮箱登录后可设置初始密码，以便使用 UID + 密码登录';

  @override
  String get navProfile => '我的';

  @override
  String get accountSecurity => '账号与安全';

  @override
  String get appearance => '外观';

  @override
  String get about => '关于';

  @override
  String get aboutSylph => '关于 Sylph';

  @override
  String get aboutSylphBody => 'Sylph · 轻量、私密的即时通讯客户端。';

  @override
  String get profileCard => '个人主页';

  @override
  String get contactsTitle => '联系人';

  @override
  String get myGroups => '我的群聊';

  @override
  String get myContacts => '我的联系人';

  @override
  String get noGroupsYet => '暂无群聊';

  @override
  String get noContactsYet => '暂无联系人';

  @override
  String errorWithReason(Object reason) {
    return '操作失败：$reason';
  }

  @override
  String sendFailedReason(Object reason) {
    return '发送失败：$reason';
  }

  @override
  String loadFailedReason(Object reason) {
    return '加载失败：$reason';
  }

  @override
  String saveFailedReason(Object reason) {
    return '保存失败：$reason';
  }

  @override
  String shareFailedReason(Object reason) {
    return '分享失败：$reason';
  }

  @override
  String encryptFailedReason(Object reason) {
    return '加密失败：$reason';
  }

  @override
  String forwardFailedReason(Object reason) {
    return '转发失败：$reason';
  }

  @override
  String recallFailedReason(Object reason) {
    return '撤回失败：$reason';
  }

  @override
  String playFailedReason(Object reason) {
    return '播放失败：$reason';
  }

  @override
  String recordStartFailedReason(Object reason) {
    return '录音启动失败：$reason';
  }

  @override
  String voiceSendFailedReason(Object reason) {
    return '语音发送失败：$reason';
  }

  @override
  String avatarUploadFailedReason(Object reason) {
    return '头像上传失败：$reason';
  }

  @override
  String loadFriendsFailedReason(Object reason) {
    return '加载好友失败：$reason';
  }

  @override
  String openCardFailedReason(Object reason) {
    return '打开名片失败：$reason';
  }

  @override
  String setWallpaperFailedReason(Object reason) {
    return '设置壁纸失败：$reason';
  }

  @override
  String get privateMode => '私密模式';

  @override
  String get privateModeOn => '已开启私密模式';

  @override
  String get privateModeOff => '已关闭私密模式';

  @override
  String e2eePrepareFailedReason(Object reason) {
    return '端到端加密密钥准备失败，请稍后重试\n原因：$reason';
  }

  @override
  String get mutedOn => '已开启消息免打扰';

  @override
  String get mutedOff => '已关闭消息免打扰';

  @override
  String get pinnedOn => '已置顶聊天';

  @override
  String get unpinned => '已取消置顶';

  @override
  String get pinToTop => '置顶';

  @override
  String get unpinLabel => '取消置顶';

  @override
  String get pinChat => '置顶聊天';

  @override
  String get muteConv => '消息免打扰';

  @override
  String get unmuteConv => '取消免打扰';

  @override
  String get viewProfile => '查看资料';

  @override
  String get setRemarkTitle => '设置备注';

  @override
  String get setRemarkHint => '给对方设置一个备注名';

  @override
  String get remarkSaved => '备注已保存';

  @override
  String get report => '举报';

  @override
  String get reportGroup => '举报群聊';

  @override
  String get blockUserTitle => '拉黑用户';

  @override
  String get blockUserConfirm => '拉黑后将不再收到对方消息，确定拉黑吗？';

  @override
  String get blockAction => '拉黑';

  @override
  String get blocked => '已拉黑';

  @override
  String get terminateChatTitle => '终止会话';

  @override
  String get terminateChatConfirm => '终止后双方都将不再显示该会话且无法继续发消息，确定终止吗？';

  @override
  String get terminateAction => '终止';

  @override
  String get chatTerminated => '会话已终止';

  @override
  String get leaveGroupTitle => '退出群聊';

  @override
  String get leaveGroupConfirm => '退出后将不再接收该群消息，确定退出吗？';

  @override
  String get leaveAction => '退出';

  @override
  String get leftGroup => '已退出群聊';

  @override
  String get dissolveGroup => '解散群聊';

  @override
  String get dissolveConfirm => '解散后群聊将不可用，确定解散吗？';

  @override
  String get dissolveAction => '解散';

  @override
  String get deleteConvTitle => '删除会话';

  @override
  String get dissolvedConvDeleteConfirm => '该群已解散，删除后会话将从列表中移除，确定吗？';

  @override
  String get convDeleted => '会话已删除';

  @override
  String get groupDissolved => '该群已解散';

  @override
  String get groupDissolvedHint => '群聊已不可用，可删除会话从列表移除';

  @override
  String selectedCount(Object count) {
    return '已选 $count 条';
  }

  @override
  String get forward => '转发';

  @override
  String get forwardTo => '转发给';

  @override
  String get forwarded => '已转发';

  @override
  String forwardedCount(Object count) {
    return '已转发 $count 条';
  }

  @override
  String forwardedPartialFail(Object count, Object reason) {
    return '已转发 $count 条，后续失败：$reason';
  }

  @override
  String get convCreating => '会话创建中，请稍后在该会话内重试';

  @override
  String get e2eePeerNoKeysForward => '对方尚未启用端到端加密，无法转发到私密会话';

  @override
  String get convLoadFailed => '会话信息加载失败';

  @override
  String get groupSettings => '群聊设置';

  @override
  String get micPermissionDenied => '请授予录音权限';

  @override
  String get voiceTooShort => '录音太短';

  @override
  String get photo => '图片';

  @override
  String get card => '名片';

  @override
  String get voice => '语音';

  @override
  String get more => '更多';

  @override
  String get keyboard => '键盘';

  @override
  String get releaseToCancel => '松开取消';

  @override
  String slideUpCancel(Object seconds) {
    return '上滑取消 · ${seconds}s';
  }

  @override
  String get holdToTalk => '按住说话';

  @override
  String get cardSent => '名片已发送';

  @override
  String get pickCardTitle => '选择名片';

  @override
  String get userCard => '个人名片';

  @override
  String get groupCard => '群聊名片';

  @override
  String userCardWithUid(Object uid) {
    return '个人名片 · UID $uid';
  }

  @override
  String groupCardWithNumber(Object number) {
    return '群聊名片 · 群号 $number';
  }

  @override
  String get noFriends => '暂无好友';

  @override
  String get noGroupsToShare => '暂无可分享的群聊';

  @override
  String groupNumberLabel(Object number) {
    return '群号 $number';
  }

  @override
  String get pickMentionTitle => '选择提醒成员';

  @override
  String confirmWithCount(Object count) {
    return '确定($count)';
  }

  @override
  String get searchMembers => '搜索成员';

  @override
  String get owner => '群主';

  @override
  String get admin => '管理员';

  @override
  String get memberRole => '成员';

  @override
  String get youAreMuted => '您已被禁言';

  @override
  String mutedRemainingDh(Object days, Object hours) {
    return '您已被禁言，剩余 $days天$hours小时';
  }

  @override
  String mutedRemainingHm(Object hours, Object mins) {
    return '您已被禁言，剩余 $hours小时$mins分';
  }

  @override
  String mutedRemainingMs(Object mins, Object secs) {
    return '您已被禁言，剩余 $mins分$secs秒';
  }

  @override
  String mutedRemainingS(Object secs) {
    return '您已被禁言，剩余 $secs秒';
  }

  @override
  String durationDays(Object days) {
    return '$days天';
  }

  @override
  String durationDaysHours(Object days, Object hours) {
    return '$days天$hours小时';
  }

  @override
  String durationHours(Object hours) {
    return '$hours小时';
  }

  @override
  String durationHoursMinutes(Object hours, Object mins) {
    return '$hours小时$mins分';
  }

  @override
  String durationMinutes(Object mins) {
    return '$mins分';
  }

  @override
  String durationSeconds(Object secs) {
    return '$secs秒';
  }

  @override
  String get newMember => '新成员';

  @override
  String get joinedGroupNotice => ' 加入了群聊';

  @override
  String get mutedBy => ' 被 ';

  @override
  String mutedForDuration(Object duration) {
    return ' 禁言 $duration';
  }

  @override
  String get unmutedBy => ' 被 ';

  @override
  String get unmutedSuffix => ' 解除禁言';

  @override
  String get theMember => '该成员';

  @override
  String get unknownUser => '用户';

  @override
  String get unknownGroup => '群聊';

  @override
  String userFallbackId(Object id) {
    return '用户$id';
  }

  @override
  String groupFallbackId(Object id) {
    return '群聊$id';
  }

  @override
  String get singleChatFallback => '单聊';

  @override
  String get chatFallback => '聊天';

  @override
  String get friendsSection => '好友';

  @override
  String get saveImage => '保存图片';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get multiSelect => '多选';

  @override
  String get recall => '撤回';

  @override
  String get recallWindowExpired => '已超过可撤回时间';

  @override
  String get youRecalled => '你撤回了一条消息';

  @override
  String get peerRecalled => '对方撤回了一条消息';

  @override
  String recalledByName(Object name) {
    return '$name撤回了一条消息';
  }

  @override
  String get adminFallback => '管理员';

  @override
  String get searchAddFriend => '搜索并添加好友';

  @override
  String get convListEmptyTitle => '还没有会话';

  @override
  String get convListEmptyHint => '点击右上角的加号，搜索并添加好友开始聊天';

  @override
  String get refresh => '刷新';

  @override
  String get groupAvatarUpdated => '群头像已更新';

  @override
  String get editGroupProfile => '编辑群资料';

  @override
  String get groupAnnouncement => '群公告';

  @override
  String get groupProfileUpdated => '群资料已更新';

  @override
  String get myNicknameInGroup => '我在本群的昵称';

  @override
  String get nicknameLeaveEmptyHint => '留空则使用默认昵称';

  @override
  String get groupNicknameUpdated => '群昵称已更新';

  @override
  String get groupQrcode => '群二维码';

  @override
  String get groupQrcodeSubtitle => '分享二维码邀请好友入群';

  @override
  String get noFriendsToShare => '没有可分享的好友';

  @override
  String get shareGroupToFriend => '分享群聊给好友';

  @override
  String sharedTo(Object name) {
    return '已分享给 $name';
  }

  @override
  String get setMemberNicknameTitle => '设置群昵称';

  @override
  String get editMyGroupNickname => '修改我的群昵称';

  @override
  String get removeAdmin => '取消管理员';

  @override
  String get adminRemoved => '已取消管理员';

  @override
  String get makeAdmin => '设为管理员';

  @override
  String get adminSet => '已设为管理员';

  @override
  String get unmuteMember => '解除禁言';

  @override
  String get muteMember => '禁言';

  @override
  String get removeMember => '移出群聊';

  @override
  String removeMemberConfirm(Object name) {
    return '确定将「$name」移出群聊吗？';
  }

  @override
  String get removeAction => '移出';

  @override
  String get memberRemoved => '已移出群聊';

  @override
  String get mutedChip => '禁言中';

  @override
  String get mutedBadge => '已禁言';

  @override
  String setNicknameFor(Object name) {
    return '设置「$name」的群昵称';
  }

  @override
  String get unmutedOk => '已解除禁言';

  @override
  String get mute1h => '禁言 1 小时';

  @override
  String get mute24h => '禁言 24 小时';

  @override
  String get mute7d => '禁言 7 天';

  @override
  String get mute30d => '禁言 30 天';

  @override
  String get muteCustom => '自定义时间…';

  @override
  String get muteCustomTitle => '选择禁言到期时间';

  @override
  String get unmuteNow => '解除禁言';

  @override
  String get groupManageTitle => '群管理';

  @override
  String get allGroupMembers => '全部群成员';

  @override
  String get searchGroupMembers => '搜索群成员';

  @override
  String viewAllMembers(Object count) {
    return '查看全部群成员（$count）';
  }

  @override
  String get mutePermanent => '长期禁言';

  @override
  String get mutedOk => '已禁言';

  @override
  String get joinRequestsTitle => '进群申请';

  @override
  String get approvalRequiredPolicy => '入群需审核';

  @override
  String get openGroup => '公开群';

  @override
  String get groupNumberTitle => '群号';

  @override
  String get notAssigned => '未分配';

  @override
  String get groupNumberCopied => '群号已复制';

  @override
  String get useDefaultNickname => '使用默认昵称';

  @override
  String get inviteFriendsTitle => '邀请好友入群';

  @override
  String get inviteFriendsSubtitle => '向好友发送群邀请，对方确认后入群';

  @override
  String get shareGroup => '分享群聊';

  @override
  String get shareGroupSubtitle => '发送群名片给好友，对方可点击加入';

  @override
  String get myJoinRequestsTitle => '我发起的入群申请';

  @override
  String get myJoinRequestsSubtitle => '查看申请状态与审核结果';

  @override
  String get approvalToggle => '进群审核';

  @override
  String get approvalOnSubtitle => '新成员入群需管理员审核';

  @override
  String get approvalOffSubtitle => '扫码可直接入群';

  @override
  String groupMembersCount(Object count) {
    return '群成员（$count）';
  }

  @override
  String get noJoinRequests => '暂无进群申请';

  @override
  String get joinRequestDefaultMsg => '申请加入群聊';

  @override
  String get decline => '拒绝';

  @override
  String get approve => '通过';

  @override
  String get requestAccepted => '已通过';

  @override
  String get requestDeclined => '已拒绝';

  @override
  String get requestCanceled => '已撤回';

  @override
  String get statusPendingReview => '审核中';

  @override
  String get noMyRequests => '暂无申请';

  @override
  String get userRejected => '用户';

  @override
  String get applyJoinGroup => '申请加入群聊';

  @override
  String get applyJoinHint => '填写申请信息（可选）';

  @override
  String get submitApplication => '提交申请';

  @override
  String get joinRequestSubmitted => '申请已提交，等待管理员审核';

  @override
  String get noPendingInvite => '未找到待处理的群邀请';

  @override
  String get joinedGroupToast => '已加入群聊';

  @override
  String get inviteIgnored => '已忽略群邀请';

  @override
  String get groupCardPageTitle => '群名片';

  @override
  String get enterGroup => '进入群聊';

  @override
  String get appliedPending => '已提交申请，等待管理员审核';

  @override
  String get ignore => '忽略';

  @override
  String get acceptInvite => '接受邀请';

  @override
  String get joinGroup => '加入群聊';

  @override
  String get contactsPageTitle => '通讯录';

  @override
  String get addFriendTooltip => '添加好友';

  @override
  String get newFriends => '新的朋友';

  @override
  String get groupInvitesEntry => '群邀请';

  @override
  String get scanEntry => '扫一扫';

  @override
  String friendsCountHeader(Object count) {
    return '好友 · $count';
  }

  @override
  String groupsCountHeader(Object count) {
    return '群聊 · $count';
  }

  @override
  String get noFriendsHint => '暂无好友，点击右上角添加';

  @override
  String get noGroupsHint => '还没有加入任何群聊';

  @override
  String get sendMessage => '发消息';

  @override
  String get socialFeedbackSection => '社交与反馈';

  @override
  String get myQrcode => '我的二维码';

  @override
  String get myQrcodeSubtitle => '展示名片，扫码即可添加你为好友';

  @override
  String get feedbackEntry => '意见反馈';

  @override
  String get feedbackSubtitle => '提交 Bug / 建议，查看官方回复';

  @override
  String get blacklistEntry => '通讯录黑名单';

  @override
  String get blacklistSubtitle => '管理已拉黑的用户';

  @override
  String get personalizationSection => '个性化';

  @override
  String get themeColor => '主题色';

  @override
  String get chatWallpaper => '聊天壁纸';

  @override
  String get defaultWallpaper => '默认壁纸';

  @override
  String get customWallpaper => '自定义壁纸';

  @override
  String get pickThemeColor => '选择主题色';

  @override
  String get noNickname => '未设置昵称';

  @override
  String get aboutBody =>
      'Sylph 是一款轻量、私密、畅快的即时通讯应用。支持单聊与群聊、端到端加密、语音与图片消息，还可以通过二维码快速添加好友、组建群组。我们希望让每一次交流都简单而安心。';

  @override
  String get feedbackEmailSubject => 'Sylph 反馈';

  @override
  String get cannotOpenMail => '无法打开邮件应用';

  @override
  String get developer => '开发者';

  @override
  String get developerName => '晚霞 · 独立开发者';

  @override
  String get contactEmailLabel => '联系邮箱';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get alreadyLatest => '当前已是最新版本';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get saved => '已保存';

  @override
  String get usernameTaken => '用户名已被占用';

  @override
  String get accountSection => '账号';

  @override
  String get emailLabel => '邮箱';

  @override
  String get usernameEditableHint => '用户名（可编辑）';

  @override
  String get bio => '简介';

  @override
  String get bioHint => '介绍一下自己';

  @override
  String get unknownGender => '未知';

  @override
  String get avatarSavedHint => '头像已更新，点击右上角保存生效';

  @override
  String get wallpaperUnsupported => '桌面/网页端暂不支持选择壁纸';

  @override
  String get wallpaperSaveFailed => '壁纸保存失败，请重试';

  @override
  String get wallpaperSet => '壁纸已设置';

  @override
  String get wallpaperReset => '已恢复默认壁纸';

  @override
  String get wallpaperPreview1 => '你好，这是壁纸预览效果';

  @override
  String get wallpaperPreview2 => '拖动下方滑块调节明暗';

  @override
  String get pickFromGallery => '从相册选择';

  @override
  String get wallpaperUnsupportedShort => '桌面/网页端暂不支持';

  @override
  String get pickLocalImage => '选择本地图片作为聊天背景';

  @override
  String get resetDefault => '恢复默认';

  @override
  String get overlayOpacity => '遮罩浓度';

  @override
  String get detailTitle => '详细资料';

  @override
  String get sendFriendRequest => '发送好友申请';

  @override
  String greetingWithName(Object name) {
    return '你好，我是 $name';
  }

  @override
  String get requestHint => '填写验证信息（可选）';

  @override
  String get sendRequestAction => '发送申请';

  @override
  String get requestSent => '好友申请已发送';

  @override
  String get noPendingRequest => '未找到待处理的申请';

  @override
  String get friendAdded => '已添加为好友';

  @override
  String get deleteFriendTitle => '删除好友';

  @override
  String deleteFriendConfirm(Object name) {
    return '确定删除与「$name」的好友关系吗？';
  }

  @override
  String get friendDeleted => '已删除好友';

  @override
  String get uidCopied => 'UID 已复制';

  @override
  String blockConfirmName(Object name) {
    return '确定拉黑「$name」吗？拉黑后将不再收到对方消息。';
  }

  @override
  String get noPendingVerify => '未找到待验证的好友申请';

  @override
  String get requestRevoked => '已撤回申请';

  @override
  String get withdrawRequest => '撤回申请';

  @override
  String remarkWithColon(Object remark) {
    return '备注：$remark';
  }

  @override
  String get noRemark => '未设置备注';

  @override
  String get bioEmptyHint => '这个人很懒，什么都没留下';

  @override
  String get messageSelf => '给自己发消息';

  @override
  String get requestPendingLabel => '已发送申请，等待验证';

  @override
  String get requestIgnored => '已忽略申请';

  @override
  String get acceptFriendRequest => '接受好友申请';

  @override
  String get addToContacts => '添加到通讯录';

  @override
  String get meMarker => '（我）';

  @override
  String inviteWithCount(Object count) {
    return '邀请($count)';
  }

  @override
  String get inviteFriends => '邀请好友';

  @override
  String get searchFriendsHint => '搜索好友';

  @override
  String get noInvitableFriends => '暂无可邀请的好友';

  @override
  String inviteSentCount(Object count) {
    return '已向 $count 位好友发送群邀请';
  }

  @override
  String get searchUserFullHint => '搜索 UID / 用户名 / 昵称';

  @override
  String get startGroupChat => '发起群聊';

  @override
  String get waitVerify => '等待验证';

  @override
  String get pendingAccept => '待接受';

  @override
  String get searchEmptyNoKeyword => '通过 UID / 昵称搜索好友';

  @override
  String get searchEmptyKeywordHint => '换个关键词，或扫描对方二维码';

  @override
  String get searchEmptyNoKeywordHint => '也可以点击上方「扫一扫」扫描好友二维码';

  @override
  String acceptedRequestFrom(Object name) {
    return '已接受 $name 的好友申请';
  }

  @override
  String get withdrawRequestConfirm => '确定撤回这条好友申请吗？';

  @override
  String get rethink => '再想想';

  @override
  String get receivedRequests => '收到的申请';

  @override
  String get sentRequests => '我发出的';

  @override
  String get noIncomingRequests => '还没有收到好友申请';

  @override
  String pendingCount(Object count) {
    return '待处理（$count）';
  }

  @override
  String get historySection => '历史记录';

  @override
  String get accept => '接受';

  @override
  String get added => '已添加';

  @override
  String get unknownPerson => '未知用户';

  @override
  String get noOutgoingRequests => '还没有发出的好友申请';

  @override
  String get groupNameRequired => '请输入群名称';

  @override
  String get selectAtLeastOne => '请至少选择 1 位好友';

  @override
  String get createAction => '创建';

  @override
  String selectFriendsCount(Object count) {
    return '选择好友（$count）';
  }

  @override
  String get selectMembersHint => '请选择群成员';

  @override
  String get myGroupNickHint => '我在本群的昵称（可选）';

  @override
  String get joinViaQrcode => '所有人可通过群二维码直接加入';

  @override
  String joinedGroupWithName(Object name) {
    return '已加入「$name」';
  }

  @override
  String get noGroupInvites => '还没有收到群邀请';

  @override
  String invitedByToJoin(Object name) {
    return '$name 邀请你加入群聊';
  }

  @override
  String get receivedGroupInvite => '你收到一个群邀请';

  @override
  String get joinAction => '加入';

  @override
  String get joinedStatus => '已加入';

  @override
  String get qrUnrecognized => '无法识别的二维码内容';

  @override
  String get userNotFound => '用户不存在';

  @override
  String qrInvalidReason(Object reason) {
    return '二维码已失效或无法解析：$reason';
  }

  @override
  String get torchUnsupported => '当前设备不支持闪光灯';

  @override
  String get imageScanUnsupported => '当前平台不支持图片二维码识别，请在手机上使用';

  @override
  String get imageReadFailed => '图片读取失败，请重新选择';

  @override
  String get qrNotFound => '未识别到二维码';

  @override
  String imageScanFailedReason(Object reason) {
    return '图片识别失败：$reason';
  }

  @override
  String get torchOnTooltip => '闪光灯';

  @override
  String get torchOffTooltip => '关闭闪光灯';

  @override
  String get galleryTooltip => '相册';

  @override
  String get cameraUnavailableManual => '当前设备相机不可用，请在下方手动输入 UID/群号';

  @override
  String get scanHint => '将二维码放入框内，即可自动扫描';

  @override
  String get manualInputHint => '相机不可用？手动输入 UID / 群号';

  @override
  String get cameraStartFailed => '相机启动失败，可重试或使用手动输入';

  @override
  String reasonDetail(Object detail) {
    return '原因：$detail';
  }

  @override
  String get openSystemSettings => '打开系统设置';

  @override
  String get cameraPermissionDenied => '相机权限被拒绝，扫码需要使用相机权限';

  @override
  String get reauthorize => '重新授权';

  @override
  String get resetQrcode => '重置二维码';

  @override
  String get resetQrcodeConfirm => '重置后旧二维码将立即失效，确定继续吗？';

  @override
  String get resetAction => '重置';

  @override
  String resetFailedReason(Object reason) {
    return '重置失败：$reason';
  }

  @override
  String get imageGenFailed => '生成图片失败';

  @override
  String get savedToGallery => '已保存到相册';

  @override
  String imageSavedWithPath(Object path) {
    return '图片已保存：$path';
  }

  @override
  String qrcodeShareSubject(Object name) {
    return '$name 的二维码 - Sylph';
  }

  @override
  String get qrcodeScanTip => '扫描二维码，即可添加好友/加入群聊';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get copyLink => '复制链接';

  @override
  String get shareImage => '分享图片';

  @override
  String get shareLink => '分享链接';

  @override
  String get inAppShare => '站内分享';

  @override
  String get sylphUser => 'Sylph 用户';

  @override
  String get shareCardTo => '分享名片给';

  @override
  String get cardShared => '已分享名片';

  @override
  String get fbTypeBug => 'Bug 问题';

  @override
  String get fbTypeSuggestion => '功能建议';

  @override
  String get fbTypeComplaint => '投诉举报';

  @override
  String get fbOther => '其他';

  @override
  String get fbSuggestion => '建议';

  @override
  String get fbComplaint => '投诉';

  @override
  String get fbStatusPending => '待处理';

  @override
  String get fbStatusProcessing => '处理中';

  @override
  String get fbStatusReplied => '已回复';

  @override
  String get fbStatusClosed => '已关闭';

  @override
  String get feedbackSubmitted => '反馈已提交，可在下方查看处理进度';

  @override
  String submitFailedReason(Object reason) {
    return '提交失败：$reason';
  }

  @override
  String get feedbackType => '反馈类型';

  @override
  String get feedbackDescHint => '请描述问题或建议，我们会尽快处理…';

  @override
  String get contactHint => '联系方式（邮箱，选填，便于我们回复）';

  @override
  String get submitFeedback => '提交反馈';

  @override
  String get myFeedback => '我的反馈';

  @override
  String get noFeedbackYet => '还没有提交过反馈';

  @override
  String get feedbackDetailTitle => '反馈详情';

  @override
  String get ticketClosedHint => '工单已关闭，再次发送将重新打开';

  @override
  String get followUpHint => '补充问题描述…';

  @override
  String get officialReply => '官方回复';

  @override
  String get syncedByEmail => '（已同步邮件）';

  @override
  String get reportSpam => '垃圾营销';

  @override
  String get reportAbuse => '辱骂骚扰';

  @override
  String get reportPorn => '色情低俗';

  @override
  String get reportFraud => '欺诈';

  @override
  String get reportSubmitted => '举报已提交';

  @override
  String reportFailedReason(Object reason) {
    return '举报失败：$reason';
  }

  @override
  String get reportDetailHint => '补充说明（选填）';

  @override
  String get submitReport => '提交举报';

  @override
  String get unblockedOk => '已解除拉黑';

  @override
  String get blacklistEmpty => '黑名单为空';

  @override
  String get unblockAction => '解除';

  @override
  String get scanQrcodeInImage => '识别二维码';

  @override
  String get saveToGallery => '保存到相册';

  @override
  String get videoPlayUnsupported => '视频播放暂不支持';

  @override
  String get techP256 => '公钥协商（一次性公钥 + 签名预签公钥回退）';

  @override
  String get techHkdf => '会话密钥派生';

  @override
  String get techAesGcm => '消息体认证加密，12 字节随机 nonce 随消息发送';

  @override
  String get techBase64 => '密文作为消息 content，encrypted=true';

  @override
  String get qrImageOnly => '仅图片支持识别二维码';

  @override
  String imageDownloadFailed(Object reason) {
    return '下载图片失败：$reason';
  }

  @override
  String get imageDataEmpty => '图片数据为空';

  @override
  String tempFileWriteFailed(Object reason) {
    return '写入临时文件失败：$reason';
  }

  @override
  String get qrContentEmpty => '二维码内容为空';

  @override
  String get videoTapToPlay => '点击播放视频';

  @override
  String get addToStickers => '添加到表情';

  @override
  String get addStickerFailed => '添加表情失败';

  @override
  String get stickerAdded => '已添加到表情';

  @override
  String get deleteStickerConfirm => '删除这个收藏表情？';

  @override
  String get emoji => '表情';

  @override
  String get emojiSection => '表情';

  @override
  String get stickerSection => '收藏表情';

  @override
  String get savedEmojiSection => '收藏的表情';

  @override
  String get emojiOnlyCannotSave => '只能收藏纯表情内容';

  @override
  String get draftLabel => '草稿';

  @override
  String get lastMessageRecalled => '撤回了一条消息';

  @override
  String get album => '相册';

  @override
  String get capture => '拍摄';

  @override
  String get cameraTakePhoto => '拍照';

  @override
  String get cameraTakeVideo => '录像';

  @override
  String get location => '位置';

  @override
  String get redPacket => '红包';

  @override
  String get developingBadge => '开发中';

  @override
  String get redPacketDeveloping => '红包功能正在开发中，敬请期待';

  @override
  String get file => '文件';

  @override
  String get music => '音乐';

  @override
  String get musicCard => '音乐';

  @override
  String get fileTooLarge => '文件大小超过 20MB 限制';

  @override
  String get locationPermissionDenied => '定位权限被拒绝，无法获取位置';

  @override
  String locationFallback(Object coords) {
    return '位置（$coords）';
  }

  @override
  String get openLocationFailed => '无法打开地图应用';

  @override
  String get openFileFailed => '无法打开文件';

  @override
  String get sendLocationTitle => '发送位置';

  @override
  String get mentionAll => '@所有人';

  @override
  String get mentionMeHint => '有人@我';

  @override
  String get lastMessageLocation => '[位置]';

  @override
  String get lastMessageMusic => '[音乐]';

  @override
  String get lastMessageCall => '[语音通话]';

  @override
  String get voiceCall => '语音通话';

  @override
  String get incomingVoiceCall => '邀请你进行语音通话';

  @override
  String get callWaitingAnswer => '等待对方接听…';

  @override
  String get callIncomingHint => '邀请你进行语音通话';

  @override
  String get callMicOn => '麦克风';

  @override
  String get callMicOff => '已静音';

  @override
  String get callSpeaker => '扬声器';

  @override
  String get hangUp => '挂断';

  @override
  String get cancelCall => '取消';

  @override
  String get callEnded => '通话结束';

  @override
  String get callRejected => '通话已拒绝';

  @override
  String get callCanceled => '通话已取消';

  @override
  String get callNoAnswer => '对方未接听';

  @override
  String get callBusy => '对方忙线中';

  @override
  String get callPeerOffline => '对方不在线';

  @override
  String get callAcceptedElsewhere => '已在其他设备接听';

  @override
  String get callMicPermissionDenied => '需要麦克风权限才能通话';

  @override
  String get callConnectFailed => '通话连接失败';

  @override
  String get callBack => '回拨';

  @override
  String callRecordCompleted(Object duration) {
    return '通话时长 $duration';
  }

  @override
  String get callRecordMissed => '未接通';

  @override
  String get callRecordRejected => '已拒绝';

  @override
  String get callRecordCanceled => '已取消';

  @override
  String get globalSearchTitle => '搜索';

  @override
  String get globalSearchHint => '搜索联系人、聊天记录';

  @override
  String get globalSearchSectionContacts => '联系人';

  @override
  String get globalSearchSectionMessages => '聊天记录';

  @override
  String get globalSearchNoResults => '未找到相关结果';

  @override
  String get addMenuTooltip => '更多操作';

  @override
  String get musicDownloading => '正在下载…';

  @override
  String get reply => '回复';

  @override
  String get cancelReplyDraft => '取消回复';

  @override
  String replyToNamed(Object name) {
    return '回复 $name';
  }

  @override
  String get quoteYou => '你';

  @override
  String get quoteImage => '[图片]';

  @override
  String get quoteVoice => '[语音]';

  @override
  String get quoteVideo => '[视频]';

  @override
  String get quoteFile => '[文件]';

  @override
  String get quoteMusic => '[音乐]';

  @override
  String get quoteLocation => '[位置]';

  @override
  String get quoteCall => '[通话]';

  @override
  String get quoteEncrypted => '[加密消息]';

  @override
  String get messageNotFound => '原消息不在当前聊天记录';

  @override
  String get callMinimize => '最小化';

  @override
  String get callSpeakerOn => '扬声器';

  @override
  String get callSpeakerOff => '听筒';

  @override
  String get callOngoingTapReturn => '点击返回通话';

  @override
  String get videoCall => '视频通话';

  @override
  String get incomingVideoCall => '邀请你进行视频通话';

  @override
  String get cameraOn => '摄像头';

  @override
  String get cameraOff => '摄像头已关';

  @override
  String get switchCamera => '翻转';

  @override
  String get groupVoiceCall => '群语音通话';

  @override
  String get incomingGroupCall => '邀请你加入群语音通话';

  @override
  String get groupCallEnded => '群通话已结束';

  @override
  String get groupCallWaitingJoin => '等待群成员加入…';

  @override
  String get groupCallMemberUnit => '人';

  @override
  String get joinCall => '加入';

  @override
  String get meLabel => '我';

  @override
  String get groupCallBusy => '忙线中，请稍后再试';

  @override
  String get groupCallFull => '群通话人数已满（最多 8 人）';

  @override
  String get groupCallNotMember => '你不是该群成员';
}
