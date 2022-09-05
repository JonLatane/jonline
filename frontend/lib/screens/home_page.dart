import 'package:auto_route/auto_route.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  final destinations = [
    const RouteDestination(
      route: PostsTab(),
      icon: Icons.chat_bubble,
      label: 'Posts',
    ),
    RouteDestination(
      route: EventsTab(),
      icon: Icons.calendar_month,
      label: 'Events',
    ),
    const RouteDestination(
      route: ProfileTab(),
      icon: Icons.person,
      label: 'Profile',
    ),
    RouteDestination(
      route: SettingsTab(tab: 'tab'),
      icon: Icons.settings,
      label: 'Settings',
    ),
  ];

  void toggleSettingsTab() => setState(() {
        _showSettingsTab = !_showSettingsTab;
      });

  bool _showSettingsTab = true;

  @override
  Widget build(context) {
    // builder will rebuild everytime this router's stack
    // updates
    // we need it to indicate which NavigationRailDestination is active
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
              if (_showSettingsTab) SettingsTab(tab: 'tab'),
            ],
            builder: (context, child, animation) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(context.topRoute.name),
                  leading: const AutoLeadingButton(
                    ignorePagelessRoutes: true,
                  ),
                ),
                body: child,
                bottomNavigationBar:
                    buildBottomNav(context, context.tabsRouter),
              );
            },
          );
  }

  Widget buildBottomNav(BuildContext context, TabsRouter tabsRouter) {
    final hideBottomNav = tabsRouter.topMatch.meta['hideBottomNav'] == true;
    return hideBottomNav
        ? const SizedBox.shrink()
        : BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble), label: 'Posts'
                  // icon: Icon(Icons.source),
                  // label: 'Books',
                  ),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month), label: 'Events'
                  // icon: Icon(Icons.source),
                  // label: 'Books',
                  ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              if (_showSettingsTab)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
            ],
          );
  }
}
