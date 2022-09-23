import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/screens/posts/editor_with_preview.dart';

import '../../app_state.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_clients.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';

// import 'package:jonline/db.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends State<CreatePostPage> {
  late AppState appState;
  late HomePageState homePage;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  String get title => titleController.value.text;
  String get link => linkController.value.text;
  String get content => contentController.value.text;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    homePage.createPost.addListener(doCreate);
    titleController.addListener(() {
      setState(() {});
      homePage.canCreatePost.value = title.isNotEmpty && !doingCreate;
    });
    contentController.addListener(() {
      setState(() {});
    });
    linkController.addListener(() {
      setState(() {});
    });
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
    homePage.canCreatePost.value = title.isNotEmpty && !value;
  }

  doCreate() async {
    doingCreate = true;
    if (JonlineAccount.selectedAccount == null) {
      showSnackBar("No account selected.");
      return;
    }
    final account = JonlineAccount.selectedAccount!;

    // showSnackBar("Updating refresh token...");
    await account.updateRefreshToken(showMessage: showSnackBar);
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
          CreatePostRequest(title: title, link: link, content: content),
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
        postId: post.id, server: JonlineAccount.selectedServer));
    final appState = context.findRootAncestorStateOfType<AppState>();
    if (appState == null) {
      doingCreate = false;

      return;
    }
    appState.posts.value = Posts(posts: [post] + appState.posts.value.posts);
    Future.delayed(const Duration(seconds: 3),
        () => appState.updatePosts(showMessage: showSnackBar));

    doingCreate = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
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
