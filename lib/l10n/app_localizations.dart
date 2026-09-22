import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Sylph'**
  String get appTitle;

  /// No description provided for @appSlogan.
  ///
  /// In zh, this message translates to:
  /// **'轻风即时通讯'**
  String get appSlogan;

  /// No description provided for @navChats.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get navChats;

  /// No description provided for @navContacts.
  ///
  /// In zh, this message translates to:
  /// **'通讯录'**
  String get navContacts;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navSettings;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'登录 Sylph'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In zh, this message translates to:
  /// **'注册账号'**
  String get registerTitle;

  /// No description provided for @tabPasswordLogin.
  ///
  /// In zh, this message translates to:
  /// **'密码登录'**
  String get tabPasswordLogin;

  /// No description provided for @tabPhoneLogin.
  ///
  /// In zh, this message translates to:
  /// **'验证码登录'**
  String get tabPhoneLogin;

  /// No description provided for @username.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get username;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @nickname.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get nickname;

  /// No description provided for @phone.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get phone;

  /// No description provided for @verificationCode.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get verificationCode;

  /// No description provided for @sendCode.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get sendCode;

  /// No description provided for @phoneLoginUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'验证码登录暂未开放，请使用用户名密码登录'**
  String get phoneLoginUnavailable;

  /// No description provided for @loginSubmit.
  ///
  /// In zh, this message translates to:
  /// **'登 录'**
  String get loginSubmit;

  /// No description provided for @registerSubmit.
  ///
  /// In zh, this message translates to:
  /// **'注 册'**
  String get registerSubmit;

  /// No description provided for @toRegister.
  ///
  /// In zh, this message translates to:
  /// **'没有账号？去注册'**
  String get toRegister;

  /// No description provided for @toLogin.
  ///
  /// In zh, this message translates to:
  /// **'已有账号？去登录'**
  String get toLogin;

  /// No description provided for @registerSuccess.
  ///
  /// In zh, this message translates to:
  /// **'注册成功，请登录'**
  String get registerSuccess;

  /// No description provided for @usernameHint.
  ///
  /// In zh, this message translates to:
  /// **'3-64 位字母、数字或下划线'**
  String get usernameHint;

  /// No description provided for @passwordHint.
  ///
  /// In zh, this message translates to:
  /// **'至少 6 位'**
  String get passwordHint;

  /// No description provided for @fieldRequired.
  ///
  /// In zh, this message translates to:
  /// **'该项不能为空'**
  String get fieldRequired;

  /// No description provided for @sessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已过期，请重新登录'**
  String get sessionExpired;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要退出当前账号吗？'**
  String get logoutConfirm;

  /// No description provided for @loginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请检查用户名或密码'**
  String get loginFailed;

  /// No description provided for @conversationsTitle.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get conversationsTitle;

  /// No description provided for @newChat.
  ///
  /// In zh, this message translates to:
  /// **'发起新聊'**
  String get newChat;

  /// No description provided for @newSingleChat.
  ///
  /// In zh, this message translates to:
  /// **'新建单聊'**
  String get newSingleChat;

  /// No description provided for @newGroupChat.
  ///
  /// In zh, this message translates to:
  /// **'新建群聊'**
  String get newGroupChat;

  /// No description provided for @searchUserHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索用户名 / 昵称'**
  String get searchUserHint;

  /// No description provided for @searchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未找到相关用户'**
  String get searchEmpty;

  /// No description provided for @groupName.
  ///
  /// In zh, this message translates to:
  /// **'群名称'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In zh, this message translates to:
  /// **'给群聊起个名字'**
  String get groupNameHint;

  /// No description provided for @selectMembers.
  ///
  /// In zh, this message translates to:
  /// **'选择成员'**
  String get selectMembers;

  /// No description provided for @createGroup.
  ///
  /// In zh, this message translates to:
  /// **'创建群聊'**
  String get createGroup;

  /// No description provided for @selectAtLeastTwo.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择 2 位成员'**
  String get selectAtLeastTwo;

  /// No description provided for @conversationEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有会话，点击右上角发起新聊'**
  String get conversationEmpty;

  /// No description provided for @pullToRefresh.
  ///
  /// In zh, this message translates to:
  /// **'下拉刷新'**
  String get pullToRefresh;

  /// No description provided for @refreshing.
  ///
  /// In zh, this message translates to:
  /// **'刷新中…'**
  String get refreshing;

  /// No description provided for @refreshDone.
  ///
  /// In zh, this message translates to:
  /// **'刷新完成'**
  String get refreshDone;

  /// No description provided for @lastMessageImage.
  ///
  /// In zh, this message translates to:
  /// **'[图片]'**
  String get lastMessageImage;

  /// No description provided for @lastMessageVoice.
  ///
  /// In zh, this message translates to:
  /// **'[语音]'**
  String get lastMessageVoice;

  /// No description provided for @lastMessageVideo.
  ///
  /// In zh, this message translates to:
  /// **'[视频]'**
  String get lastMessageVideo;

  /// No description provided for @lastMessageFile.
  ///
  /// In zh, this message translates to:
  /// **'[文件]'**
  String get lastMessageFile;

  /// No description provided for @lastMessageSystem.
  ///
  /// In zh, this message translates to:
  /// **'[系统消息]'**
  String get lastMessageSystem;

  /// No description provided for @lastMessageEncrypted.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密消息'**
  String get lastMessageEncrypted;

  /// No description provided for @lastMessageYou.
  ///
  /// In zh, this message translates to:
  /// **'你: '**
  String get lastMessageYou;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get settingsTitle;

  /// No description provided for @profileSection.
  ///
  /// In zh, this message translates to:
  /// **'个人资料'**
  String get profileSection;

  /// No description provided for @editProfile.
  ///
  /// In zh, this message translates to:
  /// **'编辑资料'**
  String get editProfile;

  /// No description provided for @accountSettings.
  ///
  /// In zh, this message translates to:
  /// **'账号与安全'**
  String get accountSettings;

  /// No description provided for @preferences.
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @theme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @devices.
  ///
  /// In zh, this message translates to:
  /// **'登录设备管理'**
  String get devices;

  /// No description provided for @privateEntry.
  ///
  /// In zh, this message translates to:
  /// **'私密会话说明'**
  String get privateEntry;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get loading;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @emptyData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get emptyData;

  /// No description provided for @updateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'更新成功'**
  String get updateSuccess;

  /// No description provided for @operationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get operationFailed;

  /// No description provided for @gender.
  ///
  /// In zh, this message translates to:
  /// **'性别'**
  String get gender;

  /// No description provided for @genderUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get genderUnknown;

  /// No description provided for @genderMale.
  ///
  /// In zh, this message translates to:
  /// **'男'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In zh, this message translates to:
  /// **'女'**
  String get genderFemale;

  /// No description provided for @usernameLabel.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get usernameLabel;

  /// No description provided for @devicesTitle.
  ///
  /// In zh, this message translates to:
  /// **'登录设备'**
  String get devicesTitle;

  /// No description provided for @currentDevice.
  ///
  /// In zh, this message translates to:
  /// **'本设备'**
  String get currentDevice;

  /// No description provided for @revokeDevice.
  ///
  /// In zh, this message translates to:
  /// **'远程下线'**
  String get revokeDevice;

  /// No description provided for @revokeDeviceConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定将该设备下线吗？该设备需要重新登录。'**
  String get revokeDeviceConfirm;

  /// No description provided for @revokedCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前设备已被下线'**
  String get revokedCurrent;

  /// No description provided for @lastLoginAt.
  ///
  /// In zh, this message translates to:
  /// **'最近登录'**
  String get lastLoginAt;

  /// No description provided for @privateInfoTitle.
  ///
  /// In zh, this message translates to:
  /// **'私密会话（端到端加密）'**
  String get privateInfoTitle;

  /// No description provided for @privateInfoBody.
  ///
  /// In zh, this message translates to:
  /// **'私密会话仅支持单聊。开启后，消息采用 P-256 (ECDH) 协商密钥，HKDF-SHA256 派生、AES-GCM 加密后再发送。服务端只可见密文，无法读取内容。\n\n密钥仅保存在本设备浏览器中，更换设备后将无法读取历史密文。'**
  String get privateInfoBody;

  /// No description provided for @chatInputHint.
  ///
  /// In zh, this message translates to:
  /// **'发送消息…'**
  String get chatInputHint;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @sendImage.
  ///
  /// In zh, this message translates to:
  /// **'发送图片'**
  String get sendImage;

  /// No description provided for @pickImage.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get pickImage;

  /// No description provided for @imagePicking.
  ///
  /// In zh, this message translates to:
  /// **'图片处理中…'**
  String get imagePicking;

  /// No description provided for @imageUploading.
  ///
  /// In zh, this message translates to:
  /// **'图片上传中…'**
  String get imageUploading;

  /// No description provided for @messageSending.
  ///
  /// In zh, this message translates to:
  /// **'发送中…'**
  String get messageSending;

  /// No description provided for @messageSendFailed.
  ///
  /// In zh, this message translates to:
  /// **'发送失败，将在重连后重试'**
  String get messageSendFailed;

  /// No description provided for @e2eeEncrypted.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密消息，无法解密'**
  String get e2eeEncrypted;

  /// No description provided for @e2eeBadge.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密'**
  String get e2eeBadge;

  /// No description provided for @privateSwitch.
  ///
  /// In zh, this message translates to:
  /// **'私密会话'**
  String get privateSwitch;

  /// No description provided for @privateEnableTip.
  ///
  /// In zh, this message translates to:
  /// **'开启后将生成本设备密钥并上传公钥束，消息会以端到端加密发送'**
  String get privateEnableTip;

  /// No description provided for @privateDisableTip.
  ///
  /// In zh, this message translates to:
  /// **'已关闭端到端加密，后续消息将以明文发送'**
  String get privateDisableTip;

  /// No description provided for @e2eePreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在准备端到端加密密钥…'**
  String get e2eePreparing;

  /// No description provided for @e2eePeerNoKeys.
  ///
  /// In zh, this message translates to:
  /// **'对方尚未启用端到端加密，请让对方先开启私密会话'**
  String get e2eePeerNoKeys;

  /// No description provided for @resend.
  ///
  /// In zh, this message translates to:
  /// **'重发'**
  String get resend;

  /// No description provided for @loadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更早的消息'**
  String get loadMore;

  /// No description provided for @noMoreMessages.
  ///
  /// In zh, this message translates to:
  /// **'没有更多消息了'**
  String get noMoreMessages;

  /// No description provided for @messagesLoading.
  ///
  /// In zh, this message translates to:
  /// **'消息加载中…'**
  String get messagesLoading;

  /// No description provided for @messagesLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'消息加载失败'**
  String get messagesLoadFailed;

  /// No description provided for @connectionConnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接…'**
  String get connectionConnecting;

  /// No description provided for @connectionReconnecting.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开，正在重连…'**
  String get connectionReconnecting;

  /// No description provided for @connectionDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开'**
  String get connectionDisconnected;

  /// No description provided for @connectionConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get connectionConnected;

  /// No description provided for @statusPending.
  ///
  /// In zh, this message translates to:
  /// **'发送中'**
  String get statusPending;

  /// No description provided for @statusSent.
  ///
  /// In zh, this message translates to:
  /// **'已发送'**
  String get statusSent;

  /// No description provided for @statusDelivered.
  ///
  /// In zh, this message translates to:
  /// **'已送达'**
  String get statusDelivered;

  /// No description provided for @statusRead.
  ///
  /// In zh, this message translates to:
  /// **'已读'**
  String get statusRead;

  /// No description provided for @statusBlocked.
  ///
  /// In zh, this message translates to:
  /// **'消息被风控拦截'**
  String get statusBlocked;

  /// No description provided for @statusFailed.
  ///
  /// In zh, this message translates to:
  /// **'发送失败'**
  String get statusFailed;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @memberCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 人'**
  String memberCount(Object count);

  /// No description provided for @sendEmailCode.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get sendEmailCode;

  /// No description provided for @codeSent.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送至邮箱'**
  String get codeSent;

  /// No description provided for @resendIn.
  ///
  /// In zh, this message translates to:
  /// **'{seconds}s 后重发'**
  String resendIn(Object seconds);

  /// No description provided for @loginByEmail.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginByEmail;

  /// No description provided for @emailFieldLabel.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get emailFieldLabel;

  /// No description provided for @emailHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入邮箱'**
  String get emailHint;

  /// No description provided for @codeHint.
  ///
  /// In zh, this message translates to:
  /// **'6 位验证码'**
  String get codeHint;

  /// No description provided for @emailLoginTip.
  ///
  /// In zh, this message translates to:
  /// **'未注册的邮箱将自动创建账号'**
  String get emailLoginTip;

  /// No description provided for @switchToUidLogin.
  ///
  /// In zh, this message translates to:
  /// **'使用 UID + 密码登录'**
  String get switchToUidLogin;

  /// No description provided for @switchToEmailLogin.
  ///
  /// In zh, this message translates to:
  /// **'使用邮箱验证码登录'**
  String get switchToEmailLogin;

  /// No description provided for @uidFieldLabel.
  ///
  /// In zh, this message translates to:
  /// **'UID'**
  String get uidFieldLabel;

  /// No description provided for @uidHint.
  ///
  /// In zh, this message translates to:
  /// **'8 位数字 UID'**
  String get uidHint;

  /// No description provided for @loginByEmailFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请检查验证码'**
  String get loginByEmailFailed;

  /// No description provided for @loginByUidFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请检查 UID 或密码'**
  String get loginByUidFailed;

  /// No description provided for @setInitialPassword.
  ///
  /// In zh, this message translates to:
  /// **'设置初始密码'**
  String get setInitialPassword;

  /// No description provided for @changePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get changePassword;

  /// No description provided for @oldPassword.
  ///
  /// In zh, this message translates to:
  /// **'原密码'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In zh, this message translates to:
  /// **'新密码'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认新密码'**
  String get confirmPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'至少 8 位，需含字母和数字'**
  String get newPasswordHint;

  /// No description provided for @passwordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不一致'**
  String get passwordMismatch;

  /// No description provided for @passwordSetSuccess.
  ///
  /// In zh, this message translates to:
  /// **'初始密码已设置'**
  String get passwordSetSuccess;

  /// No description provided for @passwordChanged.
  ///
  /// In zh, this message translates to:
  /// **'密码已修改'**
  String get passwordChanged;

  /// No description provided for @setInitialPasswordTip.
  ///
  /// In zh, this message translates to:
  /// **'邮箱登录后可设置初始密码，以便使用 UID + 密码登录'**
  String get setInitialPasswordTip;

  /// No description provided for @navProfile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navProfile;

  /// No description provided for @accountSecurity.
  ///
  /// In zh, this message translates to:
  /// **'账号与安全'**
  String get accountSecurity;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @aboutSylph.
  ///
  /// In zh, this message translates to:
  /// **'关于 Sylph'**
  String get aboutSylph;

  /// No description provided for @aboutSylphBody.
  ///
  /// In zh, this message translates to:
  /// **'Sylph · 轻量、私密的即时通讯客户端。'**
  String get aboutSylphBody;

  /// No description provided for @profileCard.
  ///
  /// In zh, this message translates to:
  /// **'个人主页'**
  String get profileCard;

  /// No description provided for @contactsTitle.
  ///
  /// In zh, this message translates to:
  /// **'联系人'**
  String get contactsTitle;

  /// No description provided for @myGroups.
  ///
  /// In zh, this message translates to:
  /// **'我的群聊'**
  String get myGroups;

  /// No description provided for @myContacts.
  ///
  /// In zh, this message translates to:
  /// **'我的联系人'**
  String get myContacts;

  /// No description provided for @noGroupsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无群聊'**
  String get noGroupsYet;

  /// No description provided for @noContactsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无联系人'**
  String get noContactsYet;

  /// No description provided for @errorWithReason.
  ///
  /// In zh, this message translates to:
  /// **'操作失败：{reason}'**
  String errorWithReason(Object reason);

  /// No description provided for @sendFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'发送失败：{reason}'**
  String sendFailedReason(Object reason);

  /// No description provided for @loadFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{reason}'**
  String loadFailedReason(Object reason);

  /// No description provided for @saveFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{reason}'**
  String saveFailedReason(Object reason);

  /// No description provided for @shareFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'分享失败：{reason}'**
  String shareFailedReason(Object reason);

  /// No description provided for @encryptFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'加密失败：{reason}'**
  String encryptFailedReason(Object reason);

  /// No description provided for @forwardFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'转发失败：{reason}'**
  String forwardFailedReason(Object reason);

  /// No description provided for @recallFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'撤回失败：{reason}'**
  String recallFailedReason(Object reason);

  /// No description provided for @playFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'播放失败：{reason}'**
  String playFailedReason(Object reason);

  /// No description provided for @recordStartFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'录音启动失败：{reason}'**
  String recordStartFailedReason(Object reason);

  /// No description provided for @voiceSendFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'语音发送失败：{reason}'**
  String voiceSendFailedReason(Object reason);

  /// No description provided for @avatarUploadFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'头像上传失败：{reason}'**
  String avatarUploadFailedReason(Object reason);

  /// No description provided for @loadFriendsFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'加载好友失败：{reason}'**
  String loadFriendsFailedReason(Object reason);

  /// No description provided for @openCardFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'打开名片失败：{reason}'**
  String openCardFailedReason(Object reason);

  /// No description provided for @setWallpaperFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'设置壁纸失败：{reason}'**
  String setWallpaperFailedReason(Object reason);

  /// No description provided for @privateMode.
  ///
  /// In zh, this message translates to:
  /// **'私密模式'**
  String get privateMode;

  /// No description provided for @privateModeOn.
  ///
  /// In zh, this message translates to:
  /// **'已开启私密模式'**
  String get privateModeOn;

  /// No description provided for @privateModeOff.
  ///
  /// In zh, this message translates to:
  /// **'已关闭私密模式'**
  String get privateModeOff;

  /// No description provided for @e2eePrepareFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密密钥准备失败，请稍后重试\n原因：{reason}'**
  String e2eePrepareFailedReason(Object reason);

  /// No description provided for @mutedOn.
  ///
  /// In zh, this message translates to:
  /// **'已开启消息免打扰'**
  String get mutedOn;

  /// No description provided for @mutedOff.
  ///
  /// In zh, this message translates to:
  /// **'已关闭消息免打扰'**
  String get mutedOff;

  /// No description provided for @pinnedOn.
  ///
  /// In zh, this message translates to:
  /// **'已置顶聊天'**
  String get pinnedOn;

  /// No description provided for @unpinned.
  ///
  /// In zh, this message translates to:
  /// **'已取消置顶'**
  String get unpinned;

  /// No description provided for @pinToTop.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get pinToTop;

  /// No description provided for @unpinLabel.
  ///
  /// In zh, this message translates to:
  /// **'取消置顶'**
  String get unpinLabel;

  /// No description provided for @pinChat.
  ///
  /// In zh, this message translates to:
  /// **'置顶聊天'**
  String get pinChat;

  /// No description provided for @muteConv.
  ///
  /// In zh, this message translates to:
  /// **'消息免打扰'**
  String get muteConv;

  /// No description provided for @unmuteConv.
  ///
  /// In zh, this message translates to:
  /// **'取消免打扰'**
  String get unmuteConv;

  /// No description provided for @viewProfile.
  ///
  /// In zh, this message translates to:
  /// **'查看资料'**
  String get viewProfile;

  /// No description provided for @setRemarkTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置备注'**
  String get setRemarkTitle;

  /// No description provided for @setRemarkHint.
  ///
  /// In zh, this message translates to:
  /// **'给对方设置一个备注名'**
  String get setRemarkHint;

  /// No description provided for @remarkSaved.
  ///
  /// In zh, this message translates to:
  /// **'备注已保存'**
  String get remarkSaved;

  /// No description provided for @report.
  ///
  /// In zh, this message translates to:
  /// **'举报'**
  String get report;

  /// No description provided for @reportGroup.
  ///
  /// In zh, this message translates to:
  /// **'举报群聊'**
  String get reportGroup;

  /// No description provided for @blockUserTitle.
  ///
  /// In zh, this message translates to:
  /// **'拉黑用户'**
  String get blockUserTitle;

  /// No description provided for @blockUserConfirm.
  ///
  /// In zh, this message translates to:
  /// **'拉黑后将不再收到对方消息，确定拉黑吗？'**
  String get blockUserConfirm;

  /// No description provided for @blockAction.
  ///
  /// In zh, this message translates to:
  /// **'拉黑'**
  String get blockAction;

  /// No description provided for @blocked.
  ///
  /// In zh, this message translates to:
  /// **'已拉黑'**
  String get blocked;

  /// No description provided for @terminateChatTitle.
  ///
  /// In zh, this message translates to:
  /// **'终止会话'**
  String get terminateChatTitle;

  /// No description provided for @terminateChatConfirm.
  ///
  /// In zh, this message translates to:
  /// **'终止后双方都将不再显示该会话且无法继续发消息，确定终止吗？'**
  String get terminateChatConfirm;

  /// No description provided for @terminateAction.
  ///
  /// In zh, this message translates to:
  /// **'终止'**
  String get terminateAction;

  /// No description provided for @chatTerminated.
  ///
  /// In zh, this message translates to:
  /// **'会话已终止'**
  String get chatTerminated;

  /// No description provided for @leaveGroupTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出群聊'**
  String get leaveGroupTitle;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In zh, this message translates to:
  /// **'退出后将不再接收该群消息，确定退出吗？'**
  String get leaveGroupConfirm;

  /// No description provided for @leaveAction.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get leaveAction;

  /// No description provided for @leftGroup.
  ///
  /// In zh, this message translates to:
  /// **'已退出群聊'**
  String get leftGroup;

  /// No description provided for @dissolveGroup.
  ///
  /// In zh, this message translates to:
  /// **'解散群聊'**
  String get dissolveGroup;

  /// No description provided for @dissolveConfirm.
  ///
  /// In zh, this message translates to:
  /// **'解散后群聊将不可用，确定解散吗？'**
  String get dissolveConfirm;

  /// No description provided for @dissolveAction.
  ///
  /// In zh, this message translates to:
  /// **'解散'**
  String get dissolveAction;

  /// No description provided for @deleteConvTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除会话'**
  String get deleteConvTitle;

  /// No description provided for @dissolvedConvDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'该群已解散，删除后会话将从列表中移除，确定吗？'**
  String get dissolvedConvDeleteConfirm;

  /// No description provided for @convDeleted.
  ///
  /// In zh, this message translates to:
  /// **'会话已删除'**
  String get convDeleted;

  /// No description provided for @groupDissolved.
  ///
  /// In zh, this message translates to:
  /// **'该群已解散'**
  String get groupDissolved;

  /// No description provided for @groupDissolvedHint.
  ///
  /// In zh, this message translates to:
  /// **'群聊已不可用，可删除会话从列表移除'**
  String get groupDissolvedHint;

  /// No description provided for @selectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 条'**
  String selectedCount(Object count);

  /// No description provided for @forward.
  ///
  /// In zh, this message translates to:
  /// **'转发'**
  String get forward;

  /// No description provided for @forwardTo.
  ///
  /// In zh, this message translates to:
  /// **'转发给'**
  String get forwardTo;

  /// No description provided for @forwarded.
  ///
  /// In zh, this message translates to:
  /// **'已转发'**
  String get forwarded;

  /// No description provided for @forwardedCount.
  ///
  /// In zh, this message translates to:
  /// **'已转发 {count} 条'**
  String forwardedCount(Object count);

  /// No description provided for @forwardedPartialFail.
  ///
  /// In zh, this message translates to:
  /// **'已转发 {count} 条，后续失败：{reason}'**
  String forwardedPartialFail(Object count, Object reason);

  /// No description provided for @convCreating.
  ///
  /// In zh, this message translates to:
  /// **'会话创建中，请稍后在该会话内重试'**
  String get convCreating;

  /// No description provided for @e2eePeerNoKeysForward.
  ///
  /// In zh, this message translates to:
  /// **'对方尚未启用端到端加密，无法转发到私密会话'**
  String get e2eePeerNoKeysForward;

  /// No description provided for @convLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'会话信息加载失败'**
  String get convLoadFailed;

  /// No description provided for @groupSettings.
  ///
  /// In zh, this message translates to:
  /// **'群聊设置'**
  String get groupSettings;

  /// No description provided for @micPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'请授予录音权限'**
  String get micPermissionDenied;

  /// No description provided for @voiceTooShort.
  ///
  /// In zh, this message translates to:
  /// **'录音太短'**
  String get voiceTooShort;

  /// No description provided for @photo.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get photo;

  /// No description provided for @card.
  ///
  /// In zh, this message translates to:
  /// **'名片'**
  String get card;

  /// No description provided for @voice.
  ///
  /// In zh, this message translates to:
  /// **'语音'**
  String get voice;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @keyboard.
  ///
  /// In zh, this message translates to:
  /// **'键盘'**
  String get keyboard;

  /// No description provided for @releaseToCancel.
  ///
  /// In zh, this message translates to:
  /// **'松开取消'**
  String get releaseToCancel;

  /// No description provided for @slideUpCancel.
  ///
  /// In zh, this message translates to:
  /// **'上滑取消 · {seconds}s'**
  String slideUpCancel(Object seconds);

  /// No description provided for @holdToTalk.
  ///
  /// In zh, this message translates to:
  /// **'按住说话'**
  String get holdToTalk;

  /// No description provided for @cardSent.
  ///
  /// In zh, this message translates to:
  /// **'名片已发送'**
  String get cardSent;

  /// No description provided for @pickCardTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择名片'**
  String get pickCardTitle;

  /// No description provided for @userCard.
  ///
  /// In zh, this message translates to:
  /// **'个人名片'**
  String get userCard;

  /// No description provided for @groupCard.
  ///
  /// In zh, this message translates to:
  /// **'群聊名片'**
  String get groupCard;

  /// No description provided for @userCardWithUid.
  ///
  /// In zh, this message translates to:
  /// **'个人名片 · UID {uid}'**
  String userCardWithUid(Object uid);

  /// No description provided for @groupCardWithNumber.
  ///
  /// In zh, this message translates to:
  /// **'群聊名片 · 群号 {number}'**
  String groupCardWithNumber(Object number);

  /// No description provided for @noFriends.
  ///
  /// In zh, this message translates to:
  /// **'暂无好友'**
  String get noFriends;

  /// No description provided for @noGroupsToShare.
  ///
  /// In zh, this message translates to:
  /// **'暂无可分享的群聊'**
  String get noGroupsToShare;

  /// No description provided for @groupNumberLabel.
  ///
  /// In zh, this message translates to:
  /// **'群号 {number}'**
  String groupNumberLabel(Object number);

  /// No description provided for @pickMentionTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择提醒成员'**
  String get pickMentionTitle;

  /// No description provided for @confirmWithCount.
  ///
  /// In zh, this message translates to:
  /// **'确定({count})'**
  String confirmWithCount(Object count);

  /// No description provided for @searchMembers.
  ///
  /// In zh, this message translates to:
  /// **'搜索成员'**
  String get searchMembers;

  /// No description provided for @owner.
  ///
  /// In zh, this message translates to:
  /// **'群主'**
  String get owner;

  /// No description provided for @admin.
  ///
  /// In zh, this message translates to:
  /// **'管理员'**
  String get admin;

  /// No description provided for @memberRole.
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get memberRole;

  /// No description provided for @youAreMuted.
  ///
  /// In zh, this message translates to:
  /// **'您已被禁言'**
  String get youAreMuted;

  /// No description provided for @mutedRemainingDh.
  ///
  /// In zh, this message translates to:
  /// **'您已被禁言，剩余 {days}天{hours}小时'**
  String mutedRemainingDh(Object days, Object hours);

  /// No description provided for @mutedRemainingHm.
  ///
  /// In zh, this message translates to:
  /// **'您已被禁言，剩余 {hours}小时{mins}分'**
  String mutedRemainingHm(Object hours, Object mins);

  /// No description provided for @mutedRemainingMs.
  ///
  /// In zh, this message translates to:
  /// **'您已被禁言，剩余 {mins}分{secs}秒'**
  String mutedRemainingMs(Object mins, Object secs);

  /// No description provided for @mutedRemainingS.
  ///
  /// In zh, this message translates to:
  /// **'您已被禁言，剩余 {secs}秒'**
  String mutedRemainingS(Object secs);

  /// No description provided for @durationDays.
  ///
  /// In zh, this message translates to:
  /// **'{days}天'**
  String durationDays(Object days);

  /// No description provided for @durationDaysHours.
  ///
  /// In zh, this message translates to:
  /// **'{days}天{hours}小时'**
  String durationDaysHours(Object days, Object hours);

  /// No description provided for @durationHours.
  ///
  /// In zh, this message translates to:
  /// **'{hours}小时'**
  String durationHours(Object hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{hours}小时{mins}分'**
  String durationHoursMinutes(Object hours, Object mins);

  /// No description provided for @durationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{mins}分'**
  String durationMinutes(Object mins);

  /// No description provided for @durationSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{secs}秒'**
  String durationSeconds(Object secs);

  /// No description provided for @newMember.
  ///
  /// In zh, this message translates to:
  /// **'新成员'**
  String get newMember;

  /// No description provided for @joinedGroupNotice.
  ///
  /// In zh, this message translates to:
  /// **' 加入了群聊'**
  String get joinedGroupNotice;

  /// No description provided for @mutedBy.
  ///
  /// In zh, this message translates to:
  /// **' 被 '**
  String get mutedBy;

  /// No description provided for @mutedForDuration.
  ///
  /// In zh, this message translates to:
  /// **' 禁言 {duration}'**
  String mutedForDuration(Object duration);

  /// No description provided for @unmutedBy.
  ///
  /// In zh, this message translates to:
  /// **' 被 '**
  String get unmutedBy;

  /// No description provided for @unmutedSuffix.
  ///
  /// In zh, this message translates to:
  /// **' 解除禁言'**
  String get unmutedSuffix;

  /// No description provided for @theMember.
  ///
  /// In zh, this message translates to:
  /// **'该成员'**
  String get theMember;

  /// No description provided for @unknownUser.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get unknownUser;

  /// No description provided for @unknownGroup.
  ///
  /// In zh, this message translates to:
  /// **'群聊'**
  String get unknownGroup;

  /// No description provided for @userFallbackId.
  ///
  /// In zh, this message translates to:
  /// **'用户{id}'**
  String userFallbackId(Object id);

  /// No description provided for @groupFallbackId.
  ///
  /// In zh, this message translates to:
  /// **'群聊{id}'**
  String groupFallbackId(Object id);

  /// No description provided for @singleChatFallback.
  ///
  /// In zh, this message translates to:
  /// **'单聊'**
  String get singleChatFallback;

  /// No description provided for @chatFallback.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get chatFallback;

  /// No description provided for @friendsSection.
  ///
  /// In zh, this message translates to:
  /// **'好友'**
  String get friendsSection;

  /// No description provided for @saveImage.
  ///
  /// In zh, this message translates to:
  /// **'保存图片'**
  String get saveImage;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @multiSelect.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get multiSelect;

  /// No description provided for @recall.
  ///
  /// In zh, this message translates to:
  /// **'撤回'**
  String get recall;

  /// No description provided for @recallWindowExpired.
  ///
  /// In zh, this message translates to:
  /// **'已超过可撤回时间'**
  String get recallWindowExpired;

  /// No description provided for @youRecalled.
  ///
  /// In zh, this message translates to:
  /// **'你撤回了一条消息'**
  String get youRecalled;

  /// No description provided for @peerRecalled.
  ///
  /// In zh, this message translates to:
  /// **'对方撤回了一条消息'**
  String get peerRecalled;

  /// No description provided for @recalledByName.
  ///
  /// In zh, this message translates to:
  /// **'{name}撤回了一条消息'**
  String recalledByName(Object name);

  /// No description provided for @adminFallback.
  ///
  /// In zh, this message translates to:
  /// **'管理员'**
  String get adminFallback;

  /// No description provided for @searchAddFriend.
  ///
  /// In zh, this message translates to:
  /// **'搜索并添加好友'**
  String get searchAddFriend;

  /// No description provided for @convListEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有会话'**
  String get convListEmptyTitle;

  /// No description provided for @convListEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角的加号，搜索并添加好友开始聊天'**
  String get convListEmptyHint;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @groupAvatarUpdated.
  ///
  /// In zh, this message translates to:
  /// **'群头像已更新'**
  String get groupAvatarUpdated;

  /// No description provided for @editGroupProfile.
  ///
  /// In zh, this message translates to:
  /// **'编辑群资料'**
  String get editGroupProfile;

  /// No description provided for @groupAnnouncement.
  ///
  /// In zh, this message translates to:
  /// **'群公告'**
  String get groupAnnouncement;

  /// No description provided for @groupProfileUpdated.
  ///
  /// In zh, this message translates to:
  /// **'群资料已更新'**
  String get groupProfileUpdated;

  /// No description provided for @myNicknameInGroup.
  ///
  /// In zh, this message translates to:
  /// **'我在本群的昵称'**
  String get myNicknameInGroup;

  /// No description provided for @nicknameLeaveEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'留空则使用默认昵称'**
  String get nicknameLeaveEmptyHint;

  /// No description provided for @groupNicknameUpdated.
  ///
  /// In zh, this message translates to:
  /// **'群昵称已更新'**
  String get groupNicknameUpdated;

  /// No description provided for @groupQrcode.
  ///
  /// In zh, this message translates to:
  /// **'群二维码'**
  String get groupQrcode;

  /// No description provided for @groupQrcodeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'分享二维码邀请好友入群'**
  String get groupQrcodeSubtitle;

  /// No description provided for @noFriendsToShare.
  ///
  /// In zh, this message translates to:
  /// **'没有可分享的好友'**
  String get noFriendsToShare;

  /// No description provided for @shareGroupToFriend.
  ///
  /// In zh, this message translates to:
  /// **'分享群聊给好友'**
  String get shareGroupToFriend;

  /// No description provided for @sharedTo.
  ///
  /// In zh, this message translates to:
  /// **'已分享给 {name}'**
  String sharedTo(Object name);

  /// No description provided for @setMemberNicknameTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置群昵称'**
  String get setMemberNicknameTitle;

  /// No description provided for @editMyGroupNickname.
  ///
  /// In zh, this message translates to:
  /// **'修改我的群昵称'**
  String get editMyGroupNickname;

  /// No description provided for @removeAdmin.
  ///
  /// In zh, this message translates to:
  /// **'取消管理员'**
  String get removeAdmin;

  /// No description provided for @adminRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已取消管理员'**
  String get adminRemoved;

  /// No description provided for @makeAdmin.
  ///
  /// In zh, this message translates to:
  /// **'设为管理员'**
  String get makeAdmin;

  /// No description provided for @adminSet.
  ///
  /// In zh, this message translates to:
  /// **'已设为管理员'**
  String get adminSet;

  /// No description provided for @unmuteMember.
  ///
  /// In zh, this message translates to:
  /// **'解除禁言'**
  String get unmuteMember;

  /// No description provided for @muteMember.
  ///
  /// In zh, this message translates to:
  /// **'禁言'**
  String get muteMember;

  /// No description provided for @removeMember.
  ///
  /// In zh, this message translates to:
  /// **'移出群聊'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定将「{name}」移出群聊吗？'**
  String removeMemberConfirm(Object name);

  /// No description provided for @removeAction.
  ///
  /// In zh, this message translates to:
  /// **'移出'**
  String get removeAction;

  /// No description provided for @memberRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已移出群聊'**
  String get memberRemoved;

  /// No description provided for @mutedChip.
  ///
  /// In zh, this message translates to:
  /// **'禁言中'**
  String get mutedChip;

  /// No description provided for @mutedBadge.
  ///
  /// In zh, this message translates to:
  /// **'已禁言'**
  String get mutedBadge;

  /// No description provided for @setNicknameFor.
  ///
  /// In zh, this message translates to:
  /// **'设置「{name}」的群昵称'**
  String setNicknameFor(Object name);

  /// No description provided for @unmutedOk.
  ///
  /// In zh, this message translates to:
  /// **'已解除禁言'**
  String get unmutedOk;

  /// No description provided for @mute1h.
  ///
  /// In zh, this message translates to:
  /// **'禁言 1 小时'**
  String get mute1h;

  /// No description provided for @mute24h.
  ///
  /// In zh, this message translates to:
  /// **'禁言 24 小时'**
  String get mute24h;

  /// No description provided for @mute7d.
  ///
  /// In zh, this message translates to:
  /// **'禁言 7 天'**
  String get mute7d;

  /// No description provided for @mute30d.
  ///
  /// In zh, this message translates to:
  /// **'禁言 30 天'**
  String get mute30d;

  /// No description provided for @muteCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义时间…'**
  String get muteCustom;

  /// No description provided for @muteCustomTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择禁言到期时间'**
  String get muteCustomTitle;

  /// No description provided for @unmuteNow.
  ///
  /// In zh, this message translates to:
  /// **'解除禁言'**
  String get unmuteNow;

  /// No description provided for @groupManageTitle.
  ///
  /// In zh, this message translates to:
  /// **'群管理'**
  String get groupManageTitle;

  /// No description provided for @allGroupMembers.
  ///
  /// In zh, this message translates to:
  /// **'全部群成员'**
  String get allGroupMembers;

  /// No description provided for @searchGroupMembers.
  ///
  /// In zh, this message translates to:
  /// **'搜索群成员'**
  String get searchGroupMembers;

  /// No description provided for @viewAllMembers.
  ///
  /// In zh, this message translates to:
  /// **'查看全部群成员（{count}）'**
  String viewAllMembers(Object count);

  /// No description provided for @mutePermanent.
  ///
  /// In zh, this message translates to:
  /// **'长期禁言'**
  String get mutePermanent;

  /// No description provided for @mutedOk.
  ///
  /// In zh, this message translates to:
  /// **'已禁言'**
  String get mutedOk;

  /// No description provided for @joinRequestsTitle.
  ///
  /// In zh, this message translates to:
  /// **'进群申请'**
  String get joinRequestsTitle;

  /// No description provided for @approvalRequiredPolicy.
  ///
  /// In zh, this message translates to:
  /// **'入群需审核'**
  String get approvalRequiredPolicy;

  /// No description provided for @openGroup.
  ///
  /// In zh, this message translates to:
  /// **'公开群'**
  String get openGroup;

  /// No description provided for @groupNumberTitle.
  ///
  /// In zh, this message translates to:
  /// **'群号'**
  String get groupNumberTitle;

  /// No description provided for @notAssigned.
  ///
  /// In zh, this message translates to:
  /// **'未分配'**
  String get notAssigned;

  /// No description provided for @groupNumberCopied.
  ///
  /// In zh, this message translates to:
  /// **'群号已复制'**
  String get groupNumberCopied;

  /// No description provided for @useDefaultNickname.
  ///
  /// In zh, this message translates to:
  /// **'使用默认昵称'**
  String get useDefaultNickname;

  /// No description provided for @inviteFriendsTitle.
  ///
  /// In zh, this message translates to:
  /// **'邀请好友入群'**
  String get inviteFriendsTitle;

  /// No description provided for @inviteFriendsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'向好友发送群邀请，对方确认后入群'**
  String get inviteFriendsSubtitle;

  /// No description provided for @shareGroup.
  ///
  /// In zh, this message translates to:
  /// **'分享群聊'**
  String get shareGroup;

  /// No description provided for @shareGroupSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'发送群名片给好友，对方可点击加入'**
  String get shareGroupSubtitle;

  /// No description provided for @myJoinRequestsTitle.
  ///
  /// In zh, this message translates to:
  /// **'我发起的入群申请'**
  String get myJoinRequestsTitle;

  /// No description provided for @myJoinRequestsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看申请状态与审核结果'**
  String get myJoinRequestsSubtitle;

  /// No description provided for @approvalToggle.
  ///
  /// In zh, this message translates to:
  /// **'进群审核'**
  String get approvalToggle;

  /// No description provided for @approvalOnSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'新成员入群需管理员审核'**
  String get approvalOnSubtitle;

  /// No description provided for @approvalOffSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'扫码可直接入群'**
  String get approvalOffSubtitle;

  /// No description provided for @groupMembersCount.
  ///
  /// In zh, this message translates to:
  /// **'群成员（{count}）'**
  String groupMembersCount(Object count);

  /// No description provided for @noJoinRequests.
  ///
  /// In zh, this message translates to:
  /// **'暂无进群申请'**
  String get noJoinRequests;

  /// No description provided for @joinRequestDefaultMsg.
  ///
  /// In zh, this message translates to:
  /// **'申请加入群聊'**
  String get joinRequestDefaultMsg;

  /// No description provided for @decline.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get decline;

  /// No description provided for @approve.
  ///
  /// In zh, this message translates to:
  /// **'通过'**
  String get approve;

  /// No description provided for @requestAccepted.
  ///
  /// In zh, this message translates to:
  /// **'已通过'**
  String get requestAccepted;

  /// No description provided for @requestDeclined.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get requestDeclined;

  /// No description provided for @requestCanceled.
  ///
  /// In zh, this message translates to:
  /// **'已撤回'**
  String get requestCanceled;

  /// No description provided for @statusPendingReview.
  ///
  /// In zh, this message translates to:
  /// **'审核中'**
  String get statusPendingReview;

  /// No description provided for @noMyRequests.
  ///
  /// In zh, this message translates to:
  /// **'暂无申请'**
  String get noMyRequests;

  /// No description provided for @userRejected.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get userRejected;

  /// No description provided for @applyJoinGroup.
  ///
  /// In zh, this message translates to:
  /// **'申请加入群聊'**
  String get applyJoinGroup;

  /// No description provided for @applyJoinHint.
  ///
  /// In zh, this message translates to:
  /// **'填写申请信息（可选）'**
  String get applyJoinHint;

  /// No description provided for @submitApplication.
  ///
  /// In zh, this message translates to:
  /// **'提交申请'**
  String get submitApplication;

  /// No description provided for @joinRequestSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'申请已提交，等待管理员审核'**
  String get joinRequestSubmitted;

  /// No description provided for @noPendingInvite.
  ///
  /// In zh, this message translates to:
  /// **'未找到待处理的群邀请'**
  String get noPendingInvite;

  /// No description provided for @joinedGroupToast.
  ///
  /// In zh, this message translates to:
  /// **'已加入群聊'**
  String get joinedGroupToast;

  /// No description provided for @inviteIgnored.
  ///
  /// In zh, this message translates to:
  /// **'已忽略群邀请'**
  String get inviteIgnored;

  /// No description provided for @groupCardPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'群名片'**
  String get groupCardPageTitle;

  /// No description provided for @enterGroup.
  ///
  /// In zh, this message translates to:
  /// **'进入群聊'**
  String get enterGroup;

  /// No description provided for @appliedPending.
  ///
  /// In zh, this message translates to:
  /// **'已提交申请，等待管理员审核'**
  String get appliedPending;

  /// No description provided for @ignore.
  ///
  /// In zh, this message translates to:
  /// **'忽略'**
  String get ignore;

  /// No description provided for @acceptInvite.
  ///
  /// In zh, this message translates to:
  /// **'接受邀请'**
  String get acceptInvite;

  /// No description provided for @joinGroup.
  ///
  /// In zh, this message translates to:
  /// **'加入群聊'**
  String get joinGroup;

  /// No description provided for @contactsPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'通讯录'**
  String get contactsPageTitle;

  /// No description provided for @addFriendTooltip.
  ///
  /// In zh, this message translates to:
  /// **'添加好友'**
  String get addFriendTooltip;

  /// No description provided for @newFriends.
  ///
  /// In zh, this message translates to:
  /// **'新的朋友'**
  String get newFriends;

  /// No description provided for @groupInvitesEntry.
  ///
  /// In zh, this message translates to:
  /// **'群邀请'**
  String get groupInvitesEntry;

  /// No description provided for @scanEntry.
  ///
  /// In zh, this message translates to:
  /// **'扫一扫'**
  String get scanEntry;

  /// No description provided for @friendsCountHeader.
  ///
  /// In zh, this message translates to:
  /// **'好友 · {count}'**
  String friendsCountHeader(Object count);

  /// No description provided for @groupsCountHeader.
  ///
  /// In zh, this message translates to:
  /// **'群聊 · {count}'**
  String groupsCountHeader(Object count);

  /// No description provided for @noFriendsHint.
  ///
  /// In zh, this message translates to:
  /// **'暂无好友，点击右上角添加'**
  String get noFriendsHint;

  /// No description provided for @noGroupsHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有加入任何群聊'**
  String get noGroupsHint;

  /// No description provided for @sendMessage.
  ///
  /// In zh, this message translates to:
  /// **'发消息'**
  String get sendMessage;

  /// No description provided for @socialFeedbackSection.
  ///
  /// In zh, this message translates to:
  /// **'社交与反馈'**
  String get socialFeedbackSection;

  /// No description provided for @myQrcode.
  ///
  /// In zh, this message translates to:
  /// **'我的二维码'**
  String get myQrcode;

  /// No description provided for @myQrcodeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'展示名片，扫码即可添加你为好友'**
  String get myQrcodeSubtitle;

  /// No description provided for @feedbackEntry.
  ///
  /// In zh, this message translates to:
  /// **'意见反馈'**
  String get feedbackEntry;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'提交 Bug / 建议，查看官方回复'**
  String get feedbackSubtitle;

  /// No description provided for @blacklistEntry.
  ///
  /// In zh, this message translates to:
  /// **'通讯录黑名单'**
  String get blacklistEntry;

  /// No description provided for @blacklistSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理已拉黑的用户'**
  String get blacklistSubtitle;

  /// No description provided for @personalizationSection.
  ///
  /// In zh, this message translates to:
  /// **'个性化'**
  String get personalizationSection;

  /// No description provided for @themeColor.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get themeColor;

  /// No description provided for @chatWallpaper.
  ///
  /// In zh, this message translates to:
  /// **'聊天壁纸'**
  String get chatWallpaper;

  /// No description provided for @defaultWallpaper.
  ///
  /// In zh, this message translates to:
  /// **'默认壁纸'**
  String get defaultWallpaper;

  /// No description provided for @customWallpaper.
  ///
  /// In zh, this message translates to:
  /// **'自定义壁纸'**
  String get customWallpaper;

  /// No description provided for @pickThemeColor.
  ///
  /// In zh, this message translates to:
  /// **'选择主题色'**
  String get pickThemeColor;

  /// No description provided for @noNickname.
  ///
  /// In zh, this message translates to:
  /// **'未设置昵称'**
  String get noNickname;

  /// No description provided for @aboutBody.
  ///
  /// In zh, this message translates to:
  /// **'Sylph 是一款轻量、私密、畅快的即时通讯应用。支持单聊与群聊、端到端加密、语音与图片消息，还可以通过二维码快速添加好友、组建群组。我们希望让每一次交流都简单而安心。'**
  String get aboutBody;

  /// No description provided for @feedbackEmailSubject.
  ///
  /// In zh, this message translates to:
  /// **'Sylph 反馈'**
  String get feedbackEmailSubject;

  /// No description provided for @cannotOpenMail.
  ///
  /// In zh, this message translates to:
  /// **'无法打开邮件应用'**
  String get cannotOpenMail;

  /// No description provided for @developer.
  ///
  /// In zh, this message translates to:
  /// **'开发者'**
  String get developer;

  /// No description provided for @developerName.
  ///
  /// In zh, this message translates to:
  /// **'晚霞 · 独立开发者'**
  String get developerName;

  /// No description provided for @contactEmailLabel.
  ///
  /// In zh, this message translates to:
  /// **'联系邮箱'**
  String get contactEmailLabel;

  /// No description provided for @checkUpdate.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get checkUpdate;

  /// No description provided for @alreadyLatest.
  ///
  /// In zh, this message translates to:
  /// **'当前已是最新版本'**
  String get alreadyLatest;

  /// No description provided for @openSourceLicenses.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get openSourceLicenses;

  /// No description provided for @saved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get saved;

  /// No description provided for @usernameTaken.
  ///
  /// In zh, this message translates to:
  /// **'用户名已被占用'**
  String get usernameTaken;

  /// No description provided for @accountSection.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get accountSection;

  /// No description provided for @emailLabel.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get emailLabel;

  /// No description provided for @usernameEditableHint.
  ///
  /// In zh, this message translates to:
  /// **'用户名（可编辑）'**
  String get usernameEditableHint;

  /// No description provided for @bio.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get bio;

  /// No description provided for @bioHint.
  ///
  /// In zh, this message translates to:
  /// **'介绍一下自己'**
  String get bioHint;

  /// No description provided for @unknownGender.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknownGender;

  /// No description provided for @avatarSavedHint.
  ///
  /// In zh, this message translates to:
  /// **'头像已更新，点击右上角保存生效'**
  String get avatarSavedHint;

  /// No description provided for @wallpaperUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'桌面/网页端暂不支持选择壁纸'**
  String get wallpaperUnsupported;

  /// No description provided for @wallpaperSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'壁纸保存失败，请重试'**
  String get wallpaperSaveFailed;

  /// No description provided for @wallpaperSet.
  ///
  /// In zh, this message translates to:
  /// **'壁纸已设置'**
  String get wallpaperSet;

  /// No description provided for @wallpaperReset.
  ///
  /// In zh, this message translates to:
  /// **'已恢复默认壁纸'**
  String get wallpaperReset;

  /// No description provided for @wallpaperPreview1.
  ///
  /// In zh, this message translates to:
  /// **'你好，这是壁纸预览效果'**
  String get wallpaperPreview1;

  /// No description provided for @wallpaperPreview2.
  ///
  /// In zh, this message translates to:
  /// **'拖动下方滑块调节明暗'**
  String get wallpaperPreview2;

  /// No description provided for @pickFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get pickFromGallery;

  /// No description provided for @wallpaperUnsupportedShort.
  ///
  /// In zh, this message translates to:
  /// **'桌面/网页端暂不支持'**
  String get wallpaperUnsupportedShort;

  /// No description provided for @pickLocalImage.
  ///
  /// In zh, this message translates to:
  /// **'选择本地图片作为聊天背景'**
  String get pickLocalImage;

  /// No description provided for @resetDefault.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get resetDefault;

  /// No description provided for @overlayOpacity.
  ///
  /// In zh, this message translates to:
  /// **'遮罩浓度'**
  String get overlayOpacity;

  /// No description provided for @detailTitle.
  ///
  /// In zh, this message translates to:
  /// **'详细资料'**
  String get detailTitle;

  /// No description provided for @sendFriendRequest.
  ///
  /// In zh, this message translates to:
  /// **'发送好友申请'**
  String get sendFriendRequest;

  /// No description provided for @greetingWithName.
  ///
  /// In zh, this message translates to:
  /// **'你好，我是 {name}'**
  String greetingWithName(Object name);

  /// No description provided for @requestHint.
  ///
  /// In zh, this message translates to:
  /// **'填写验证信息（可选）'**
  String get requestHint;

  /// No description provided for @sendRequestAction.
  ///
  /// In zh, this message translates to:
  /// **'发送申请'**
  String get sendRequestAction;

  /// No description provided for @requestSent.
  ///
  /// In zh, this message translates to:
  /// **'好友申请已发送'**
  String get requestSent;

  /// No description provided for @noPendingRequest.
  ///
  /// In zh, this message translates to:
  /// **'未找到待处理的申请'**
  String get noPendingRequest;

  /// No description provided for @friendAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加为好友'**
  String get friendAdded;

  /// No description provided for @deleteFriendTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除好友'**
  String get deleteFriendTitle;

  /// No description provided for @deleteFriendConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除与「{name}」的好友关系吗？'**
  String deleteFriendConfirm(Object name);

  /// No description provided for @friendDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除好友'**
  String get friendDeleted;

  /// No description provided for @uidCopied.
  ///
  /// In zh, this message translates to:
  /// **'UID 已复制'**
  String get uidCopied;

  /// No description provided for @blockConfirmName.
  ///
  /// In zh, this message translates to:
  /// **'确定拉黑「{name}」吗？拉黑后将不再收到对方消息。'**
  String blockConfirmName(Object name);

  /// No description provided for @noPendingVerify.
  ///
  /// In zh, this message translates to:
  /// **'未找到待验证的好友申请'**
  String get noPendingVerify;

  /// No description provided for @requestRevoked.
  ///
  /// In zh, this message translates to:
  /// **'已撤回申请'**
  String get requestRevoked;

  /// No description provided for @withdrawRequest.
  ///
  /// In zh, this message translates to:
  /// **'撤回申请'**
  String get withdrawRequest;

  /// No description provided for @remarkWithColon.
  ///
  /// In zh, this message translates to:
  /// **'备注：{remark}'**
  String remarkWithColon(Object remark);

  /// No description provided for @noRemark.
  ///
  /// In zh, this message translates to:
  /// **'未设置备注'**
  String get noRemark;

  /// No description provided for @bioEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'这个人很懒，什么都没留下'**
  String get bioEmptyHint;

  /// No description provided for @messageSelf.
  ///
  /// In zh, this message translates to:
  /// **'给自己发消息'**
  String get messageSelf;

  /// No description provided for @requestPendingLabel.
  ///
  /// In zh, this message translates to:
  /// **'已发送申请，等待验证'**
  String get requestPendingLabel;

  /// No description provided for @requestIgnored.
  ///
  /// In zh, this message translates to:
  /// **'已忽略申请'**
  String get requestIgnored;

  /// No description provided for @acceptFriendRequest.
  ///
  /// In zh, this message translates to:
  /// **'接受好友申请'**
  String get acceptFriendRequest;

  /// No description provided for @addToContacts.
  ///
  /// In zh, this message translates to:
  /// **'添加到通讯录'**
  String get addToContacts;

  /// No description provided for @meMarker.
  ///
  /// In zh, this message translates to:
  /// **'（我）'**
  String get meMarker;

  /// No description provided for @inviteWithCount.
  ///
  /// In zh, this message translates to:
  /// **'邀请({count})'**
  String inviteWithCount(Object count);

  /// No description provided for @inviteFriends.
  ///
  /// In zh, this message translates to:
  /// **'邀请好友'**
  String get inviteFriends;

  /// No description provided for @searchFriendsHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索好友'**
  String get searchFriendsHint;

  /// No description provided for @noInvitableFriends.
  ///
  /// In zh, this message translates to:
  /// **'暂无可邀请的好友'**
  String get noInvitableFriends;

  /// No description provided for @inviteSentCount.
  ///
  /// In zh, this message translates to:
  /// **'已向 {count} 位好友发送群邀请'**
  String inviteSentCount(Object count);

  /// No description provided for @searchUserFullHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索 UID / 用户名 / 昵称'**
  String get searchUserFullHint;

  /// No description provided for @startGroupChat.
  ///
  /// In zh, this message translates to:
  /// **'发起群聊'**
  String get startGroupChat;

  /// No description provided for @waitVerify.
  ///
  /// In zh, this message translates to:
  /// **'等待验证'**
  String get waitVerify;

  /// No description provided for @pendingAccept.
  ///
  /// In zh, this message translates to:
  /// **'待接受'**
  String get pendingAccept;

  /// No description provided for @searchEmptyNoKeyword.
  ///
  /// In zh, this message translates to:
  /// **'通过 UID / 昵称搜索好友'**
  String get searchEmptyNoKeyword;

  /// No description provided for @searchEmptyKeywordHint.
  ///
  /// In zh, this message translates to:
  /// **'换个关键词，或扫描对方二维码'**
  String get searchEmptyKeywordHint;

  /// No description provided for @searchEmptyNoKeywordHint.
  ///
  /// In zh, this message translates to:
  /// **'也可以点击上方「扫一扫」扫描好友二维码'**
  String get searchEmptyNoKeywordHint;

  /// No description provided for @acceptedRequestFrom.
  ///
  /// In zh, this message translates to:
  /// **'已接受 {name} 的好友申请'**
  String acceptedRequestFrom(Object name);

  /// No description provided for @withdrawRequestConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定撤回这条好友申请吗？'**
  String get withdrawRequestConfirm;

  /// No description provided for @rethink.
  ///
  /// In zh, this message translates to:
  /// **'再想想'**
  String get rethink;

  /// No description provided for @receivedRequests.
  ///
  /// In zh, this message translates to:
  /// **'收到的申请'**
  String get receivedRequests;

  /// No description provided for @sentRequests.
  ///
  /// In zh, this message translates to:
  /// **'我发出的'**
  String get sentRequests;

  /// No description provided for @noIncomingRequests.
  ///
  /// In zh, this message translates to:
  /// **'还没有收到好友申请'**
  String get noIncomingRequests;

  /// No description provided for @pendingCount.
  ///
  /// In zh, this message translates to:
  /// **'待处理（{count}）'**
  String pendingCount(Object count);

  /// No description provided for @historySection.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get historySection;

  /// No description provided for @accept.
  ///
  /// In zh, this message translates to:
  /// **'接受'**
  String get accept;

  /// No description provided for @added.
  ///
  /// In zh, this message translates to:
  /// **'已添加'**
  String get added;

  /// No description provided for @unknownPerson.
  ///
  /// In zh, this message translates to:
  /// **'未知用户'**
  String get unknownPerson;

  /// No description provided for @noOutgoingRequests.
  ///
  /// In zh, this message translates to:
  /// **'还没有发出的好友申请'**
  String get noOutgoingRequests;

  /// No description provided for @groupNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入群名称'**
  String get groupNameRequired;

  /// No description provided for @selectAtLeastOne.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择 1 位好友'**
  String get selectAtLeastOne;

  /// No description provided for @createAction.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get createAction;

  /// No description provided for @selectFriendsCount.
  ///
  /// In zh, this message translates to:
  /// **'选择好友（{count}）'**
  String selectFriendsCount(Object count);

  /// No description provided for @selectMembersHint.
  ///
  /// In zh, this message translates to:
  /// **'请选择群成员'**
  String get selectMembersHint;

  /// No description provided for @myGroupNickHint.
  ///
  /// In zh, this message translates to:
  /// **'我在本群的昵称（可选）'**
  String get myGroupNickHint;

  /// No description provided for @joinViaQrcode.
  ///
  /// In zh, this message translates to:
  /// **'所有人可通过群二维码直接加入'**
  String get joinViaQrcode;

  /// No description provided for @joinedGroupWithName.
  ///
  /// In zh, this message translates to:
  /// **'已加入「{name}」'**
  String joinedGroupWithName(Object name);

  /// No description provided for @noGroupInvites.
  ///
  /// In zh, this message translates to:
  /// **'还没有收到群邀请'**
  String get noGroupInvites;

  /// No description provided for @invitedByToJoin.
  ///
  /// In zh, this message translates to:
  /// **'{name} 邀请你加入群聊'**
  String invitedByToJoin(Object name);

  /// No description provided for @receivedGroupInvite.
  ///
  /// In zh, this message translates to:
  /// **'你收到一个群邀请'**
  String get receivedGroupInvite;

  /// No description provided for @joinAction.
  ///
  /// In zh, this message translates to:
  /// **'加入'**
  String get joinAction;

  /// No description provided for @joinedStatus.
  ///
  /// In zh, this message translates to:
  /// **'已加入'**
  String get joinedStatus;

  /// No description provided for @qrUnrecognized.
  ///
  /// In zh, this message translates to:
  /// **'无法识别的二维码内容'**
  String get qrUnrecognized;

  /// No description provided for @userNotFound.
  ///
  /// In zh, this message translates to:
  /// **'用户不存在'**
  String get userNotFound;

  /// No description provided for @qrInvalidReason.
  ///
  /// In zh, this message translates to:
  /// **'二维码已失效或无法解析：{reason}'**
  String qrInvalidReason(Object reason);

  /// No description provided for @torchUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前设备不支持闪光灯'**
  String get torchUnsupported;

  /// No description provided for @imageScanUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前平台不支持图片二维码识别，请在手机上使用'**
  String get imageScanUnsupported;

  /// No description provided for @imageReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片读取失败，请重新选择'**
  String get imageReadFailed;

  /// No description provided for @qrNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未识别到二维码'**
  String get qrNotFound;

  /// No description provided for @imageScanFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'图片识别失败：{reason}'**
  String imageScanFailedReason(Object reason);

  /// No description provided for @torchOnTooltip.
  ///
  /// In zh, this message translates to:
  /// **'闪光灯'**
  String get torchOnTooltip;

  /// No description provided for @torchOffTooltip.
  ///
  /// In zh, this message translates to:
  /// **'关闭闪光灯'**
  String get torchOffTooltip;

  /// No description provided for @galleryTooltip.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get galleryTooltip;

  /// No description provided for @cameraUnavailableManual.
  ///
  /// In zh, this message translates to:
  /// **'当前设备相机不可用，请在下方手动输入 UID/群号'**
  String get cameraUnavailableManual;

  /// No description provided for @scanHint.
  ///
  /// In zh, this message translates to:
  /// **'将二维码放入框内，即可自动扫描'**
  String get scanHint;

  /// No description provided for @manualInputHint.
  ///
  /// In zh, this message translates to:
  /// **'相机不可用？手动输入 UID / 群号'**
  String get manualInputHint;

  /// No description provided for @cameraStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'相机启动失败，可重试或使用手动输入'**
  String get cameraStartFailed;

  /// No description provided for @reasonDetail.
  ///
  /// In zh, this message translates to:
  /// **'原因：{detail}'**
  String reasonDetail(Object detail);

  /// No description provided for @openSystemSettings.
  ///
  /// In zh, this message translates to:
  /// **'打开系统设置'**
  String get openSystemSettings;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'相机权限被拒绝，扫码需要使用相机权限'**
  String get cameraPermissionDenied;

  /// No description provided for @reauthorize.
  ///
  /// In zh, this message translates to:
  /// **'重新授权'**
  String get reauthorize;

  /// No description provided for @resetQrcode.
  ///
  /// In zh, this message translates to:
  /// **'重置二维码'**
  String get resetQrcode;

  /// No description provided for @resetQrcodeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'重置后旧二维码将立即失效，确定继续吗？'**
  String get resetQrcodeConfirm;

  /// No description provided for @resetAction.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get resetAction;

  /// No description provided for @resetFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'重置失败：{reason}'**
  String resetFailedReason(Object reason);

  /// No description provided for @imageGenFailed.
  ///
  /// In zh, this message translates to:
  /// **'生成图片失败'**
  String get imageGenFailed;

  /// No description provided for @savedToGallery.
  ///
  /// In zh, this message translates to:
  /// **'已保存到相册'**
  String get savedToGallery;

  /// No description provided for @imageSavedWithPath.
  ///
  /// In zh, this message translates to:
  /// **'图片已保存：{path}'**
  String imageSavedWithPath(Object path);

  /// No description provided for @qrcodeShareSubject.
  ///
  /// In zh, this message translates to:
  /// **'{name} 的二维码 - Sylph'**
  String qrcodeShareSubject(Object name);

  /// No description provided for @qrcodeScanTip.
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码，即可添加好友/加入群聊'**
  String get qrcodeScanTip;

  /// No description provided for @copiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get copiedToClipboard;

  /// No description provided for @copyLink.
  ///
  /// In zh, this message translates to:
  /// **'复制链接'**
  String get copyLink;

  /// No description provided for @shareImage.
  ///
  /// In zh, this message translates to:
  /// **'分享图片'**
  String get shareImage;

  /// No description provided for @shareLink.
  ///
  /// In zh, this message translates to:
  /// **'分享链接'**
  String get shareLink;

  /// No description provided for @inAppShare.
  ///
  /// In zh, this message translates to:
  /// **'站内分享'**
  String get inAppShare;

  /// No description provided for @sylphUser.
  ///
  /// In zh, this message translates to:
  /// **'Sylph 用户'**
  String get sylphUser;

  /// No description provided for @shareCardTo.
  ///
  /// In zh, this message translates to:
  /// **'分享名片给'**
  String get shareCardTo;

  /// No description provided for @cardShared.
  ///
  /// In zh, this message translates to:
  /// **'已分享名片'**
  String get cardShared;

  /// No description provided for @fbTypeBug.
  ///
  /// In zh, this message translates to:
  /// **'Bug 问题'**
  String get fbTypeBug;

  /// No description provided for @fbTypeSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'功能建议'**
  String get fbTypeSuggestion;

  /// No description provided for @fbTypeComplaint.
  ///
  /// In zh, this message translates to:
  /// **'投诉举报'**
  String get fbTypeComplaint;

  /// No description provided for @fbOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get fbOther;

  /// No description provided for @fbSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'建议'**
  String get fbSuggestion;

  /// No description provided for @fbComplaint.
  ///
  /// In zh, this message translates to:
  /// **'投诉'**
  String get fbComplaint;

  /// No description provided for @fbStatusPending.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get fbStatusPending;

  /// No description provided for @fbStatusProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中'**
  String get fbStatusProcessing;

  /// No description provided for @fbStatusReplied.
  ///
  /// In zh, this message translates to:
  /// **'已回复'**
  String get fbStatusReplied;

  /// No description provided for @fbStatusClosed.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get fbStatusClosed;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'反馈已提交，可在下方查看处理进度'**
  String get feedbackSubmitted;

  /// No description provided for @submitFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'提交失败：{reason}'**
  String submitFailedReason(Object reason);

  /// No description provided for @feedbackType.
  ///
  /// In zh, this message translates to:
  /// **'反馈类型'**
  String get feedbackType;

  /// No description provided for @feedbackDescHint.
  ///
  /// In zh, this message translates to:
  /// **'请描述问题或建议，我们会尽快处理…'**
  String get feedbackDescHint;

  /// No description provided for @contactHint.
  ///
  /// In zh, this message translates to:
  /// **'联系方式（邮箱，选填，便于我们回复）'**
  String get contactHint;

  /// No description provided for @submitFeedback.
  ///
  /// In zh, this message translates to:
  /// **'提交反馈'**
  String get submitFeedback;

  /// No description provided for @myFeedback.
  ///
  /// In zh, this message translates to:
  /// **'我的反馈'**
  String get myFeedback;

  /// No description provided for @noFeedbackYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有提交过反馈'**
  String get noFeedbackYet;

  /// No description provided for @feedbackDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'反馈详情'**
  String get feedbackDetailTitle;

  /// No description provided for @ticketClosedHint.
  ///
  /// In zh, this message translates to:
  /// **'工单已关闭，再次发送将重新打开'**
  String get ticketClosedHint;

  /// No description provided for @followUpHint.
  ///
  /// In zh, this message translates to:
  /// **'补充问题描述…'**
  String get followUpHint;

  /// No description provided for @officialReply.
  ///
  /// In zh, this message translates to:
  /// **'官方回复'**
  String get officialReply;

  /// No description provided for @syncedByEmail.
  ///
  /// In zh, this message translates to:
  /// **'（已同步邮件）'**
  String get syncedByEmail;

  /// No description provided for @reportSpam.
  ///
  /// In zh, this message translates to:
  /// **'垃圾营销'**
  String get reportSpam;

  /// No description provided for @reportAbuse.
  ///
  /// In zh, this message translates to:
  /// **'辱骂骚扰'**
  String get reportAbuse;

  /// No description provided for @reportPorn.
  ///
  /// In zh, this message translates to:
  /// **'色情低俗'**
  String get reportPorn;

  /// No description provided for @reportFraud.
  ///
  /// In zh, this message translates to:
  /// **'欺诈'**
  String get reportFraud;

  /// No description provided for @reportSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'举报已提交'**
  String get reportSubmitted;

  /// No description provided for @reportFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'举报失败：{reason}'**
  String reportFailedReason(Object reason);

  /// No description provided for @reportDetailHint.
  ///
  /// In zh, this message translates to:
  /// **'补充说明（选填）'**
  String get reportDetailHint;

  /// No description provided for @submitReport.
  ///
  /// In zh, this message translates to:
  /// **'提交举报'**
  String get submitReport;

  /// No description provided for @unblockedOk.
  ///
  /// In zh, this message translates to:
  /// **'已解除拉黑'**
  String get unblockedOk;

  /// No description provided for @blacklistEmpty.
  ///
  /// In zh, this message translates to:
  /// **'黑名单为空'**
  String get blacklistEmpty;

  /// No description provided for @unblockAction.
  ///
  /// In zh, this message translates to:
  /// **'解除'**
  String get unblockAction;

  /// No description provided for @scanQrcodeInImage.
  ///
  /// In zh, this message translates to:
  /// **'识别二维码'**
  String get scanQrcodeInImage;

  /// No description provided for @saveToGallery.
  ///
  /// In zh, this message translates to:
  /// **'保存到相册'**
  String get saveToGallery;

  /// No description provided for @videoPlayUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'视频播放暂不支持'**
  String get videoPlayUnsupported;

  /// No description provided for @techP256.
  ///
  /// In zh, this message translates to:
  /// **'公钥协商（一次性公钥 + 签名预签公钥回退）'**
  String get techP256;

  /// No description provided for @techHkdf.
  ///
  /// In zh, this message translates to:
  /// **'会话密钥派生'**
  String get techHkdf;

  /// No description provided for @techAesGcm.
  ///
  /// In zh, this message translates to:
  /// **'消息体认证加密，12 字节随机 nonce 随消息发送'**
  String get techAesGcm;

  /// No description provided for @techBase64.
  ///
  /// In zh, this message translates to:
  /// **'密文作为消息 content，encrypted=true'**
  String get techBase64;

  /// No description provided for @qrImageOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅图片支持识别二维码'**
  String get qrImageOnly;

  /// No description provided for @imageDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载图片失败：{reason}'**
  String imageDownloadFailed(Object reason);

  /// No description provided for @imageDataEmpty.
  ///
  /// In zh, this message translates to:
  /// **'图片数据为空'**
  String get imageDataEmpty;

  /// No description provided for @tempFileWriteFailed.
  ///
  /// In zh, this message translates to:
  /// **'写入临时文件失败：{reason}'**
  String tempFileWriteFailed(Object reason);

  /// No description provided for @qrContentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'二维码内容为空'**
  String get qrContentEmpty;

  /// No description provided for @videoTapToPlay.
  ///
  /// In zh, this message translates to:
  /// **'点击播放视频'**
  String get videoTapToPlay;

  /// No description provided for @addToStickers.
  ///
  /// In zh, this message translates to:
  /// **'添加到表情'**
  String get addToStickers;

  /// No description provided for @addStickerFailed.
  ///
  /// In zh, this message translates to:
  /// **'添加表情失败'**
  String get addStickerFailed;

  /// No description provided for @stickerAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加到表情'**
  String get stickerAdded;

  /// No description provided for @deleteStickerConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除这个收藏表情？'**
  String get deleteStickerConfirm;

  /// No description provided for @emoji.
  ///
  /// In zh, this message translates to:
  /// **'表情'**
  String get emoji;

  /// No description provided for @emojiSection.
  ///
  /// In zh, this message translates to:
  /// **'表情'**
  String get emojiSection;

  /// No description provided for @stickerSection.
  ///
  /// In zh, this message translates to:
  /// **'收藏表情'**
  String get stickerSection;

  /// No description provided for @savedEmojiSection.
  ///
  /// In zh, this message translates to:
  /// **'收藏的表情'**
  String get savedEmojiSection;

  /// No description provided for @emojiOnlyCannotSave.
  ///
  /// In zh, this message translates to:
  /// **'只能收藏纯表情内容'**
  String get emojiOnlyCannotSave;

  /// No description provided for @draftLabel.
  ///
  /// In zh, this message translates to:
  /// **'草稿'**
  String get draftLabel;

  /// No description provided for @lastMessageRecalled.
  ///
  /// In zh, this message translates to:
  /// **'撤回了一条消息'**
  String get lastMessageRecalled;

  /// No description provided for @album.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get album;

  /// No description provided for @capture.
  ///
  /// In zh, this message translates to:
  /// **'拍摄'**
  String get capture;

  /// No description provided for @cameraTakePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get cameraTakePhoto;

  /// No description provided for @cameraTakeVideo.
  ///
  /// In zh, this message translates to:
  /// **'录像'**
  String get cameraTakeVideo;

  /// No description provided for @location.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get location;

  /// No description provided for @redPacket.
  ///
  /// In zh, this message translates to:
  /// **'红包'**
  String get redPacket;

  /// No description provided for @developingBadge.
  ///
  /// In zh, this message translates to:
  /// **'开发中'**
  String get developingBadge;

  /// No description provided for @redPacketDeveloping.
  ///
  /// In zh, this message translates to:
  /// **'红包功能正在开发中，敬请期待'**
  String get redPacketDeveloping;

  /// No description provided for @file.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get file;

  /// No description provided for @music.
  ///
  /// In zh, this message translates to:
  /// **'音乐'**
  String get music;

  /// No description provided for @musicCard.
  ///
  /// In zh, this message translates to:
  /// **'音乐'**
  String get musicCard;

  /// No description provided for @fileTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'文件大小超过 20MB 限制'**
  String get fileTooLarge;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'定位权限被拒绝，无法获取位置'**
  String get locationPermissionDenied;

  /// No description provided for @locationFallback.
  ///
  /// In zh, this message translates to:
  /// **'位置（{coords}）'**
  String locationFallback(Object coords);

  /// No description provided for @openLocationFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开地图应用'**
  String get openLocationFailed;

  /// No description provided for @openFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开文件'**
  String get openFileFailed;

  /// No description provided for @sendLocationTitle.
  ///
  /// In zh, this message translates to:
  /// **'发送位置'**
  String get sendLocationTitle;

  /// No description provided for @mentionAll.
  ///
  /// In zh, this message translates to:
  /// **'@所有人'**
  String get mentionAll;

  /// No description provided for @mentionMeHint.
  ///
  /// In zh, this message translates to:
  /// **'有人@我'**
  String get mentionMeHint;

  /// No description provided for @lastMessageLocation.
  ///
  /// In zh, this message translates to:
  /// **'[位置]'**
  String get lastMessageLocation;

  /// No description provided for @lastMessageMusic.
  ///
  /// In zh, this message translates to:
  /// **'[音乐]'**
  String get lastMessageMusic;

  /// No description provided for @lastMessageCall.
  ///
  /// In zh, this message translates to:
  /// **'[语音通话]'**
  String get lastMessageCall;

  /// No description provided for @voiceCall.
  ///
  /// In zh, this message translates to:
  /// **'语音通话'**
  String get voiceCall;

  /// No description provided for @incomingVoiceCall.
  ///
  /// In zh, this message translates to:
  /// **'邀请你进行语音通话'**
  String get incomingVoiceCall;

  /// No description provided for @callWaitingAnswer.
  ///
  /// In zh, this message translates to:
  /// **'等待对方接听…'**
  String get callWaitingAnswer;

  /// No description provided for @callIncomingHint.
  ///
  /// In zh, this message translates to:
  /// **'邀请你进行语音通话'**
  String get callIncomingHint;

  /// No description provided for @callMicOn.
  ///
  /// In zh, this message translates to:
  /// **'麦克风'**
  String get callMicOn;

  /// No description provided for @callMicOff.
  ///
  /// In zh, this message translates to:
  /// **'已静音'**
  String get callMicOff;

  /// No description provided for @callSpeaker.
  ///
  /// In zh, this message translates to:
  /// **'扬声器'**
  String get callSpeaker;

  /// No description provided for @hangUp.
  ///
  /// In zh, this message translates to:
  /// **'挂断'**
  String get hangUp;

  /// No description provided for @cancelCall.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancelCall;

  /// No description provided for @callEnded.
  ///
  /// In zh, this message translates to:
  /// **'通话结束'**
  String get callEnded;

  /// No description provided for @callRejected.
  ///
  /// In zh, this message translates to:
  /// **'通话已拒绝'**
  String get callRejected;

  /// No description provided for @callCanceled.
  ///
  /// In zh, this message translates to:
  /// **'通话已取消'**
  String get callCanceled;

  /// No description provided for @callNoAnswer.
  ///
  /// In zh, this message translates to:
  /// **'对方未接听'**
  String get callNoAnswer;

  /// No description provided for @callBusy.
  ///
  /// In zh, this message translates to:
  /// **'对方忙线中'**
  String get callBusy;

  /// No description provided for @callPeerOffline.
  ///
  /// In zh, this message translates to:
  /// **'对方不在线'**
  String get callPeerOffline;

  /// No description provided for @callAcceptedElsewhere.
  ///
  /// In zh, this message translates to:
  /// **'已在其他设备接听'**
  String get callAcceptedElsewhere;

  /// No description provided for @callMicPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'需要麦克风权限才能通话'**
  String get callMicPermissionDenied;

  /// No description provided for @callConnectFailed.
  ///
  /// In zh, this message translates to:
  /// **'通话连接失败'**
  String get callConnectFailed;

  /// No description provided for @callBack.
  ///
  /// In zh, this message translates to:
  /// **'回拨'**
  String get callBack;

  /// No description provided for @callRecordCompleted.
  ///
  /// In zh, this message translates to:
  /// **'通话时长 {duration}'**
  String callRecordCompleted(Object duration);

  /// No description provided for @callRecordMissed.
  ///
  /// In zh, this message translates to:
  /// **'未接通'**
  String get callRecordMissed;

  /// No description provided for @callRecordRejected.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get callRecordRejected;

  /// No description provided for @callRecordCanceled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get callRecordCanceled;

  /// No description provided for @globalSearchTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get globalSearchTitle;

  /// No description provided for @globalSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索联系人、聊天记录'**
  String get globalSearchHint;

  /// No description provided for @globalSearchSectionContacts.
  ///
  /// In zh, this message translates to:
  /// **'联系人'**
  String get globalSearchSectionContacts;

  /// No description provided for @globalSearchSectionMessages.
  ///
  /// In zh, this message translates to:
  /// **'聊天记录'**
  String get globalSearchSectionMessages;

  /// No description provided for @globalSearchNoResults.
  ///
  /// In zh, this message translates to:
  /// **'未找到相关结果'**
  String get globalSearchNoResults;

  /// No description provided for @addMenuTooltip.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get addMenuTooltip;

  /// No description provided for @musicDownloading.
  ///
  /// In zh, this message translates to:
  /// **'正在下载…'**
  String get musicDownloading;

  /// No description provided for @reply.
  ///
  /// In zh, this message translates to:
  /// **'回复'**
  String get reply;

  /// No description provided for @cancelReplyDraft.
  ///
  /// In zh, this message translates to:
  /// **'取消回复'**
  String get cancelReplyDraft;

  /// No description provided for @replyToNamed.
  ///
  /// In zh, this message translates to:
  /// **'回复 {name}'**
  String replyToNamed(Object name);

  /// No description provided for @quoteYou.
  ///
  /// In zh, this message translates to:
  /// **'你'**
  String get quoteYou;

  /// No description provided for @quoteImage.
  ///
  /// In zh, this message translates to:
  /// **'[图片]'**
  String get quoteImage;

  /// No description provided for @quoteVoice.
  ///
  /// In zh, this message translates to:
  /// **'[语音]'**
  String get quoteVoice;

  /// No description provided for @quoteVideo.
  ///
  /// In zh, this message translates to:
  /// **'[视频]'**
  String get quoteVideo;

  /// No description provided for @quoteFile.
  ///
  /// In zh, this message translates to:
  /// **'[文件]'**
  String get quoteFile;

  /// No description provided for @quoteMusic.
  ///
  /// In zh, this message translates to:
  /// **'[音乐]'**
  String get quoteMusic;

  /// No description provided for @quoteLocation.
  ///
  /// In zh, this message translates to:
  /// **'[位置]'**
  String get quoteLocation;

  /// No description provided for @quoteCall.
  ///
  /// In zh, this message translates to:
  /// **'[通话]'**
  String get quoteCall;

  /// No description provided for @quoteEncrypted.
  ///
  /// In zh, this message translates to:
  /// **'[加密消息]'**
  String get quoteEncrypted;

  /// No description provided for @messageNotFound.
  ///
  /// In zh, this message translates to:
  /// **'原消息不在当前聊天记录'**
  String get messageNotFound;

  /// No description provided for @callMinimize.
  ///
  /// In zh, this message translates to:
  /// **'最小化'**
  String get callMinimize;

  /// No description provided for @callSpeakerOn.
  ///
  /// In zh, this message translates to:
  /// **'扬声器'**
  String get callSpeakerOn;

  /// No description provided for @callSpeakerOff.
  ///
  /// In zh, this message translates to:
  /// **'听筒'**
  String get callSpeakerOff;

  /// No description provided for @callOngoingTapReturn.
  ///
  /// In zh, this message translates to:
  /// **'点击返回通话'**
  String get callOngoingTapReturn;

  /// No description provided for @videoCall.
  ///
  /// In zh, this message translates to:
  /// **'视频通话'**
  String get videoCall;

  /// No description provided for @incomingVideoCall.
  ///
  /// In zh, this message translates to:
  /// **'邀请你进行视频通话'**
  String get incomingVideoCall;

  /// No description provided for @cameraOn.
  ///
  /// In zh, this message translates to:
  /// **'摄像头'**
  String get cameraOn;

  /// No description provided for @cameraOff.
  ///
  /// In zh, this message translates to:
  /// **'摄像头已关'**
  String get cameraOff;

  /// No description provided for @switchCamera.
  ///
  /// In zh, this message translates to:
  /// **'翻转'**
  String get switchCamera;

  /// No description provided for @groupVoiceCall.
  ///
  /// In zh, this message translates to:
  /// **'群语音通话'**
  String get groupVoiceCall;

  /// No description provided for @incomingGroupCall.
  ///
  /// In zh, this message translates to:
  /// **'邀请你加入群语音通话'**
  String get incomingGroupCall;

  /// No description provided for @groupCallEnded.
  ///
  /// In zh, this message translates to:
  /// **'群通话已结束'**
  String get groupCallEnded;

  /// No description provided for @groupCallWaitingJoin.
  ///
  /// In zh, this message translates to:
  /// **'等待群成员加入…'**
  String get groupCallWaitingJoin;

  /// No description provided for @groupCallMemberUnit.
  ///
  /// In zh, this message translates to:
  /// **'人'**
  String get groupCallMemberUnit;

  /// No description provided for @joinCall.
  ///
  /// In zh, this message translates to:
  /// **'加入'**
  String get joinCall;

  /// No description provided for @meLabel.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get meLabel;

  /// No description provided for @groupCallBusy.
  ///
  /// In zh, this message translates to:
  /// **'忙线中，请稍后再试'**
  String get groupCallBusy;

  /// No description provided for @groupCallFull.
  ///
  /// In zh, this message translates to:
  /// **'群通话人数已满（最多 8 人）'**
  String get groupCallFull;

  /// No description provided for @groupCallNotMember.
  ///
  /// In zh, this message translates to:
  /// **'你不是该群成员'**
  String get groupCallNotMember;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'zh':
      return AppL10nZh();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
