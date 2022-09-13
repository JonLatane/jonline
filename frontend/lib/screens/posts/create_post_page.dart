import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/models/jonline_account_operations.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:jonline/screens/posts/post_preview.dart';

// import 'package:jonline/db.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends State<CreatePostPage> {
  late AppState appState;
  late HomePageState homePage;
  bool _showPreview = false;
  List<bool> focuses = [false, false, false];
  bool get showPreview => _showPreview;
  set showPreview(bool value) {
    if (value != _showPreview) {
      final focusSources = [titleFocus, linkFocus, contentFocus];
      if (value == true) {
        print("saving focus");
        focuses = focusSources.map((e) => e.hasFocus).toList();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          print("restoring focus");
          focuses.asMap().forEach((index, hasFocus) {
            if (hasFocus) {
              focusSources[index].requestFocus();
            }
          });
        });
      }

      setState(() {
        _disableQuickPaste = true;
        _showPreview = value;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Future.delayed(const Duration(milliseconds: 100), () {
          _disableQuickPaste = false;
        });
      });
    }
  }

  String? quickPasteLink;
  bool get enableQuickPaste => quickPasteLink != null && quickPasteLink != link;

  // int counter = 1;
  final FocusNode titleFocus = FocusNode();
  final TextEditingController titleController = TextEditingController();
  final FocusNode linkFocus = FocusNode();
  final TextEditingController linkController = TextEditingController();
  final FocusNode contentFocus = FocusNode();
  final TextEditingController contentController = TextEditingController();

  String get title => titleController.value.text;
  String get link => linkController.value.text;
  String get content => contentController.value.text;
  bool _disableQuickPaste = false;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    homePage.postsCreated.addListener(doCreate);
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
    linkFocus.addListener(() {
      if (linkFocus.hasFocus && !_disableQuickPaste) {
        updateQuickPasteLink();
      }
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => updateQuickPasteLink());
  }

  @override
  dispose() {
    homePage.postsCreated.removeListener(doCreate);
    titleFocus.dispose();
    titleController.dispose();
    contentFocus.dispose();
    contentController.dispose();
    linkFocus.dispose();
    linkController.dispose();
    super.dispose();
  }

  bool _doingCreate = false;
  bool get doingCreate => _doingCreate;
  set doingCreate(bool value) {
    setState(() {
      _doingCreate = value;
    });
    homePage.canCreatePost.value = title.isNotEmpty && !value;
  }

  updateQuickPasteLink() async {
    final String? text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text == null || !text.startsWith("http")) {
      setState(() {
        quickPasteLink = null;
      });
    } else {
      setState(() {
        quickPasteLink = text;
      });
    }
  }

  doCreate() async {
    doingCreate = true;
    if (JonlineAccount.selectedAccount == null) {
      showSnackBar("No account selected.");
      return;
    }
    final account = JonlineAccount.selectedAccount!;

    showSnackBar("Updating refresh token...");
    await account.updateRefreshToken(showMessage: showSnackBar);
    await communicationDelay;
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
    context.navigateBack();
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
      // appBar: AppBar(
      //   title: const Text("Create Post"),
      //   leading: const AutoLeadingButton(
      //     ignorePagelessRoutes: true,
      //   ),
      //   actions: [
      //     SizedBox(
      //       width: 72,
      //       child: ElevatedButton(
      //         style: ButtonStyle(
      //             padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
      //             foregroundColor: MaterialStateProperty.all(
      //                 Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
      //             overlayColor:
      //                 MaterialStateProperty.all(Colors.white.withAlpha(100)),
      //             splashFactory: InkSparkle.splashFactory),
      //         onPressed: title.isEmpty ? null : doCreate,
      //         // doingStuff || username.isEmpty || password.isEmpty
      //         //     ? null
      //         //     : createAccount,
      //         child: Padding(
      //           padding: const EdgeInsets.all(4.0),
      //           child: Column(
      //             children: const [
      //               Expanded(child: SizedBox()),
      //               Icon(Icons.add),
      //               // Text('jonline.io/', style: TextStyle(fontSize: 11)),
      //               Text('CREATE', style: TextStyle(fontSize: 12)),
      //               Expanded(child: SizedBox()),
      //             ],
      //           ),
      //         ),
      //       ),
      //     ),
      //     const AccountChooser(),
      //   ],
      // ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              buildModeSwitch(context),
              const SizedBox(height: 8),
              Expanded(
                  child: Stack(
                children: [
                  IgnorePointer(
                    ignoring: showPreview,
                    child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: showPreview ? 0.03 : 1,
                        child: buildEditor(context)),
                  ),
                  IgnorePointer(
                    ignoring: !showPreview,
                    child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: !showPreview ? 0 : 1,
                        child: buildPreview(context)),
                  )
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildModeSwitch(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: TextButton(
              onPressed: () {
                showPreview = false;
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      !showPreview ? Colors.white : Colors.transparent)),
              // doingStuff || username.isEmpty || password.isEmpty
              //     ? null
              //     : createAccount,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: const [
                    Text('EDIT'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: TextButton(
              onPressed: title.isEmpty
                  ? null
                  : () {
                      showPreview = true;
                    },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      showPreview ? Colors.white : Colors.transparent)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: const [
                    Text('PREVIEW'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPreview(BuildContext context) {
    String? content, link;
    if (this.content.isNotEmpty) content = this.content;
    if (this.link.isNotEmpty) link = this.link;
    if (MediaQuery.of(context).size.height < 552) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: PostPreview(
                  allowScrollingContent: true,
                  post: Post(
                      title: title,
                      content: content,
                      link: link,
                      author: Post_Author(username: "jonline.io/jon"))),
            ),
          ),
        ],
      );
    } else {
      return Column(children: [
        const Expanded(
          child: SizedBox(),
        ),
        PostPreview(
            post: Post(
                title: title,
                content: content,
                link: link,
                author: Post_Author(username: "jonline.io/jon"))),
        const Expanded(
          child: SizedBox(),
        ),
      ]);
    }
  }

  Widget buildEditor(BuildContext context) {
    return Column(children: [
      TextField(
        focusNode: titleFocus,
        controller: titleController,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        enableSuggestions: true,
        autocorrect: true,
        maxLines: 1,
        cursorColor: Colors.white,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
        enabled: !doingCreate && !showPreview,
        decoration: const InputDecoration(
            border: InputBorder.none, hintText: "Title", isDense: true),
        onChanged: (value) {},
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: linkFocus,
              controller: linkController,
              keyboardType: TextInputType.url,
              enableSuggestions: false,
              autocorrect: false,
              maxLines: 1,
              cursorColor: Colors.white,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 14),
              enabled: !doingCreate && !showPreview,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Link (optional)",
                  isDense: true),
              onChanged: (value) {},
            ),
          ),
          AnimatedContainer(
              duration: animationDuration,
              // height: 10,
              width: quickPasteLink != null ? 72 : 0,
              child: TextButton(
                onPressed: enableQuickPaste
                    ? () {
                        setState(() {
                          linkController.text =
                              quickPasteLink ?? linkController.text;
                          quickPasteLink = null;
                          linkFocus.unfocus();
                        });
                      }
                    : null,
                child: Stack(
                  children: [
                    AnimatedOpacity(
                        opacity: enableQuickPaste ? 1 : 0.5,
                        duration: animationDuration,
                        child: Icon(Icons.paste,
                            color: enableQuickPaste ? topColor : Colors.white)),
                    AnimatedOpacity(
                        opacity: quickPasteLink == link ? 0.5 : 0,
                        duration: animationDuration,
                        child: Icon(Icons.check, color: bottomColor)),
                  ],
                ),
              ))
        ],
      ),
      const SizedBox(height: 8),
      Expanded(
        child: TextField(
          focusNode: contentFocus,
          controller: contentController,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          enableSuggestions: true,
          autocorrect: true,
          maxLines: null,
          cursorColor: Colors.white,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
          enabled: !doingCreate && !showPreview,
          decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Content (optional)",
              isDense: true),
          onChanged: (value) {},
        ),
      ),
      const Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Markdown is supported.",
            textAlign: TextAlign.right,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w400, fontSize: 12),
          )),
      // const SizedBox(height: 8),
      // Row(
      //   children: [
      //     const Expanded(
      //       flex: 1,
      //       child: SizedBox(),
      //     ),
      //     Expanded(
      //       flex: 6,
      //       child: ElevatedButton(
      //         onPressed: title.isEmpty ? null : () {},
      //         // doingStuff || username.isEmpty || password.isEmpty
      //         //     ? null
      //         //     : createAccount,
      //         child: Padding(
      //           padding: const EdgeInsets.all(4.0),
      //           child: Column(
      //             children: const [
      //               Text('Create Post'),
      //             ],
      //           ),
      //         ),
      //       ),
      //     ),
      //     const Expanded(
      //       flex: 1,
      //       child: SizedBox(),
      //     ),
      //   ],
      // ),
      // const Expanded(
      //   child: SizedBox(),
      // ),
    ]);
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
