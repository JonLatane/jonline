import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/screens/posts/threaded_replies.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../jonotifier.dart';
import '../../models/jonline_operations.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';
import 'post_preview.dart';

class PostDetailsPage extends StatefulWidget {
  final String server;
  final String postId;

  const PostDetailsPage({
    Key? key,
    @pathParam this.server = "INVALID",
    @pathParam this.postId = "INVALID",
  }) : super(key: key);

  @override
  PostDetailsPageState createState() => PostDetailsPageState();
}

class PostDetailsPageState extends State<PostDetailsPage> {
  late AppState appState;
  late HomePageState homePage;
  Jonotifier updateReplies = Jonotifier();
  TextTheme get textTheme => Theme.of(context).textTheme;
  Post? subjectPost;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    try {
      final post =
          appState.posts.value.posts.firstWhere((p) => p.id == widget.postId);
      subjectPost = post;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final post = await JonlineOperations.getSelectedPosts(
              request: GetPostsRequest(postId: widget.postId),
              showMessage: showSnackBar);
          setState(() {
            subjectPost = post!.posts.first;
          });
        } catch (e) {
          showSnackBar("Failed to load post data for ${widget.postId} 😔");
          showSnackBar(formatServerError(e));
        }
      });
    }
  }

  @override
  dispose() {
    updateReplies.dispose();
    super.dispose();
  }

  get q => MediaQuery.of(context);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: subjectPost != null
            ? RefreshIndicator(
                onRefresh: () async {
                  try {
                    final post = await JonlineOperations.getSelectedPosts(
                        request: GetPostsRequest(postId: widget.postId),
                        showMessage: showSnackBar);
                    setState(() {
                      subjectPost = post!.posts.first;
                      showSnackBar("Updated post details! 🎉");
                    });
                  } catch (e) {
                    showSnackBar(
                        "Failed to load post data for ${widget.postId} 😔");
                    showSnackBar(formatServerError(e));
                  }
                  updateReplies();
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: PostPreview(
                        server: widget.server,
                        post: subjectPost!,
                        maxContentHeight: null,
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: HeaderSliver(
                          subjectPost!, updateReplies, widget.server),
                    ),
                    ThreadedReplies(
                      post: subjectPost!,
                      server: widget.server,
                      updateReplies: updateReplies,
                    ),

                    // other sliver widgets
                  ],
                ),
              ) /*SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                    child: Column(
                  children: [
                    PostPreview(
                      server: widget.server,
                      post: subjectPost!,
                      maxContentHeight: null,
                    ),
                    Row(children: [
                      Expanded(
                          child: TextButton(
                        onPressed: updateReplies,
                        child: Row(children: const [
                          Icon(Icons.refresh),
                          Expanded(child: Text("Update Replies")),
                        ]),
                      )),
                      Expanded(
                          child: TextButton(
                        onPressed: () {
                          context.pushRoute(CreateReplyRoute(
                              postId: widget.postId, server: widget.server));
                        },
                        child: Row(children: const [
                          Icon(Icons.reply),
                          Expanded(child: Text("Reply")),
                        ]),
                      )),
                    ]),
                    SizedBox(
                        height: q.size.height -
                            q.padding.top -
                            q.padding.bottom -
                            100,
                        child: ThreadedReplies(
                          post: subjectPost!,
                          server: widget.server,
                          updateReplies: updateReplies,
                        ))
                  ],
                )))*/
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("Loading post data..."),
                  ],
                ),
              ));
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}

class HeaderSliver extends SliverPersistentHeaderDelegate {
  final Post subjectPost;
  final Jonotifier updateReplies;
  final String server;

  HeaderSliver(this.subjectPost, this.updateReplies, this.server);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final q = MediaQuery.of(context);
    return Column(
      children: [
        // PostPreview(
        //   server: server,
        //   post: subjectPost,
        //   maxContentHeight: null,
        // ),
        Row(children: [
          Expanded(
              child: TextButton(
            onPressed: updateReplies,
            child: Row(children: const [
              Icon(Icons.refresh),
              Expanded(child: Text("Update Replies")),
            ]),
          )),
          Expanded(
              child: TextButton(
            onPressed: () {
              context.pushRoute(
                  CreateReplyRoute(postId: subjectPost.id, server: server));
            },
            child: Row(children: const [
              Icon(Icons.reply),
              Expanded(child: Text("Reply")),
            ]),
          )),
        ]),
      ],
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
