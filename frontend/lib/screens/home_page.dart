import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/models/jonline_server.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart';

import '../app_state.dart';
import '../jonotifier.dart';
import '../models/settings.dart';
import '../my_platform.dart';
import '../router/router.gr.dart';
import 'home_page_app_bar.dart';

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

  Jonotifier adminPageFocused = Jonotifier();

  // Notifiers to let the App Bar communicate with pages
  Jonotifier createPost = Jonotifier();
  Jonotifier createReply = Jonotifier();
  Jonotifier updatePost = Jonotifier();
  Jonotifier updateReply = Jonotifier();
  ValueNotifier<bool> canCreatePost = ValueNotifier(false);
  ValueNotifier<bool> canCreateReply = ValueNotifier(false);
  Jonotifier scrollToTop = Jonotifier();
  Map<String, Function(BuildContext)> appBarBuilders = {};

  String? titleServer;
  String? titleUsername;
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
        // if (showSettingsTab) // Making this dynamic screws up auto_route :(
        RouteDestination(
          route: SettingsTab(tab: 'tab'),
          icon: Icons.settings,
          label: 'Settings',
        ),
      ];

  @override
  initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    canCreatePost.addListener(updateState);
    canCreateReply.addListener(updateState);
    appState.accounts.addListener(updateState);
    appState.colorTheme.addListener(updateState);
    Settings.showSettingsTabListener.addListener(updateState);
    if (MyPlatform.isMobile) {
      NativeDeviceOrientationCommunicator()
          .onOrientationChanged()
          .listen((NativeDeviceOrientation o) {
        setState(() {
          orientation = o;
        });
      });
    }
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
    canCreatePost.removeListener(updateState);
    canCreateReply.removeListener(updateState);
    appState.colorTheme.removeListener(updateState);
    super.dispose();
  }

  updateState() => setState(() {});

  RouteData? _lastRoute;
  @override
  Widget build(context) {
    // builder will rebuild everytime this router's stack updates

    if (_lastRoute?.name == "AdminRoute" &&
        context.topRoute.name != "AdminRoute") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.colorTheme.value =
            JonlineServer.selectedServer.configuration?.serverInfo.colors;
      });
    } else if (_lastRoute?.name != "AdminRoute" &&
        context.topRoute.name == "AdminRoute") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adminPageFocused();
      });
    }
    _lastRoute = context.topRoute;
    return /*kIsWeb
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
        :*/
        AutoTabsRouter.pageView(
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
                                (useSideNav && sideNavExpanded ? 0.6 : 0.7) +
                            (useSideNav ? 4 : 0)
                        : 0,
                  ),
                  if (useSideNav) buildSideNav(context),
                  Expanded(child: child),
                  SizedBox(
                    width:
                        (orientation == NativeDeviceOrientation.landscapeRight)
                            ? MediaQuery.of(context).padding.right * 0.7
                            : 0,
                  )
                ],
              ),
              bottomNavigationBar: useSideNav ? null : buildBottomNav(context),
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
        if (Settings.showSettingsTab || context.topRoute.name == 'SettingsTab')
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
      ];

  DateTime? lastActiveNavTapTime;
  handleNavThings() {
    if (lastActiveNavTapTime != null &&
        DateTime.now().difference(lastActiveNavTapTime!) <
            const Duration(milliseconds: 500)) {
      switch (context.topRoute.name) {
        case "PostDetailsRoute":
        case "CreatePostRoute":
        case "CreateReplyRoute":
        case "CreateDeepReplyRoute":
          // context.popRoute();
          context.replaceRoute(const PostListRoute());
          break;
        case "EventDetailsRoute":
          context.replaceRoute(const EventListRoute());
          break;
        case "MyActivityRoute":
          context.replaceRoute(const AccountsRoute());
          break;
        default:
        // print("${context.topRoute.name} not handled");
      }
    } else {
      lastActiveNavTapTime = DateTime.now();
    }
  }

  Widget buildBottomNav(BuildContext context) {
    final tabsRouter = context.tabsRouter;
    final hideBottomNav = tabsRouter.topMatch.meta['hideBottomNav'] == true;
    final items = navigationItems;
    return hideBottomNav
        ? const SizedBox.shrink()
        : BottomNavigationBar(
            selectedItemColor: appState.navColor,
            type: BottomNavigationBarType.fixed,
            currentIndex: min(items.length - 1, tabsRouter.activeIndex),
            onTap: (index) {
              if (index == tabsRouter.activeIndex) {
                scrollToTop();
                handleNavThings();
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
                                    handleNavThings();
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
                                                ? appState.navColor
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
                                                                  ? appState
                                                                      .navColor
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
