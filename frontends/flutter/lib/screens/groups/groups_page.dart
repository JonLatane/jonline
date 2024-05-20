import 'dart:math';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/screens/groups/group_preview.dart';
import 'package:jonline/utils/colors.dart';
import 'package:jonline/utils/moderation_accessors.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';
import '../../router/router.gr.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  GroupsScreenState createState() => GroupsScreenState();
}

class GroupsScreenState extends JonlineState<GroupsScreen>
    with AutoRouteAwareStateMixin<GroupsScreen> {
  GroupListingType listingType = GroupListingType.ALL_GROUPS;
  Map<GroupListingType, GetGroupsResponse> listingData = {};
  ScrollController listScrollController = ScrollController();
  ScrollController gridScrollController = ScrollController();
  ScrollController emptyScrollController = ScrollController();
  ScrollController sectionScrollController = ScrollController();

  bool get useList => mq.size.width < 450;
  double get headerHeight => 40 * mq.textScaleFactor;

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
    gridScrollController.dispose();
    listScrollController.dispose();
    emptyScrollController.dispose();
    sectionScrollController.dispose();

    super.dispose();
  }

  updateState() {
    setState(() {});
  }

  scrollToTop() {
    if (context.topRoute.name == GroupsRoute.name) {
      final scrollController =
          useList ? listScrollController : gridScrollController;
      if (scrollController.offset > 0) {
        scrollController.animateTo(0,
            duration: animationDuration, curve: Curves.easeInOut);
      } else {
        setState(() {
          listingType = GroupListingType.ALL_GROUPS;
        });
        sectionScrollController.animateTo(0,
            duration: animationDuration, curve: Curves.easeInOut);
      }
    }
  }

  List<Group> get groupList {
    List<Group> result = appState.groups.value;
    switch (listingType) {
      case GroupListingType.ALL_GROUPS:
        break;
      case GroupListingType.MY_GROUPS:
        result = result.where((g) => g.member).toList();
        break;
      case GroupListingType.REQUESTED_GROUPS:
        result = result.where((g) => g.requested).toList();
        break;
      case GroupListingType.INVITED_GROUPS:
        result = result.where((g) => g.invited).toList();
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
                                controller: emptyScrollController,
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
                                                style: textTheme.bodySmall),
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
                                                            WidgetStateProperty.all(
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
                            controller: listScrollController,
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
                                  key: Key(
                                      "groupsPage-group-${JonlineServer.selectedServer.server}-${group.id}"),
                                  child: Row(
                                    children: [
                                      Expanded(child: buildGroupItem(group)),
                                    ],
                                  ));
                            },
                          )
                        : MasonryGridView.count(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: gridScrollController,
                            padding: EdgeInsets.only(
                                top: mq.padding.top + headerHeight,
                                bottom: mq.padding.bottom + 48),
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
              SizedBox(
                height: mq.padding.top,
              ),
              ClipRRect(
                  child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  height: headerHeight,
                  color: Theme.of(context).canvasColor.withOpacity(0.5),
                  child: buildSectionSelector(),
                ),
              )),
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
      GroupListingType.REQUESTED_GROUPS
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
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  backgroundColor: WidgetStateProperty.all(l == listingType
                      ? appState.primaryColor.textColor.withOpacity(0.8)
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
                        // fontWeight: FontWeight.w200,
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
      controller: sectionScrollController,
      scrollDirection: Axis.horizontal,
      child: selector,
    );
  }

  Widget buildGroupItem(Group group) {
    return GroupPreview(
        key: Key(
            "groupsPage-group-item-${JonlineServer.selectedServer.server}-${group.id}"),
        server: JonlineServer.selectedServer.server,
        group: group);
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
