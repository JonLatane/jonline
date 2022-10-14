import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/utils/enum_conversions.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
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

  @override
  void initState() {
    super.initState();
    appState.accounts.addListener(updateState);
    widget.usernameController?.addListener(updateGroupName);
    widget.usernameController?.text = user.username;
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
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

  bool get following => user.currentUserFollow.targetUserModeration.passes;
  bool get followRequestPending =>
      user.currentUserFollow.targetUserModeration.pending;

  bool get followsYou =>
      user.targetCurrentUserFollow.targetUserModeration.passes;
  bool get wantsToFollowYou =>
      user.targetCurrentUserFollow.targetUserModeration.pending;

  bool get member =>
      membership?.groupModeration.passes == true &&
      membership?.userModeration.passes == true;
  bool get wantsToJoinGroup => membership?.groupModeration.pending == true;

  @override
  Widget build(BuildContext context) {
    bool following = user.currentUserFollow.targetUserModeration.passes;
    bool cannotFollow = appState.selectedAccount == null ||
        appState.selectedAccount?.userId == user.id;
    final backgroundColor =
        appState.selectedAccount?.userId == user.id ? appState.navColor : null;
    final textColor = backgroundColor?.textColor;
    // print("user.targetCurrentUserFollow: ${user.targetCurrentUserFollow}");
    return Card(
      // color: Colors.blue,
      color: backgroundColor,
      child: InkWell(
        //    onTap: null, //TODO: Do we want to navigate the user somewhere?

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
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: Icon(Icons.account_circle,
                            size: 32, color: textColor ?? Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${JonlineServer.selectedServer.server}/',
                                      style: textTheme.caption?.copyWith(
                                          color: textColor?.withOpacity(0.5)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.username,
                                    style: textTheme.headline6
                                        ?.copyWith(color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (user.permissions.contains(Permission.ADMIN))
                        Tooltip(
                          message: "${user.username} is an admin",
                          child: SizedBox(
                            height: 32,
                            width: 32,
                            child: Icon(Icons.admin_panel_settings_outlined,
                                size: 24, color: textColor ?? Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                      duration: animationDuration,
                      height: wantsToJoinGroup ? 50 * mq.textScaleFactor : 0,
                      child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: wantsToJoinGroup ? 1 : 0,
                        child: Column(
                          children: [
                            Text(
                                "wants to join ${appState.selectedGroup.value?.name}",
                                style: textTheme.caption?.copyWith(
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
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
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
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
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
                                style: textTheme.caption?.copyWith(
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
                                                : () => approveFollowRequest(),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
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
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
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
                        child: Text("follows you",
                            style: textTheme.caption
                                ?.copyWith(color: textColor?.withOpacity(0.5))),
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
                              //   style: textTheme.caption?.copyWith(
                              //       color: textColor?.withOpacity(0.5)),
                              //   maxLines: 1,
                              //   overflow: TextOverflow.ellipsis,
                              // ),
                              // Expanded(
                              //   child: Text(
                              //     user.id,
                              //     style: textTheme.caption?.copyWith(
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
                                  style: textTheme.caption?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                              Text(
                                  " follower${user.followerCount == 1 ? '' : 's'}",
                                  style: textTheme.caption?.copyWith(
                                      color: textColor?.withOpacity(0.5))),
                              const Expanded(child: SizedBox()),
                              Text("following ${user.followingCount}",
                                  style: textTheme.caption?.copyWith(
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
                                            padding: MaterialStateProperty.all(
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
                          opacity: !(following || followRequestPending) ? 1 : 0,
                          child: Row(children: [
                            Expanded(
                                child: SizedBox(
                                    height: 32,
                                    child: TextButton(
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.all(0))),
                                        onPressed: cannotFollow
                                            ? null
                                            : () => follow(),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.add),
                                            const SizedBox(width: 4),
                                            Text(user.defaultFollowModeration
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
    );
  }

  follow() async {
    try {
      final follow = await (await JonlineAccount.selectedAccount!.getClient())!
          .createFollow(
              Follow(
                userId: JonlineAccount.selectedAccount!.userId,
                targetUserId: user.id,
              ),
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.currentUserFollow = follow;
        if (follow.targetUserModeration.passes) {
          user.followerCount += 1;
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
          Follow(
            userId: JonlineAccount.selectedAccount!.userId,
            targetUserId: user.id,
          ),
          options: JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.currentUserFollow = Follow();
        if (follow.targetUserModeration.passes) {
          user.followerCount -= 1;
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
              Follow(
                  userId: user.id,
                  targetUserId: JonlineAccount.selectedAccount!.userId,
                  targetUserModeration: Moderation.APPROVED),
              options:
                  JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.targetCurrentUserFollow = follow;
        if (follow.targetUserModeration.passes) {
          user.followingCount += 1;
          appState.users.value.where((u) => u.id == user.id).forEach((u) {
            u.followingCount += 1;
          });
          JonlineAccount.selectedAccount?.user?.followerCount += 1;
          appState.users.value
              .where((u) => u.id == JonlineAccount.selectedAccount?.userId)
              .forEach((u) {
            u.followerCount += 1;
          });
        }
      });
      showSnackBar('Approved request from ${user.username}.');
    } catch (e) {
      showSnackBar(formatServerError(e));
    }
  }

  rejectFollowRequest() async {
    try {
      await (await JonlineAccount.selectedAccount!.getClient())!.deleteFollow(
          Follow(
              userId: user.id,
              targetUserId: JonlineAccount.selectedAccount!.userId),
          options: JonlineAccount.selectedAccount!.authenticatedCallOptions);
      setState(() {
        user.targetCurrentUserFollow = Follow();
      });
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
                  Membership(
                      userId: user.id,
                      groupId: this.membership!.groupId,
                      groupModeration: Moderation.APPROVED),
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
              Membership(userId: user.id, groupId: membership!.groupId),
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
