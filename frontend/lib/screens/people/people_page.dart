import 'dart:math';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/utils/moderation_accessors.dart';
import 'package:recase/recase.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/permissions.pb.dart';
import '../../generated/users.pb.dart';
import '../../generated/visibility_moderation.pbenum.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_operations.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../utils/colors.dart';
import 'person_preview.dart';
// import 'user_preview.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({Key? key}) : super(key: key);

  @override
  PeopleScreenState createState() => PeopleScreenState();
}

enum PeopleListingType {
  members,
  everyone,
  following,
  friends,
  followers,
  followRequests,
  membershipRequests,
}

extension PeopleUserListingType on PeopleListingType {
  UserListingType? get userListingType {
    switch (this) {
      case PeopleListingType.everyone:
        return UserListingType.EVERYONE;
      case PeopleListingType.following:
        return UserListingType.FOLLOWING;
      case PeopleListingType.friends:
        return UserListingType.FRIENDS;
      case PeopleListingType.followers:
        return UserListingType.FOLLOWERS;
      case PeopleListingType.followRequests:
        return UserListingType.FOLLOW_REQUESTS;
      // case PeopleListingType.membershipRequests:
      //   return UserListingType.MEMBERSHIP_REQUESTS;
      default:
        return null;
    }
  }
}

class PeopleListingResponse {
  final GetUsersResponse? users;
  final GetMembersResponse? members;

  PeopleListingResponse({
    this.users,
    this.members,
  });
}

