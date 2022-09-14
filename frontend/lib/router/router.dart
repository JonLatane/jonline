import 'package:auto_route/auto_route.dart';
import 'package:jonline/router/auth_guard.dart';
import 'package:jonline/screens/events/routes.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:jonline/screens/login_page.dart';
import 'package:jonline/screens/posts/routes.dart';
import 'package:jonline/screens/accounts/routes.dart';
import 'package:jonline/screens/settings_page.dart';
import 'package:jonline/screens/user-data/routes.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page|Screen,Route',
  routes: <AutoRoute>[
    // app stack
    AutoRoute<String>(
      path: '/',
      page: HomePage,
      guards: [AuthGuard],
      deferredLoading: true,
      children: [
        postsTab,
        eventsTab,
        accountsTab,
        AutoRoute(
          path: 'settings/:tab',
          page: SettingsPage,
          name: 'SettingsTab',
        ),
      ],
    ),
    userDataRoutes,
    // auth
    AutoRoute(page: LoginPage, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $RootRouter {}
