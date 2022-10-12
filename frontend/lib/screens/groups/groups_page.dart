import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/screens/groups/group_details_page.dart';
import 'package:jonline/utils/enum_conversions.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  GroupsScreenState createState() => GroupsScreenState();
}

class GroupsScreenState extends State<GroupsScreen>
    with AutoRouteAwareStateMixin<GroupsScreen> {
  late AppState appState;
  late HomePageState homePage;

  ScrollController scrollController = ScrollController();

  @override
  void didPushNext() {
    // print('didPushNext');
  }

  @override
  void initState() {
    // print("GroupListPage.initState");
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    appState.accounts.addListener(updateState);
    for (var n in [
      appState.groups,
      appState.updatingGroups,
      appState.didUpdateGroups
    ]) {
      n.addListener(updateState);
    }
    homePage.scrollToTop.addListener(scrollToTop);
    homePage.groupsSearch.addListener(updateState);
    homePage.groupsSearchController.addListener(updateState);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("GroupListPage.dispose");
    appState.accounts.removeListener(updateState);
    for (var n in [
      appState.groups,
      appState.updatingGroups,
      appState.didUpdateGroups
    ]) {
      n.removeListener(updateState);
    }
    homePage.scrollToTop.removeListener(scrollToTop);
    homePage.groupsSearch.removeListener(updateState);
    homePage.groupsSearchController.removeListener(updateState);
    scrollController.dispose();
    super.dispose();
  }

  updateState() {
    setState(() {});
  }

  scrollToTop() {
    if (context.topRoute.name == 'GroupsRoute') {
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
    List<Group> groupList = appState.groups.value;
    if (homePage.groupsSearch.value &&
        homePage.groupsSearchController.text != '') {
      groupList = groupList.where((group) {
        return group.name
            .toLowerCase()
            .contains(homePage.groupsSearchController.text.toLowerCase());
      }).toList();
    }
    return Scaffold(
      // appBar: ,
      body: RefreshIndicator(
        displacement: MediaQuery.of(context).padding.top + 40,
        onRefresh: () async =>
            await appState.updateGroups(showMessage: showSnackBar),
        child: ScrollConfiguration(
            // key: Key("groupListScrollConfiguration-${groupList.length}"),
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: groupList.isEmpty && !appState.didUpdateGroups.value
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
                                    constraints: BoxConstraints(
                                        maxWidth: 250 *
                                            MediaQuery.of(context)
                                                .textScaleFactor),
                                    child: Column(
                                      children: [
                                        Text(
                                            appState.updatingGroups.value
                                                ? "Loading Groups..."
                                                : appState.errorUpdatingGroups
                                                        .value
                                                    ? "Error Loading Groups"
                                                    : "No Groups",
                                            style: textTheme.titleLarge),
                                        Text(
                                            JonlineServer.selectedServer.server,
                                            style: textTheme.caption),
                                        if (!appState.updatingGroups.value &&
                                            !appState
                                                .errorUpdatingGroups.value &&
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
                                                          'Login/Create Account to see/create more Groups.',
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
                    ? ImplicitlyAnimatedList<Group>(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: scrollController,
                        items: groupList,
                        areItemsTheSame: (a, b) => a.id == b.id,
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top,
                            bottom: MediaQuery.of(context).padding.bottom),
                        itemBuilder: (context, animation, group, index) {
                          return SizeFadeTransition(
                              sizeFraction: 0.7,
                              curve: Curves.easeInOut,
                              animation: animation,
                              child: Row(
                                children: [
                                  Expanded(child: buildGroupItem(group)),
                                ],
                              ));
                        },
                      )
                    : MasonryGridView.count(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: scrollController,
                        crossAxisCount: max(
                            2,
                            min(6, (MediaQuery.of(context).size.width) / 300)
                                .floor()),
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        itemCount: groupList.length,
                        itemBuilder: (context, index) {
                          final group = groupList[index];
                          return buildGroupItem(group);
                        },
                      )),
      ),
    );
  }

  joinGroup(Group group) async {
    try {
      final membership =
          await (await JonlineAccount.selectedAccount!.getClient())!
              .createMembership(
                  Membership(
                    userId: JonlineAccount.selectedAccount!.userId,
                    groupId: group.id,
                  ),
                  options:
                      JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        group.currentUserMembership = membership;
        if (membership.groupModeration.passes &&
            membership.userModeration.passes) {
          group.memberCount += 1;
        }
      });
      showSnackBar('Joined ${group.name}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  leaveGroup(Group group) async {
    final membership = group.currentUserMembership;
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!
          .deleteMembership(
              Membership(
                userId: JonlineAccount.selectedAccount!.userId,
                groupId: group.id,
              ),
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        group.currentUserMembership = Membership();

        if (membership.groupModeration.passes &&
            membership.userModeration.passes) {
          group.memberCount -= 1;
        }
      });
      showSnackBar('Left ${group.name}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  Widget buildGroupItem(Group group) {
    bool isMember = group.currentUserMembership.groupModeration.passes;
    bool invitePending = group.currentUserMembership.groupModeration.pending;
    bool canJoin = appState.selectedAccount != null;
    return Card(
      // color:
      //     appState.selectedAccount?.id == group.id ? appState.navColor : null,
      child: InkWell(
        onTap: () {
          context.navigateTo(GroupDetailsRoute(
              groupId: group.id, server: JonlineServer.selectedServer.server));
        }, //TODO: Do we want to navigate the group somewhere?
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
                        child: Icon(Icons.group_work_outlined,
                            size: 32, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${JonlineServer.selectedServer.server}/group/',
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
                                    group.name,
                                    style: textTheme.headline6?.copyWith(
                                        /*color:
                                            appState.selectedAccount?.groupId ==
                                                    group.id
                                                ? appState.primaryColor
                                                : null*/
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                                "Group ID: ",
                                style: textTheme.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Expanded(
                                child: Text(
                                  group.id,
                                  style: textTheme.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(group.memberCount.toString(),
                            style: textTheme.caption),
                        Text(" member${group.memberCount == 1 ? '' : 's'}",
                            style: textTheme.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      IgnorePointer(
                        ignoring: !(isMember || invitePending),
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: isMember || invitePending ? 1 : 0,
                          child: Row(children: [
                            Expanded(
                                child: SizedBox(
                                    height: 32,
                                    child: TextButton(
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.all(0))),
                                        onPressed: () => leaveGroup(group),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                                Icons.remove_circle_outline),
                                            const SizedBox(width: 4),
                                            Text(invitePending
                                                ? "CANCEL REQUEST"
                                                : "LEAVE")
                                          ],
                                        ))))
                          ]),
                        ),
                      ),
                      IgnorePointer(
                          ignoring: (isMember || invitePending),
                          child: AnimatedOpacity(
                              duration: animationDuration,
                              opacity: !(isMember || invitePending) ? 1 : 0,
                              child: Row(children: [
                                Expanded(
                                    child: SizedBox(
                                        height: 32,
                                        child: TextButton(
                                            style: ButtonStyle(
                                                padding:
                                                    MaterialStateProperty.all(
                                                        const EdgeInsets.all(
                                                            0))),
                                            onPressed: canJoin
                                                ? () => joinGroup(group)
                                                : null,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.add),
                                                const SizedBox(width: 4),
                                                Text(group
                                                        .defaultMembershipModeration
                                                        .pending
                                                    ? "REQUEST"
                                                    : "JOIN")
                                              ],
                                            ))))
                              ]))),
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
