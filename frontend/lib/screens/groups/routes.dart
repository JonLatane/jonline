import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';

import '../../router/auth_guard.dart';
import 'create_group_page.dart';
import 'group_details_page.dart';
import 'groups_page.dart';

const groupsTab = AutoRoute(
  path: 'groups',
  page: EmptyRouterPage,
  name: 'GroupsTab',
  children: [
    AutoRoute(path: '', page: GroupsScreen),
    AutoRoute(
      path: 'group/:id',
      usesPathAsKey: true,
      page: GroupDetailsPage,
      guards: [AuthGuard],
    ),
    AutoRoute(
      path: 'create',
      usesPathAsKey: true,
      page: CreateGroupPage,
      guards: [AuthGuard],
    ),
  ],
);
