import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/jonotifier.dart';
import 'package:jonline/my_platform.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:jonline/screens/home_page_app_bar.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart';

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
  late AppState appState;

  String? titleServer;
  String? titleUsername;
  ValueNotifier<bool> canCreatePost = ValueNotifier(false);
  ValueNotifier<int> postsCreated = ValueNotifier(0);
  Jonotifier scrollToTop = Jonotifier();
  bool get sideNavExpanded => _sideNavExpanded;
  bool _sideNavExpanded = false;
  NativeDeviceOrientation orientation = NativeDeviceOrientation.unknown;

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
    appState = context.findRootAncestorStateOfType<AppState>()!;
    canCreatePost.addListener(updateState);
    appState.accounts.addListener(updateState);
    NativeDeviceOrientationCommunicator()
        .onOrientationChanged()
        .listen((NativeDeviceOrientation o) {
      setState(() {
        orientation = o;
      });
    });
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
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
              return ScrollsToTop(
                  onScrollsToTop: (ScrollsToTopEvent event) async {
                    scrollToTop();
                  },
                  child: Scaffold(
                    appBar: appBar,
                    body: Row(
                      children: [
                        AnimatedContainer(
                          duration: animationDuration,
                          width: (orientation ==
                                  NativeDeviceOrientation.landscapeLeft)
                              ? MediaQuery.of(context).padding.left *
                                      (useSideNav && sideNavExpanded
                                          ? 0.6
                                          : 0.7) +
                                  (useSideNav ? 4 : 0)
                              : 0,
                        ),
                        if (useSideNav) buildSideNav(context),
                        Expanded(child: child),
                        SizedBox(
                          width: (orientation ==
                                  NativeDeviceOrientation.landscapeRight)
                              ? MediaQuery.of(context).padding.right * 0.7
                              : 0,
                        )
                      ],
                    ),
                    bottomNavigationBar:
                        useSideNav ? null : buildBottomNav(context),
                  ));
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
  Widget buildBottomNav(BuildContext context) {
    final tabsRouter = context.tabsRouter;
    final hideBottomNav = tabsRouter.topMatch.meta['hideBottomNav'] == true;
    final items = navigationItems;
    return hideBottomNav
        ? const SizedBox.shrink()
        : BottomNavigationBar(
            selectedItemColor: bottomColor,
            type: BottomNavigationBarType.fixed,
            currentIndex: min(items.length - 1, tabsRouter.activeIndex),
            onTap: (index) {
              if (index == tabsRouter.activeIndex) {
                scrollToTop();
              }
              tabsRouter.setActiveIndex(index);
            },
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
          : 48,
      child: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
            child: Column(children: [
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
                                  if (index == tabsRouter.activeIndex) {
                                    scrollToTop();
                                  }
                                  tabsRouter.setActiveIndex(index);
                                  if (MediaQuery.of(context).size.width < 700) {
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
                                            size: 32,
                                            color: active
                                                ? bottomColor
                                                : Colors.grey),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              AnimatedContainer(
                                                duration: animationDuration,
                                                width:
                                                    _sideNavExpanded ? 12 : 0,
                                              ),
                                              Expanded(
                                                child: AnimatedOpacity(
                                                  opacity:
                                                      _sideNavExpanded ? 1 : 0,
                                                  duration: animationDuration,
                                                  child: Text(item.label!,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.clip,
                                                      style: textTheme
                                                          .subtitle1!
                                                          .copyWith(
                                                              color: active
                                                                  ? bottomColor
                                                                  : Colors
                                                                      .grey)),
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
            ]),
          )),
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
                          size: 32,
                          color: Colors.grey),
                    ],
                  )))
        ],
      ),
    );
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
