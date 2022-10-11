import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

import '../../app_state.dart';
import '../../generated/permissions.pb.dart';
import '../../generated/users.pb.dart';

import '../../models/jonline_server.dart';
import '../home_page.dart';
// import 'user_preview.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({Key? key}) : super(key: key);

  @override
  PeopleScreenState createState() => PeopleScreenState();
}

class PeopleScreenState extends State<PeopleScreen>
    with AutoRouteAwareStateMixin<PeopleScreen> {
  late AppState appState;
  late HomePageState homePage;

  ScrollController scrollController = ScrollController();

  @override
  void didPushNext() {
    // print('didPushNext');
  }

  @override
  void initState() {
    // print("UserListPage.initState");
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    appState.accounts.addListener(updateState);
    for (var n in [
      appState.users,
      appState.updatingUsers,
      appState.didUpdateUsers
    ]) {
      n.addListener(updateState);
    }
    homePage.scrollToTop.addListener(scrollToTop);
    homePage.peopleSearch.addListener(updateState);
    homePage.peopleSearchController.addListener(updateState);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("UserListPage.dispose");
    appState.accounts.removeListener(updateState);
    for (var n in [
      appState.users,
      appState.updatingUsers,
      appState.didUpdateUsers
    ]) {
      n.removeListener(updateState);
    }
    homePage.scrollToTop.removeListener(scrollToTop);
    homePage.peopleSearch.removeListener(updateState);
    homePage.peopleSearchController.removeListener(updateState);
    scrollController.dispose();
    super.dispose();
  }

  updateState() {
    setState(() {});
  }

  scrollToTop() {
    if (context.topRoute.name == 'PeopleRoute') {
      scrollController.animateTo(0,
          duration: animationDuration, curve: Curves.easeInOut);
      // gridScrollController.animateTo(0,
      //     duration: animationDuration, curve: Curves.easeInOut);
    }
  }

  bool get useList => MediaQuery.of(context).size.width < 450;
  TextTheme get textTheme => Theme.of(context).textTheme;
  @override
  Widget build(BuildContext context) {
    List<User> userList = appState.users.value;
    if (homePage.peopleSearch.value &&
        homePage.peopleSearchController.text != '') {
      userList = userList.where((user) {
        return user.username
            .toLowerCase()
            .contains(homePage.peopleSearchController.text.toLowerCase());
      }).toList();
    }
    return Scaffold(
      // appBar: ,
      body: RefreshIndicator(
        displacement: MediaQuery.of(context).padding.top + 40,
        onRefresh: () async =>
            await appState.updateUsers(showMessage: showSnackBar),
        child: ScrollConfiguration(
            // key: Key("userListScrollConfiguration-${userList.length}"),
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: userList.isEmpty && !appState.didUpdateUsers.value
                ? Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: scrollController,
                            child: Column(
                              children: [
                                SizedBox(
                                    height:
                                        (MediaQuery.of(context).size.height -
                                                200) /
                                            2),
                                Center(
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 350),
                                    child: Column(
                                      children: [
                                        Text(
                                            appState.updatingUsers.value
                                                ? "Loading People..."
                                                : appState.errorUpdatingUsers
                                                        .value
                                                    ? "Error Loading People"
                                                    : "No People",
                                            style: textTheme.titleLarge),
                                        Text(
                                            JonlineServer.selectedServer.server,
                                            style: textTheme.caption),
                                        if (!appState.updatingUsers.value &&
                                            !appState
                                                .errorUpdatingUsers.value &&
                                            appState.selectedAccount == null)
                                          Column(
                                            children: [
                                              const SizedBox(height: 8),
                                              TextButton(
                                                style: ButtonStyle(
                                                    padding:
                                                        MaterialStateProperty
                                                            .all(
                                                                const EdgeInsets
                                                                    .all(16))),
                                                onPressed: () => context
                                                    .navigateNamedTo('/login'),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                          'Login/Create Account to see more People.',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                  color: appState
                                                                      .primaryColor)),
                                                    ),
                                                    const Icon(
                                                        Icons.arrow_right)
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ),
                    ],
                  )
                : useList
                    ? ImplicitlyAnimatedList<User>(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: scrollController,
                        items: userList,
                        areItemsTheSame: (a, b) => a.id == b.id,
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top,
                            bottom: MediaQuery.of(context).padding.bottom),
                        itemBuilder: (context, animation, user, index) {
                          return SizeFadeTransition(
                              sizeFraction: 0.7,
                              curve: Curves.easeInOut,
                              animation: animation,
                              child: Row(
                                children: [
                                  Expanded(child: buildUserItem(user)),
                                ],
                              ));
                        },
                      )
                    : MasonryGridView.count(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: scrollController,
                        crossAxisCount: max(
                            2,
                            min(6, (MediaQuery.of(context).size.width) / 250)
                                .floor()),
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        itemCount: userList.length,
                        itemBuilder: (context, index) {
                          final user = userList[index];
                          return buildUserItem(user);
                        },
                      )),
      ),
    );
  }

  Widget buildUserItem(User user) {
    bool cannotFollow = appState.selectedAccount == null ||
        appState.selectedAccount?.userId == user.id;
    return Card(
      color: appState.selectedAccount?.id == user.id ? appState.navColor : null,
      child: InkWell(
        //    onTap: null, //TODO: Do we want to navigate the user somewhere?

        onTap: () {
          context.navigateNamedTo(
              'person/${JonlineServer.selectedServer.server}/${user.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        height: 48,
                        width: 48,
                        child: Icon(Icons.account_circle,
                            size: 32, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${JonlineServer.selectedServer.server}/',
                                      style: textTheme.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.username,
                                    style: textTheme.headline6?.copyWith(
                                        color:
                                            appState.selectedAccount?.userId ==
                                                    user.id
                                                ? appState.primaryColor
                                                : null),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (user.permissions.contains(Permission.ADMIN))
                        Tooltip(
                          message: "${user.username} is an admin",
                          child: const SizedBox(
                            height: 32,
                            width: 32,
                            child: Icon(Icons.admin_panel_settings_outlined,
                                size: 24, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(
                                "User ID: ",
                                style: textTheme.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Expanded(
                                child: Text(
                                  user.id,
                                  style: textTheme.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                          child: SizedBox(
                              height: 32,
                              child: TextButton(
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all(
                                          const EdgeInsets.all(0))),
                                  onPressed: cannotFollow
                                      ? null
                                      : () {
                                          showSnackBar(
                                              "This isn't done yet 😔");
                                        },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add),
                                      Text("FOLLOW")
                                    ],
                                  ))))
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
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
