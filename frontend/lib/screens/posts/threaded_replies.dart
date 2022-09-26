import 'dart:collection';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/jonotifier.dart';
import 'package:jonline/models/settings.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_operations.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';
import 'post_preview.dart';

class ThreadedReplies extends StatefulWidget {
  final Post post;
  final String server;
  final Jonotifier? updateReplies;
  final ValueNotifier<bool> updatingReplies;

  const ThreadedReplies(
      {Key? key,
      required this.post,
      required this.server,
      this.updateReplies,
      required this.updatingReplies})
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
  Set<ThreadedReply> subRepliesLoading = {};

  updateReplies() async {
    widget.updatingReplies.value = true;
    final Posts? posts = await JonlineOperations.getSelectedPosts(
        request: GetPostsRequest(repliesToPostId: widget.post.id),
        showMessage: showSnackBar);
    if (posts == null) return;

    // showSnackBar("Replies loaded! 🎉");
    final updatedReplies = posts.posts.map((p) => ThreadedReply(p, 0)).toList();
    // setState(() {
    //   replies = posts.posts.map((p) => ThreadedReply(p, 0)).toList();
    // });

    // List<Future<void>> subReplyFutures = [];
    Set<String> preloadedReplies = {};
    for (int i = 1; i < Settings.replyLayersToLoad; i++) {
      final repliesCopy = List.from(updatedReplies);
      for (final reply in repliesCopy) {
        if (reply.post.responseCount == 0 || subRepliesLoaded.contains(reply)) {
          continue;
        }
        // subReplyFutures.add(Future.microtask(() async {
        await loadSubReplies(reply, targetReplySet: updatedReplies);
        setState(() => preloadedReplies.add(reply.post.id));
        // }));
      }
    }

    for (final subreply in subRepliesLoaded) {
      if (preloadedReplies.contains(subreply.post.id)) continue;
      // subReplyFutures
      //     .add(
      await loadSubReplies(subreply, targetReplySet: updatedReplies);
      // );
    }
    // await Future.wait(subReplyFutures);
    if (!mounted) return;
    setState(() {
      replies = updatedReplies;
    });
    widget.updatingReplies.value = false;
  }

  Future<void> loadSubReplies(ThreadedReply reply,
      {bool quietly = false, List<ThreadedReply>? targetReplySet}) async {
    bool alreadyLoaded = subRepliesLoaded.contains(reply);
    setState(() => subRepliesLoading.add(reply));
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
          subRepliesLoading.remove(reply);
          subRepliesLoaded.remove(reply);
        });
      }
      return;
    }
    if (posts.posts.isEmpty) {
      if (!quietly) showSnackBar("No replies.");
      setState(() {
        subRepliesLoading.remove(reply);
        if (!quietly) subRepliesLoaded.remove(reply);
      });
      return;
    }
    if (!mounted) return;

    // showSnackBar("Sub-replies loaded! 🎉");
    final newReplies =
        posts.posts.map((p) => ThreadedReply(p, reply.depth + 1)).toList();
    final target = targetReplySet ?? replies;
    applyChange() {
      subRepliesLoading.remove(reply);
      subRepliesLoaded.add(reply);
      target.insertAll(
          target.indexWhere((e) => e.post.id == reply.post.id) + 1, newReplies);
    }

    if (targetReplySet == null) {
      setState(applyChange);
    } else {
      applyChange();
    }
  }

  hideSubReplies(ThreadedReply reply) async {
    setState(() {
      subRepliesLoaded.remove(reply);
      final index = replies.indexWhere((r) => r.post.id == reply.post.id) + 1;
      while (index < replies.length && replies[index].depth > reply.depth) {
        final removed = replies.removeAt(index);
        subRepliesLoaded.remove(removed);
      }
    });
  }

  bool canReply = JonlineAccount.selectedAccount != null;
  updateState() {
    setState(() {
      canReply = JonlineAccount.selectedAccount != null;
    });
  }

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    appState.accounts.addListener(updateState);

    widget.updateReplies?.addListener(updateReplies);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateReplies();
    });
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
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
    bool repliesLoaded = subRepliesLoaded.contains(reply);
    bool repliesLoading = subRepliesLoading.contains(reply);
    Widget result = Column(
      children: [
        PostPreview(
            server: widget.server,
            post: reply.post,
            maxContentHeight: null,
            isReply: true),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: repliesLoading || widget.updatingReplies.value
                    ? null
                    : repliesLoaded
                        ? () {
                            hideSubReplies(reply);
                          }
                        : () {
                            loadSubReplies(reply);
                          },
                child: Row(
                  children: [
                    AnimatedRotation(
                      duration: animationDuration,
                      turns: repliesLoaded ? 0 : -0.25,
                      child: const Icon(Icons.arrow_drop_down),
                    ),
                    Text("${repliesLoaded ? "Hide" : "View"} Replies"),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: canReply
                    ? () {
                        if (!(repliesLoaded || repliesLoading)) {
                          loadSubReplies(reply, quietly: true);
                        }
                        context.pushRoute(CreateDeepReplyRoute(
                            discussionPostId: widget.post.id,
                            postId: reply.post.id,
                            server: widget.server));
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
    );

    for (int i = 0; i < reply.depth; i++) {
      result = Container(
        decoration: BoxDecoration(
            border: Border(
                left: BorderSide(
                    color: (reply.depth - i) % 2 == 0 ? topColor : bottomColor,
                    width: 5.0))),
        child: result,
      );
    }
    return result;
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}

class ThreadedReply {
  Post post;
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
