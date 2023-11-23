import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/utils/moderation_accessors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/users.pb.dart';
import '../../jonline_state.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';
import '../../utils/colors.dart';

class GroupPreview extends StatefulWidget {
  final String server;
  final Group group;
  final TextEditingController? groupNameController;
  final TextEditingController? descriptionController;
  final bool navigable;

  const GroupPreview(
      {super.key,
      required this.server,
      required this.group,
      this.navigable = true,
      this.groupNameController,
      this.descriptionController});

  @override
  State<GroupPreview> createState() => _GroupPreviewState();
}

class _GroupPreviewState extends JonlineState<GroupPreview> {
  Group get group => widget.group;
  bool editingDescription = false;

  @override
  void initState() {
    super.initState();
    appState.accounts.addListener(updateState);
    widget.groupNameController?.addListener(updateGroupName);
    widget.groupNameController?.text = group.name;
    widget.descriptionController?.addListener(updateDescription);
    widget.descriptionController?.text = group.description;
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
    widget.groupNameController?.removeListener(updateGroupName);

    super.dispose();
  }

  updateGroupName() {
    if (widget.groupNameController != null) {
      setState(() {
        group.name = widget.groupNameController!.text;
      });
    }
  }

  updateDescription() {
    if (widget.descriptionController != null) {
      setState(() {
        group.description = widget.descriptionController!.text;
      });
    }
  }

  updateState() {
    setState(() {});
  }

  List<Permission> get groupPermissions =>
      group.currentUserMembership.permissions;

  bool get member => group.member;
  bool get admin => userPermissions.contains(Permission.ADMIN);
  bool get moderator => userPermissions.contains(Permission.MODERATE_GROUPS);
  bool get groupAdmin => admin || groupPermissions.contains(Permission.ADMIN);

