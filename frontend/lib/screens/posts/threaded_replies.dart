import 'dart:collection';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/jonotifier.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_operations.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';
import 'post_preview.dart';

class ThreadedReplies extends StatefulWidget {
  final Post post;
  final String server;
  final Jonotifier? updateReplies;

  const ThreadedReplies(
      {Key? key, required this.post, required this.server, this.updateReplies})
      : super(key: key);

  @override
  ThreadedRepliesState createState() => ThreadedRepliesState();
}

class ThreadedRepliesState extends State<ThreadedReplies> {
  late AppState appState;
  late HomePageState homePage;
  TextTheme get textTheme => Theme.of(context).textTheme;
  List<ThreadedReply> replies = [];
  LinkedHashSet<ThreadedReply> subRepliesLoaded = LinkedHashSet();

  updateReplies() async {
    final Posts? posts = await JonlineOperations.getSelectedPosts(
        request: GetPostsRequest(repliesToPostId: widget.post.id),
        showMessage: showSnackBar);
    if (posts == null) return;

    showSnackBar("Replies loaded! 🎉");
    setState(() {
      replies = posts.posts.map((p) => ThreadedReply(p, 0)).toList();
    });

    for (final subreply in subRepliesLoaded) {
      await loadSubReplies(subreply);
    }
  }

  loadSubReplies(ThreadedReply reply) async {
    bool alreadyLoaded = subRepliesLoaded.contains(reply);
    if (!alreadyLoaded) {
      setState(() {
        subRepliesLoaded.add(reply);
      });
    }
    final Posts? posts = await JonlineOperations.getSelectedPosts(
        request: GetPostsRequest(repliesToPostId: reply.post.id),
        showMessage: showSnackBar);
    if (posts == null) {
      if (!alreadyLoaded) {
        setState(() {
          subRepliesLoaded.remove(reply);
        });
      }
      return;
    }

    showSnackBar("Sub-replies loaded! 🎉");
    setState(() {
      subRepliesLoaded.add(reply);
      replies.insertAll(
          replies.indexWhere((e) => e.post.id == reply.post.id) + 1,
          posts.posts.map((p) => ThreadedReply(p, reply.depth + 1)).toList());
    });
  }

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    widget.updateReplies?.addListener(updateReplies);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateReplies();
    });
  }

  @override
  dispose() {
    widget.updateReplies?.removeListener(updateReplies);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverImplicitlyAnimatedList<ThreadedReply>(
      items: replies,
      itemBuilder: (context, animation, reply, index) {
        return SizeFadeTransition(
            sizeFraction: 0.2,
            curve: Curves.easeInOut,
            animation: animation,
            child: buildReply(reply, context));
      },
      areItemsTheSame: (a, b) => a.post.id == b.post.id,
    );
  }

  Widget buildReply(ThreadedReply reply, BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 10.0 * (1 + reply.depth)),
        child: Column(
          children: [
            PostPreview(server: widget.server, post: reply.post, isReply: true),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: subRepliesLoaded.contains(reply)
                        ? null
                        : () {
                            loadSubReplies(reply);
                          },
                    child: Row(
                      children: const [
                        AnimatedRotation(
                          duration: animationDuration,
                          turns: -0.25,
                          child: Icon(Icons.arrow_drop_down),
                        ),
                        Text("View Replies"),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      context.pushRoute(CreateDeepReplyRoute(
                          discussionPostId: widget.post.id,
                          postId: reply.post.id,
                          server: widget.server));
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.reply),
                        Text("Reply"),
                      ],
                    ),
                  ),
                ),
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
  @override
  bool operator ==(Object other) =>
      other is ThreadedReply &&
      other.runtimeType == runtimeType &&
      other.post == post &&
      other.depth == depth;

  @override
  int get hashCode => pow(post.hashCode, depth).toInt();
}
