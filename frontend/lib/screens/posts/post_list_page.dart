import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:jonline/screens/posts/post_preview.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);

  @override
  PostListScreenState createState() => PostListScreenState();
}

class PostListScreenState extends State<PostListScreen>
    with AutoRouteAwareStateMixin<PostListScreen> {
  late AppState appState;
  late HomePageState homePage;
  ScrollController listScrollController = ScrollController();
  ScrollController gridScrollController = ScrollController();

  @override
  void didPushNext() {
    print('didPushNext');
  }

  @override
  void initState() {
    // print("PostListPage.initState");
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    appState.accounts.addListener(onAccountsChanged);
    appState.posts.addListener(onPostsUpdated);
    homePage.scrolledToTop.addListener(scrollToTop);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("PostListPage.dispose");
    appState.accounts.removeListener(onAccountsChanged);
    appState.posts.removeListener(onPostsUpdated);
    homePage.scrolledToTop.removeListener(scrollToTop);
    listScrollController.dispose();
    gridScrollController.dispose();
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
      showSnackBar("Scrolling posts to top");
      listScrollController.animateTo(0,
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
        onRefresh: () => appState.updatePosts(showMessage: showSnackBar),
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
                    controller: listScrollController,
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
                          onTap: () {
                            context.pushRoute(PostDetailsRoute(id: post.id));
                          },
                          post: post,
                        ),
                      );
                    },
                  )
                : MasonryGridView.count(
                    controller: listScrollController,
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
                        maxContentHeight: 400,
                        onTap: () {
                          context.pushRoute(PostDetailsRoute(id: post.id));
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
