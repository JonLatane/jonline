import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';

import '../../router/auth_guard.dart';
import 'person_details_page.dart';
import 'person_list_page.dart';

const peopleTab = AutoRoute(
  path: 'people',
  page: EmptyRouterPage,
  name: 'PeopleTab',
  children: [
    AutoRoute(path: '', page: PersonListScreen),
    AutoRoute(
      path: 'person/:id',
      usesPathAsKey: true,
      page: PersonDetailsPage,
      guards: [AuthGuard],
    ),
  ],
);
