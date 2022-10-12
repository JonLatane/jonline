import 'dart:math';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/screens/groups/group_details_page.dart';
import 'package:jonline/utils/colors.dart';
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
  TextTheme get textTheme => Theme.of(context).textTheme;
  MediaQueryData get mq => MediaQuery.of(context);

  GroupListingType listingType = GroupListingType.ALL_GROUPS;
  Map<GroupListingType, GetGroupsResponse> listingData = {};
  ScrollController scrollController = ScrollController();
  bool get useList => MediaQuery.of(context).size.width < 450;
  double get headerHeight => 48 * MediaQuery.of(context).textScaleFactor;

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
      body: Stack(
        children: [
          RefreshIndicator(
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
                                        height: (MediaQuery.of(context)
                                                    .size
                                                    .height -
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
                                                    : appState
                                                            .errorUpdatingGroups
                                                            .value
                                                        ? "Error Loading Groups"
                                                        : "No Groups",
                                                style: textTheme.titleLarge),
                                            Text(
                                                JonlineServer
                                                    .selectedServer.server,
                                                style: textTheme.caption),
                                            if (!appState
                                                    .updatingGroups.value &&
                                                !appState.errorUpdatingGroups
                                                    .value &&
                                                appState.selectedAccount ==
                                                    null)
                                              Column(
                                                children: [
                                                  const SizedBox(height: 8),
                                                  TextButton(
                                                    style: ButtonStyle(
                                                        padding:
                                                            MaterialStateProperty.all(
                                                                const EdgeInsets
                                                                    .all(16))),
                                                    onPressed: () =>
                                                        context.navigateNamedTo(
                                                            '/login'),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                              'Login/Create Account to see/create more Groups.',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
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
                                top: MediaQuery.of(context).padding.top +
                                    headerHeight,
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
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top +
                                    headerHeight,
                                bottom: MediaQuery.of(context).padding.bottom),
                            crossAxisCount: max(
                                2,
                                min(
                                        6,
                                        (MediaQuery.of(context).size.width) /
                                            300)
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
          Column(
            children: [
              ClipRRect(
                  child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            height: MediaQuery.of(context).padding.top,
                            color:
                                Theme.of(context).canvasColor.withOpacity(0.5),
                          ),
                          Container(
                            height: headerHeight,
                            color:
                                Theme.of(context).canvasColor.withOpacity(0.5),
                            child: buildSectionSelector(),
                          ),
                          Container(
                            height: 4,
                            color:
                                Theme.of(context).canvasColor.withOpacity(0.5),
                          ),
                        ],
                      ))),
            ],
          )
        ],
      ),
    );
  }

  Widget buildSectionSelector() {
    final sectionCount = GroupListingType.values.length;
    final minSectionTabWidth = 110.0 * mq.textScaleFactor;
    bool scrollSections =
        (mq.size.width / minSectionTabWidth) < sectionCount.toDouble();
    final selector = Row(
      children: [
        ...GroupListingType.values.map((e) {
          var textButton = TextButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(e == listingType
                      ? appState.primaryColor.textColor
                      : null)),
              // bac: ,
              onPressed: () {
                setState(() {
                  listingType = e;
                });
              },
              child: Column(
                children: [
                  const Expanded(child: SizedBox()),
                  Text(
                    e.name.replaceAll('_', '\n'),
                    style:
                        TextStyle(color: e == listingType ? null : Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ));
          if (!scrollSections) {
            return Expanded(
              child: textButton,
            );
          } else {
            return SizedBox(width: minSectionTabWidth, child: textButton);
          }
        })
        // const SizedBox(width: 8)
      ],
    );
    if (scrollSections) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: selector,
      );
    } else {
      return selector;
    }
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
      showSnackBar(
          '${group.defaultMembershipModeration.pending ? "Requested to join" : "Joined"} ${group.name}.');
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
      showSnackBar(
          '${membership.groupModeration.pending ? "Canceled request for" : "Left"} ${group.name}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  Widget buildGroupItem(Group group) {
    bool isMember = group.currentUserMembership.groupModeration.passes;
    bool invitePending = group.currentUserMembership.groupModeration.pending;
    bool canJoin = appState.selectedAccount != null;
    bool selected = appState.selectedGroup.value == group;
    final backgroundColor = selected ? appState.navColor : null;
    final textColor = backgroundColor?.textColor;
    return Card(
      color: backgroundColor,
      // color:
      //     appState.selectedAccount?.id == group.id ? appState.navColor : null,
      child: InkWell(
        onLongPress: () {
          if (selected) {
            appState.selectedGroup.value = null;
          } else {
            appState.selectedGroup.value = group;
          }
        },
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
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: Icon(Icons.group_work_outlined,
                            size: 32, color: textColor ?? Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${JonlineServer.selectedServer.server}/group/',
                                      style: textTheme.caption?.copyWith(
                                        color: textColor?.withOpacity(0.5),
                                      ),
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
                                      color: textColor,
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
                                style: textTheme.caption?.copyWith(
                                  color: textColor?.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Expanded(
                                child: Text(
                                  group.id,
                                  style: textTheme.caption?.copyWith(
                                    color: textColor?.withOpacity(0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.account_circle,
                          color: textColor ?? Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.memberCount.toString(),
                          style: textTheme.caption?.copyWith(
                            color: textColor?.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          " member${group.memberCount == 1 ? '' : 's'}",
                          style: textTheme.caption?.copyWith(
                            color: textColor?.withOpacity(0.5),
                          ),
                        ),
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
