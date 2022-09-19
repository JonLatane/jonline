import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/screens/posts/threaded_replies.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_operations.dart';
import '../../models/server_errors.dart';
import '../home_page.dart';
import 'post_preview.dart';

class PostDetailsPage extends StatefulWidget {
  final String id;
  final String server;

  const PostDetailsPage({
    Key? key,
    @PathParam('id') this.id = "INVALID",
    @PathParam('server') this.server = "INVALID",
  }) : super(key: key);

  @override
  PostDetailsPageState createState() => PostDetailsPageState();
}

class PostDetailsPageState extends State<PostDetailsPage> {
  late AppState appState;
  late HomePageState homePage;
  TextTheme get textTheme => Theme.of(context).textTheme;
  Post? post;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    try {
      final post =
          appState.posts.value.posts.firstWhere((p) => p.id == widget.id);
      this.post = post;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final post = await JonlineOperations.getSelectedPosts(
              request: GetPostsRequest(postId: widget.id),
              showMessage: showSnackBar);
          setState(() {
            this.post = post!.posts.first;
          });
        } catch (e) {
          showSnackBar("Failed to load post data for ${widget.id} 😔");
          showSnackBar(formatServerError(e));
        }
      });
    }
  }

  @override
  dispose() {
    super.dispose();
  }

  get q => MediaQuery.of(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: post != null
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                    child: Column(
                  children: [
                    PostPreview(
                      server: widget.server,
                      post: post!,
                      maxContentHeight: null,
                    ),
                    SizedBox(
                        height: q.size.height -
                            q.padding.top -
                            q.padding.bottom -
                            100,
                        child:
                            ThreadedReplies(post: post!, server: widget.server))
                  ],
                )))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("Loading post data..."),
                  ],
                ),
              ));
  }

  Widget buildReplies(BuildContext context) {
    return Container();
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
