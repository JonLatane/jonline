import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';
import 'package:jonline/screens/posts/create_reply_page.dart';

import '../../router/auth_guard.dart';
import '../accounts/user_profile_page.dart';
import 'create_post_page.dart';
import 'post_details_page.dart';
import 'posts_page.dart';

const postsTab = AutoRoute(
  path: 'posts',
  page: EmptyRouterPage,
  name: 'PostsTab',
  children: [
    AutoRoute(path: '', page: PostsScreen, guards: []),
    AutoRoute(
        path: 'post/:server/:postId',
        usesPathAsKey: true,
        page: PostDetailsPage,
        guards: []),
    AutoRoute(
      path: 'create',
      usesPathAsKey: true,
      page: CreatePostPage,
      guards: [AuthGuard],
    ),
    AutoRoute(
      path: 'post/:server/:postId/reply',
      usesPathAsKey: true,
      page: CreateReplyPage,
      guards: [AuthGuard],
    ),
    AutoRoute(
      path: 'post/:server/:postId/reply/:subjectPostId/reply',
      usesPathAsKey: true,
      page: CreateDeepReplyPage,
      guards: [AuthGuard],
    ),
    AutoRoute(
        path: 'author/:server/:userId',
        usesPathAsKey: true,
        page: AuthorProfilePage),
  ],
);
