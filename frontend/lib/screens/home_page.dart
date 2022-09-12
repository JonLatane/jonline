import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/my_platform.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:jonline/screens/home_page_title.dart';

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
  String? titleServer;
  String? titleUsername;
  ValueNotifier<bool> canCreatePost = ValueNotifier(false);
  ValueNotifier<int> postsCreated = ValueNotifier(0);
  bool get sideNavExpanded => _sideNavExpanded;
  bool _sideNavExpanded = false;

  get useSideNav => MediaQuery.of(context).size.width > 600;
  TextTheme get textTheme => Theme.of(context).textTheme;
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
          route: AccountsTab(),
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
  initState() {
    super.initState();
    canCreatePost.addListener(updateState);
  }

  @override
  dispose() {
    canCreatePost.removeListener(updateState);
    super.dispose();
  }

  updateState() => setState(() {});

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
              const AccountsTab(),
              SettingsTab(tab: 'tab'),
            ],
            builder: (context, child, animation) {
              return Scaffold(
                appBar: AppBar(
                  title: titleWidget ?? Text(title),
                  leading: showLeadingNav
                      ? const AutoLeadingButton(
                          // showIfChildCanPop: false,
                          showIfParentCanPop: false,
                          ignorePagelessRoutes: true,
                        )
                      : null,
                  automaticallyImplyLeading: false,
                  actions: actions,
                ),
                body: Row(
                  children: [
                    AnimatedContainer(
                      duration: animationDuration,
                      width: MediaQuery.of(context).padding.left *
                          (sideNavExpanded ? 0.6 : 0.8),
                    ),
                    if (useSideNav) buildSideNav(context),
                    Expanded(child: child),
                    SizedBox(
                      width: MediaQuery.of(context).padding.right,
                    )
                  ],
                ),
                bottomNavigationBar: useSideNav
                    ? null
                    : buildBottomNav(context, context.tabsRouter),
              );
            },
          );
  }

  List<BottomNavigationBarItem> get navigationItems => [
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
  Widget buildBottomNav(BuildContext context, TabsRouter tabsRouter) {
    final hideBottomNav = tabsRouter.topMatch.meta['hideBottomNav'] == true;
    final items = navigationItems;
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

  Widget buildSideNav(BuildContext context) {
    final tabsRouter = context.tabsRouter;
    final items = navigationItems;
    return AnimatedContainer(
      duration: animationDuration,
      width: _sideNavExpanded
          ? (MediaQuery.of(context).size.width > 600 ? 150 : 110) *
              MediaQuery.of(context).textScaleFactor
          : 40,
      child: Column(
        children: [
          ...items
              .asMap()
              .map(
                (index, item) {
                  final active = index == tabsRouter.activeIndex;
                  return MapEntry(
                      index,
                      Tooltip(
                        message: item.label!,
                        child: InkWell(
                            onTap: () {
                              tabsRouter.setActiveIndex(index);
                              if (MediaQuery.of(context).size.width < 600) {
                                setState(() {
                                  _sideNavExpanded = false;
                                });
                              }
                            },
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                child: Row(
                                  children: [
                                    Icon((item.icon as Icon).icon,
                                        color:
                                            active ? bottomColor : Colors.grey),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: animationDuration,
                                            width: _sideNavExpanded ? 8 : 0,
                                          ),
                                          Expanded(
                                            child: AnimatedOpacity(
                                              opacity: _sideNavExpanded ? 1 : 0,
                                              duration: animationDuration,
                                              child: Text(item.label!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.clip,
                                                  style: TextStyle(
                                                      color: active
                                                          ? bottomColor
                                                          : Colors.grey)),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ))),
                      ));
                },
              )
              .values
              .toList(),
          const Expanded(
            child: SizedBox(),
          ),

          InkWell(
              onTap: () {
                setState(() {
                  _sideNavExpanded = !_sideNavExpanded;
                });
              },
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          _sideNavExpanded
                              ? Icons.arrow_left
                              : Icons.arrow_right,
                          color: Colors.grey),
                    ],
                  )))
          // Expanded(
          //   child: SideNavigationBar(
          //       // expandable: false,
          //       onTap: tabsRouter.setActiveIndex,
          //       // expandable: false,
          //       initiallyExpanded: true,
          //       selectedIndex: min(items.length - 1, tabsRouter.activeIndex),
          //       theme: SideNavigationBarTheme(
          //           dividerTheme: const SideNavigationBarDividerTheme(
          //               showFooterDivider: false,
          //               showHeaderDivider: false,
          //               showMainDivider: false),
          //           itemTheme: SideNavigationBarItemTheme(
          //               labelTextStyle: textTheme.caption,
          //               selectedItemColor: bottomColor),
          //           togglerTheme: const SideNavigationBarTogglerTheme()),
          //       items: items),
          // ),
        ],
      ),
    );
  }
}
