import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:jonline/screens/accounts/account_chooser.dart';
import 'package:jonline/screens/stateful_app_bar_widget.dart';
import 'package:side_navigation/side_navigation.dart';

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
                    if (useSideNav) buildSideNav(context),
                    Expanded(child: child),
                  ],
                ),
                bottomNavigationBar: useSideNav
                    ? null
                    : buildBottomNav(context, context.tabsRouter),
              );
            },
          );
  }

  String? _titleServer;
  String? _titleUsername;
  Widget? get titleWidget {
    switch (context.topRoute.name) {
      case 'MyActivityRoute':
        // context.topRoute.args[0] as String;
        if (_titleServer == null || _titleUsername == null) {
          // final Object? accountId = context.topRoute.args;
          final String accountId =
              context.topRoute.pathParams.get('account_id');
          Future.microtask(() async {
            final account = (await JonlineAccount.accounts).firstWhere(
              (account) => account.id == accountId,
            );
            setState(() {
              _titleServer = account.server;
              _titleUsername = account.username;
            });
          });
        }
        return Row(
          children: [
            Text("${_titleServer ?? '...'}/", style: textTheme.caption),
            Text(_titleUsername ?? '...', style: textTheme.subtitle2),
          ],
        );
      default:
        _titleServer = null;
        _titleUsername = null;
    }
  }

  String get title {
    switch (context.topRoute.name) {
      case 'PostListRoute':
      case 'PostsTab':
        return 'Posts';
      case 'PostDetailsRoute':
        return 'Post Details';
      case 'EventListRoute':
      case 'EventsTab':
        return 'Events';
      case 'EventDetailsRoute':
        return 'Event Details';
      case 'ProfileRoute':
      case 'AccountsRoute':
      case 'AccountsTab':
        return 'Accounts & Profiles';
      case 'CreatePostRoute':
        return 'Create Post';
      case 'SettingsRoute':
      case 'SettingsTab':
        return 'Settings';
    }
    return context.topRoute.name;
  }

  bool get showLeadingNav {
    switch (context.topRoute.name) {
      case 'PostListRoute':
      case 'PostsTab':
      case 'EventListRoute':
      case 'EventsTab':
        return false;
    }
    return true;
  }

  ValueNotifier<int> postsCreated = ValueNotifier(0);
  List<Widget>? get actions {
    switch (context.topRoute.name) {
      case 'PostListRoute':
      case 'PostsTab':
        return [
          if (JonlineAccount.selectedAccount != null)
            TextButton(
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                context.navigateNamedTo('/posts/create');
              },
            ),
          const AccountChooser(),
        ];
      case 'EventListRoute':
      case 'EventsTab':
        return [
          if (JonlineAccount.selectedAccount != null)
            const TextButton(
              onPressed: null,
              child: Icon(
                Icons.add,
                // color: Colors.white,
              ),
            ),
          const AccountChooser(),
        ];
      case 'CreatePostRoute':
        return [
          if (JonlineAccount.selectedAccount != null)
            SizedBox(
              width: 72,
              child: ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                    foregroundColor: MaterialStateProperty.all(
                        Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
                    overlayColor:
                        MaterialStateProperty.all(Colors.white.withAlpha(100)),
                    splashFactory: InkSparkle.splashFactory),
                onPressed: title.isEmpty ? null : () => postsCreated.value += 1,
                // doingStuff || username.isEmpty || password.isEmpty
                //     ? null
                //     : createAccount,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    children: const [
                      Expanded(child: SizedBox()),
                      Icon(Icons.add),
                      // Text('jonline.io/', style: TextStyle(fontSize: 11)),
                      Text('CREATE', style: TextStyle(fontSize: 12)),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
          const AccountChooser(),
        ];
      case 'ProfileRoute':
      case 'AccountsTab':
        return null;
      case 'SettingsRoute':
      case 'SettingsTab':
        return null;
    }
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

  Widget buildSideNav(BuildContext context) {
    final tabsRouter = context.tabsRouter;
    final items = [
      const SideNavigationBarItem(
        icon: Icons.chat_bubble,
        label: 'Posts',
      ),
      const SideNavigationBarItem(
        icon: Icons.calendar_month,
        label: 'Events',
      ),
      const SideNavigationBarItem(
        icon: Icons.person,
        label: 'Me',
      ),
      if (showSettingsTab)
        const SideNavigationBarItem(
          icon: Icons.settings,
          label: 'Settings',
        ),
    ];
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      // width: 150,
      child: SideNavigationBar(
          // expandable: false,
          onTap: tabsRouter.setActiveIndex,
          // header: const SideNavigationBarHeader(
          //     image: CircleAvatar(
          //       child: Icon(Icons.account_balance),
          //     ),
          //     title: Text('Jonline'),
          //     subtitle: Text('Subtitle widget')),
          // footer: SideNavigationBarFooter(label: Text('Footer label')),
          selectedIndex: min(items.length - 1, tabsRouter.activeIndex),
          theme: SideNavigationBarTheme(
              dividerTheme: const SideNavigationBarDividerTheme(
                  showFooterDivider: false,
                  showHeaderDivider: false,
                  showMainDivider: false),
              itemTheme:
                  SideNavigationBarItemTheme(selectedItemColor: bottomColor),
              togglerTheme: const SideNavigationBarTogglerTheme()),
          items: items),
    );
  }
}
