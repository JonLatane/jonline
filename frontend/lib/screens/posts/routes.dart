import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';
import 'package:jonline/router/auth_guard.dart';
import 'package:jonline/screens/posts/create_post_page.dart';

import 'post_details_page.dart';
import 'post_list_page.dart';

const postsTab = AutoRoute(
  path: 'posts',
  page: EmptyRouterPage,
  name: 'PostsTab',
  children: [
    AutoRoute(path: '', page: PostListScreen),
    AutoRoute(
      path: 'create',
      usesPathAsKey: true,
      page: CreatePostPage,
      guards: [AuthGuard],
    ),
    AutoRoute(
      path: 'post/:id',
      usesPathAsKey: true,
      page: PostDetailsPage,
      guards: [],
    ),
  ],
);
