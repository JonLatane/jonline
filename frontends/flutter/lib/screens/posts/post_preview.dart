import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fa_solid.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/models/jonline_operations.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:jonline/utils/moderation_accessors.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/posts.pb.dart';
import '../../generated/users.pb.dart';
import '../../jonotifier.dart';
import '../../models/jonline_clients.dart';
import '../../models/jonline_server.dart';
import '../../models/settings.dart';
import '../media/media_image.dart';

// import 'package:jonline/db.dart';
// final previewStorage = GetStorage('preview');

class PostPreview extends StatefulWidget {
  final String server;
  final Post post;
  final bool allowScrollingContent;
  final double? maxContentHeight;
  final VoidCallback? onTap;
  final bool isReply;
  final bool isReplyByAuthor;
  final Function()? onPressResponseCount;
  final Jonotifier? refreshContent;

  const PostPreview(
      {Key? key,
      required this.server,
      required this.post,
      this.maxContentHeight = 300,
      this.onTap,
      this.allowScrollingContent = false,
      this.isReply = false,
      this.isReplyByAuthor = false,
      this.onPressResponseCount,
      this.refreshContent})
      : super(key: key);

  @override
  PostPreviewState createState() => PostPreviewState();
}

class PostPreviewState extends JonlineBaseState<PostPreview> {
  static final log = Logger('PostPreviewState');
  Post get post => widget.post;
  GroupPost? get currentGroupPost {
    final groupId = appState.selectedGroup.value?.id;
    if (groupId == null) return null;
    if (post.currentGroupPost.groupId == groupId) {
      return post.currentGroupPost;
    }
    if (groupPosts == null) {
      loadGroupPosts();
      return null;
    }
    return groupPosts?.groupPosts
        .firstWhereOrNull((gp) => gp.groupId == groupId);
  }

  String? get title => post.title;
  String? get link => post.link.isEmpty
      ? null
      : post.link.startsWith(RegExp(r'https?://'))
          ? post.link
          : 'http://${post.link}';
  String? get previewMediaId => post.media.firstOrNull?.id;
  // String get previewKey => "post-preview-${widget.server}:${post.id}";
  // List<int>? previewImage;
  String? get content => post.content.isEmpty ? null : post.content;
  String? get username =>
      post.author.username.isEmpty ? null : post.author.username;
  int get responseCount => post.responseCount;

  bool loadingGroupPosts = false;
  bool failedToLoadGroupPosts = false;
  bool loadingServerPreview = false;
  bool hasLoadedServerPreview = false;
  bool failedToLoadServerPreview = false;
  User? get author =>
      appState.users.value.where((u) => u.id == post.author.userId).firstOrNull;

  GetGroupPostsResponse? groupPosts;

  @override
  void initState() {
    super.initState();
    // final key = previewKey;
    // if (MemoryCache.instance.contains(key)) {
    //   previewImage = MemoryCache.instance.read(key);
    //   hasLoadedServerPreview = true;
    // }

    loadGroupPosts();

    widget.refreshContent?.addListener(refreshContent);
  }

  @override
  dispose() {
    widget.refreshContent?.removeListener(refreshContent);
    super.dispose();
  }

  refreshContent() async {
    await loadGroupPosts();
  }

