import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';

import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/models/jonline_account_operations.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:jonline/screens/posts/post_preview.dart';

class PostDetailsPage extends StatefulWidget {
  final String id;

  const PostDetailsPage({
    Key? key,
    @PathParam('id') this.id = "INVALID",
  }) : super(key: key);

  @override
  PostDetailsPageState createState() => PostDetailsPageState();
}

class PostDetailsPageState extends State<PostDetailsPage> {
  late AppState appState;
  late HomePageState homePage;
  TextTheme get textTheme => Theme.of(context).textTheme;
  Post? post;
  Posts replies = Posts();

  updateReplies() async {
    final Posts? posts = await JonlineAccountOperations.getSelectedPosts(
        request: GetPostsRequest(repliesToPostId: widget.id),
        showMessage: showSnackBar);
    if (posts == null) return;

    showSnackBar("Replies loaded! 🎉");
    setState(() {
      replies = posts;
    });
  }

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnackBar("Failed to load cached post data 😔 for ${widget.id}");
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateReplies();
    });
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: post != null
            ? SingleChildScrollView(
                child: Center(
                    child: Column(
                children: [
                  PostPreview(
                    post: post!,
                    maxContentHeight: null,
                  ),
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
