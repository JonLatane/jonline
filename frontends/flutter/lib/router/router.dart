import 'package:auto_route/auto_route.dart';
import '../screens/groups/routes.dart';

import '../router/auth_guard.dart';
import '../screens/accounts/routes.dart';
import '../screens/events/routes.dart';
import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/people/routes.dart';
import '../screens/posts/routes.dart';
import '../screens/settings_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page|Screen,Route',
  routes: <AutoRoute>[
    // app stack
    AutoRoute<String>(
      path: '/',
      page: HomePage,
      guards: [AuthGuard],
      deferredLoading: false,
      children: [
        postsTab,
        groupsTab,
        peopleTab,
        eventsTab,
        accountsTab,
        AutoRoute(
          path: 'settings/:tab',
          page: SettingsPage,
          name: 'SettingsTab',
        ),
      ],
    ),
    // auth
    AutoRoute(page: LoginPage, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $RootRouter {}
