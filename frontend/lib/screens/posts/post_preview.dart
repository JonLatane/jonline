import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jonline/models/jonline_operations.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_state.dart';
import '../../generated/posts.pb.dart';
import '../../models/settings.dart';

// import 'package:jonline/db.dart';
final previewStorage = GetStorage('preview');

class PostPreview extends StatefulWidget {
  final String server;
  final Post post;
  final bool allowScrollingContent;
  final double? maxContentHeight;
  final VoidCallback? onTap;
  final bool isReply;
  const PostPreview(
      {Key? key,
      required this.server,
      required this.post,
      this.maxContentHeight = 300,
      this.onTap,
      this.isReply = false,
      this.allowScrollingContent = false})
      : super(key: key);

  @override
  PostPreviewState createState() => PostPreviewState();
}

class PostPreviewState extends State<PostPreview> {
  TextTheme get textTheme => Theme.of(context).textTheme;

  String? get title => widget.post.title;
  String? get link => widget.post.link.isEmpty
      ? null
      : widget.post.link.startsWith(RegExp(r'https?://'))
          ? widget.post.link
          : 'http://${widget.post.link}';
  List<int>? previewImage;
  String? get content =>
      widget.post.content.isEmpty ? null : widget.post.content;
  String? get username =>
      widget.post.author.username.isEmpty ? null : widget.post.author.username;
  int get replyCount => widget.post.replyCount;

  bool _hasLoadedServerPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.link.isNotEmpty) {
      loadServerPreview();
    }
  }

  @override
  dispose() {
    super.dispose();
  }

  loadServerPreview() async {
    if (_hasLoadedServerPreview) return;
    final key = "${widget.server}:${widget.post.id}";
    List<int>? previewData;
    if (previewStorage.hasData(key)) {
      previewData = previewStorage.read(key).cast<int>();
    }
    if (previewData == null) {
      previewData = (await JonlineOperations.getSelectedPosts(
              request: GetPostsRequest(postId: widget.post.id),
              showMessage: showSnackBar))
          ?.posts
          .firstOrNull
          ?.previewImage;
      previewStorage.write(key, previewData);
    }
    if (previewData != null && previewData.isNotEmpty) {
      setState(() {
        previewImage = previewData;
      });
    }
    setState(() {
      _hasLoadedServerPreview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget view = AnimatedContainer(
      duration: animationDuration,
      padding: const EdgeInsets.all(8.0), //child: Text('hi')
      child: Column(
        children: [
          // Text("hi"),
          if (title?.isNotEmpty == true && !widget.isReply)
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: content != null
                        ? Theme.of(context).textTheme.titleLarge
                        : title!.length < 20
                            ? Theme.of(context).textTheme.titleLarge
                            : title!.length < 255
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
                              if (link != null &&
                                  !Settings.preferServerPreviews)
                                buildLocalPreview(context),
                              if (link != null &&
                                  (Settings.preferServerPreviews &&
                                      (_hasLoadedServerPreview &&
                                          previewImage == null)))
                                SizedBox(
                                    height: previewHeight,
                                    child: buildLocalPreview(context)),
                              if (previewImage != null &&
                                  Settings.preferServerPreviews)
                                buildServerPreview(context),
                              if (link != null &&
                                  Settings.preferServerPreviews &&
                                  !_hasLoadedServerPreview)
                                buildLoadingServerPreview(context),
                              if (content != null)
                                Container(
                                  height: 8,
                                ),
                              if (content != null)
                                Row(
                                  children: [
                                    Expanded(
                                        child: MarkdownBody(
                                      data: content!,
                                      selectable:
                                          widget.maxContentHeight == null ||
                                              widget.allowScrollingContent,
                                      onTapLink: (text, href, title) {
                                        if (href != null) {
                                          try {
                                            launchUrl(Uri.parse(href));
                                          } catch (e) {
                                            showSnackBar("Invalid link. 😔");
                                          }
                                        } else {
                                          showSnackBar("No link. 😔");
                                        }
                                      },
                                    )),
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
              Text(
                " repl${replyCount == 1 ? "y" : "ies"}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );

    if (Settings.developerMode) {
      view = Stack(
        children: [
          view,
          Align(
            alignment: Alignment.topRight,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.post.id, style: textTheme.caption),
            ),
          )
        ],
      );
    }

    final card = Card(
        child: widget.onTap == null
            ? view
            : InkWell(onTap: widget.onTap, child: view));
    return card;
  }

  Widget buildServerPreview(BuildContext context) {
    return Tooltip(
      message: link!,
      child: SizedBox(
        height: previewHeight,
        child: Stack(
          children: [
            Opacity(
              opacity: 0.8,
              child: Row(
                children: [
                  Expanded(
                    child: Image.memory(
                        Uint8List.fromList(
                          previewImage!,
                        ),
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topLeft),
                  ),
                ],
              ),
            ),
            InkWell(
                onTap: () => launchUrl(Uri.parse(link!)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            color: Colors.black.withOpacity(0.8),
                            child: Text(
                              link!,
                              maxLines: 2,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .caption!
                                  .copyWith(color: topColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }

  static const double previewHeight = 250;

  Widget buildLocalPreview(BuildContext context) {
    // return Tooltip(
    //   message: link!,
    //   child: AnyLinkPreview(
    //     link: link!,
    //     displayDirection: UIDirection.uiDirectionHorizontal,
    //     showMultimedia: true,
    //     bodyMaxLines: 5,
    //     bodyTextOverflow: TextOverflow.ellipsis,
    //     titleStyle: const TextStyle(
    //       color: Colors.black,
    //       fontWeight: FontWeight.bold,
    //       fontSize: 15,
    //     ),
    //     bodyStyle: const TextStyle(color: Colors.grey, fontSize: 12),
    //     errorWidget: (previewImage != null && previewImage!.isNotEmpty)
    //         ? buildServerPreview(context)
    //         : buildPreviewUnavailable(context),
    //     // errorImage: "https://google.com/",
    //     cache: const Duration(days: 7),
    //     backgroundColor: Colors.grey[300],
    //     borderRadius: 12,
    //     removeElevation: false,
    //     boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.grey)],
    //     // onTap: () {}, // This disables tap event
    //   ),
    // );

    // return LinkPreviewGenerator(
    //   bodyMaxLines: 3,
    //   link: link!,
    //   linkPreviewStyle: LinkPreviewStyle.large,
    //   showGraphic: true,
    // );

    return Tooltip(
      message: link!,
      child: LinkPreviewGenerator(
        key: ValueKey(link),
        bodyMaxLines: 3,
        link: link!,
        linkPreviewStyle:
            content != null ? LinkPreviewStyle.small : LinkPreviewStyle.large,
        // errorBody: '',
        errorWidget: (previewImage != null && previewImage!.isNotEmpty)
            ? buildServerPreview(context)
            : buildPreviewUnavailable(context),
        showGraphic: true,
      ),
    );

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
  }

  Widget buildPreviewUnavailable(BuildContext context) {
    return InkWell(
      onTap: () {
        try {
          launchUrl(Uri.parse(link!));
        } catch (e) {
          showSnackBar("Failed to open link");
        }
      },
      child: Container(
        color: bottomColor.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(child: Text('Preview unavailable 😔')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(
                  link!,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: topColor),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingServerPreview(BuildContext context) {
    return InkWell(
      onTap: () {
        try {
          launchUrl(Uri.parse(link!));
        } catch (e) {
          showSnackBar("Failed to open link");
        }
      },
      child: Container(
        height: previewHeight,
        color: Colors.white.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(child: Text('Preview loading...')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(
                  link!,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: topColor),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
