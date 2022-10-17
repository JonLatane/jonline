import 'dart:math';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/utils/colors.dart';
import 'package:recase/recase.dart';

import '../../app_state.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';
import '../../router/router.gr.dart';
import 'post_preview.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({Key? key}) : super(key: key);

  @override
  PostsScreenState createState() => PostsScreenState();
}

class PostsScreenState extends JonlineState<PostsScreen>
    with AutoRouteAwareStateMixin<PostsScreen> {
  ScrollController scrollController = ScrollController();
  ScrollController emptyScrollController = ScrollController();
  PostListingType get listingType => appState.posts.listingType;
  set listingType(PostListingType value) => appState.posts.listingType = value;

  @override
  void didPushNext() {
    // print('didPushNext');
  }

  @override
  void initState() {
    // print("PostsPage.initState");
    super.initState();
    appState.accounts.addListener(updateState);
    appState.posts.addStatusListener(updateState);
    appState.selectedGroup.addListener(updateState);
    homePage.scrollToTop.addListener(scrollToTop);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("PostsPage.dispose");
    appState.accounts.removeListener(updateState);
    appState.posts.removeStatusListener(updateState);
    appState.selectedGroup.removeListener(updateState);
    homePage.scrollToTop.removeListener(scrollToTop);
    scrollController.dispose();
    super.dispose();
  }

  updateState() {
    setState(() {});
  }

  scrollToTop() {
    if (context.topRoute.name == 'PostsRoute') {
      scrollController.animateTo(0,
          duration: animationDuration, curve: Curves.easeInOut);
      // gridScrollController.animateTo(0,
      //     duration: animationDuration, curve: Curves.easeInOut);
    }
  }

  bool get useList => mq.size.width < 450;
  double get headerHeight => 48 * mq.textScaleFactor;
  bool get viewingGroup => appState.viewingGroup;

  List<Permission> get permissions =>
      appState.selectedAccount?.permissions ?? [];
  bool get canShowPendingModeration =>
      !viewingGroup && permissions.contains(Permission.MODERATE_POSTS);
  List<Permission> get groupPermissions =>
      appState.selectedGroup.value?.currentUserMembership.permissions ?? [];
  bool get canShowGroupPendingModeration =>
      viewingGroup && groupPermissions.contains(Permission.MODERATE_POSTS);
  adaptToInvariants() {
    final initialListingType = listingType;
    if (!viewingGroup &&
        [
          PostListingType.GROUP_POSTS,
          PostListingType.GROUP_POSTS_PENDING_MODERATION
        ].contains(listingType)) {
      listingType = PostListingType.PUBLIC_POSTS;
    } else if (viewingGroup &&
        ![
          PostListingType.GROUP_POSTS,
          PostListingType.GROUP_POSTS_PENDING_MODERATION
        ].contains(listingType)) {
      listingType = PostListingType.GROUP_POSTS;
      // resetMembers();
    }

    if (!JonlineAccount.loggedIn) {
      listingType = viewingGroup
          ? PostListingType.GROUP_POSTS
          : PostListingType.PUBLIC_POSTS;
    }
    if (listingType == PostListingType.GROUP_POSTS_PENDING_MODERATION &&
        !canShowGroupPendingModeration) {
      listingType = PostListingType.GROUP_POSTS;
    }
    if (listingType == PostListingType.POSTS_PENDING_MODERATION &&
        !canShowPendingModeration) {
      listingType = PostListingType.PUBLIC_POSTS;
    }
    if (listingType != initialListingType) {
      appState.posts.update();
    }
  }

  List<Post> get postList => appState.posts.value.posts;

  @override
  Widget build(BuildContext context) {
    adaptToInvariants();
    final List<Post> postList = appState.posts.value.posts;
    return Scaffold(
      // appBar: ,
      body: Stack(
        children: [
          RefreshIndicator(
            displacement: mq.padding.top + 40,
            onRefresh: () async =>
                await appState.posts.update(showMessage: showSnackBar),
            child: ScrollConfiguration(
                // key: Key("postListScrollConfiguration-${postList.length}"),
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
                        ? ImplicitlyAnimatedList<Post>(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: scrollController,
                            // controller: PrimaryScrollController.of(context),
                            // The current items in the list.
                            items: postList,

                            // Called by the DiffUtil to decide whether two object represent the same item.
                            // For example, if your items have unique ids, this method should check their id equality.
                            areItemsTheSame: (a, b) => a.id == b.id,
                            padding: EdgeInsets.only(
                                top: mq.padding.top + headerHeight,
                                bottom: mq.padding.bottom + 48),
                            // Called, as needed, to build list item widgets.
                            // List items are only built when they're scrolled into view.
                            itemBuilder: (context, animation, post, index) {
                              // Specifiy a transition to be used by the ImplicitlyAnimatedList.
                              // See the Transitions section on how to import this transition.
                              return SizeFadeTransition(
                                sizeFraction: 0.7,
                                curve: Curves.easeInOut,
                                animation: animation,
                                child: PostPreview(
                                  server: JonlineServer.selectedServer.server,
                                  onTap: () {
                                    context.pushRoute(PostDetailsRoute(
                                        postId: post.id,
                                        server: JonlineServer
                                            .selectedServer.server));
                                  },
                                  post: post,
                                ),
                              );
                            },
                          )
                        : MasonryGridView.count(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: scrollController,
                            padding: EdgeInsets.only(
                                top: mq.padding.top + headerHeight,
                                bottom: mq.padding.bottom + 48),
                            crossAxisCount: max(
                                2,
                                min(
                                        6,
                                        (MediaQuery.of(context).size.width) /
                                            350)
                                    .floor()),
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            itemCount: postList.length,
                            itemBuilder: (context, index) {
                              final post = postList[index];
                              return PostPreview(
                                server: JonlineServer.selectedServer.server,
                                maxContentHeight: 400,
                                onTap: () {
                                  context.pushRoute(PostDetailsRoute(
                                      postId: post.id,
                                      server:
                                          JonlineServer.selectedServer.server));
                                },
                                post: post,
                              );
                            },
                          ),
                    IgnorePointer(
                        ignoring: postList.isNotEmpty,
                        child: AnimatedOpacity(
                            opacity: postList.isEmpty && appState.posts.updating
                                ? 1
                                : appState.posts.updating
                                    ? 0.7
                                    : 0,
                            duration: animationDuration,
                            child: buildLoadingView())),
                    IgnorePointer(
                        ignoring: postList.isNotEmpty,
                        child: AnimatedOpacity(
                            opacity:
                                postList.isEmpty && !appState.posts.updating
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
        AnimatedContainer(
            duration: animationDuration,
            height: appState.posts.updating
                ? (MediaQuery.of(context).size.height - 200) / 2
                : 120),
        Center(
          child: AnimatedContainer(
            duration: animationDuration,
            // color: Colors.black.withOpacity(0.6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(postList.isEmpty ? 0 : 0.6),
                borderRadius: BorderRadius.circular(8)),
            constraints: const BoxConstraints(maxWidth: 350),
            child: Column(
              children: [
                Text("Loading Posts...", style: textTheme.titleLarge),
                Text(
                    "${JonlineServer.selectedServer.server}/${viewingGroup ? 'g/${appState.selectedGroup.value!.id}' : ''}",
                    style: textTheme.caption),
                if (viewingGroup) Text(appState.selectedGroup.value!.name),
              ],
            ),
          ),
        ),
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
                                  ? "Error Loading Posts"
                                  : "No Posts",
                              style: textTheme.titleLarge),
                          Text(
                              "${JonlineServer.selectedServer.server}/${viewingGroup ? 'g/${appState.selectedGroup.value!.id}' : ''}",
                              style: textTheme.caption),
                          if (viewingGroup)
                            Text(appState.selectedGroup.value!.name),
                          if (!appState.posts.updating &&
                              !appState.posts.errorUpdating &&
                              !appState.loggedIn)
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
                                            'Login/Create Account to see more Posts.',
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
  // bool get canShowPostRequests {
  //   final group = appState.selectedGroup.value;
  //   if (group == null) return false;
  //   return (appState.selectedAccount?.permissions.contains(Permission.ADMIN) ??
  //           false) ||
  //       group.currentUserMembership.permissions.any(
  //           (p) => [Permission.ADMIN, Permission.MODERATE_USERS].contains(p));
  // }

  Widget buildSectionSelector() {
    final visibleSections = (!appState.viewingGroup)
        ? [
            PostListingType.PUBLIC_POSTS,
            PostListingType.FOLLOWING_POSTS,
            PostListingType.MY_GROUPS_POSTS,
            // PostListingType.DIRECT_POSTS,
          ]
        : [
            PostListingType.GROUP_POSTS,
            PostListingType.GROUP_POSTS_PENDING_MODERATION,
          ];
    final sectionCount = visibleSections.length;
    final minSectionTabWidth = 110.0 * mq.textScaleFactor;
    final evenSectionWidth =
        (mq.size.width - homePage.sideNavPaddingWidth) / sectionCount;
    final visibleSectionWidth = max(minSectionTabWidth, evenSectionWidth);
    final selector = Row(
      children: [
        ...[
          PostListingType.GROUP_POSTS,
          PostListingType.PUBLIC_POSTS,
          PostListingType.FOLLOWING_POSTS,
          PostListingType.MY_GROUPS_POSTS,
          PostListingType.DIRECT_POSTS,
          PostListingType.GROUP_POSTS_PENDING_MODERATION
        ]
            // .where((l) => l != UserListingType.FRIENDS)
            .map((l) {
          bool usable =
              JonlineAccount.loggedIn || l == PostListingType.PUBLIC_POSTS;
          ;
          // usable &= canShowMembershipRequests ||
          //     l != PostListingType.membershipRequests;
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
                    l.name == "GROUP_POSTS"
                        ? "GROUP POSTS"
                        : (l.name == "GROUP_POSTS_PENDING_MODERATION"
                            ? "PENDING MODERATION"
                            : l.name.constantCase
                                .replaceAll('_POSTS', '')
                                .replaceAll('_', ' ')),
                    style: TextStyle(
                        color: l == listingType
                            ? null
                            : usable
                                ? Colors.white
                                : Colors.grey),
                    maxLines: 1,
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
      scrollDirection: Axis.horizontal,
      child: selector,
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
