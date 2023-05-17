import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/screens/posts/editor_with_preview.dart';

import '../../app_state.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_clients.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';

// import 'package:jonline/db.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends JonlineState<CreatePostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  String get title => titleController.value.text;
  String get link => linkController.value.text;
  String get content => contentController.value.text;
  bool get linkValid {
    try {
      Uri.parse(link);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get canCreate =>
      title.isNotEmpty || (link.isNotEmpty && linkValid) || content.isNotEmpty;

  @override
  void initState() {
    super.initState();
    homePage.createPost.addListener(doCreate);
    titleController.addListener(() {
      setState(() {});
      updateHomepage();
    });
    contentController.addListener(() {
      setState(() {});
      updateHomepage();
    });
    linkController.addListener(() {
      setState(() {});
      updateHomepage();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateHomepage();
    });
  }

  updateHomepage() {
    homePage.canCreatePost.value = canCreate && !doingCreate;
  }

  @override
  dispose() {
    homePage.createPost.removeListener(doCreate);
    titleController.dispose();
    contentController.dispose();
    linkController.dispose();
    super.dispose();
  }

  bool _doingCreate = false;
  bool get doingCreate => _doingCreate;
  set doingCreate(bool value) {
    setState(() {
      enabled.value = !value;
      _doingCreate = value;
    });
    homePage.canCreatePost.value = canCreate && !value;
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
    showSnackBar("Creating post...");
    final startTime = DateTime.now();
    final Post post;
    try {
      post = await client!.createPost(
          Post(
              title: title.isNotEmpty ? title : null,
              link: link.isNotEmpty ? link : null,
              content: content.isNotEmpty ? content : null),
          options: account.authenticatedCallOptions);
    } catch (e) {
      await communicationDelay;
      showSnackBar("Error creating post 😔");
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
    showSnackBar("Post created! 🎉");
    if (!mounted) {
      doingCreate = false;
      return;
    }
    // context.navigateBack();
    context.replaceRoute(PostDetailsRoute(
        postId: post.id, server: JonlineServer.selectedServer.server));
    appState.posts.value =
        GetPostsResponse(posts: [post] + appState.posts.value.posts);
    Future.delayed(const Duration(seconds: 3),
        () => appState.posts.update(showMessage: showSnackBar));

    doingCreate = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        SizedBox(height: mq.padding.top),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: EditorWithPreview(
                  titleController: titleController,
                  linkController: linkController,
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
