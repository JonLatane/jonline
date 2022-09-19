import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';
import 'post_preview.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);

  @override
  PostListScreenState createState() => PostListScreenState();
}

class PostListScreenState extends State<PostListScreen>
    with AutoRouteAwareStateMixin<PostListScreen> {
  late AppState appState;
  late HomePageState homePage;
  ScrollController scrollController = ScrollController();

  @override
  void didPushNext() {
    // print('didPushNext');
  }

  @override
  void initState() {
    // print("PostListPage.initState");
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    appState.accounts.addListener(onAccountsChanged);
    appState.posts.addListener(onPostsUpdated);
    homePage.scrollToTop.addListener(scrollToTop);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("PostListPage.dispose");
    appState.accounts.removeListener(onAccountsChanged);
    appState.posts.removeListener(onPostsUpdated);
    homePage.scrollToTop.removeListener(scrollToTop);
    scrollController.dispose();
    super.dispose();
  }

  onAccountsChanged() {
    setState(() {});
  }

  onPostsUpdated() {
    setState(() {});
  }

  scrollToTop() {
    if (context.topRoute.name == 'PostListRoute') {
      scrollController.animateTo(0,
          duration: animationDuration, curve: Curves.easeInOut);
      // gridScrollController.animateTo(0,
      //     duration: animationDuration, curve: Curves.easeInOut);
    }
  }

  bool get useList => MediaQuery.of(context).size.width < 400;
  @override
  Widget build(BuildContext context) {
    final List<Post> postList = appState.posts.value.posts;
    return Scaffold(
      // appBar: ,
      body: RefreshIndicator(
        onRefresh: () async =>
            await appState.updatePosts(showMessage: showSnackBar),
        child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: useList
                ? ImplicitlyAnimatedList<Post>(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: scrollController,
                    // controller: PrimaryScrollController.of(context),
                    // The current items in the list.
                    items: postList,
                    // Called by the DiffUtil to decide whether two object represent the same item.
                    // For example, if your items have unique ids, this method should check their id equality.
                    areItemsTheSame: (a, b) => a.id == b.id,
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
                          server: JonlineAccount.selectedServer,
                          onTap: () {
                            context.pushRoute(PostDetailsRoute(
                                postId: post.id,
                                server: JonlineAccount.selectedServer));
                          },
                          post: post,
                        ),
                      );
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
                    itemCount: postList.length,
                    itemBuilder: (context, index) {
                      final post = postList[index];
                      return PostPreview(
                        server: JonlineAccount.selectedServer,
                        maxContentHeight: 400,
                        onTap: () {
                          context.pushRoute(PostDetailsRoute(
                              postId: post.id,
                              server: JonlineAccount.selectedServer));
                        },
                        post: post,
                      );
                    },
                  )),
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
