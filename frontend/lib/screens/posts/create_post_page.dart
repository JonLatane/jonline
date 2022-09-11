import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/screens/posts/post_preview.dart';

// import 'package:jonline/db.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends State<CreatePostPage> {
  bool _showPreview = false;
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

  @override
  void initState() {
    super.initState();
    titleController.addListener(() {
      setState(() {});
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
    titleFocus.dispose();
    titleController.dispose();
    contentFocus.dispose();
    contentController.dispose();
    linkFocus.dispose();
    linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        leading: const AutoLeadingButton(
          ignorePagelessRoutes: true,
        ),
        actions: [
          SizedBox(
            width: 72,
            child: ElevatedButton(
              style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                  foregroundColor: MaterialStateProperty.all(
                      Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
                  overlayColor:
                      MaterialStateProperty.all(Colors.white.withAlpha(100)),
                  splashFactory: InkSparkle.splashFactory),
              onPressed: title.isEmpty ? null : () {},
              // doingStuff || username.isEmpty || password.isEmpty
              //     ? null
              //     : createAccount,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: const [
                    Expanded(child: SizedBox()),
                    Icon(Icons.add),
                    // Text('jonline.io/', style: TextStyle(fontSize: 11)),
                    Text('CREATE', style: TextStyle(fontSize: 12)),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: TextButton(
              style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                  foregroundColor:
                      MaterialStateProperty.all(Colors.white.withAlpha(100)),
                  overlayColor:
                      MaterialStateProperty.all(Colors.white.withAlpha(100)),
                  splashFactory: InkSparkle.splashFactory),
              onPressed: () {
                // context.router.pop();
              },
              child: Column(
                children: const [
                  Expanded(child: SizedBox()),
                  Text('jonline.io/', style: TextStyle(fontSize: 11)),
                  Text('jon', style: TextStyle(fontSize: 12)),
                  Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ],
      ),
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
                    ignoring: _showPreview,
                    child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: _showPreview ? 0.03 : 1,
                        child: buildEditor(context)),
                  ),
                  IgnorePointer(
                    ignoring: !_showPreview,
                    child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: !_showPreview ? 0 : 1,
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
                setState(() {
                  _showPreview = false;
                });
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      !_showPreview ? Colors.white : Colors.transparent)),
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
                      setState(() {
                        _showPreview = true;
                      });
                    },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      _showPreview ? Colors.white : Colors.transparent)),
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
        enableSuggestions: true,
        autocorrect: true,
        maxLines: 1,
        cursorColor: Colors.white,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
        // enabled: !doingStuff,
        decoration: const InputDecoration(
            border: InputBorder.none, hintText: "Title", isDense: true),
        onChanged: (value) {},
      ),
      TextField(
        focusNode: linkFocus,
        controller: linkController,
        enableSuggestions: false,
        autocorrect: false,
        maxLines: 1,
        cursorColor: Colors.white,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
        // enabled: !doingStuff,
        decoration: const InputDecoration(
            border: InputBorder.none, hintText: "Link", isDense: true),
        onChanged: (value) {},
      ),
      const SizedBox(height: 8),
      Expanded(
        child: TextField(
          focusNode: contentFocus,
          controller: contentController,
          // obscureText: true,
          enableSuggestions: true,
          autocorrect: true,
          maxLines: null,
          cursorColor: Colors.white,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
          // enabled: !doingStuff,
          decoration: const InputDecoration(
              border: InputBorder.none, hintText: "Content", isDense: true),
          onChanged: (value) {
            // widget.melody.name = value;
            //                          BeatScratchPlugin.updateMelody(widget.melody);
            // BeatScratchPlugin.onSynthesizerStatusChange();
          },
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
}
