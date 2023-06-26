import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jonline/models/jonline_server.dart';
// import 'package:native_device_orientation/native_device_orientation.dart';
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
  MediaQueryData get mq => MediaQuery.of(context);

  Jonotifier serverConfigPageFocused = Jonotifier();

  // Notifiers to let the App Bar communicate with pages
  Jonotifier createGroup = Jonotifier();
  Jonotifier createPost = Jonotifier();
  Jonotifier createReply = Jonotifier();
  Jonotifier updatePost = Jonotifier();
  Jonotifier updateReply = Jonotifier();
  ValueNotifier<bool> canCreateGroup = ValueNotifier(false);
  ValueNotifier<bool> canCreatePost = ValueNotifier(false);
  ValueNotifier<bool> canCreateReply = ValueNotifier(false);
  Jonotifier scrollToTop = Jonotifier();
  Map<String, Function(BuildContext)> appBarBuilders = {};
  FocusNode peopleSearchFocus = FocusNode();
  TextEditingController peopleSearchController = TextEditingController();
  ValueJonotifier<bool> peopleSearch = ValueJonotifier(false);
  FocusNode groupsSearchFocus = FocusNode();
  TextEditingController groupsSearchController = TextEditingController();
  ValueJonotifier<bool> groupsSearch = ValueJonotifier(false);

  ValueJonotifier<String?> titleServerNotifier = ValueJonotifier(null);
  ValueJonotifier<String?> titleUsernameNotifier = ValueJonotifier(null);
  String? get titleServer => titleServerNotifier.value;
  set titleServer(String? value) => titleServerNotifier.value = value;
  String? get titleUsername => titleUsernameNotifier.value;
  set titleUsername(String? value) => titleUsernameNotifier.value = value;
  bool get sideNavExpanded =>
      (draggingSideNav && !Settings.keepSideNavExpanded) || _sideNavExpanded;
  bool _sideNavExpanded = false;
  // NativeDeviceOrientation orientation = NativeDeviceOrientation.unknown;

  get useSideNav => mq.size.width > 600;
  TextTheme get textTheme => Theme.of(context).textTheme;
  // get destinations => [
  //       const RouteDestination(
  //         route: PeopleTab(),
  //         icon: Icons.people_alt_outlined,
  //         label: 'People',
  //       ),
  //       const RouteDestination(
  //         route: PostsTab(),
  //         icon: Icons.chat_bubble,
  //         label: 'Posts',
  //       ),
  //       const RouteDestination(
  //         route: EventsTab(),
  //         icon: Icons.calendar_month,
  //         label: 'Events',
  //       ),
  //       const RouteDestination(
  //         route: AccountsTab(),
  //         icon: Icons.person,
  //         label: 'Me',
  //       ),
  //       // if (showSettingsTab) // Making this dynamic screws up auto_route :(
  //       RouteDestination(
  //         route: SettingsTab(tab: 'tab'),
  //         icon: Icons.settings,
  //         label: 'Settings',
  //       ),
  //     ];

  @override
  initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;

    canCreateGroup.addListener(updateState);
    canCreatePost.addListener(updateState);
    canCreateReply.addListener(updateState);
    appState.accounts.addListener(updateState);
    appState.colorTheme.addListener(updateState);
    appState.selectedGroup.addListener(updateState);
    Settings.showSettingsTabListener.addListener(updateState);
    Settings.showPeopleTabListener.addListener(updateState);
    Settings.showGroupsTabListener.addListener(updateState);
    Settings.keepSideNavExpandedListener.addListener(updateState);
    peopleSearch.addListener(updateState);
    groupsSearch.addListener(updateState);
    titleServerNotifier.addListener(updateState);
    titleUsernameNotifier.addListener(updateState);

    // if (MyPlatform.isMobile) {
    //   NativeDeviceOrientationCommunicator()
    //       .onOrientationChanged()
    //       .listen((NativeDeviceOrientation o) {
    //     setState(() {
    //       orientation = o;
    //     });
    //   });
    // }
  }

  @override
  dispose() {
    canCreateGroup.removeListener(updateState);
    canCreatePost.removeListener(updateState);
    canCreateReply.removeListener(updateState);
    appState.accounts.removeListener(updateState);
    appState.colorTheme.removeListener(updateState);
    appState.selectedGroup.removeListener(updateState);
    Settings.showSettingsTabListener.removeListener(updateState);
    Settings.showPeopleTabListener.removeListener(updateState);
    Settings.showGroupsTabListener.removeListener(updateState);
    Settings.keepSideNavExpandedListener.removeListener(updateState);
    peopleSearch.removeListener(updateState);
    groupsSearch.removeListener(updateState);
    titleServerNotifier.removeListener(updateState);
    titleUsernameNotifier.removeListener(updateState);

    super.dispose();
  }

  updateState() {
    // print("HomePageState.updateState()");
    setState(() {});
  }

  final List<Future<dynamic> Function()> setupOtherShaders = [];

  //TODO this is still a hacky way to default the user to the "Posts" tab.
  gotoDefaultTab(TabsRouter tabsRouter, {int? initialTab}) async {
    final initialTab2 = initialTab ?? tabsRouter.activeIndex;
    if (initialTab2 == 0) {
      await Future.delayed(animationDuration, () async {
        tabsRouter.setActiveIndex(2);
      });
    }
  }

  RouteData? _lastRoute;

  bool isFirstBuild = true;
  bool isServerConfigPage(RouteData? route) =>
      route?.name == "AdminRoute" || route?.name == "ServerConfigurationRoute";
  @override
  Widget build(context) {
    // builder will rebuild everytime this router's stack updates
    if (isServerConfigPage(_lastRoute) &&
        !isServerConfigPage(context.topRoute)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        appState.colorTheme.value =
            JonlineServer.selectedServer.configuration?.serverInfo.colors;
        await appState.updateServersAndAccounts();
        // await JonlineServer.selectedServer.updateConfiguration();
        // if (!isServerConfigPage(context.topRoute)) {
        //   appState.colorTheme.value =
        //       JonlineServer.selectedServer.configuration?.serverInfo.colors;
        // }
      });
    } else if (!isServerConfigPage(_lastRoute) &&
        isServerConfigPage(context.topRoute)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        serverConfigPageFocused();
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
        const GroupsTab(),
        const PeopleTab(),
        const PostsTab(),
        const EventsTab(),
        const AccountsTab(),
        SettingsTab(tab: 'tab'),
      ],
      homeIndex: 2,
      builder: (context, child, animation) {
        TabsRouter tabsRouter = context.tabsRouter;

        // handleWebShaderSetup(tabsRouter);
        if (isFirstBuild) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            gotoDefaultTab(tabsRouter);
          });
        }
        isFirstBuild = false;
        return ScrollsToTop(
            onScrollsToTop: (ScrollsToTopEvent event) async {
              scrollToTop();
            },
            child: Stack(
              children: [
                Scaffold(
                  appBar: appBar,
                  extendBodyBehindAppBar: true,
                  extendBody: true,
                  body: Stack(
                    children: [
                      Row(
                        children: [
                          buildLeftPadding(),
                          AnimatedContainer(
                              duration: animationDuration,
                              width: sideNavPaddingWidth),
                          Expanded(child: child),
                          buildRightPadding(),
                        ],
                      ),
                      if (useSideNav)
                        Row(
                          children: [
                            buildLeftPadding(),
                            buildSideNav(context),
                          ],
                        )
                    ],
                  ),
                  bottomNavigationBar:
                      useSideNav ? null : buildBottomNav(context),
                )
              ],
            ));
      },
    );
  }

  Widget buildTopPadding() => AnimatedContainer(
        duration: animationDuration,
        height:
            0 /*(MyPlatform.isIPad &&
                orientation == NativeDeviceOrientation.landscapeLeft)
            ? 0
            : 0*/
        ,
      );

  Widget buildLeftPadding() => AnimatedContainer(
      duration: animationDuration,
      width: //(orientation == NativeDeviceOrientation.landscapeLeft)
          // ?
          mq.padding.left * (useSideNav && sideNavExpanded ? 0.7 : 0.7) +
              (useSideNav ? 4 : 0)
      // : 0,
      );

  Widget buildRightPadding() => SizedBox(
      width: //(orientation == NativeDeviceOrientation.landscapeRight)
          //?
          mq.padding.right * 0.7
      // : 0,
      );

  static const sideNavBaseWidth = 48.0;
  double get sideNavExpandedWidth =>
      (MediaQuery.of(context).size.width > 600 ? 150 : 110) *
      mq.textScaleFactor;
  double get sideNavPaddingWidth => useSideNav
      ? Settings.keepSideNavExpanded
          ? sideNavWidth
          : sideNavBaseWidth
      : 0;
  double get sideNavWidth => useSideNav
      ? sideNavExpanded
          ? sideNavExpandedWidth
          : sideNavBaseWidth
      : 0;

  bool get showPeople =>
      Settings.showPeopleTab ||
      [PeopleRoute.name, UserProfileRoute.name].contains(context.topRoute.name);
  bool get showGroups =>
      Settings.showGroupsTab ||
      [GroupsRoute.name, GroupDetailsRoute.name]
          .contains(context.topRoute.name);
  bool get showSettings =>
      Settings.showSettingsTab ||
      [SettingsTab.name].contains(context.topRoute.name);
  List<BottomNavigationBarItem> get navigationItems => [
        const BottomNavigationBarItem(
            icon: Icon(Icons.group_work_outlined), label: 'Groups'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: appState.selectedGroup.value == null ? 'People' : 'Members'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble), label: 'Posts'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), label: 'Events'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Me',
        ),
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
        case PostDetailsRoute.name:
        case CreatePostRoute.name:
        case CreateReplyRoute.name:
        case CreateDeepReplyRoute.name:
        case AuthorProfileRoute.name:
          // context.popRoute();
          context.replaceRoute(const PostsRoute());
          break;
        case EventDetailsRoute.name:
          context.replaceRoute(const EventListRoute());
          break;
        case UserProfileRoute.name:
          context.replaceRoute(const PeopleRoute());
          break;
        case GroupDetailsRoute.name:
          context.replaceRoute(const GroupsRoute());
          break;
        case MyProfileRoute.name:
        case ServerConfigurationRoute.name:
          context.replaceRoute(const AccountsRoute());
          break;
        default:
        // print("${context.topRoute.name} not handled");
      }
    } else {
      lastActiveNavTapTime = DateTime.now();
    }
  }

  double _lastBottomNavDragPosition = 0.0;

  Widget buildBottomNav(BuildContext context) {
    TabsRouter tabsRouter = context.tabsRouter;
    final hideBottomNav = tabsRouter.topMatch.meta['hideBottomNav'] == true;
    final items = navigationItems;
    final width = mq.size.width;
    final numButtons = 3 +
        (showSettings ? 1 : 0) +
        (showGroups ? 1 : 0) +
        (showPeople ? 1 : 0);
    final buttonWidth = width / numButtons;
    final bottomPadding = mq.padding.bottom * 0.7;
    return hideBottomNav
        ? const SizedBox.shrink()
        : GestureDetector(
            onHorizontalDragStart: (details) =>
                _lastBottomNavDragPosition = details.globalPosition.dx,
            onHorizontalDragUpdate: (details) {
              int lastTab = (_lastBottomNavDragPosition / increment).floor();
              int tab = (details.globalPosition.dx / increment).floor();
              if (tab > lastTab) {
                if (tabsRouter.activeIndex < navigationItems.length - 1) {
                  HapticFeedback.lightImpact();
                  tabsRouter.setActiveIndex(tabsRouter.activeIndex + 1);
                  _lastBottomNavDragPosition = details.globalPosition.dx;
                }
              } else if (tab < lastTab) {
                if (tabsRouter.activeIndex > 0) {
                  HapticFeedback.lightImpact();
                  tabsRouter.setActiveIndex(tabsRouter.activeIndex - 1);
                  _lastBottomNavDragPosition = details.globalPosition.dx;
                }
              }
            },
            child: ClipRRect(
                child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: AnimatedContainer(
                      color: Theme.of(context).canvasColor.withOpacity(0.7),
                      duration: animationDuration,
                      width: width,
                      height: 72 + bottomPadding,
                      // width: _sideNavExpanded
                      //     ? (MediaQuery.of(context).size.width > 600 ? 150 : 110) *
                      //        mq.textScaleFactor
                      //     : sideNavBaseWidth,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // const SizedBox(
                                //   height: 48,
                                // ),
                                ...items
                                    .asMap()
                                    .map(
                                      (index, item) {
                                        final active =
                                            index == tabsRouter.activeIndex;
                                        final hidden =
                                            ((index == 0) && !showGroups) ||
                                                ((index == 1) && !showPeople) ||
                                                ((index == 5) && !showSettings);
                                        final actualWidth =
                                            hidden ? 0.0 : buttonWidth;
                                        return MapEntry(
                                            index,
                                            Tooltip(
                                              message: item.label!,
                                              child: AnimatedOpacity(
                                                duration: animationDuration,
                                                opacity: hidden ? 0.0 : 1.0,
                                                child: AnimatedContainer(
                                                  duration: animationDuration,
                                                  width: actualWidth,
                                                  child: TextButton(
                                                      style: ButtonStyle(
                                                          overlayColor:
                                                              MaterialStateProperty
                                                                  .all(appState
                                                                      .navColor
                                                                      .withOpacity(
                                                                          0.2)),
                                                          padding:
                                                              MaterialStateProperty
                                                                  .all(EdgeInsets
                                                                      .zero)),
                                                      onPressed: () {
                                                        if (index ==
                                                            tabsRouter
                                                                .activeIndex) {
                                                          scrollToTop();
                                                          handleNavThings();
                                                        }
                                                        tabsRouter
                                                            .setActiveIndex(
                                                                index);
                                                        if (!Settings
                                                            .keepSideNavExpanded) {
                                                          setState(() {
                                                            _sideNavExpanded =
                                                                false;
                                                          });
                                                        }
                                                        // }
                                                      },
                                                      child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 8,
                                                                  horizontal:
                                                                      8),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                  (item.icon
                                                                          as Icon)
                                                                      .icon,
                                                                  size: 32,
                                                                  color: active
                                                                      ? appState
                                                                          .navColor
                                                                      : Colors
                                                                          .grey),
                                                              AnimatedScale(
                                                                duration:
                                                                    animationDuration,
                                                                scale: active
                                                                    ? 1.2
                                                                    : 1,
                                                                child: Text(
                                                                    item.label!,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: textTheme
                                                                        .bodySmall!
                                                                        .copyWith(
                                                                            color: active
                                                                                ? appState.navColor
                                                                                : Colors.grey)),
                                                              ),
                                                            ],
                                                          ))),
                                                ),
                                              ),
                                            ));
                                      },
                                    )
                                    .values
                                    .toList(),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: bottomPadding,
                          )
                        ],
                      ),
                    ))),
          );
  }

  static final appBarHeight = MyPlatform.isMacOS ? 56.0 : 48.0;
  static final appBarPadding = MyPlatform.isMacOS ? 10.0 : 0.0;

  bool draggingSideNav = false;
  double _lastSideNavDragPosition = 0.0;
  static const double increment = 59.0;
  Widget buildSideNav(BuildContext context) {
    final tabsRouter = context.tabsRouter;
    final items = navigationItems;
    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() {
          draggingSideNav = true;
        });
        _lastSideNavDragPosition = details.globalPosition.dy;
      },
      onVerticalDragUpdate: (details) {
        int lastTab = (_lastSideNavDragPosition / increment).floor();
        int tab = (details.globalPosition.dy / increment).floor();
        if (tab > lastTab) {
          if (tabsRouter.activeIndex < navigationItems.length - 1) {
            HapticFeedback.lightImpact();
            tabsRouter.setActiveIndex(tabsRouter.activeIndex + 1);
            _lastSideNavDragPosition = details.globalPosition.dy;
          }
        } else if (tab < lastTab) {
          if (tabsRouter.activeIndex > 0) {
            HapticFeedback.lightImpact();
            tabsRouter.setActiveIndex(tabsRouter.activeIndex - 1);
            _lastSideNavDragPosition = details.globalPosition.dy;
          }
        }
      },
      onVerticalDragEnd: (details) {
        setState(() {
          draggingSideNav = false;
        });
      },
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta != null) {
          if (details.primaryDelta! > 5.0) {
            setState(() {
              _sideNavExpanded = true;
            });
          } else if (details.primaryDelta! < -5.0) {
            setState(() {
              _sideNavExpanded = false;
            });
          }
        }
      },
      child: ClipRRect(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: AnimatedContainer(
                color: Theme.of(context).canvasColor.withOpacity(0.7),
                duration: animationDuration,
                width: sideNavWidth,
                child: Column(
                  children: [
                    SizedBox(
                      height: appBarHeight +
                          appBarPadding +
                          Settings.sidebarTopPadding,
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                      child: Column(children: [
                        ...items
                            .asMap()
                            .map(
                              (index, item) {
                                final active = index == tabsRouter.activeIndex;
                                final hidden = ((index == 0) && !showGroups) ||
                                    ((index == 1) && !showPeople) ||
                                    ((index == 5) && !showSettings);
                                return MapEntry(
                                    index,
                                    Tooltip(
                                      message: item.label!,
                                      child: AnimatedOpacity(
                                        duration: animationDuration,
                                        opacity: hidden ? 0 : 1,
                                        child: AnimatedContainer(
                                          duration: animationDuration,
                                          height: hidden ? 0 : 48,
                                          child: TextButton(
                                              style: ButtonStyle(
                                                  overlayColor:
                                                      MaterialStateProperty.all(
                                                          appState.navColor
                                                              .withOpacity(
                                                                  0.2)),
                                                  padding:
                                                      MaterialStateProperty.all(
                                                          EdgeInsets.zero)),
                                              onPressed: () {
                                                if (index ==
                                                    tabsRouter.activeIndex) {
                                                  scrollToTop();
                                                  handleNavThings();
                                                }
                                                tabsRouter
                                                    .setActiveIndex(index);
                                                if (!Settings
                                                    .keepSideNavExpanded) {
                                                  setState(() {
                                                    _sideNavExpanded = false;
                                                  });
                                                }
                                              },
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 8,
                                                      horizontal: 8),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          (item.icon as Icon)
                                                              .icon,
                                                          size: 32,
                                                          color: active
                                                              ? appState
                                                                  .navColor
                                                              : Colors.grey),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            AnimatedContainer(
                                                              duration:
                                                                  animationDuration,
                                                              width:
                                                                  sideNavExpanded
                                                                      ? 12
                                                                      : 0,
                                                            ),
                                                            Expanded(
                                                              child:
                                                                  AnimatedOpacity(
                                                                opacity:
                                                                    sideNavExpanded
                                                                        ? 1
                                                                        : 0,
                                                                duration:
                                                                    animationDuration,
                                                                child: Text(
                                                                    item.label!,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .clip,
                                                                    style: textTheme
                                                                        .titleMedium!
                                                                        .copyWith(
                                                                            color: active
                                                                                ? appState.navColor
                                                                                : Colors.grey)),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ))),
                                        ),
                                      ),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedRotation(
                                  duration: animationDuration,
                                  turns: sideNavExpanded ? 0 : -0.5,
                                  child: const Icon(Icons.arrow_left,
                                      size: 32, color: Colors.grey),
                                ),
                              ],
                            )))
                  ],
                ),
              ))),
    );
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
