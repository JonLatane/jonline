import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';

import '../../generated/media.pb.dart';
import '../../models/jonline_server.dart';

// [media] may be a bare media ID (fetched via `/media/{id}`) or a `Media`/`MediaReference`,
// whose `url` (if set) is used directly instead -- used for media Jonline doesn't store
// locally, e.g. from federated ActivityPub/Mastodon or AT Protocol/Bluesky content.
ImageProvider mediaImageProvider(
  Object media, {
  String? serverOverride,
}) {
  return NetworkImage(mediaImageUrl(media, serverOverride: serverOverride));
}

String mediaImageUrl(
  Object media, {
  String? serverOverride,
}) {
  final String? url = media is MediaReference
      ? (media.hasUrl() ? media.url : null)
      : media is Media
          ? (media.hasUrl() ? media.url : null)
          : null;
  if (url != null && url.isNotEmpty) {
    return url;
  }
  final String mediaId = media is MediaReference
      ? media.id
      : media is Media
          ? media.id
          : media as String;
  final String server = serverOverride ?? JonlineServer.selectedServer.server;

  // TODO: use auth token
  final protocol = server == 'localhost' ? 'http' : 'https';
  return "$protocol://$server/media/$mediaId";
}

class MediaImage extends StatefulWidget {
  final Object? media;
  final BoxFit? fit;
  final Alignment? alignment;
  final String? serverOverride;

  const MediaImage(
      {Key? key,
      required this.media,
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
    if (widget.media == null) {
      return const SizedBox();
    }
    return Image.network(
        mediaImageUrl(widget.media!, serverOverride: widget.serverOverride),
        fit: widget.fit ?? BoxFit.fitWidth,
        alignment: widget.alignment ?? Alignment.topLeft);
  }
}