class PeopleScreenState extends JonlineState<PeopleScreen>
    with AutoRouteAwareStateMixin<PeopleScreen> {
  PeopleListingType listingType = PeopleListingType.everyone;
  Map<PeopleListingType, PeopleListingResponse> listingData = {};
  ScrollController listScrollController = ScrollController();
  ScrollController gridScrollController = ScrollController();
  ScrollController emptyScrollController = ScrollController();
  ScrollController sectionScrollController = ScrollController();

  bool get useList => mq.size.width < 450;
  double get headerHeight => 48 * mq.textScaleFactor;
  @override
  void didPushNext() {
    // print('didPushNext');
  }

  @override
  void initState() {
    // print("UserListPage.initState");
    super.initState();
    appState.accounts.addListener(updateState);
    for (var n in [
      appState.users,
      appState.updatingUsers,
      appState.errorUpdatingUsers,
      appState.didUpdateUsers
    ]) {
      n.addListener(updateState);
    }
    appState.selectedGroup.addListener(resetMembers);
    appState.selectedAccountChanged.addListener(hardResetMembers);
    // appState.selectedGroup.addListener(updateState);

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
      appState.errorUpdatingUsers,
      appState.didUpdateUsers
    ]) {
      n.removeListener(updateState);
    }
    appState.selectedGroup.removeListener(resetMembers);
    appState.selectedAccountChanged.removeListener(hardResetMembers);
    // appState.selectedGroup.addListener(updateState);

    homePage.scrollToTop.removeListener(scrollToTop);
    homePage.peopleSearch.removeListener(updateState);
    homePage.peopleSearchController.removeListener(updateState);
    listScrollController.dispose();
    gridScrollController.dispose();
    emptyScrollController.dispose();
    sectionScrollController.dispose();
    super.dispose();
  }

  updateState() {
    setState(() {});
  }

  scrollToTop() {
    ScrollController scrollController =
        useList ? listScrollController : gridScrollController;
    if (context.topRoute.name == 'PeopleRoute') {
      if (scrollController.offset > 0) {
        scrollController.animateTo(0,
            duration: animationDuration, curve: Curves.easeInOut);
      } else {
        setState(() {
          listingType = viewingGroup
              ? PeopleListingType.members
              : PeopleListingType.everyone;
          sectionScrollController.animateTo(0,
              duration: animationDuration, curve: Curves.easeInOut);
        });
      }
    }
  }

  bool get viewingGroup => appState.viewingGroup;
  bool get canShowMembershipRequests {
    final group = appState.selectedGroup.value;
    if (group == null) return false;
    return (appState.selectedAccount?.permissions.contains(Permission.ADMIN) ??
            false) ||
        group.currentUserMembership.permissions.any(
            (p) => [Permission.ADMIN, Permission.MODERATE_USERS].contains(p));
  }

  String get people => viewingGroup
      ? listingType == PeopleListingType.membershipRequests
          ? "Membership Requests"
          : "Members"
      : "People";

  hardResetMembers() async => await resetMembers(hard: true);

  resetMembers({bool hard = false}) async {
    // print("resetMembers");
    appState.updatingUsers.value = true;
    adaptToInvariants();
    if (hard) {
      setState(() {
        listingData = {};
      });
    }
    await updateMembers();
  }

  updateMembers({PeopleListingType? customListingType}) async {
    if (customListingType == null) {
      appState.updatingUsers.value = true;
    }
    final listingType = customListingType ?? this.listingType;
    final selectedGroup = appState.selectedGroup.value;
    if (selectedGroup == null) {
      return;
    }
    final request = listingType == PeopleListingType.membershipRequests
        ? GetMembersRequest(
            groupId: selectedGroup.id, groupModeration: Moderation.PENDING)
        : GetMembersRequest(
            groupId: selectedGroup.id,
          );
    final GetMembersResponse? response = await JonlineOperations.getMembers(
      request: request,
    );
    if (response == null) {
      setState(() {
        appState.errorUpdatingUsers.value = true;
        appState.updatingUsers.value = false;
        // showSnackBar
      });
      if (customListingType == null) {
        updateOtherMembers();
      }
      return;
    }
    if (customListingType == null) {
      appState.didUpdateUsers.value = true;
      appState.didUpdateUsers.value = true;
    }
    setState(() {
      if (customListingType == null) {
        appState.updatingUsers.value = false;
      }
      listingData[listingType] = PeopleListingResponse(members: response);
      // print("Set state: ${response.members.length}");
    });

    if (customListingType == null) {
      appState.didUpdateUsers.value = false;
      updateOtherMembers();
    }
  }

  updateOtherMembers() {
    if (listingType == PeopleListingType.membershipRequests) {
      updateMembers(customListingType: PeopleListingType.members);
    } else {
      updateMembers(customListingType: PeopleListingType.membershipRequests);
    }
  }

  List<Person> get userList {
    List<Person> result = appState.users.value.map((p) => Person(p)).toList();
    switch (listingType) {
      case PeopleListingType.membershipRequests:
      case PeopleListingType.members:
        // print("userList");
        result = listingData[listingType]
                ?.members
                ?.members
                .map((e) => Person(e.user, membership: e.membership))
                .toList() ??
            [];
        // result = [];
        break;
      case PeopleListingType.everyone:
        // The cached data (appState.users.value) is fine.
        break;
      case PeopleListingType.following:
        result = result.where((p) => p.user.following).toList();
        break;
      case PeopleListingType.friends:
        result = result.where((p) => p.user.friends).toList();
        break;
      case PeopleListingType.followers:
        result = result.where((p) => p.user.followsYou).toList();
        break;
      case PeopleListingType.followRequests:
        result = result.where((p) => p.user.wantsToFollowYou).toList();
        break;
      // default:
      // result = appState.users.value;
    }
    if (homePage.peopleSearch.value &&
        homePage.peopleSearchController.text != '') {
      result = result.where((person) {
        return person.user.username
            .toLowerCase()
            .contains(homePage.peopleSearchController.text.toLowerCase());
      }).toList();
    }
    return result;
  }

  adaptToInvariants() {
    if (!viewingGroup && listingType.userListingType == null) {
      listingType = PeopleListingType.everyone;
    } else if (viewingGroup && listingType.userListingType != null) {
      listingType = PeopleListingType.members;
      // resetMembers();
    }

    if (!JonlineAccount.loggedIn) {
      listingType =
          viewingGroup ? PeopleListingType.members : PeopleListingType.everyone;
    }
    if (listingType == PeopleListingType.membershipRequests &&
        !canShowMembershipRequests) {
      listingType = PeopleListingType.members;
    }
  }

  @override
  Widget build(BuildContext context) {
    adaptToInvariants();
    List<Person> userList = this.userList;
    return Scaffold(
      // appBar: ,
      body: Stack(
        children: [
          RefreshIndicator(
            displacement: mq.padding.top + 40,
            onRefresh: () async {
              if (viewingGroup) {
                await updateMembers();
              } else {
                await appState.updateUsers(showMessage: showSnackBar);
              }
            },
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
                child: Stack(
                  children: [
                    useList
                        ? ImplicitlyAnimatedList<Person>(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: listScrollController,
                            items: userList,
                            areItemsTheSame: (a, b) => a.user.id == b.user.id,
                            padding: EdgeInsets.only(
                                top: mq.padding.top + headerHeight,
                                bottom: mq.padding.bottom + 48),
                            itemBuilder: (context, animation, person, index) {
                              return SizeFadeTransition(
                                  sizeFraction: 0.7,
                                  curve: Curves.easeInOut,
                                  animation: animation,
                                  key: Key(
                                      "personPage-person-${JonlineServer.selectedServer.server}-${person.user.id}"),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: PersonPreview(
                                              person: person,
                                              server: JonlineServer
                                                  .selectedServer.server)),
                                    ],
                                  ));
                            },
                          )
                        : MasonryGridView.count(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: gridScrollController,
                            padding: EdgeInsets.only(
                                top: mq.padding.top + headerHeight,
                                bottom: mq.padding.bottom),
                            crossAxisCount: max(
                                2,
                                min(
                                        6,
                                        (MediaQuery.of(context).size.width) /
                                            270)
                                    .floor()),
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            itemCount: userList.length,
                            itemBuilder: (context, index) {
                              final person = userList[index];
                              return PersonPreview(
                                  key: Key(
                                      "personPage-person-griditem-${JonlineServer.selectedServer.server}-${person.user.id}"),
                                  person: person,
                                  server: JonlineServer.selectedServer.server);
                            },
                          ),
                    IgnorePointer(
                      ignoring: userList.isNotEmpty,
                      child: AnimatedOpacity(
                          opacity:
                              userList.isEmpty && appState.updatingUsers.value
                                  ? 1
                                  : appState.updatingUsers.value
                                      ? 0.7
                                      : 0,
                          duration: animationDuration,
                          child: buildLoadingView()),
                    ),
                    IgnorePointer(
                        ignoring: userList.isNotEmpty,
                        child: AnimatedOpacity(
                            opacity: userList.isEmpty &&
                                    !appState.updatingUsers.value
                                ? 1
                                : 0,
                            duration: animationDuration,
                            child: buildEmptyView())),
                  ],
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

  Widget buildLoadingView() {
    return Column(
      children: [
        Expanded(
            child: Column(
          children: [
            SizedBox(height: (MediaQuery.of(context).size.height - 200) / 2),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  children: [
                    Text("Loading $people...", style: textTheme.titleLarge),
                    Text(
                        "${JonlineServer.selectedServer.server}/${viewingGroup ? 'g/${appState.selectedGroup.value!.id}' : ''}",
                        style: textTheme.caption),
                    if (viewingGroup) Text(appState.selectedGroup.value!.name),
                  ],
                ),
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget buildEmptyView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: emptyScrollController,
              child: Column(
                children: [
                  SizedBox(
                      height: (MediaQuery.of(context).size.height - 200) / 2),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Column(
                        children: [
                          Text(
                              appState.errorUpdatingUsers.value
                                  ? "Error Loading $people"
                                  : "No $people",
                              style: textTheme.titleLarge),
                          Text(
                              "${JonlineServer.selectedServer.server}/${viewingGroup ? 'g/${appState.selectedGroup.value!.id}' : ''}",
                              style: textTheme.caption),
                          if (viewingGroup)
                            Text(appState.selectedGroup.value!.name),
                          if (!appState.updatingUsers.value &&
                              !appState.errorUpdatingUsers.value &&
                              appState.selectedAccount == null)
                            Column(
                              children: [
                                const SizedBox(height: 8),
                                TextButton(
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all(
                                          const EdgeInsets.all(16))),
                                  onPressed: () =>
                                      context.navigateNamedTo('/login'),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                            'Login/Create Account to see more People.',
                                            textAlign: TextAlign.center,
                                            style: textTheme.titleSmall
                                                ?.copyWith(
                                                    color:
                                                        appState.primaryColor)),
                                      ),
                                      const Icon(Icons.arrow_right)
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
    );
  }

  Widget buildSectionSelector() {
    final visibleSections = (!viewingGroup)
        ? [
            PeopleListingType.everyone,
            PeopleListingType.following,
            PeopleListingType.friends,
            PeopleListingType.followers,
            PeopleListingType.followRequests,
          ]
        : [
            PeopleListingType.members,
            PeopleListingType.membershipRequests,
          ];
    final sectionCount = visibleSections.length;
    final minSectionTabWidth = 110.0 * mq.textScaleFactor;
    final evenSectionWidth =
        (mq.size.width - homePage.sideNavPaddingWidth) / sectionCount;
    final visibleSectionWidth = max(minSectionTabWidth, evenSectionWidth);
    final selector = Row(
      children: [
        ...PeopleListingType.values
            // .where((l) => l != UserListingType.FRIENDS)
            .map((l) {
          bool usable = JonlineAccount.loggedIn ||
              l == PeopleListingType.everyone ||
              l == PeopleListingType.members;
          usable &= canShowMembershipRequests ||
              l != PeopleListingType.membershipRequests;
          var textButton = TextButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(l == listingType
                      ? appState.primaryColor.textColor.withOpacity(0.8)
                      : null)),
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
                    l.name.constantCase.replaceAll('_', '\n'),
                    style: TextStyle(
                        color: l == listingType
                            ? null
                            : usable
                                ? Colors.white
                                : Colors.grey),
                    maxLines: l.name.constantCase.contains('_') ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ));
          bool visible = visibleSections.contains(l);
          return AnimatedOpacity(
            duration: animationDuration,
            opacity: visible ? 1 : 0,
            child: AnimatedContainer(
                duration: animationDuration,
                width: visible ? visibleSectionWidth : 0,
                child: textButton),
          );
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
        user.currentUserFollow = follow;
        if (follow.targetUserModeration.passes) {
          user.followerCount += 1;
          appState.users.value.where((u) => u.id == user.id).forEach((u) {
            u.followerCount += 1;
          });
          JonlineAccount.selectedAccount?.user?.followingCount += 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followingCount += 1;
          });
        }
      });
      // showSnackBar('Followed ${user.username}.');
      showSnackBar(
          '${follow.targetUserModeration.pending ? "Requested to follow" : "Followed"} ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  unfollow(User user) async {
    final follow = user.currentUserFollow;
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!.deleteFollow(
          Follow(
            userId: JonlineAccount.selectedAccount!.userId,
            targetUserId: user.id,
          ),
          options: JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.currentUserFollow = Follow();
        if (follow.targetUserModeration.passes) {
          user.followerCount -= 1;
          appState.users.value.where((u) => u.id == user.id).forEach((u) {
            u.followerCount -= 1;
          });
          JonlineAccount.selectedAccount?.user?.followingCount -= 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followingCount -= 1;
          });
        }
      });
      showSnackBar(
          '${follow.targetUserModeration.pending ? "Canceled request to" : "Unfollowed"} ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  approve(User user) async {
    try {
      final follow = await (await JonlineAccount.selectedAccount!.getClient())!
          .updateFollow(
              Follow(
                  userId: user.id,
                  targetUserId: JonlineAccount.selectedAccount!.userId,
                  targetUserModeration: Moderation.APPROVED),
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.targetCurrentUserFollow = follow;
        if (follow.targetUserModeration.passes) {
          user.followingCount += 1;
          appState.users.value.where((u) => u.id == user.id).forEach((u) {
            u.followingCount += 1;
          });
          JonlineAccount.selectedAccount?.user?.followerCount += 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followerCount += 1;
          });
        }
      });
      showSnackBar('Approved request from ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  reject(User user) async {
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!.deleteFollow(
          Follow(
              userId: user.id,
              targetUserId: JonlineAccount.selectedAccount!.userId),
          options: JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.targetCurrentUserFollow = Follow();
      });
      showSnackBar('Rejected request from ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