  loadGroupPosts() async {
    if (widget.isReply) return;
    if (groupPosts != null || loadingGroupPosts || failedToLoadGroupPosts) {
      return;
    }

    setState(() => loadingGroupPosts = true);
    try {
      log.fine("Loading group posts for ${post.id}");
      final groupPosts = await JonlineOperations.getGroupPosts(
          GetGroupPostsRequest()..postId = post.id,
          showMessage: (e) => log.info(e));
      if (!mounted) return;
      setState(() {
        this.groupPosts = groupPosts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => failedToLoadGroupPosts = true);
    } finally {
      if (mounted) {
        setState(() => loadingGroupPosts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget view = AnimatedContainer(
      duration: animationDuration,
      padding: const EdgeInsets.only(
          top: 8.0, left: 8.0, right: 8.0, bottom: 4.0), //child: Text('hi')
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
                        ? textTheme.titleLarge
                        : title!.length < 20
                            ? textTheme.titleLarge
                            : title!.length < 255
                                ? textTheme.titleMedium
                                : textTheme.titleSmall,
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
                              // if (link != null &&
                              //     !Settings.preferServerPreviews)
                              //   buildLocalPreview(context),
                              // if (link != null &&
                              //     (Settings.preferServerPreviews &&
                              //         (hasLoadedServerPreview &&
                              //             previewImage == null)))
                              //   SizedBox(
                              //       height: previewHeight,
                              //       child: buildLocalPreview(context)),
                              if (previewMediaId?.isNotEmpty == true) // &&
                                // Settings.preferServerPreviews)
                                buildServerPreview(context),
                              // if (link != null &&
                              //     // Settings.preferServerPreviews &&
                              //     !hasLoadedServerPreview)
                              //   buildLoadingServerPreview(context),
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
              Expanded(
                flex: 5,
                child: TextButton(
                  style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  )),
                  onPressed: () {
                    context.navigateNamedTo(
                        '/posts/author/${widget.server}/${post.author.userId}');
                  },
                  child: Row(
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
                      if (author?.hasAvatar() ?? false)
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: CircleAvatar(
                            backgroundImage:
                                mediaImageProvider(author!.avatar.id),
                            maxRadius: 10,
                          ),
                        ),
                      if (author?.permissions.contains(Permission.RUN_BOTS) ??
                          false)
                        Tooltip(
                          message: "${author?.username} may run (or be) a bot",
                          child: const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Iconify(FaSolid.robot,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      if (author?.permissions.contains(Permission.ADMIN) ??
                          false)
                        Tooltip(
                          message: "${author?.username} is an admin",
                          child: const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(Icons.admin_panel_settings_outlined,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          username ?? noOne,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: widget.isReplyByAuthor
                                  ? appState.authorColor
                                  : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              TextButton(
                style: ButtonStyle(
                    padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                )),
                onPressed: widget.onPressResponseCount,
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply,
                      color: Colors.white,
                    ),
                    Text(
                      responseCount.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.white),
                    ),
                    Text(
                      " response${responseCount == 1 ? "" : "s"}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (!widget.isReply)
                PostPreviewGroupChooser(
                  post: post,
                  currentGroupPost: currentGroupPost,
                  groupPosts: groupPosts,
                  refreshNotifier: widget.refreshContent,
                ),
              const Expanded(
                child: SizedBox(),
              )
            ],
          )
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
              child: Text(post.id, style: textTheme.bodySmall),
            ),
          )
        ],
      );
    }

    final card = Card(
        color: Colors.grey[800],
        child: widget.onTap == null
            ? view
            : InkWell(onTap: widget.onTap, child: view));
    return card;
  }

  Widget buildServerPreview(BuildContext context) {
    if (link == null) return const SizedBox();
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
                    child: MediaImage(mediaId: previewMediaId!),
                  )
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
                                  .bodySmall!
                                  .copyWith(color: appState.primaryColor),
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
        errorWidget: (previewMediaId != null && previewMediaId!.isNotEmpty)
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
    //   width:mq.size.width,
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
        color: appState.navColor.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            const Row(
              children: [
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
                      .copyWith(color: appState.primaryColor),
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
            const Row(
              children: [
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
                      .copyWith(color: appState.primaryColor),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}

class PostPreviewGroupChooser extends StatefulWidget {
  final Post post;
  final GroupPost? currentGroupPost;
  final GetGroupPostsResponse? groupPosts;
  final Jonotifier? refreshNotifier;

  const PostPreviewGroupChooser(
      {required this.post,
      required this.currentGroupPost,
      required this.groupPosts,
      required this.refreshNotifier,
      super.key});

  @override
  State<PostPreviewGroupChooser> createState() =>
      _PostPreviewGroupChooserState();
}

class _PostPreviewGroupChooserState
    extends JonlineState<PostPreviewGroupChooser> {
  bool posting = false;

  @override
  Widget build(BuildContext context) {
    Widget view;
    if (appState.selectedGroup.value == null) {
      view = Row(children: [
        Text(
            "posted in ${widget.post.groupCount} group${widget.post.groupCount == 1 ? "" : "s"}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w300, color: Colors.grey)),
      ]);
    } else if (widget.currentGroupPost == null) {
      final String groupName = appState.selectedGroup.value!.name;
      view = Row(children: [
        Text(
            "posted in ${widget.post.groupCount} group${widget.post.groupCount == 1 ? "" : "s"}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w300, color: Colors.grey)),
        Text(posting ? ". Posting to " : ", but not ",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w300, color: Colors.grey)),
        Text(
          groupName,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (posting)
          const Text("... ",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey)),
      ]);
    } else {
      final otherGroupCount = widget.post.groupCount - 1;
      final String groupName = appState.groups.value
          .firstWhere((g) => g.id == widget.currentGroupPost!.groupId)
          .name;
      view = Row(children: [
        const Text("posted in ",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w300, color: Colors.grey)),
        Text(
          groupName,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
            " and $otherGroupCount other group${otherGroupCount == 1 ? "" : "s"}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w300, color: Colors.grey)),
      ]);
    }
    return TextButton(
      style: ButtonStyle(
          padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      )),
      onPressed: () {
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox? overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox?;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(button.size.bottomRight(Offset.zero),
                ancestor: overlay),
          ),
          Offset.zero & (overlay?.size ?? Size.zero),
        );
        showGroupChooser(context, position);
      },
      child: view,
    );
  }

  Future<Object> showGroupChooser(
      BuildContext context, RelativeRect position) async {
    ThemeData theme = Theme.of(context);
    // TextTheme textTheme = theme.textTheme;
    ThemeData darkTheme = theme;
    // final appState = context.findRootAncestorStateOfType<AppState>()!;
    final groups = (widget.groupPosts?.groupPosts ?? [])
        .map((e) => appState.groups.value.firstWhere((g) => g.id == e.groupId));
    // if (appState.selectedGroup.value != null &&
    //     !groups.any((g) => appState.selectedGroup.value?.id == g.id)) {
    //   appState.selectedGroup.value = null;
    // }
    final myGroups = groups.where((g) => g.member);
    final pendingGroups = groups.where((g) => g.wantsToJoinGroup);
    final otherGroups = groups.where((g) => !g.member && !g.wantsToJoinGroup);
    return showMenu(
        context: context,
        position: position,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Colors.grey[700],
        // color: (musicBackgroundColor.luminance < 0.5
        //         ? subBackgroundColor
        //         : musicBackgroundColor)
        //     .withOpacity(0.95),
        items: [
          // PopupMenuItem(
          //   padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          //   mouseCursor: SystemMouseCursors.basic,
          //   value: null,
          //   enabled: false,
          //   child: Text(
          //     'Accounts',
          //     style: darkTheme.textTheme.titleLarge,
          //   ),
          // ),
          PopupMenuItem(
            padding: EdgeInsets.zero,
            mouseCursor: SystemMouseCursors.basic,
            value: null,
            enabled: false,
            child: Column(children: [
              if (widget.currentGroupPost == null &&
                  appState.selectedGroup.value != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: appState.selectedAccount == null
                        ? null
                        : () async {
                            setState(() => posting = true);
                            Navigator.pop(context);
                            try {
                              final client = await JonlineClients
                                  .getSelectedOrDefaultClient();
                              await client!.createGroupPost(
                                  GroupPost()
                                    ..groupId = appState.selectedGroup.value!.id
                                    ..postId = widget.post.id,
                                  options: JonlineAccount.selectedAccount!
                                      .authenticatedCallOptions);
                            } catch (e) {
                              // showSnackBar("Error loading group posts.");
                              showSnackBar(formatServerError(e));
                            }

                            widget.refreshNotifier?.call();
                            // Kinda hacky :/
                            await Future.delayed(const Duration(seconds: 2));

                            if (!mounted) return;
                            setState(() => posting = false);
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  appState.selectedAccount == null
                                      ? "Login to post to "
                                      : 'Post to ',
                                  style: darkTheme.textTheme.bodySmall,
                                ),
                                Text(
                                  appState.selectedGroup.value?.name ?? '',
                                  style: darkTheme.textTheme.titleMedium!
                                      .copyWith(
                                          color:
                                              appState.selectedAccount == null
                                                  ? Colors.grey
                                                  : null),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // if (post.title.isNotEmpty)
                    //   Row(
                    //     children: [
                    //       Expanded(
                    //         child: Text(
                    //           post.title,
                    //           style: darkTheme.textTheme.titleMedium,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    const SizedBox(height: 8),
                    Text(
                      "Currently posted to:",
                      style: darkTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (myGroups.isNotEmpty &&
                  (pendingGroups.isNotEmpty || otherGroups.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'My Groups on ',
                        style: myGroups.isEmpty
                            ? darkTheme.textTheme.titleMedium
                            : darkTheme.textTheme.titleLarge,
                      ),
                      Text(
                        "${JonlineServer.selectedServer.server}/",
                        style: darkTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ...myGroups.map((a) => _groupItem(a, context)),
              if (pendingGroups
                      .isNotEmpty /*&&
                  (myGroups.isNotEmpty || otherGroups.isNotEmpty)*/
                  )
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Requested Memberships',
                        style: darkTheme.textTheme.titleLarge,
                      ),
                      // Text(
                      //   "${JonlineServer.selectedServer.server}/",
                      //   style: darkTheme.textTheme.bodySmall,
                      // ),
                    ],
                  ),
                ),
              ...pendingGroups.map((a) => _groupItem(a, context)),
              if (otherGroups.isNotEmpty &&
                  (myGroups.isNotEmpty || pendingGroups.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Other Groups on ',
                        style: otherGroups.isEmpty
                            ? darkTheme.textTheme.titleMedium
                            : darkTheme.textTheme.titleLarge,
                      ),
                      Text(
                        "${JonlineServer.selectedServer.server}/",
                        style: darkTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ...otherGroups.map((a) => _groupItem(a, context)),
            ]),
          ),
        ]);
  }

  Widget _groupItem(Group g, BuildContext context) {
    ThemeData darkTheme = Theme.of(context);
    ThemeData lightTheme = ThemeData.light();
    bool selected = g.id ==
        context
            .findRootAncestorStateOfType<AppState>()!
            .selectedGroup
            .value
            ?.id;
    ThemeData theme = selected ? lightTheme : darkTheme;
    TextTheme textTheme = theme.textTheme;
    return Theme(
      data: theme,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        child: InkWell(
            mouseCursor: SystemMouseCursors.basic,
            onTap: () {
              Navigator.pop(context);
              AppState appState =
                  context.findRootAncestorStateOfType<AppState>()!;
              if (selected) {
                appState.selectedGroup.value = null;
                showSnackBar(
                    "Viewing all groups on ${JonlineServer.selectedServer.server}.");
              } else {
                appState.selectedGroup.value = g;
                showSnackBar(
                    "Viewing ${g.name} on ${JonlineServer.selectedServer.server}.");
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Column(
                    children: [Icon(Icons.group_work)],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              "${JonlineServer.selectedServer.server}/g/${g.id}",
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall
                              // style: const TextStyle(color: Colors.white)
                              ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(g.name,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium),
                        ),
                      ],
                    ),
                  ),
                  if (g.currentUserMembership.permissions
                      .contains(Permission.RUN_BOTS))
                    const Iconify(FaSolid.robot, size: 16),
                  if (g.currentUserMembership.permissions
                      .contains(Permission.ADMIN))
                    const Icon(Icons.admin_panel_settings_outlined, size: 16)
                ],
              ),
            )),
      ),
    );
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
