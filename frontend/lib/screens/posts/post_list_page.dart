import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:jonline/screens/accounts/account_chooser.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:jonline/screens/posts/post_preview.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);

  @override
  PostListScreenState createState() => PostListScreenState();
}

class PostListScreenState extends State<PostListScreen>
    with AutoRouteAwareStateMixin<PostListScreen> {
  late AppState appState;
  late HomePageState homePage;

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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("PostListPage.dispose");
    appState.accounts.removeListener(onAccountsChanged);
    appState.posts.removeListener(onPostsUpdated);
    super.dispose();
  }

  onAccountsChanged() {
    setState(() {});
  }

  onPostsUpdated() {
    setState(() {});
  }

  appBar() {
    return AppBar(
      // automaticallyImplyLeading: false,
      title: const Text(
        "Posts",
      ),
      // leading:
      actions: [
        if (JonlineAccount.selectedAccount != null)
          TextButton(
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              context.navigateNamedTo('/posts/create');
            },
          ),
        const AccountChooser(),
      ],
    );
  }

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
                PointerDeviceKind.mouse,
              },
            ),
            child: (MediaQuery.of(context).size.width < 400)
                ?
                //Another
                ImplicitlyAnimatedList<Post>(
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
                    // An optional builder when an item was removed from the list.
                    // If not specified, the List uses the itemBuilder with
                    // the animation reversed.
                    // removeItemBuilder: (context, animation, oldItem) {
                    //   return FadeTransition(
                    //     opacity: animation,
                    //     child: Text(oldItem.name),
                    //   );
                    // },
                  )
                : MasonryGridView.count(
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
                  )

            // GridView.builder(
            //     gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            //         maxCrossAxisExtent: 200,
            //         childAspectRatio: 12 / 16,
            //         crossAxisSpacing: 0,
            //         mainAxisSpacing: 0),
            //     itemCount: postList.length,
            //     itemBuilder: (BuildContext ctx, index) {
            //       final post = postList[index];
            //       return Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           PostPreview(
            //             maxContentHeight: 100,
            //             onTap: () {
            //               context.pushRoute(PostDetailsRoute(id: post.id));
            //             },
            //             post: post,
            //           ),
            //         ],
            //       );
            //     }),
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
