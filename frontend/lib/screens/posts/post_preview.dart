import 'package:any_link_preview/any_link_preview.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jonline/generated/posts.pb.dart';

// import 'package:jonline/db.dart';

class PostPreview extends StatefulWidget {
  final Post post;
  const PostPreview({Key? key, required this.post}) : super(key: key);

  @override
  PostPreviewState createState() => PostPreviewState();
}

class PostPreviewState extends State<PostPreview> {
  String get title => widget.post.title;
  String? get link => widget.post.link.isEmpty ? null : widget.post.link;
  String? get content =>
      widget.post.content.isEmpty ? null : widget.post.content;
  String? get username =>
      widget.post.author.username.isEmpty ? null : widget.post.author.username;
  int get replyCount => widget.post.replyCount;

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8.0), //child: Text('hi')
        child: Column(
          children: [
            // Text("hi"),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: content != null
                        ? Theme.of(context).textTheme.titleLarge
                        : title.length < 20
                            ? Theme.of(context).textTheme.titleLarge
                            : title.length < 255
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.titleSmall,
                    // const TextStyle(
                    //     fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            if (link != null)
              Container(
                height: 8,
              ),
            if (link != null)
              AnyLinkPreview(
                link: link!,
              ),
            if (content != null)
              Container(
                height: 8,
              ),
            if (content != null)
              Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Row(
                    children: [
                      Expanded(
                          child: SingleChildScrollView(
                              child: MarkdownBody(data: content!)))
                      // child: Text(
                      //   content!,
                      //   style: const TextStyle(
                      //       fontSize: 13, fontWeight: FontWeight.w400),
                      //   textAlign: TextAlign.left,
                      // ),
                      ,
                    ],
                  )),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Text(
                  "by ${username ?? 'someone forgotten'}",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey),
                ),
                const Expanded(child: SizedBox()),
                const Icon(
                  Icons.reply,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text("$replyCount replies"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
