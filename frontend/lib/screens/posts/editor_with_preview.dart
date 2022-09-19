import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../home_page.dart';
import 'post_preview.dart';

class EditorWithPreview extends StatefulWidget {
  // If not provided, will hide the title.
  final TextEditingController? titleController;
  final TextEditingController? linkController;
  final TextEditingController? contentController;
  final ValueNotifier<bool>? enabled;

  const EditorWithPreview(
      {Key? key,
      this.titleController,
      this.linkController,
      this.contentController,
      this.enabled})
      : super(key: key);

  @override
  EditorWithPreviewState createState() => EditorWithPreviewState();
}

class EditorWithPreviewState extends State<EditorWithPreview> {
  late AppState appState;
  late HomePageState homePage;
  bool _showPreview = false;
  List<bool> focuses = [false, false, false];
  bool get showPreview => _showPreview;
  set showPreview(bool value) {
    if (value != _showPreview) {
      final focusSources = [titleFocus, linkFocus, contentFocus];
      if (value == true) {
        focuses = focusSources.map((e) => e.hasFocus).toList();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          focuses.asMap().forEach((index, hasFocus) {
            if (hasFocus) {
              focusSources[index].requestFocus();
            }
          });
        });
      }

      setState(() {
        _showPreview = value;
      });
    }
  }

  bool quickPasteDone = false;

  final FocusNode titleFocus = FocusNode();
  final FocusNode linkFocus = FocusNode();
  final FocusNode contentFocus = FocusNode();
  late final TextEditingController? titleController;
  late final TextEditingController? linkController;
  late final TextEditingController? contentController;
  late final ValueNotifier<bool> enabled;

  String? get title => titleController?.value.text;
  String? get link => linkController?.value.text;
  String? get content => contentController?.value.text;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;

    titleController = widget.titleController;
    linkController = widget.linkController;
    contentController = widget.contentController;
    enabled = widget.enabled ?? ValueNotifier(true);

    titleController?.addListener(() {
      setState(() {});
    });
    contentController?.addListener(() {
      setState(() {});
    });
    linkController?.addListener(() {
      setState(() {});
    });
  }

  @override
  dispose() {
    titleFocus.dispose();
    contentFocus.dispose();
    linkFocus.dispose();
    // if (widget.titleController == null) titleController.dispose();
    // if (widget.contentController == null) contentController.dispose();
    // if (widget.linkController == null) linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              onPressed: title?.isEmpty == true
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
    if (this.content?.isNotEmpty == true) content = this.content;
    if (this.link?.isNotEmpty == true) link = this.link;
    if (MediaQuery.of(context).size.height < 552) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: PostPreview(
                  allowScrollingContent: true,
                  server: JonlineAccount.selectedServer,
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
            server: JonlineAccount.selectedServer,
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
      if (widget.titleController != null)
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
          enabled: enabled.value && !showPreview,
          decoration: const InputDecoration(
              border: InputBorder.none, hintText: "Title", isDense: true),
          onChanged: (value) {},
        ),
      if (widget.linkController != null)
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
                enabled: enabled.value && !showPreview,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Link (optional)",
                    isDense: true),
                onChanged: (value) {},
              ),
            ),
            AnimatedContainer(
                duration: animationDuration,
                width: 72,
                child: TextButton(
                  onPressed: quickPasteDone
                      ? null
                      : () async {
                          final String? text =
                              (await Clipboard.getData(Clipboard.kTextPlain))
                                  ?.text;
                          if (text == null || !text.startsWith("http")) {
                            showSnackBar('No link found in the clipboard. 😔');
                          } else {
                            setState(() {
                              linkController?.text = text;
                              quickPasteDone = true;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                quickPasteDone = false;
                              });
                            });
                          }
                        },
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                          opacity: quickPasteDone ? 0.8 : 1,
                          duration: animationDuration,
                          child: Icon(Icons.paste, color: topColor)),
                      AnimatedOpacity(
                          opacity: quickPasteDone ? 1 : 0,
                          duration: animationDuration,
                          child: Icon(Icons.check, color: bottomColor)),
                    ],
                  ),
                ))
          ],
        ),
      const SizedBox(height: 8),
      if (widget.contentController != null)
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
            enabled: enabled.value && !showPreview,
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText:
                    "Content${widget.titleController != null ? " (optional)" : ""} ",
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
    ]);
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
