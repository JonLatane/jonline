import 'package:auto_route/auto_route.dart';
import 'package:jonline/router/auth_guard.dart';
import 'package:jonline/screens/books/book_details_page.dart';
import 'package:jonline/screens/books/book_list_page.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:jonline/screens/login_page.dart';
import 'package:jonline/screens/profile/routes.dart';
import 'package:jonline/screens/settings.dart';
import 'package:jonline/screens/user-data/routes.dart';
import 'package:auto_route/empty_router_widgets.dart';

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
        AutoRoute(
          deferredLoading: true,
          path: 'books',
          page: EmptyRouterPage,
          name: 'BooksTab',
          initial: true,
          maintainState: true,
          children: [
            AutoRoute(
              path: '',
              page: BookListScreen,
            ),
            AutoRoute(
              path: ':id',
              page: BookDetailsPage,
              fullscreenDialog: true,
            ),
          ],
        ),
        profileTab,
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
