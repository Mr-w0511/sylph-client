import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../features/auth/login_page.dart';
import '../features/call/audio_call_page.dart';
import '../features/call/call_page.dart';
import '../features/call/group_call_page.dart';
import '../features/chat/chat_page.dart';
import '../features/contacts/add_friend_page.dart';
import '../features/contacts/contacts_page.dart';
import '../features/contacts/friend_requests_page.dart';
import '../features/contacts/user_profile_page.dart';
import '../features/conversations/conversations_page.dart';
import '../features/conversations/new_group_page.dart';
import '../features/feedback/feedback_page.dart';
import '../features/feedback/feedback_thread_page.dart';
import '../features/group/group_invites_page.dart';
import '../features/group/group_members_page.dart';
import '../features/group/group_profile_page.dart';
import '../features/group/group_settings_page.dart';
import '../features/qrcode/my_qrcode_page.dart';
import '../features/qrcode/scan_page.dart';
import '../features/search/global_search_page.dart';
import '../features/settings/about_page.dart';
import '../features/settings/blacklist_page.dart';
import '../features/settings/devices_page.dart';
import '../features/settings/home_shell.dart';
import '../features/settings/private_info_page.dart';
import '../features/settings/profile_edit_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/wallpaper_page.dart';
import '../features/splash/splash_page.dart';
import '../state/providers.dart';
import '../widgets/state_views.dart';

/// 全局根 Navigator key：通话状态机在任意页面（含后台拉起）推入 /call。
final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionControllerProvider).status;
      final loc = state.matchedLocation;
      switch (status) {
        case AuthStatus.bootstrap:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return loc == '/login' ? null : '/login';
        case AuthStatus.authenticated:
          if (loc == '/splash' || loc == '/login') return '/conversations';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            HomeShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conversations',
                builder: (_, _) => const ConversationsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (_, _) => const ContactsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/add-friend', builder: (_, _) => const AddFriendPage()),
      GoRoute(path: '/new-group', builder: (_, _) => const NewGroupPage()),
      GoRoute(path: '/scan', builder: (_, _) => const ScanPage()),
      GoRoute(path: '/my-qrcode', builder: (_, _) => const MyQrcodePage()),
      GoRoute(path: '/search', builder: (_, _) => const GlobalSearchPage()),
      GoRoute(path: '/call', builder: (_, _) => const CallPage()),
      GoRoute(
          path: '/audio-call', builder: (_, _) => const AudioCallPage()),
      GoRoute(path: '/group-call', builder: (_, _) => const GroupCallPage()),
      GoRoute(
        path: '/friend-requests',
        builder: (_, _) => const FriendRequestsPage(),
      ),
      GoRoute(
        path: '/group-invites',
        builder: (_, _) => const GroupInvitesPage(),
      ),
      GoRoute(path: '/feedback', builder: (_, _) => const FeedbackPage()),
      GoRoute(
        path: '/feedback/thread',
        builder: (_, state) =>
            FeedbackThreadPage(feedback: state.extra as FeedbackModel),
      ),
      GoRoute(
        path: '/user-profile',
        builder: (_, state) {
          final args = state.extra as UserProfileArgs;
          return UserProfilePage(
              user: args.user, groupConvId: args.groupConvId);
        },
      ),
      GoRoute(
        path: '/group-profile',
        builder: (_, state) =>
            GroupProfilePage(group: state.extra as GroupBrief),
      ),
      GoRoute(
        path: '/group/:id/settings',
        builder: (_, state) =>
            GroupSettingsPage(convId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/group/:id/members',
        builder: (_, state) =>
            GroupMembersPage(convId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatPage(
          convId: int.parse(state.pathParameters['id']!),
          initialMsgId: state.uri.queryParameters['msgId'],
        ),
      ),
      GoRoute(
        path: '/chat-by-user/:userId',
        builder: (_, state) =>
            ChatByUserPage(userId: int.parse(state.pathParameters['userId']!)),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const ProfileEditPage(),
      ),
      GoRoute(path: '/devices', builder: (_, _) => const DevicesPage()),
      GoRoute(
        path: '/blacklist',
        builder: (_, _) => const BlacklistPage(),
      ),
      GoRoute(
        path: '/private-info',
        builder: (_, _) => const PrivateInfoPage(),
      ),
      GoRoute(path: '/about', builder: (_, _) => const AboutPage()),
      GoRoute(path: '/wallpaper', builder: (_, _) => const WallpaperPage()),
    ],
  );
});

/// 通讯录点击「发消息」：确保单聊会话存在后进入聊天页。
class ChatByUserPage extends ConsumerStatefulWidget {
  final int userId;
  const ChatByUserPage({super.key, required this.userId});

  @override
  ConsumerState<ChatByUserPage> createState() => _ChatByUserPageState();
}

class _ChatByUserPageState extends ConsumerState<ChatByUserPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final conv = await ref
          .read(conversationRepoProvider)
          .createSingle(widget.userId);
      await ref.read(realtimeProvider).refreshConversations();
      if (!mounted) return;
      context.pushReplacement('/chat/${conv.id}');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _error == null
          ? const Center(child: CircularProgressIndicator())
          : ErrorView(message: _error!),
    );
  }
}
