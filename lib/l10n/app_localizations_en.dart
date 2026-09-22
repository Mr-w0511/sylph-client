// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sylph';

  @override
  String get appSlogan => 'Lightweight instant messaging';

  @override
  String get navChats => 'Chats';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navSettings => 'Me';

  @override
  String get loginTitle => 'Sign in to Sylph';

  @override
  String get registerTitle => 'Create account';

  @override
  String get tabPasswordLogin => 'Password';

  @override
  String get tabPhoneLogin => 'SMS code';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get nickname => 'Nickname';

  @override
  String get phone => 'Phone';

  @override
  String get verificationCode => 'Code';

  @override
  String get sendCode => 'Send code';

  @override
  String get phoneLoginUnavailable =>
      'SMS login is not available yet. Please sign in with username and password.';

  @override
  String get loginSubmit => 'SIGN IN';

  @override
  String get registerSubmit => 'SIGN UP';

  @override
  String get toRegister => 'No account? Sign up';

  @override
  String get toLogin => 'Already have an account? Sign in';

  @override
  String get registerSuccess => 'Registered successfully. Please sign in.';

  @override
  String get usernameHint => '3-64 letters, digits or underscores';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get sessionExpired => 'Session expired. Please sign in again.';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out of the current account?';

  @override
  String get loginFailed => 'Sign-in failed, check username or password';

  @override
  String get conversationsTitle => 'Chats';

  @override
  String get newChat => 'New chat';

  @override
  String get newSingleChat => 'New direct chat';

  @override
  String get newGroupChat => 'New group';

  @override
  String get searchUserHint => 'Search username / nickname';

  @override
  String get searchEmpty => 'No users found';

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'Name this group';

  @override
  String get selectMembers => 'Select members';

  @override
  String get createGroup => 'Create group';

  @override
  String get selectAtLeastTwo => 'Please select at least 2 members';

  @override
  String get conversationEmpty =>
      'No conversations yet. Tap the button above to start one.';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get refreshing => 'Refreshing…';

  @override
  String get refreshDone => 'Refreshed';

  @override
  String get lastMessageImage => '[Image]';

  @override
  String get lastMessageVoice => '[Voice]';

  @override
  String get lastMessageVideo => '[Video]';

  @override
  String get lastMessageFile => '[File]';

  @override
  String get lastMessageSystem => '[System]';

  @override
  String get lastMessageEncrypted => 'End-to-end encrypted message';

  @override
  String get lastMessageYou => 'You: ';

  @override
  String get settingsTitle => 'Me';

  @override
  String get profileSection => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get accountSettings => 'Account & security';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get devices => 'Signed-in devices';

  @override
  String get privateEntry => 'About private chats';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get emptyData => 'Nothing here';

  @override
  String get updateSuccess => 'Updated';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get gender => 'Gender';

  @override
  String get genderUnknown => 'Unset';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get usernameLabel => 'Username';

  @override
  String get devicesTitle => 'Signed-in devices';

  @override
  String get currentDevice => 'This device';

  @override
  String get revokeDevice => 'Sign out remotely';

  @override
  String get revokeDeviceConfirm =>
      'Sign this device out? It will need to sign in again.';

  @override
  String get revokedCurrent => 'This device has been signed out';

  @override
  String get lastLoginAt => 'Last sign-in';

  @override
  String get privateInfoTitle => 'Private chats (end-to-end encrypted)';

  @override
  String get privateInfoBody =>
      'Private chats are only available for direct conversations. Messages use P-256 ECDH key agreement, HKDF-SHA256 key derivation and AES-GCM encryption before leaving this device. The server only sees ciphertext.\n\nKeys are stored in this browser only; history cannot be decrypted on a new device.';

  @override
  String get chatInputHint => 'Type a message…';

  @override
  String get send => 'Send';

  @override
  String get sendImage => 'Send image';

  @override
  String get pickImage => 'Pick image';

  @override
  String get imagePicking => 'Processing image…';

  @override
  String get imageUploading => 'Uploading image…';

  @override
  String get messageSending => 'Sending…';

  @override
  String get messageSendFailed =>
      'Failed to send. It will be retried after reconnecting.';

  @override
  String get e2eeEncrypted => 'End-to-end encrypted message, unable to decrypt';

  @override
  String get e2eeBadge => 'End-to-end encrypted';

  @override
  String get privateSwitch => 'Private chat';

  @override
  String get privateEnableTip =>
      'Device keys will be generated and the public key bundle uploaded. Messages will be sent end-to-end encrypted.';

  @override
  String get privateDisableTip =>
      'End-to-end encryption is off. New messages will be sent as plaintext.';

  @override
  String get e2eePreparing => 'Preparing end-to-end encryption keys…';

  @override
  String get e2eePeerNoKeys =>
      'Your contact has not enabled end-to-end encryption yet.';

  @override
  String get resend => 'Resend';

  @override
  String get loadMore => 'Load earlier messages';

  @override
  String get noMoreMessages => 'No more messages';

  @override
  String get messagesLoading => 'Loading messages…';

  @override
  String get messagesLoadFailed => 'Failed to load messages';

  @override
  String get connectionConnecting => 'Connecting…';

  @override
  String get connectionReconnecting => 'Disconnected. Reconnecting…';

  @override
  String get connectionDisconnected => 'Disconnected';

  @override
  String get connectionConnected => 'Connected';

  @override
  String get statusPending => 'Sending';

  @override
  String get statusSent => 'Sent';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusRead => 'Read';

  @override
  String get statusBlocked => 'Blocked by moderation';

  @override
  String get statusFailed => 'Failed';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String memberCount(Object count) {
    return '$count members';
  }

  @override
  String get sendEmailCode => 'Send code';

  @override
  String get codeSent => 'Code sent to your email';

  @override
  String resendIn(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get loginByEmail => 'Sign in';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get codeHint => '6-digit code';

  @override
  String get emailLoginTip => 'New emails will be registered automatically';

  @override
  String get switchToUidLogin => 'Sign in with UID + password';

  @override
  String get switchToEmailLogin => 'Sign in with email code';

  @override
  String get uidFieldLabel => 'UID';

  @override
  String get uidHint => '8-digit UID';

  @override
  String get loginByEmailFailed => 'Sign-in failed, check the code';

  @override
  String get loginByUidFailed => 'Sign-in failed, check UID or password';

  @override
  String get setInitialPassword => 'Set initial password';

  @override
  String get changePassword => 'Change password';

  @override
  String get oldPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm new password';

  @override
  String get newPasswordHint => 'At least 8 chars, with letters and digits';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordSetSuccess => 'Initial password set';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get setInitialPasswordTip =>
      'After signing in by email, set a password to enable UID + password login.';

  @override
  String get navProfile => 'Me';

  @override
  String get accountSecurity => 'Account & security';

  @override
  String get appearance => 'Appearance';

  @override
  String get about => 'About';

  @override
  String get aboutSylph => 'About Sylph';

  @override
  String get aboutSylphBody =>
      'Sylph · lightweight, private instant messaging.';

  @override
  String get profileCard => 'Profile';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get myGroups => 'My groups';

  @override
  String get myContacts => 'My contacts';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get noContactsYet => 'No contacts yet';

  @override
  String errorWithReason(Object reason) {
    return 'Operation failed: $reason';
  }

  @override
  String sendFailedReason(Object reason) {
    return 'Failed to send: $reason';
  }

  @override
  String loadFailedReason(Object reason) {
    return 'Failed to load: $reason';
  }

  @override
  String saveFailedReason(Object reason) {
    return 'Failed to save: $reason';
  }

  @override
  String shareFailedReason(Object reason) {
    return 'Failed to share: $reason';
  }

  @override
  String encryptFailedReason(Object reason) {
    return 'Encryption failed: $reason';
  }

  @override
  String forwardFailedReason(Object reason) {
    return 'Failed to forward: $reason';
  }

  @override
  String recallFailedReason(Object reason) {
    return 'Failed to recall: $reason';
  }

  @override
  String playFailedReason(Object reason) {
    return 'Failed to play: $reason';
  }

  @override
  String recordStartFailedReason(Object reason) {
    return 'Failed to start recording: $reason';
  }

  @override
  String voiceSendFailedReason(Object reason) {
    return 'Failed to send voice: $reason';
  }

  @override
  String avatarUploadFailedReason(Object reason) {
    return 'Failed to upload avatar: $reason';
  }

  @override
  String loadFriendsFailedReason(Object reason) {
    return 'Failed to load friends: $reason';
  }

  @override
  String openCardFailedReason(Object reason) {
    return 'Failed to open card: $reason';
  }

  @override
  String setWallpaperFailedReason(Object reason) {
    return 'Failed to set wallpaper: $reason';
  }

  @override
  String get privateMode => 'Private mode';

  @override
  String get privateModeOn => 'Private mode enabled';

  @override
  String get privateModeOff => 'Private mode disabled';

  @override
  String e2eePrepareFailedReason(Object reason) {
    return 'Failed to prepare E2EE keys. Try again later.\nReason: $reason';
  }

  @override
  String get mutedOn => 'Notifications muted';

  @override
  String get mutedOff => 'Notifications unmuted';

  @override
  String get pinnedOn => 'Chat pinned';

  @override
  String get unpinned => 'Chat unpinned';

  @override
  String get pinToTop => 'Pin to top';

  @override
  String get unpinLabel => 'Unpin';

  @override
  String get pinChat => 'Pin to top';

  @override
  String get muteConv => 'Mute notifications';

  @override
  String get unmuteConv => 'Unmute notifications';

  @override
  String get viewProfile => 'View profile';

  @override
  String get setRemarkTitle => 'Set remark';

  @override
  String get setRemarkHint => 'Set a remark for this person';

  @override
  String get remarkSaved => 'Remark saved';

  @override
  String get report => 'Report';

  @override
  String get reportGroup => 'Report group';

  @override
  String get blockUserTitle => 'Block user';

  @override
  String get blockUserConfirm =>
      'You will no longer receive messages from them. Block?';

  @override
  String get blockAction => 'Block';

  @override
  String get blocked => 'Blocked';

  @override
  String get terminateChatTitle => 'End chat';

  @override
  String get terminateChatConfirm =>
      'The chat will be hidden for both sides and no more messages can be sent. End it?';

  @override
  String get terminateAction => 'End';

  @override
  String get chatTerminated => 'Chat ended';

  @override
  String get leaveGroupTitle => 'Leave group';

  @override
  String get leaveGroupConfirm =>
      'You will stop receiving messages from this group. Leave?';

  @override
  String get leaveAction => 'Leave';

  @override
  String get leftGroup => 'Left the group';

  @override
  String get dissolveGroup => 'Disband group';

  @override
  String get dissolveConfirm =>
      'The group will become unavailable. Disband it?';

  @override
  String get dissolveAction => 'Disband';

  @override
  String get deleteConvTitle => 'Delete chat';

  @override
  String get dissolvedConvDeleteConfirm =>
      'This group has been dissolved. Delete the chat to remove it from the list?';

  @override
  String get convDeleted => 'Chat deleted';

  @override
  String get groupDissolved => 'This group has been dissolved';

  @override
  String get groupDissolvedHint =>
      'The group is no longer available. Delete the chat to remove it.';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get forward => 'Forward';

  @override
  String get forwardTo => 'Forward to';

  @override
  String get forwarded => 'Forwarded';

  @override
  String forwardedCount(Object count) {
    return 'Forwarded $count messages';
  }

  @override
  String forwardedPartialFail(Object count, Object reason) {
    return 'Forwarded $count messages, then failed: $reason';
  }

  @override
  String get convCreating => 'Creating chat. Try again in that chat later.';

  @override
  String get e2eePeerNoKeysForward =>
      'The peer hasn\'t enabled end-to-end encryption. Can\'t forward to a private chat.';

  @override
  String get convLoadFailed => 'Failed to load conversation';

  @override
  String get groupSettings => 'Group settings';

  @override
  String get micPermissionDenied => 'Microphone permission is required';

  @override
  String get voiceTooShort => 'Recording too short';

  @override
  String get photo => 'Photo';

  @override
  String get card => 'Contact card';

  @override
  String get voice => 'Voice';

  @override
  String get more => 'More';

  @override
  String get keyboard => 'Keyboard';

  @override
  String get releaseToCancel => 'Release to cancel';

  @override
  String slideUpCancel(Object seconds) {
    return 'Slide up to cancel · ${seconds}s';
  }

  @override
  String get holdToTalk => 'Hold to talk';

  @override
  String get cardSent => 'Card sent';

  @override
  String get pickCardTitle => 'Choose a card';

  @override
  String get userCard => 'Contact card';

  @override
  String get groupCard => 'Group card';

  @override
  String userCardWithUid(Object uid) {
    return 'Contact card · UID $uid';
  }

  @override
  String groupCardWithNumber(Object number) {
    return 'Group card · Group no. $number';
  }

  @override
  String get noFriends => 'No friends yet';

  @override
  String get noGroupsToShare => 'No groups to share';

  @override
  String groupNumberLabel(Object number) {
    return 'Group no. $number';
  }

  @override
  String get pickMentionTitle => 'Mention members';

  @override
  String confirmWithCount(Object count) {
    return 'OK ($count)';
  }

  @override
  String get searchMembers => 'Search members';

  @override
  String get owner => 'Owner';

  @override
  String get admin => 'Admin';

  @override
  String get memberRole => 'Member';

  @override
  String get youAreMuted => 'You have been muted';

  @override
  String mutedRemainingDh(Object days, Object hours) {
    return 'You are muted, ${days}d ${hours}h remaining';
  }

  @override
  String mutedRemainingHm(Object hours, Object mins) {
    return 'You are muted, ${hours}h ${mins}m remaining';
  }

  @override
  String mutedRemainingMs(Object mins, Object secs) {
    return 'You are muted, ${mins}m ${secs}s remaining';
  }

  @override
  String mutedRemainingS(Object secs) {
    return 'You are muted, ${secs}s remaining';
  }

  @override
  String durationDays(Object days) {
    return '${days}d';
  }

  @override
  String durationDaysHours(Object days, Object hours) {
    return '${days}d ${hours}h';
  }

  @override
  String durationHours(Object hours) {
    return '${hours}h';
  }

  @override
  String durationHoursMinutes(Object hours, Object mins) {
    return '${hours}h ${mins}m';
  }

  @override
  String durationMinutes(Object mins) {
    return '${mins}m';
  }

  @override
  String durationSeconds(Object secs) {
    return '${secs}s';
  }

  @override
  String get newMember => 'New member';

  @override
  String get joinedGroupNotice => ' joined the group';

  @override
  String get mutedBy => ' muted by ';

  @override
  String mutedForDuration(Object duration) {
    return ' for $duration';
  }

  @override
  String get unmutedBy => ' unmuted by ';

  @override
  String get unmutedSuffix => '';

  @override
  String get theMember => 'this member';

  @override
  String get unknownUser => 'User';

  @override
  String get unknownGroup => 'Group';

  @override
  String userFallbackId(Object id) {
    return 'User $id';
  }

  @override
  String groupFallbackId(Object id) {
    return 'Group $id';
  }

  @override
  String get singleChatFallback => 'Chat';

  @override
  String get chatFallback => 'Chat';

  @override
  String get friendsSection => 'Friends';

  @override
  String get saveImage => 'Save image';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get multiSelect => 'Select';

  @override
  String get recall => 'Recall';

  @override
  String get recallWindowExpired => 'Recall window has expired';

  @override
  String get youRecalled => 'You recalled a message';

  @override
  String get peerRecalled => 'This message was recalled';

  @override
  String recalledByName(Object name) {
    return '$name recalled a message';
  }

  @override
  String get adminFallback => 'Admin';

  @override
  String get searchAddFriend => 'Search and add friends';

  @override
  String get convListEmptyTitle => 'No chats yet';

  @override
  String get convListEmptyHint =>
      'Tap the + button at the top right to search and add friends';

  @override
  String get refresh => 'Refresh';

  @override
  String get groupAvatarUpdated => 'Group avatar updated';

  @override
  String get editGroupProfile => 'Edit group profile';

  @override
  String get groupAnnouncement => 'Group announcement';

  @override
  String get groupProfileUpdated => 'Group profile updated';

  @override
  String get myNicknameInGroup => 'My nickname in group';

  @override
  String get nicknameLeaveEmptyHint =>
      'Leave empty to use your default nickname';

  @override
  String get groupNicknameUpdated => 'Group nickname updated';

  @override
  String get groupQrcode => 'Group QR code';

  @override
  String get groupQrcodeSubtitle => 'Share the QR code to invite friends';

  @override
  String get noFriendsToShare => 'No friends to share with';

  @override
  String get shareGroupToFriend => 'Share group with friends';

  @override
  String sharedTo(Object name) {
    return 'Shared with $name';
  }

  @override
  String get setMemberNicknameTitle => 'Set group nickname';

  @override
  String get editMyGroupNickname => 'Edit my group nickname';

  @override
  String get removeAdmin => 'Remove admin';

  @override
  String get adminRemoved => 'Admin removed';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get adminSet => 'Admin set';

  @override
  String get unmuteMember => 'Unmute';

  @override
  String get muteMember => 'Mute';

  @override
  String get removeMember => 'Remove from group';

  @override
  String removeMemberConfirm(Object name) {
    return 'Remove $name from the group?';
  }

  @override
  String get removeAction => 'Remove';

  @override
  String get memberRemoved => 'Removed from group';

  @override
  String get mutedChip => 'Muted';

  @override
  String get mutedBadge => 'Muted';

  @override
  String setNicknameFor(Object name) {
    return 'Set group nickname for $name';
  }

  @override
  String get unmutedOk => 'Unmuted';

  @override
  String get mute1h => 'Mute for 1 hour';

  @override
  String get mute24h => 'Mute for 24 hours';

  @override
  String get mute7d => 'Mute for 7 days';

  @override
  String get mute30d => 'Mute for 30 days';

  @override
  String get muteCustom => 'Custom time…';

  @override
  String get muteCustomTitle => 'Select mute until';

  @override
  String get unmuteNow => 'Unmute now';

  @override
  String get groupManageTitle => 'Group management';

  @override
  String get allGroupMembers => 'All members';

  @override
  String get searchGroupMembers => 'Search members';

  @override
  String viewAllMembers(Object count) {
    return 'View all members ($count)';
  }

  @override
  String get mutePermanent => 'Mute long-term';

  @override
  String get mutedOk => 'Muted';

  @override
  String get joinRequestsTitle => 'Join requests';

  @override
  String get approvalRequiredPolicy => 'Approval required';

  @override
  String get openGroup => 'Public group';

  @override
  String get groupNumberTitle => 'Group number';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get groupNumberCopied => 'Group number copied';

  @override
  String get useDefaultNickname => 'Using default nickname';

  @override
  String get inviteFriendsTitle => 'Invite friends';

  @override
  String get inviteFriendsSubtitle =>
      'Send invites to friends. They join after confirming.';

  @override
  String get shareGroup => 'Share group';

  @override
  String get shareGroupSubtitle =>
      'Send the group card to friends so they can join';

  @override
  String get myJoinRequestsTitle => 'My join requests';

  @override
  String get myJoinRequestsSubtitle =>
      'View status and results of your requests';

  @override
  String get approvalToggle => 'Approval to join';

  @override
  String get approvalOnSubtitle => 'New members need admin approval';

  @override
  String get approvalOffSubtitle => 'People can join directly via QR code';

  @override
  String groupMembersCount(Object count) {
    return 'Members ($count)';
  }

  @override
  String get noJoinRequests => 'No join requests';

  @override
  String get joinRequestDefaultMsg => 'Wants to join the group';

  @override
  String get decline => 'Decline';

  @override
  String get approve => 'Accept';

  @override
  String get requestAccepted => 'Accepted';

  @override
  String get requestDeclined => 'Declined';

  @override
  String get requestCanceled => 'Canceled';

  @override
  String get statusPendingReview => 'Pending';

  @override
  String get noMyRequests => 'No requests yet';

  @override
  String get userRejected => 'User';

  @override
  String get applyJoinGroup => 'Request to join';

  @override
  String get applyJoinHint => 'Optional message';

  @override
  String get submitApplication => 'Submit';

  @override
  String get joinRequestSubmitted => 'Request submitted, waiting for approval';

  @override
  String get noPendingInvite => 'No pending invite found';

  @override
  String get joinedGroupToast => 'Joined the group';

  @override
  String get inviteIgnored => 'Invite declined';

  @override
  String get groupCardPageTitle => 'Group profile';

  @override
  String get enterGroup => 'Enter chat';

  @override
  String get appliedPending => 'Request submitted, waiting for approval';

  @override
  String get ignore => 'Ignore';

  @override
  String get acceptInvite => 'Accept invite';

  @override
  String get joinGroup => 'Join group';

  @override
  String get contactsPageTitle => 'Contacts';

  @override
  String get addFriendTooltip => 'Add friends';

  @override
  String get newFriends => 'New friends';

  @override
  String get groupInvitesEntry => 'Group invites';

  @override
  String get scanEntry => 'Scan';

  @override
  String friendsCountHeader(Object count) {
    return 'Friends · $count';
  }

  @override
  String groupsCountHeader(Object count) {
    return 'Groups · $count';
  }

  @override
  String get noFriendsHint => 'No friends yet. Add from the top right.';

  @override
  String get noGroupsHint => 'You haven\'t joined any groups yet';

  @override
  String get sendMessage => 'Message';

  @override
  String get socialFeedbackSection => 'Social & feedback';

  @override
  String get myQrcode => 'My QR code';

  @override
  String get myQrcodeSubtitle =>
      'Show your card so friends can add you by scanning';

  @override
  String get feedbackEntry => 'Feedback';

  @override
  String get feedbackSubtitle =>
      'Report bugs or ideas and see official replies';

  @override
  String get blacklistEntry => 'Blocked contacts';

  @override
  String get blacklistSubtitle => 'Manage blocked users';

  @override
  String get personalizationSection => 'Personalization';

  @override
  String get themeColor => 'Theme color';

  @override
  String get chatWallpaper => 'Chat wallpaper';

  @override
  String get defaultWallpaper => 'Default wallpaper';

  @override
  String get customWallpaper => 'Custom wallpaper';

  @override
  String get pickThemeColor => 'Pick a theme color';

  @override
  String get noNickname => 'No nickname set';

  @override
  String get aboutBody =>
      'Sylph is a lightweight, private and smooth instant messaging app. It supports direct and group chats, end-to-end encryption, voice and photo messages, and lets you add friends or build groups quickly via QR codes. We hope every conversation feels simple and secure.';

  @override
  String get feedbackEmailSubject => 'Sylph Feedback';

  @override
  String get cannotOpenMail => 'Can\'t open the mail app';

  @override
  String get developer => 'Developer';

  @override
  String get developerName => 'Wanxia · Independent developer';

  @override
  String get contactEmailLabel => 'Contact email';

  @override
  String get checkUpdate => 'Check for updates';

  @override
  String get alreadyLatest => 'You\'re on the latest version';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get saved => 'Saved';

  @override
  String get usernameTaken => 'Username already taken';

  @override
  String get accountSection => 'Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get usernameEditableHint => 'Username (editable)';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Tell us about yourself';

  @override
  String get unknownGender => 'Unknown';

  @override
  String get avatarSavedHint =>
      'Avatar updated. Tap Save at the top right to apply.';

  @override
  String get wallpaperUnsupported => 'Not supported on desktop/web yet';

  @override
  String get wallpaperSaveFailed => 'Failed to save wallpaper. Try again.';

  @override
  String get wallpaperSet => 'Wallpaper set';

  @override
  String get wallpaperReset => 'Wallpaper reset to default';

  @override
  String get wallpaperPreview1 => 'Hi, this is a wallpaper preview';

  @override
  String get wallpaperPreview2 => 'Drag the slider below to adjust brightness';

  @override
  String get pickFromGallery => 'Choose from gallery';

  @override
  String get wallpaperUnsupportedShort => 'Not supported on desktop/web';

  @override
  String get pickLocalImage => 'Pick a local image as the chat background';

  @override
  String get resetDefault => 'Reset to default';

  @override
  String get overlayOpacity => 'Overlay opacity';

  @override
  String get detailTitle => 'Profile';

  @override
  String get sendFriendRequest => 'Send friend request';

  @override
  String greetingWithName(Object name) {
    return 'Hi, I\'m $name';
  }

  @override
  String get requestHint => 'Optional verification message';

  @override
  String get sendRequestAction => 'Send request';

  @override
  String get requestSent => 'Friend request sent';

  @override
  String get noPendingRequest => 'No pending request found';

  @override
  String get friendAdded => 'Friend added';

  @override
  String get deleteFriendTitle => 'Delete friend';

  @override
  String deleteFriendConfirm(Object name) {
    return 'Remove $name from your contacts?';
  }

  @override
  String get friendDeleted => 'Friend deleted';

  @override
  String get uidCopied => 'UID copied';

  @override
  String blockConfirmName(Object name) {
    return 'Block $name? You will no longer receive messages from them.';
  }

  @override
  String get noPendingVerify => 'No pending friend request found';

  @override
  String get requestRevoked => 'Request withdrawn';

  @override
  String get withdrawRequest => 'Withdraw request';

  @override
  String remarkWithColon(Object remark) {
    return 'Remark: $remark';
  }

  @override
  String get noRemark => 'No remark set';

  @override
  String get bioEmptyHint => 'This user hasn\'t written anything yet';

  @override
  String get messageSelf => 'Message yourself';

  @override
  String get requestPendingLabel => 'Request sent, waiting for approval';

  @override
  String get requestIgnored => 'Request ignored';

  @override
  String get acceptFriendRequest => 'Accept request';

  @override
  String get addToContacts => 'Add to contacts';

  @override
  String get meMarker => ' (me)';

  @override
  String inviteWithCount(Object count) {
    return 'Invite ($count)';
  }

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get searchFriendsHint => 'Search friends';

  @override
  String get noInvitableFriends => 'No friends to invite';

  @override
  String inviteSentCount(Object count) {
    return 'Group invite sent to $count friends';
  }

  @override
  String get searchUserFullHint => 'Search UID / username / nickname';

  @override
  String get startGroupChat => 'New group chat';

  @override
  String get waitVerify => 'Pending';

  @override
  String get pendingAccept => 'Awaiting';

  @override
  String get searchEmptyNoKeyword => 'Find friends by UID / nickname';

  @override
  String get searchEmptyKeywordHint =>
      'Try another keyword, or scan their QR code';

  @override
  String get searchEmptyNoKeywordHint =>
      'You can also tap \"Scan\" above to scan a friend\'s QR code';

  @override
  String acceptedRequestFrom(Object name) {
    return 'Accepted $name\'s friend request';
  }

  @override
  String get withdrawRequestConfirm => 'Withdraw this friend request?';

  @override
  String get rethink => 'Keep it';

  @override
  String get receivedRequests => 'Received';

  @override
  String get sentRequests => 'Sent';

  @override
  String get noIncomingRequests => 'No friend requests yet';

  @override
  String pendingCount(Object count) {
    return 'Pending ($count)';
  }

  @override
  String get historySection => 'History';

  @override
  String get accept => 'Accept';

  @override
  String get added => 'Added';

  @override
  String get unknownPerson => 'Unknown user';

  @override
  String get noOutgoingRequests => 'No sent requests yet';

  @override
  String get groupNameRequired => 'Please enter a group name';

  @override
  String get selectAtLeastOne => 'Please select at least 1 friend';

  @override
  String get createAction => 'Create';

  @override
  String selectFriendsCount(Object count) {
    return 'Select friends ($count)';
  }

  @override
  String get selectMembersHint => 'Select group members';

  @override
  String get myGroupNickHint => 'My nickname in this group (optional)';

  @override
  String get joinViaQrcode => 'Anyone can join directly via the group QR code';

  @override
  String joinedGroupWithName(Object name) {
    return 'Joined \"$name\"';
  }

  @override
  String get noGroupInvites => 'No group invites yet';

  @override
  String invitedByToJoin(Object name) {
    return '$name invited you to join the group';
  }

  @override
  String get receivedGroupInvite => 'You received a group invite';

  @override
  String get joinAction => 'Join';

  @override
  String get joinedStatus => 'Joined';

  @override
  String get qrUnrecognized => 'Unrecognized QR code content';

  @override
  String get userNotFound => 'User not found';

  @override
  String qrInvalidReason(Object reason) {
    return 'QR code expired or unreadable: $reason';
  }

  @override
  String get torchUnsupported => 'Flashlight is not supported on this device';

  @override
  String get imageScanUnsupported =>
      'Scanning QR from images is not supported on this platform. Please use a phone.';

  @override
  String get imageReadFailed => 'Failed to read the image. Please pick again.';

  @override
  String get qrNotFound => 'No QR code detected';

  @override
  String imageScanFailedReason(Object reason) {
    return 'Failed to scan the image: $reason';
  }

  @override
  String get torchOnTooltip => 'Flashlight';

  @override
  String get torchOffTooltip => 'Turn off flashlight';

  @override
  String get galleryTooltip => 'Gallery';

  @override
  String get cameraUnavailableManual =>
      'Camera unavailable on this device. Enter UID/group number below.';

  @override
  String get scanHint =>
      'Align the QR code inside the frame to scan automatically';

  @override
  String get manualInputHint => 'Camera unavailable? Enter UID / group number';

  @override
  String get cameraStartFailed =>
      'Camera failed to start. Retry or enter manually.';

  @override
  String reasonDetail(Object detail) {
    return 'Reason: $detail';
  }

  @override
  String get openSystemSettings => 'Open system settings';

  @override
  String get cameraPermissionDenied =>
      'Camera permission denied. Scanning requires the camera.';

  @override
  String get reauthorize => 'Grant permission';

  @override
  String get resetQrcode => 'Reset QR code';

  @override
  String get resetQrcodeConfirm =>
      'The old QR code will stop working immediately. Continue?';

  @override
  String get resetAction => 'Reset';

  @override
  String resetFailedReason(Object reason) {
    return 'Reset failed: $reason';
  }

  @override
  String get imageGenFailed => 'Failed to generate image';

  @override
  String get savedToGallery => 'Saved to gallery';

  @override
  String imageSavedWithPath(Object path) {
    return 'Image saved: $path';
  }

  @override
  String qrcodeShareSubject(Object name) {
    return '$name\'s QR code - Sylph';
  }

  @override
  String get qrcodeScanTip => 'Scan the QR code to add friends or join groups';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get copyLink => 'Copy link';

  @override
  String get shareImage => 'Share image';

  @override
  String get shareLink => 'Share link';

  @override
  String get inAppShare => 'Share in app';

  @override
  String get sylphUser => 'Sylph user';

  @override
  String get shareCardTo => 'Share card to';

  @override
  String get cardShared => 'Card shared';

  @override
  String get fbTypeBug => 'Bug report';

  @override
  String get fbTypeSuggestion => 'Feature request';

  @override
  String get fbTypeComplaint => 'Complaint';

  @override
  String get fbOther => 'Other';

  @override
  String get fbSuggestion => 'Suggestion';

  @override
  String get fbComplaint => 'Complaint';

  @override
  String get fbStatusPending => 'Pending';

  @override
  String get fbStatusProcessing => 'Processing';

  @override
  String get fbStatusReplied => 'Replied';

  @override
  String get fbStatusClosed => 'Closed';

  @override
  String get feedbackSubmitted => 'Feedback submitted. Track progress below.';

  @override
  String submitFailedReason(Object reason) {
    return 'Submit failed: $reason';
  }

  @override
  String get feedbackType => 'Feedback type';

  @override
  String get feedbackDescHint => 'Describe the issue or suggestion…';

  @override
  String get contactHint => 'Contact (email, optional, so we can reply)';

  @override
  String get submitFeedback => 'Submit feedback';

  @override
  String get myFeedback => 'My feedback';

  @override
  String get noFeedbackYet => 'No feedback submitted yet';

  @override
  String get feedbackDetailTitle => 'Feedback details';

  @override
  String get ticketClosedHint =>
      'This ticket is closed. Sending again will reopen it.';

  @override
  String get followUpHint => 'Add more details…';

  @override
  String get officialReply => 'Official reply';

  @override
  String get syncedByEmail => ' (also sent by email)';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportAbuse => 'Abuse';

  @override
  String get reportPorn => 'Adult content';

  @override
  String get reportFraud => 'Fraud';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String reportFailedReason(Object reason) {
    return 'Report failed: $reason';
  }

  @override
  String get reportDetailHint => 'More details (optional)';

  @override
  String get submitReport => 'Submit report';

  @override
  String get unblockedOk => 'Unblocked';

  @override
  String get blacklistEmpty => 'Blacklist is empty';

  @override
  String get unblockAction => 'Unblock';

  @override
  String get scanQrcodeInImage => 'Scan QR code';

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get videoPlayUnsupported => 'Video playback is not supported';

  @override
  String get techP256 =>
      'Public key agreement (ephemeral key + signed pre-key fallback)';

  @override
  String get techHkdf => 'Session key derivation';

  @override
  String get techAesGcm =>
      'Authenticated encryption for message bodies; a 12-byte random nonce is sent with each message';

  @override
  String get techBase64 =>
      'Ciphertext travels as message content with encrypted=true';

  @override
  String get qrImageOnly => 'Only images support QR code recognition';

  @override
  String imageDownloadFailed(Object reason) {
    return 'Failed to download image: $reason';
  }

  @override
  String get imageDataEmpty => 'Image data is empty';

  @override
  String tempFileWriteFailed(Object reason) {
    return 'Failed to write temp file: $reason';
  }

  @override
  String get qrContentEmpty => 'QR code content is empty';

  @override
  String get videoTapToPlay => 'Tap to play video';

  @override
  String get addToStickers => 'Add to stickers';

  @override
  String get addStickerFailed => 'Failed to add sticker';

  @override
  String get stickerAdded => 'Added to stickers';

  @override
  String get deleteStickerConfirm => 'Delete this sticker?';

  @override
  String get emoji => 'Emoji';

  @override
  String get emojiSection => 'Emoji';

  @override
  String get stickerSection => 'Stickers';

  @override
  String get savedEmojiSection => 'Saved emoji';

  @override
  String get emojiOnlyCannotSave => 'Only emoji text can be saved';

  @override
  String get draftLabel => 'Draft';

  @override
  String get lastMessageRecalled => 'Message recalled';

  @override
  String get album => 'Album';

  @override
  String get capture => 'Camera';

  @override
  String get cameraTakePhoto => 'Take photo';

  @override
  String get cameraTakeVideo => 'Record video';

  @override
  String get location => 'Location';

  @override
  String get redPacket => 'Red packet';

  @override
  String get developingBadge => 'Soon';

  @override
  String get redPacketDeveloping =>
      'Red packet is under development, stay tuned';

  @override
  String get file => 'File';

  @override
  String get music => 'Music';

  @override
  String get musicCard => 'Music';

  @override
  String get fileTooLarge => 'File exceeds the 20MB limit';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String locationFallback(Object coords) {
    return 'Location ($coords)';
  }

  @override
  String get openLocationFailed => 'Cannot open the map app';

  @override
  String get openFileFailed => 'Cannot open the file';

  @override
  String get sendLocationTitle => 'Send location';

  @override
  String get mentionAll => '@everyone';

  @override
  String get mentionMeHint => 'Mentioned me';

  @override
  String get lastMessageLocation => '[Location]';

  @override
  String get lastMessageMusic => '[Music]';

  @override
  String get lastMessageCall => '[Voice call]';

  @override
  String get voiceCall => 'Voice call';

  @override
  String get incomingVoiceCall => 'invites you to a voice call';

  @override
  String get callWaitingAnswer => 'Waiting for answer…';

  @override
  String get callIncomingHint => 'Incoming voice call';

  @override
  String get callMicOn => 'Mute';

  @override
  String get callMicOff => 'Muted';

  @override
  String get callSpeaker => 'Speaker';

  @override
  String get hangUp => 'Hang up';

  @override
  String get cancelCall => 'Cancel';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callRejected => 'Call declined';

  @override
  String get callCanceled => 'Call canceled';

  @override
  String get callNoAnswer => 'No answer';

  @override
  String get callBusy => 'Peer is busy';

  @override
  String get callPeerOffline => 'Peer is offline';

  @override
  String get callAcceptedElsewhere => 'Answered on another device';

  @override
  String get callMicPermissionDenied => 'Microphone permission is required';

  @override
  String get callConnectFailed => 'Connection failed';

  @override
  String get callBack => 'Call back';

  @override
  String callRecordCompleted(Object duration) {
    return 'Duration $duration';
  }

  @override
  String get callRecordMissed => 'Missed';

  @override
  String get callRecordRejected => 'Declined';

  @override
  String get callRecordCanceled => 'Canceled';

  @override
  String get globalSearchTitle => 'Search';

  @override
  String get globalSearchHint => 'Search contacts and messages';

  @override
  String get globalSearchSectionContacts => 'Contacts';

  @override
  String get globalSearchSectionMessages => 'Messages';

  @override
  String get globalSearchNoResults => 'No results found';

  @override
  String get addMenuTooltip => 'More';

  @override
  String get musicDownloading => 'Downloading…';

  @override
  String get reply => 'Reply';

  @override
  String get cancelReplyDraft => 'Cancel reply';

  @override
  String replyToNamed(Object name) {
    return 'Replying to $name';
  }

  @override
  String get quoteYou => 'You';

  @override
  String get quoteImage => '[Image]';

  @override
  String get quoteVoice => '[Voice]';

  @override
  String get quoteVideo => '[Video]';

  @override
  String get quoteFile => '[File]';

  @override
  String get quoteMusic => '[Music]';

  @override
  String get quoteLocation => '[Location]';

  @override
  String get quoteCall => '[Call]';

  @override
  String get quoteEncrypted => '[Encrypted message]';

  @override
  String get messageNotFound =>
      'Original message is not in the current chat history';

  @override
  String get callMinimize => 'Minimize';

  @override
  String get callSpeakerOn => 'Speaker';

  @override
  String get callSpeakerOff => 'Earpiece';

  @override
  String get callOngoingTapReturn => 'Tap to return to call';

  @override
  String get videoCall => 'Video call';

  @override
  String get incomingVideoCall => 'Invites you to a video call';

  @override
  String get cameraOn => 'Camera';

  @override
  String get cameraOff => 'Camera off';

  @override
  String get switchCamera => 'Flip';

  @override
  String get groupVoiceCall => 'Group voice call';

  @override
  String get incomingGroupCall => 'Invites you to a group voice call';

  @override
  String get groupCallEnded => 'Group call ended';

  @override
  String get groupCallWaitingJoin => 'Waiting for members to join…';

  @override
  String get groupCallMemberUnit => 'members';

  @override
  String get joinCall => 'Join';

  @override
  String get meLabel => 'Me';

  @override
  String get groupCallBusy => 'Line busy, please try again later';

  @override
  String get groupCallFull => 'Group call is full (up to 8 members)';

  @override
  String get groupCallNotMember => 'You are not a member of this group';
}
