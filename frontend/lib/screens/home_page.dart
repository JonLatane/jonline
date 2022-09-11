import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/router/router.gr.dart';

class HomePage extends StatefulWidget implements AutoRouteWrapper {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  HomePageState createState() => HomePageState();

  @override
  Widget wrappedRoute(BuildContext context) {
    return this;
  }
}

class RouteDestination {
  final PageRouteInfo route;
  final IconData icon;
  final String label;

  const RouteDestination({
    required this.route,
    required this.icon,
    required this.label,
  });
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  get destinations => [
        const RouteDestination(
          route: PostsTab(),
          icon: Icons.chat_bubble,
          label: 'Posts',
        ),
        const RouteDestination(
          route: EventsTab(),
          icon: Icons.calendar_month,
          label: 'Events',
        ),
        const RouteDestination(
          route: ProfileTab(),
          icon: Icons.person,
          label: 'Me',
        ),
        // if (showSettingsTab)
        RouteDestination(
          route: SettingsTab(tab: 'tab'),
          icon: Icons.settings,
          label: 'Settings',
        ),
      ];

  // bool _showSettingsTab = false;
  ValueNotifier<bool> showSettingsTabListener = ValueNotifier(false);
  bool _showedSettingsFromSwipe = false;
  bool get showSettingsTab => showSettingsTabListener.value;
  set showSettingsTab(bool value) {
    setState(() {
      showSettingsTabListener.value = value;
    });
  }

  @override
  Widget build(context) {
    // builder will rebuild everytime this router's stack
    // updates
    // we need it to indicate which NavigationRailDestination is active
    if (context.topRoute.name == 'SettingsTab' && !showSettingsTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showedSettingsFromSwipe = true;
        showSettingsTab = true;
      });
    } else if (_showedSettingsFromSwipe &&
        context.topRoute.name != 'SettingsTab') {
      _showedSettingsFromSwipe = false;
      showSettingsTab = false;
    }
    return kIsWeb
        ? AutoRouter(builder: (context, child) {
            // we check for active route index by using
            // router.isRouteActive method
            var activeIndex = destinations.indexWhere(
              (d) => context.router.isRouteActive(d.route.routeName),
            );
            // there might be no active route until router is mounted
            // so we play safe
            if (activeIndex == -1) {
              activeIndex = 0;
            }
            return Row(
              children: [
                NavigationRail(
                  destinations: destinations
                      .map((item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ))
                      .toList(),
                  selectedIndex: activeIndex,
                  onDestinationSelected: (index) {
                    // use navigate instead of push so you won't have
                    // many useless route stacks
                    context.navigateTo(destinations[index].route);
                  },
                ),
                // child is the rendered route stack
                Expanded(child: child)
              ],
            );
          })
        : AutoTabsRouter.pageView(
            routes: [
              const PostsTab(),
              const EventsTab(),
              const ProfileTab(),
              SettingsTab(tab: 'tab'),
            ],
            builder: (context, child, animation) {
              return Scaffold(
                // appBar: AppBar(
                //   title: Text(title),
                //   leading: const AutoLeadingButton(
                //     ignorePagelessRoutes: true,
                //   ),
                // ),
                body: child,
                bottomNavigationBar:
                    buildBottomNav(context, context.tabsRouter),
              );
            },
          );
  }

  String get title {
    switch (context.topRoute.name) {
      case 'PostListRoute':
      case 'PostsTab':
        return 'Posts';
      case 'EventListRoute':
      case 'EventsTab':
        return 'Events';
      case 'ProfileRoute':
      case 'ProfileTab':
        return 'Accounts & Profiles';
      case 'SettingsRoute':
      case 'SettingsTab':
        return 'Settings';
    }
    return context.topRoute.name;
  }

  Widget buildBottomNav(BuildContext context, TabsRouter tabsRouter) {
    final hideBottomNav = tabsRouter.topMatch.meta['hideBottomNav'] == true;
    final items = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble), label: 'Posts'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month), label: 'Events'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Me',
      ),
      if (showSettingsTab)
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
    ];
    return hideBottomNav
        ? const SizedBox.shrink()
        : BottomNavigationBar(
            selectedItemColor: bottomColor,
            type: BottomNavigationBarType.fixed,
            currentIndex: min(items.length - 1, tabsRouter.activeIndex),
            onTap: tabsRouter.setActiveIndex,
            items: items,
          );
  }
}
