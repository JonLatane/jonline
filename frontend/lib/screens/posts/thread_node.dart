import 'package:flutter/material.dart';

import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import 'post_preview.dart';

// import 'package:jonline/db.dart';

class ThreadNode extends StatefulWidget {
  final Post post;
  // final bool allowScrollingContent;
  // final double? maxContentHeight;
  // final VoidCallback? onTap;
  const ThreadNode({
    Key? key,
    required this.post,
    // this.maxContentHeight = 300,
    // this.onTap,
    // this.allowScrollingContent = false
  }) : super(key: key);

  @override
  ThreadNodeState createState() => ThreadNodeState();
}

class ThreadNodeState extends State<ThreadNode> {
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
    final Widget view = PostPreview(
      server: JonlineAccount.selectedServer,
      post: widget.post,
      maxContentHeight: null,
    );

    //InkWell(onTap: widget.onTap, child: view)
    final card = Card(child: view);
    return card;
  }
}
