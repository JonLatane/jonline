import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/utils/enum_conversions.dart';

import '../../app_state.dart';
import '../../models/jonline_account.dart';
import '../../models/server_errors.dart';
import '../../utils/colors.dart';
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

  follow(User user) async {
    try {
      final follow = await (await JonlineAccount.selectedAccount!.getClient())!
          .createFollow(
              Follow(
                userId: JonlineAccount.selectedAccount!.userId,
                targetUserId: user.id,
              ),
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.followRelationship = follow;
        if (follow.targetUserModeration.passes) {
          user.followerCount += 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followingCount += 1;
          });
        }
      });
      showSnackBar('Followed ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  unfollow(User user) async {
    final follow = user.followRelationship;
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!.deleteFollow(
          Follow(
            userId: JonlineAccount.selectedAccount!.userId,
            targetUserId: user.id,
          ),
          options: JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.followRelationship = Follow();
        if (follow.targetUserModeration.passes) {
          user.followerCount -= 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followingCount -= 1;
          });
        }
      });
      showSnackBar('Unfollowed ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  Widget buildUserItem(User user) {
    bool following = user.followRelationship.targetUserModeration.passes;
    bool pending_request = user.followRelationship.targetUserModeration.pending;
    bool cannotFollow = appState.selectedAccount == null ||
        appState.selectedAccount?.userId == user.id;
    final backgroundColor =
        appState.selectedAccount?.userId == user.id ? appState.navColor : null;
    final textColor = backgroundColor?.textColor;
    return Card(
      // color: Colors.blue,
      color: backgroundColor,
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
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: Icon(Icons.account_circle,
                            size: 32, color: textColor ?? Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${JonlineServer.selectedServer.server}/',
                                      style: textTheme.caption?.copyWith(
                                          color: textColor?.withOpacity(0.5)),
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
                                    style: textTheme.headline6
                                        ?.copyWith(color: textColor),
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
                          child: SizedBox(
                            height: 32,
                            width: 32,
                            child: Icon(Icons.admin_panel_settings_outlined,
                                size: 24, color: textColor ?? Colors.white),
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
                              // Text(
                              //   "User ID: ",
                              //   style: textTheme.caption?.copyWith(
                              //       color: textColor?.withOpacity(0.5)),
                              //   maxLines: 1,
                              //   overflow: TextOverflow.ellipsis,
                              // ),
                              // Expanded(
                              //   child: Text(
                              //     user.id,
                              //     style: textTheme.caption?.copyWith(
                              //         color: textColor?.withOpacity(0.5)),
                              //     maxLines: 1,
                              //     overflow: TextOverflow.ellipsis,
                              //   ),
                              // ),
                              // const Icon(
                              //   Icons.account_circle,
                              //   color: Colors.white,
                              // ),
                              // const SizedBox(width: 4),
                              Text(user.followerCount.toString(),
                                  style: textTheme.caption?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                              Text(
                                  " follower${user.followerCount == 1 ? '' : 's'}",
                                  style: textTheme.caption?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                              const Expanded(child: SizedBox()),
                              Text("following ${user.followingCount}",
                                  style: textTheme.caption?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      IgnorePointer(
                        ignoring: !(following || pending_request),
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: following || pending_request ? 1 : 0,
                          child: Row(children: [
                            Expanded(
                                child: SizedBox(
                                    height: 32,
                                    child: TextButton(
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.all(0))),
                                        onPressed: () => unfollow(user),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                                Icons.remove_circle_outline),
                                            const SizedBox(width: 4),
                                            Text(pending_request
                                                ? "CANCEL REQUEST"
                                                : "UNFOLLOW")
                                          ],
                                        ))))
                          ]),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: (following || pending_request),
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: !(following || pending_request) ? 1 : 0,
                          child: Row(children: [
                            Expanded(
                                child: SizedBox(
                                    height: 32,
                                    child: TextButton(
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.all(0))),
                                        onPressed: cannotFollow
                                            ? null
                                            : () => follow(user),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.add),
                                            const SizedBox(width: 4),
                                            Text(user.defaultFollowModeration
                                                    .pending
                                                ? "REQUEST"
                                                : "FOLLOW")
                                          ],
                                        ))))
                          ]),
                        ),
                      )
                    ],
                  ),
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
