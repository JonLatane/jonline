import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';

import '../accounts/user_profile_page.dart';
import 'people_page.dart';

const peopleTab = AutoRoute(
  path: 'people',
  page: EmptyRouterPage,
  name: 'PeopleTab',
  children: [
    AutoRoute(path: '', page: PeopleScreen),
    AutoRoute(
        path: 'person/:server/:userId',
        usesPathAsKey: true,
        page: UserProfilePage),
  ],
);
