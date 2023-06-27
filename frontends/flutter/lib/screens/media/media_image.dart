import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';

import '../../models/jonline_server.dart';

ImageProvider mediaImageProvider(
  String mediaId, {
  String? serverOverride,
}) {
  final String server = serverOverride ?? JonlineServer.selectedServer.server;

  final protocol = server == 'localhost' ? 'http' : 'https';
  return NetworkImage("$protocol://$server/media/$mediaId");
}

class MediaImage extends StatefulWidget {
  final String? mediaId;
  final BoxFit? fit;
  final Alignment? alignment;
  final String? serverOverride;

  const MediaImage(
      {Key? key,
      required this.mediaId,
      this.fit,
      this.alignment,
      this.serverOverride})
      : super(key: key);

  @override
  MediaImageState createState() => MediaImageState();
}

class MediaImageState extends JonlineBaseState<MediaImage> {
  @override
  Widget build(BuildContext context) {
    final String server =
        widget.serverOverride ?? JonlineServer.selectedServer.server;
    if (widget.mediaId == null) {
      return const SizedBox();
    }
    final protocol = server == 'localhost' ? 'http' : 'https';
    return Image.network("$protocol://$server/media/${widget.mediaId}",
        fit: widget.fit ?? BoxFit.fitWidth,
        alignment: widget.alignment ?? Alignment.topLeft);
  }
}
