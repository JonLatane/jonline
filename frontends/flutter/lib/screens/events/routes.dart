import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';

import '../../router/auth_guard.dart';
import 'event_details_page.dart';
import 'event_list_page.dart';

const eventsTab = AutoRoute(
  path: 'events',
  page: EmptyRouterPage,
  name: 'EventsTab',
  children: [
    AutoRoute(path: '', page: EventListScreen),
    AutoRoute(
      path: 'event/:id',
      usesPathAsKey: true,
      page: EventDetailsPage,
      guards: [AuthGuard],
    ),
  ],
);
