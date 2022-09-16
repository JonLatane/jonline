import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';

import 'accounts_page.dart';
import 'my_activity_page.dart';

const accountsTab = AutoRoute(
  path: 'accounts',
  name: 'AccountsTab',
  page: EmptyRouterPage,
  children: [
    AutoRoute(path: '', page: AccountsPage),
    AutoRoute(
        path: 'account/:account_id/activity',
        usesPathAsKey: true,
        page: MyActivityPage),
  ],
);
