import 'dart:math';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/screens/groups/group_preview.dart';
import 'package:jonline/utils/colors.dart';
import 'package:jonline/utils/enum_conversions.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  GroupsScreenState createState() => GroupsScreenState();
}

class GroupsScreenState extends JonlineState<GroupsScreen>
    with AutoRouteAwareStateMixin<GroupsScreen> {
  GroupListingType listingType = GroupListingType.ALL_GROUPS;
  Map<GroupListingType, GetGroupsResponse> listingData = {};
  ScrollController scrollController = ScrollController();
  bool get useList => mq.size.width < 450;
  double get headerHeight => 48 * mq.textScaleFactor;

  @override
  void didPushNext() {
    // print('didPushNext');
  }

  @override
  void initState() {
    // print("GroupListPage.initState");
    super.initState();
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

  List<Group> get groupList {
    List<Group> result = appState.groups.value;
    switch (listingType) {
      case GroupListingType.ALL_GROUPS:
        break;
      case GroupListingType.MY_GROUPS:
        result = result
            .where((u) =>
                u.currentUserMembership.groupModeration.passes &&
                u.currentUserMembership.userModeration.passes)
            .toList();
        break;
      case GroupListingType.REQUESTED:
        result = result
            .where((u) =>
                u.currentUserMembership.groupModeration.pending &&
                u.currentUserMembership.userModeration.passes)
            .toList();
        break;
      case GroupListingType.INVITED:
        result = result
            .where((u) => u.currentUserMembership.userModeration.pending)
            .toList();
        break;
    }
    if (homePage.peopleSearch.value &&
        homePage.peopleSearchController.text != '') {
      result = result.where((group) {
        return group.name
            .toLowerCase()
            .contains(homePage.peopleSearchController.text.toLowerCase());
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (!JonlineAccount.loggedIn) {
      listingType = GroupListingType.ALL_GROUPS;
    }
    return Scaffold(
      // appBar: ,
      body: Stack(
        children: [
          RefreshIndicator(
            displacement: mq.padding.top + 40,
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
                                            maxWidth: 250 * mq.textScaleFactor),
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
                                top: mq.padding.top + headerHeight,
                                bottom: mq.padding.bottom),
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
                                top: mq.padding.top + headerHeight,
                                bottom: mq.padding.bottom),
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
                            height: mq.padding.top,
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
    final visibleSections = [
      GroupListingType.ALL_GROUPS,
      GroupListingType.MY_GROUPS,
      GroupListingType.REQUESTED
    ];
    final sectionCount = visibleSections.length;
    final minSectionTabWidth = 110.0 * mq.textScaleFactor;
    final evenSectionWidth =
        (mq.size.width - homePage.sideNavPaddingWidth) / sectionCount;
    final visibleSectionWidth = max(minSectionTabWidth, evenSectionWidth);
    final selector = Row(
      children: [
        ...GroupListingType.values.map((l) {
          var usable =
              JonlineAccount.loggedIn || l == GroupListingType.ALL_GROUPS;

          var textButton = TextButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(l == listingType
                      ? appState.primaryColor.textColor
                      : null)),
              // bac: ,
              onPressed: usable
                  ? () {
                      setState(() {
                        listingType = l;
                      });
                    }
                  : null,
              child: Column(
                children: [
                  const Expanded(child: SizedBox()),
                  Text(
                    l.name.replaceAll('_', '\n'),
                    style: TextStyle(
                        color: l == listingType
                            ? null
                            : usable
                                ? Colors.white
                                : Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ));
          return AnimatedContainer(
              duration: animationDuration,
              width: visibleSectionWidth,
              child: textButton);
        })
        // const SizedBox(width: 8)
      ],
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: selector,
    );
  }

  Widget buildGroupItem(Group group) {
    return GroupPreview(
        server: JonlineServer.selectedServer.server, group: group);
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
