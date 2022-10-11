import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';

import 'accounts_page.dart';
import 'server_configuration_page.dart';
import 'user_profile_page.dart';

const accountsTab = AutoRoute(
  path: 'accounts',
  name: 'AccountsTab',
  page: EmptyRouterPage,
  children: [
    AutoRoute(path: '', page: AccountsPage),
    AutoRoute(
        path: 'account/:accountId/profile',
        usesPathAsKey: true,
        page: MyProfilePage),
    AutoRoute(
        path: 'server/:server/configuration',
        usesPathAsKey: true,
        page: ServerConfigurationPage),
    AutoRoute(
        path: 'account/:accountId/admin', usesPathAsKey: true, page: AdminPage),
  ],
);
