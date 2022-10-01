import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';

import 'accounts_page.dart';
import 'admin_page.dart';
import 'my_activity_page.dart';
import 'server_configuration_page.dart';

const accountsTab = AutoRoute(
  path: 'accounts',
  name: 'AccountsTab',
  page: EmptyRouterPage,
  children: [
    AutoRoute(path: '', page: AccountsPage),
    AutoRoute(
        path: 'account/:accountId/activity',
        usesPathAsKey: true,
        page: MyActivityPage),
    AutoRoute(
        path: 'account/:accountId/server_configuration',
        usesPathAsKey: true,
        page: ServerConfigurationPage),
    AutoRoute(
        path: 'account/:accountId/admin', usesPathAsKey: true, page: AdminPage),
  ],
);