  @override
  Widget build(BuildContext context) {
    bool isMember = group.currentUserMembership.groupModeration.passes;
    bool invitePending = group.currentUserMembership.groupModeration.pending;
    bool canJoin = appState.selectedAccount != null;
    bool selected = appState.selectedGroup.value?.id == group.id;
    final backgroundColor = selected ? appState.navColor : Colors.grey[800];
    final textColor = backgroundColor?.textColor;
    return Card(
      color: backgroundColor,
      // color:
      //     appState.selectedAccount?.id == group.id ? appState.navColor : null,
      child: InkWell(
        onLongPress: () {
          if (selected) {
            appState.selectedGroup.value = null;
          } else {
            appState.selectedGroup.value = group;
          }
        },
        onTap: widget.navigable
            ? () {
                context.navigateTo(GroupDetailsRoute(
                    groupId: group.id,
                    server: JonlineServer.selectedServer.server));
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: Icon(Icons.group_work_outlined,
                            size: 32, color: textColor ?? Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${JonlineServer.selectedServer.server}/group/${group.id}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: textColor?.withOpacity(0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      if (widget.groupNameController == null)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                group.name,
                                                textAlign: TextAlign.left,
                                                style: textTheme.titleLarge
                                                    ?.copyWith(
                                                  color: textColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (widget.groupNameController != null)
                                        TextField(
                                          // focusNode: titleFocus,
                                          controller:
                                              widget.groupNameController,
                                          keyboardType: TextInputType.url,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          enableSuggestions: true,
                                          autocorrect: true,
                                          maxLines: 1,
                                          cursorColor: Colors.white,
                                          style: textTheme.titleLarge
                                              ?.copyWith(color: textColor),
                                          enabled: member || admin,
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Group Name",
                                              isDense: true),
                                          onChanged: (value) {},
                                        ),
                                      if (widget.groupNameController != null)
                                        Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              "Group Name may be updated.",
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color:
                                                      textColor ?? Colors.white,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12),
                                            )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!editingDescription)
                    Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 150),
                                child: Opacity(
                                  opacity: 0.5,
                                  child: Transform.translate(
                                    offset: const Offset(0, -2),
                                    child: Transform.scale(
                                      scale: 0.9,
                                      child: Theme(
                                          data: (backgroundColor?.bright == true
                                                  ? ThemeData.light()
                                                  : ThemeData.dark())
                                              .copyWith(
                                            colorScheme: ColorScheme.fromSeed(
                                                seedColor:
                                                    appState.primaryColor),
                                          ),
                                          child: MarkdownBody(
                                            data: group.description,
                                            selectable: false,
                                            onTapLink: (text, href, title) {
                                              if (href != null) {
                                                try {
                                                  launchUrl(Uri.parse(href));
                                                } catch (e) {
                                                  showSnackBar(
                                                      "Invalid link. 😔");
                                                }
                                              } else {
                                                showSnackBar("No link. 😔");
                                              }
                                            },
                                          )),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                  if (editingDescription)
                    Theme(
                        data: (backgroundColor?.bright == true
                                ? ThemeData.light()
                                : ThemeData.dark())
                            .copyWith(
                          colorScheme: ColorScheme.fromSeed(
                              seedColor: appState.primaryColor),
                        ),
                        child: TextField(
                          controller: widget.descriptionController,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          enableSuggestions: true,
                          autocorrect: true,
                          maxLines: null,
                          cursorColor: Colors.white,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 14),
                          // enabled: enabled.value,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Description",
                              isDense: true),
                          onChanged: (value) {},
                        )),
                  if (widget.descriptionController != null)
                    TextButton(
                      onPressed: () => setState(() {
                        editingDescription = !editingDescription;
                      }),
                      child: Text(
                          editingDescription ? "DONE" : "EDIT DESCRIPTION"),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            context.navigateNamedTo('/posts');
                            appState.selectedGroup.value = group;
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble,
                                color: textColor ?? Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                group.postCount.toString(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: textColor?.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                " post${group.postCount == 1 ? '' : 's'}",
                                style: textTheme.bodySmall?.copyWith(
                                  color: textColor?.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: SizedBox(),
                        ),
                        TextButton(
                          onPressed: () {
                            context.navigateNamedTo('/people');
                            appState.selectedGroup.value = group;
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: textColor ?? Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                group.memberCount.toString(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: textColor?.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                " member${group.memberCount == 1 ? '' : 's'}",
                                style: textTheme.bodySmall?.copyWith(
                                  color: textColor?.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      IgnorePointer(
                        ignoring: !(isMember || invitePending),
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: isMember || invitePending ? 1 : 0,
                          child: Row(children: [
                            Expanded(
                                child: SizedBox(
                                    height: 32,
                                    child: TextButton(
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.all(0))),
                                        onPressed: () => leaveGroup(group),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                                Icons.remove_circle_outline),
                                            const SizedBox(width: 4),
                                            Text(invitePending
                                                ? "CANCEL REQUEST"
                                                : "LEAVE")
                                          ],
                                        ))))
                          ]),
                        ),
                      ),
                      IgnorePointer(
                          ignoring: (isMember || invitePending),
                          child: AnimatedOpacity(
                              duration: animationDuration,
                              opacity: !(isMember || invitePending) ? 1 : 0,
                              child: Row(children: [
                                Expanded(
                                    child: SizedBox(
                                        height: 32,
                                        child: TextButton(
                                            style: ButtonStyle(
                                                padding:
                                                    MaterialStateProperty.all(
                                                        const EdgeInsets.all(
                                                            0))),
                                            onPressed: canJoin
                                                ? () => joinGroup(group)
                                                : null,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.add),
                                                const SizedBox(width: 4),
                                                Text(group
                                                        .defaultMembershipModeration
                                                        .pending
                                                    ? "REQUEST"
                                                    : "JOIN")
                                              ],
                                            ))))
                              ]))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  joinGroup(Group group) async {
    try {
      final membership =
          await (await JonlineAccount.selectedAccount!.getClient())!
              .createMembership(
                  Membership()
                    ..userId = JonlineAccount.selectedAccount!.userId
                    ..groupId = group.id,
                  options:
                      JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        group.currentUserMembership = membership;
        if (membership.member) {
          group.memberCount += 1;
        }
      });
      showSnackBar(
          '${group.defaultMembershipModeration.pending ? "Requested to join" : "Joined"} ${group.name}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  leaveGroup(Group group) async {
    final membership = group.currentUserMembership;
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!
          .deleteMembership(
              Membership()
                ..userId = JonlineAccount.selectedAccount!.userId
                ..groupId = group.id,
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        group.currentUserMembership = Membership();

        if (membership.groupModeration.passes &&
            membership.userModeration.passes) {
          group.memberCount -= 1;
        }
      });
      showSnackBar(
          '${membership.groupModeration.pending ? "Canceled request for" : "Left"} ${group.name}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
