import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:link_preview_generator/link_preview_generator.dart';

// import 'package:jonline/db.dart';

class PostPreview extends StatefulWidget {
  final Post post;
  final bool allowScrollingContent;
  final double? maxContentHeight;
  final VoidCallback? onTap;
  const PostPreview(
      {Key? key,
      required this.post,
      this.maxContentHeight = 300,
      this.onTap,
      this.allowScrollingContent = false})
      : super(key: key);

  @override
  PostPreviewState createState() => PostPreviewState();
}

class PostPreviewState extends State<PostPreview> {
  String get title => widget.post.title;
  String? get link => widget.post.link.isEmpty
      ? null
      : widget.post.link.startsWith(RegExp(r'https?://'))
          ? widget.post.link
          : 'http://${widget.post.link}';
  String? get content =>
      widget.post.content.isEmpty ? null : widget.post.content;
  String? get username =>
      widget.post.author.username.isEmpty ? null : widget.post.author.username;
  int get replyCount => widget.post.replyCount;

  // String? _lastGeneratedLink;
  // var _previewData;

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
    // if (_previewData == null && link != null) {
    //   _lastGeneratedLink = link;
    // } else if (_previewData != null && link != _lastGeneratedLink) {
    //   _previewData = null;
    // }
    final Widget view = Container(
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
          if (content != null || link != null)
            Container(
                constraints: widget.maxContentHeight != null
                    ? BoxConstraints(maxHeight: widget.maxContentHeight!)
                    : null,
                child: Row(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          physics: widget.allowScrollingContent
                              ? null
                              : const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              if (link != null)
                                Container(
                                  height: 8,
                                ),
                              if (link != null)
                                LinkPreviewGenerator(
                                  key: ValueKey(link),
                                  bodyMaxLines: 3,
                                  link: link!,
                                  linkPreviewStyle: content != null
                                      ? LinkPreviewStyle.small
                                      : LinkPreviewStyle.large,
                                  errorBody: '',
                                  showGraphic: true,
                                ),
                              // LinkPreview(
                              //   key: ValueKey(link!),
                              //   enableAnimation: true,
                              //   onPreviewDataFetched: (data) {
                              //     setState(() {
                              //       _previewData = data;
                              //     });
                              //   },
                              //   previewData: _previewData,
                              //   text: link!,
                              //   width: MediaQuery.of(context).size.width,
                              // ),
                              if (content != null)
                                Container(
                                  height: 8,
                                ),
                              if (content != null)
                                Row(
                                  children: [
                                    Expanded(
                                        child: MarkdownBody(data: content!)),
                                  ],
                                ),
                            ],
                          )))
                ])),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              const Text(
                "by ",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey),
              ),
              Expanded(
                child: Text(
                  username ?? noOne,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey),
                ),
              ),
              const Expanded(child: SizedBox()),
              const Icon(
                Icons.reply,
                color: Colors.white,
              ),
              Text(
                replyCount.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                " replies",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );

    final card = Card(
        child: widget.onTap == null
            ? view
            : InkWell(onTap: widget.onTap, child: view));
    return card;
  }
}
