import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/screens/posts/editor_with_preview.dart';
import 'package:jonline/screens/posts/post_preview.dart';

import '../../app_state.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_clients.dart';
import '../../models/jonline_operations.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';

// import 'package:jonline/db.dart';

class CreateReplyPage extends StatefulWidget {
  final String server;
  final String postId;
  final String discussionPostId;
  const CreateReplyPage({
    Key? key,
    @pathParam this.server = "",
    @pathParam this.postId = "",
    this.discussionPostId = "",
  }) : super(key: key);

  @override
  CreateReplyPageState createState() => CreateReplyPageState();
}

class CreateDeepReplyPage extends CreateReplyPage {
  const CreateDeepReplyPage({
    Key? key,
    @pathParam String server = "",
    @PathParam('subjectPostId') String postId = "",
    @PathParam('postId') String discussionPostId = "",
  }) : super(
          key: key,
          server: server,
          postId: postId,
          discussionPostId: discussionPostId,
        );
}

class CreateReplyPageState extends JonlineState<CreateReplyPage> {
  // final TextEditingController linkController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  // String get link => linkController.value.text;
  String get content => contentController.value.text;
  Post? subjectPost;
  Post? discussionPost;
  String? get discussionPostId =>
      widget.discussionPostId.isNotEmpty ? widget.discussionPostId : null;

  onAccountsChanged() {
    if (JonlineServer.selectedServer.server != widget.server) {
      context.replaceRoute(const PostsRoute());
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    homePage.createReply.addListener(doCreate);
    appState.accounts.addListener(onAccountsChanged);

    contentController.addListener(() {
      setState(() {});
      homePage.canCreateReply.value = content.isNotEmpty && !doingCreate;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      homePage.canCreateReply.value = content.isNotEmpty;
    });
    try {
      final post =
          appState.posts.value.posts.firstWhere((p) => p.id == widget.postId);
      subjectPost = post;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final post = await JonlineOperations.getPosts(
              request: GetPostsRequest()..postId = widget.postId,
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
    if (discussionPostId != null) {
      try {
        final post = appState.posts.value.posts
            .firstWhere((p) => p.id == discussionPostId);
        discussionPost = post;
      } catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final post = await JonlineOperations.getPosts(
                request: GetPostsRequest()..postId = widget.postId,
                showMessage: showSnackBar);
            setState(() {
              discussionPost = post!.posts.first;
            });
          } catch (e) {
            showSnackBar("Failed to load post data for ${widget.postId} 😔");
            showSnackBar(formatServerError(e));
          }
        });
      }
    }
  }

  @override
  dispose() {
    appState.accounts.removeListener(onAccountsChanged);
    homePage.createReply.removeListener(doCreate);
    contentController.dispose();
    // linkController.dispose();
    super.dispose();
  }

  bool _doingCreate = false;
  bool get doingCreate => _doingCreate;
  set doingCreate(bool value) {
    setState(() {
      enabled.value = !value;
      _doingCreate = value;
    });
    homePage.canCreateReply.value = content.isNotEmpty && !value;
  }

  doCreate() async {
    doingCreate = true;
    if (JonlineAccount.selectedAccount == null) {
      showSnackBar("No account selected.");
      return;
    }
    final account = JonlineAccount.selectedAccount!;

    // showSnackBar("Updating refresh token...");
    await account.ensureAccessToken(showMessage: showSnackBar);
    // await communicationDelay;
    final JonlineClient? client =
        await (account.getClient(showMessage: showSnackBar));
    if (client == null) {
      showSnackBar("Account not ready.");
    }
    if (subjectPost == null) {
      showSnackBar("Subject post not ready.");
    }
    showSnackBar("Creating reply...");
    final startTime = DateTime.now();
    try {
      await client!.createPost(
          Post()
            ..replyToPostId = subjectPost!.id
            ..content = content,
          options: account.authenticatedCallOptions);
    } catch (e) {
      await communicationDelay;
      showSnackBar("Error creating reply 😔");
      await communicationDelay;
      showSnackBar(formatServerError(e));
      doingCreate = false;
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch -
            startTime.millisecondsSinceEpoch <
        500) {
      await communicationDelay;
    }
    showSnackBar("Reply created! 🎉");
    if (!mounted) {
      doingCreate = false;
      return;
    }
    context.navigateBack();
    appState.updateReplies();
    doingCreate = false;
  }

  bool showingSubject = false;
  bool showingDiscussionPost = false;
  double get detailHeight =>
      (MediaQuery.of(context).size.height -
          mq.padding.top -
          mq.padding.bottom -
          48) *
      0.45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        SizedBox(height: mq.padding.top),
        Row(
          children: [
            if (discussionPostId != null)
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showingDiscussionPost = !showingDiscussionPost;
                      if (showingDiscussionPost) showingSubject = false;
                    });
                  },
                  child: Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 1),
                        child: AnimatedRotation(
                            duration: animationDuration,
                            turns: showingDiscussionPost ? 0 : -0.25,
                            child: const Icon(Icons.arrow_drop_down)),
                      ),
                      const Expanded(
                        child: Text("Original Post..."),
                      )
                    ],
                  ),
                ),
              ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    showingSubject = !showingSubject;
                    if (showingSubject) showingDiscussionPost = false;
                  });
                },
                child: Row(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, 1),
                      child: AnimatedRotation(
                          duration: animationDuration,
                          turns: showingSubject ? 0 : -0.25,
                          child: const Icon(Icons.arrow_drop_down)),
                    ),
                    const Expanded(
                      child: Text("Replying To..."),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        if (discussionPostId != null)
          AnimatedContainer(
              duration: animationDuration,
              height: showingDiscussionPost ? detailHeight : 0,
              child: SingleChildScrollView(
                  child: discussionPost != null
                      ? PostPreview(
                          post: discussionPost!,
                          server: widget.server,
                          maxContentHeight: null,
                        )
                      : const Text("loading"))),
        AnimatedContainer(
            duration: animationDuration,
            height: showingSubject ? detailHeight : 0,
            child: SingleChildScrollView(
                child: subjectPost != null
                    ? PostPreview(
                        post: subjectPost!,
                        server: widget.server,
                        maxContentHeight: null,
                        isReply: discussionPostId != null,
                      )
                    : const Text("loading"))),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: EditorWithPreview(
                  // linkController: linkController,
                  contentController: contentController,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: mq.padding.bottom),
      ],
    ));
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
