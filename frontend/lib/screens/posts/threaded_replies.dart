import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_operations.dart';
import '../../models/server_errors.dart';
import '../home_page.dart';
import 'post_preview.dart';

class ThreadedReplies extends StatefulWidget {
  final Post post;
  final String server;

  const ThreadedReplies({Key? key, required this.post, required this.server})
      : super(key: key);

  @override
  ThreadedRepliesState createState() => ThreadedRepliesState();
}

class ThreadedRepliesState extends State<ThreadedReplies> {
  late AppState appState;
  late HomePageState homePage;
  TextTheme get textTheme => Theme.of(context).textTheme;
  List<ThreadedReply> replies = [];

  updateReplies() async {
    final Posts? posts = await JonlineOperations.getSelectedPosts(
        request: GetPostsRequest(repliesToPostId: widget.post.id),
        showMessage: showSnackBar);
    if (posts == null) return;

    showSnackBar("Replies loaded! 🎉");
    setState(() {
      replies = posts.posts.map((p) => ThreadedReply(p, 0)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
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
    return ImplicitlyAnimatedList<ThreadedReply>(
      items: replies,
      itemBuilder: (context, animation, reply, index) {
        return buildReply(reply, context);
      },
      areItemsTheSame: (a, b) => a.post.id == b.post.id,
    );
  }

  Widget buildReply(ThreadedReply reply, BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 5.0 * reply.depth),
        child: Column(
          children: [
            PostPreview(server: widget.server, post: reply.post),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {},
                    child: const Icon(Icons.reply),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {},
                    child: const Icon(Icons.arrow_forward),
                  ),
                )
              ],
            )
          ],
        ));
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}

class ThreadedReply {
  final Post post;
  final int depth;

  ThreadedReply(this.post, this.depth);
}
