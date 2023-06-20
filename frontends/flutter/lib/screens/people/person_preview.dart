import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fa_solid.dart';
import 'package:intl/intl.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/screens/media/media_image.dart';
import 'package:jonline/utils/moderation_accessors.dart';

import '../../app_state.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/users.pb.dart';
import '../../generated/visibility_moderation.pbenum.dart';
import '../../jonline_state.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../utils/colors.dart';

class Person {
  final User user;
  Membership? membership;

  Person(this.user, {this.membership});
}

class PersonPreview extends StatefulWidget {
  final String server;
  final Person person;
  final TextEditingController? usernameController;
  final bool navigable;

  const PersonPreview(
      {super.key,
      required this.server,
      required this.person,
      this.navigable = true,
      this.usernameController});

  @override
  State<PersonPreview> createState() => _PersonPreviewState();
}

class _PersonPreviewState extends JonlineState<PersonPreview> {
  Person get person => widget.person;
  User get user => person.user;
  Membership? get membership => person.membership;
  String get memberSince {
    final membership = this.membership;
    if (membership == null) return "";
    return DateFormat('yyyy-dd-MM HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(
            (membership.updatedAt.seconds * 1000).toInt()));
  }

  String get requestedOrInvitedAt {
    final membership = this.membership;
    if (membership == null) return "";
    return DateFormat('yyyy-dd-MM HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(
            (membership.createdAt.seconds * 1000).toInt()));
  }

  @override
  void initState() {
    super.initState();
    appState.accounts.addListener(updateState);
    appState.users.addListener(updateState);
    appState.selectedAccountChanged.addListener(updateState);
    widget.usernameController?.addListener(updateGroupName);
    widget.usernameController?.text = user.username;
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
    appState.users.removeListener(updateState);
    appState.selectedAccountChanged.removeListener(updateState);
    widget.usernameController?.removeListener(updateGroupName);

    super.dispose();
  }

  updateGroupName() {
    if (widget.usernameController != null) {
      setState(() {
        user.username = widget.usernameController!.text;
      });
    }
  }

  updateState() {
    setState(() {});
  }

  bool get admin => userPermissions.contains(Permission.ADMIN);
  bool get moderator => userPermissions.contains(Permission.MODERATE_USERS);

  bool get following => user.following;
  bool get followRequestPending => user.followRequestPending;

  bool get followsYou => user.followsYou;
  bool get wantsToFollowYou => user.wantsToFollowYou;

  bool get member => membership?.member ?? false;
  bool get wantsToJoinGroup => membership?.wantsToJoinGroup ?? false;

  bool get currentUserProfile => user.id == appState.selectedAccount?.userId;

  @override
  Widget build(BuildContext context) {
    bool following = user.currentUserFollow.targetUserModeration.passes;
    bool cannotFollow = appState.selectedAccount == null || currentUserProfile;
    final backgroundColor = currentUserProfile ? appState.navColor : null;
    final textColor = backgroundColor?.textColor;
    // print("user.targetCurrentUserFollow: ${user.targetCurrentUserFollow}");
    return Card(
      // color: Colors.blue,
      color: backgroundColor,
      child: AnimatedContainer(
        duration: animationDuration,
        color: backgroundColor,
        child: InkWell(
          onTap: () {
            context.navigateNamedTo(
                'person/${JonlineServer.selectedServer.server}/${user.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        // if (user.avatar.isNotEmpty)
                        //   CircleAvatar(
                        //     backgroundImage:
                        //         MemoryImage(Uint8List.fromList(user.avatar)),
                        //   )
                        // else
                        //   CircleAvatar(
                        //     child: Icon(
                        //       Icons.person,
                        //       color: textColor,
                        //     ),
                        //   ),
                        // const SizedBox(width: 8),
                        SizedBox(
                            height: 48,
                            width: 48,
                            child: (user.avatarMediaId.isNotEmpty)
                                ? CircleAvatar(
                                    backgroundImage:
                                        mediaImageProvider(user.avatarMediaId),
                                  )
                                : const CircleAvatar(
                                    backgroundColor: Colors.black12,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  )
                            // : Icon(Icons.account_circle,
                            //     size: 32, color: textColor ?? Colors.white),
                            ),
                        const SizedBox(width: 6),
                        // SizedBox(
                        //   height: 48,
                        //   width: 48,
                        //   child: Icon(Icons.account_circle,
                        //       size: 32, color: textColor ?? Colors.white),
                        // ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        '${JonlineServer.selectedServer.server}/',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: textColor?.withOpacity(0.5)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              if (widget.usernameController == null)
                                Tooltip(
                                  message: user.username,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.username,
                                          style: textTheme.titleLarge
                                              ?.copyWith(color: textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.usernameController != null)
                                TextField(
                                  // focusNode: titleFocus,
                                  controller: widget.usernameController,
                                  keyboardType: TextInputType.url,
                                  textCapitalization: TextCapitalization.words,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  maxLines: 1,
                                  cursorColor: Colors.white,
                                  style: textTheme.titleLarge
                                      ?.copyWith(color: textColor),
                                  enabled: currentUserProfile || admin,
                                  decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "Group Name",
                                      isDense: true),
                                  onChanged: (value) {},
                                ),
                              if (widget.usernameController != null &&
                                  (currentUserProfile || admin))
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "Username may be updated.",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: textColor ?? Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12),
                                    )),
                            ],
                          ),
                        ),
                        if (user.permissions.contains(Permission.RUN_BOTS))
                          Tooltip(
                            message: "${user.username} may run (or be) a bot",
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: Iconify(FaSolid.robot,
                                  size: 18, color: textColor ?? Colors.white),
                            ),
                          ),
                        if (user.permissions.contains(Permission.ADMIN))
                          Tooltip(
                            message: "${user.username} is an admin",
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: Icon(Icons.admin_panel_settings_outlined,
                                  size: 22, color: textColor ?? Colors.white),
                            ),
                          ),
                      ],
                    ),
                    if (member) const SizedBox(height: 4),
                    AnimatedContainer(
                        duration: animationDuration,
                        height: member ? 16 * mq.textScaleFactor : 0,
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: member ? 1 : 0,
                          child: Text("member since $memberSince",
                              style: textTheme.bodySmall?.copyWith(
                                  color: textColor?.withOpacity(0.5))),
                        )),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                        duration: animationDuration,
                        height: wantsToJoinGroup ? 64 * mq.textScaleFactor : 0,
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: wantsToJoinGroup ? 1 : 0,
                          child: Column(
                            children: [
                              Text(
                                  "wants to join ${appState.selectedGroup.value?.name}",
                                  style: textTheme.bodySmall?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                              const SizedBox(height: 4),
                              Text("requested at $requestedOrInvitedAt",
                                  style: textTheme.bodySmall?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                              Expanded(
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
                                              onPressed: cannotFollow
                                                  ? null
                                                  : () => approveMembership(),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.check),
                                                  SizedBox(width: 4),
                                                  Text("APPROVE")
                                                ],
                                              )))),
                                  // ]),
                                  // Row(children: [
                                  Expanded(
                                      child: SizedBox(
                                          height: 32,
                                          child: TextButton(
                                              style: ButtonStyle(
                                                  padding:
                                                      MaterialStateProperty.all(
                                                          const EdgeInsets.all(
                                                              0))),
                                              onPressed: cannotFollow
                                                  ? null
                                                  : () => rejectMembership(),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons
                                                      .remove_circle_outline),
                                                  SizedBox(width: 4),
                                                  Text("REJECT")
                                                ],
                                              ))))
                                ]),
                              ),
                            ],
                          ),
                        )),
                    AnimatedContainer(
                        duration: animationDuration,
                        height: wantsToFollowYou ? 50 * mq.textScaleFactor : 0,
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: wantsToFollowYou ? 1 : 0,
                          child: Column(
                            children: [
                              Text("wants to follow you",
                                  style: textTheme.bodySmall?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                              Expanded(
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
                                              onPressed: cannotFollow
                                                  ? null
                                                  : () =>
                                                      approveFollowRequest(),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.check),
                                                  SizedBox(width: 4),
                                                  Text("APPROVE")
                                                ],
                                              )))),
                                  // ]),
                                  // Row(children: [
                                  Expanded(
                                      child: SizedBox(
                                          height: 32,
                                          child: TextButton(
                                              style: ButtonStyle(
                                                  padding:
                                                      MaterialStateProperty.all(
                                                          const EdgeInsets.all(
                                                              0))),
                                              onPressed: cannotFollow
                                                  ? null
                                                  : () => rejectFollowRequest(),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons
                                                      .remove_circle_outline),
                                                  SizedBox(width: 4),
                                                  Text("REJECT")
                                                ],
                                              ))))
                                ]),
                              ),
                            ],
                          ),
                        )),
                    AnimatedContainer(
                        duration: animationDuration,
                        height: followsYou ? 16 * mq.textScaleFactor : 0,
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: followsYou ? 1 : 0,
                          child: Text(following ? "friends" : "follows you",
                              style: textTheme.bodySmall?.copyWith(
                                  color: textColor?.withOpacity(0.5))),
                        )),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                // Text(
                                //   "User ID: ",
                                //   style: textTheme.bodySmall?.copyWith(
                                //       color: textColor?.withOpacity(0.5)),
                                //   maxLines: 1,
                                //   overflow: TextOverflow.ellipsis,
                                // ),
                                // Expanded(
                                //   child: Text(
                                //     user.id,
                                //     style: textTheme.bodySmall?.copyWith(
                                //         color: textColor?.withOpacity(0.5)),
                                //     maxLines: 1,
                                //     overflow: TextOverflow.ellipsis,
                                //   ),
                                // ),
                                // const Icon(
                                //   Icons.account_circle,
                                //   color: Colors.white,
                                // ),
                                // const SizedBox(width: 4),
                                Text(user.followerCount.toString(),
                                    style: textTheme.bodySmall?.copyWith(
                                        color: textColor?.withOpacity(0.5))),
                                Text(
                                    " follower${user.followerCount == 1 ? '' : 's'}",
                                    style: textTheme.bodySmall?.copyWith(
                                        color: textColor?.withOpacity(0.5))),
                                const Expanded(child: SizedBox()),
                                Text("following ${user.followingCount}",
                                    style: textTheme.bodySmall?.copyWith(
                                        color: textColor?.withOpacity(0.5))),
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
                          ignoring: !(following || followRequestPending),
                          child: AnimatedOpacity(
                            duration: animationDuration,
                            opacity: following || followRequestPending ? 1 : 0,
                            child: Row(children: [
                              Expanded(
                                  child: SizedBox(
                                      height: 32,
                                      child: TextButton(
                                          style: ButtonStyle(
                                              padding:
                                                  MaterialStateProperty.all(
                                                      const EdgeInsets.all(0))),
                                          onPressed: () => unfollow(),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.remove_circle_outline),
                                              const SizedBox(width: 4),
                                              Text(followRequestPending
                                                  ? "CANCEL REQUEST"
                                                  : "UNFOLLOW")
                                            ],
                                          ))))
                            ]),
                          ),
                        ),
                        IgnorePointer(
                          ignoring: (following || followRequestPending),
                          child: AnimatedOpacity(
                            duration: animationDuration,
                            opacity:
                                !(following || followRequestPending) ? 1 : 0,
                            child: Row(children: [
                              Expanded(
                                  child: SizedBox(
                                      height: 32,
                                      child: TextButton(
                                          style: ButtonStyle(
                                              padding:
                                                  MaterialStateProperty.all(
                                                      const EdgeInsets.all(0))),
                                          onPressed: cannotFollow
                                              ? null
                                              : () => follow(),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (!currentUserProfile)
                                                const Icon(Icons.add),
                                              const SizedBox(width: 4),
                                              Text(currentUserProfile
                                                  ? "YOU"
                                                  : user.defaultFollowModeration
                                                          .pending
                                                      ? "REQUEST"
                                                      : "FOLLOW")
                                            ],
                                          ))))
                            ]),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  follow() async {
    try {
      final follow = await (await JonlineAccount.selectedAccount!.getClient())!
          .createFollow(
              Follow()
                ..userId = JonlineAccount.selectedAccount!.userId
                ..targetUserId = user.id,
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.currentUserFollow = follow;
        if (follow.targetUserModeration.passes) {
          // user.followerCount += 1;
          appState.users.value.where((u) => u.id == user.id).forEach((u) {
            u.followerCount += 1;
          });
          JonlineAccount.selectedAccount?.user?.followingCount += 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followingCount += 1;
          });
        }
      });
      appState.users.notify();
      // showSnackBar('Followed ${user.username}.');
      showSnackBar(
          '${follow.targetUserModeration.pending ? "Requested to follow" : "Followed"} ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  unfollow() async {
    final follow = user.currentUserFollow;
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!.deleteFollow(
          Follow()
            ..userId = JonlineAccount.selectedAccount!.userId
            ..targetUserId = user.id,
          options: JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.currentUserFollow = Follow();
        if (follow.targetUserModeration.passes) {
          // user.followerCount -= 1;
          appState.users.value.where((u) => u.id == user.id).forEach((u) {
            u.followerCount -= 1;
          });
          JonlineAccount.selectedAccount?.user?.followingCount -= 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followingCount -= 1;
          });
        }
      });
      appState.users.notify();
      showSnackBar(
          '${follow.targetUserModeration.pending ? "Canceled request to" : "Unfollowed"} ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  approveFollowRequest() async {
    try {
      final follow = await (await JonlineAccount.selectedAccount!.getClient())!
          .updateFollow(
              Follow()
                ..userId = user.id
                ..targetUserId = JonlineAccount.selectedAccount!.userId
                ..targetUserModeration = Moderation.APPROVED,
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.targetCurrentUserFollow = follow;
        if (follow.targetUserModeration.passes) {
          user.followingCount += 1;
          appState.users.value.where((u) => u.id == user.id).forEach((u) {
            u.followingCount += 1;
            u.targetCurrentUserFollow = follow;
          });
          JonlineAccount.selectedAccount?.user?.followerCount += 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followerCount += 1;
          });
        }
      });
      appState.users.notify();
      showSnackBar('Approved request from ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  rejectFollowRequest() async {
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!.deleteFollow(
          Follow()
            ..userId = user.id
            ..targetUserId = JonlineAccount.selectedAccount!.userId,
          options: JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.targetCurrentUserFollow = Follow();
      });
      appState.users.notify();
      showSnackBar('Rejected request from ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  approveMembership() async {
    try {
      final membership =
          await (await JonlineAccount.selectedAccount!.getClient())!
              .updateMembership(
                  Membership()
                    ..userId = user.id
                    ..groupId = this.membership!.groupId
                    ..groupModeration = Moderation.APPROVED,
                  options:
                      JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        person.membership = membership;
        if (membership.userModeration.passes &&
            membership.groupModeration.passes) {
          appState.groups.value
              .where((u) => u.id == membership.groupId)
              .forEach((g) {
            g.memberCount += 1;
            appState.selectedGroup.value?.memberCount = g.memberCount;
          });
        }
      });
      showSnackBar('Approved join request from ${user.username}.');
      await appState.updateGroups();
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  rejectMembership() async {
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!
          .deleteMembership(
              Membership()
                ..userId = user.id
                ..groupId = membership!.groupId,
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.targetCurrentUserFollow = Follow();
      });
      showSnackBar('Rejected join request from ${user.username}.');
      await appState.updateGroups();
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
