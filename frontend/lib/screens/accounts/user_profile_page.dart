import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/utils/colors.dart';
import 'package:jonline/utils/enum_conversions.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../../app_state.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/users.pb.dart';
import '../../generated/visibility_moderation.pbenum.dart' as vm;
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_operations.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';
import '../../utils/proto_utils.dart';

class UserProfilePage extends StatefulWidget {
  final String? accountId;
  final String? server;
  final String? userId;

  const UserProfilePage(
      {Key? key,
      @pathParam this.server,
      @pathParam this.userId,
      this.accountId})
      : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class AuthorProfilePage extends UserProfilePage {
  const AuthorProfilePage({
    Key? key,
    @pathParam super.server,
    @pathParam super.userId,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class MyProfilePage extends UserProfilePage {
  const MyProfilePage({
    Key? key,
    @pathParam super.accountId,
  }) : super(key: key, server: null, userId: null);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends JonlineState<UserProfilePage> {
  bool loading = true;
  JonlineAccount? account;
  User? userData;
  bool get loaded => userData != null;
  TextEditingController usernameController = TextEditingController();

  bool get ownProfile =>
      widget.accountId != null ||
      widget.userId == JonlineAccount.selectedAccount?.userId;
  bool get admin => widget.accountId != null
      ? userData?.permissions.contains(Permission.ADMIN) == true
      : JonlineAccount.selectedAccount?.permissions
              .contains(Permission.ADMIN) ==
          true;
  bool get moderator => widget.accountId != null
      ? userData?.permissions.contains(Permission.MODERATE_USERS) == true
      : JonlineAccount.selectedAccount?.permissions
              .contains(Permission.MODERATE_USERS) ==
          true;

  @override
  initState() {
    super.initState();
    appState.accounts.addListener(updateState);
    usernameController.addListener(() {
      setState(() {
        userData = userData?.jonRebuild((u) {
          u.username = usernameController.text;
        });
        account?.user = userData;
      });
    });
    Future.microtask(updateProfileData);
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
    usernameController.dispose();
    super.dispose();
  }

  updateState() {
    setState(() {});
  }

  updateProfileData() async {
    JonlineAccount? account;
    User? userData;
    if (widget.accountId != null) {
      account = (await JonlineAccount.accounts).firstWhere(
        (account) => account.id == widget.accountId,
      );
      await account.updateUserData();
      userData = account.user;
    } else {
      final users = (await JonlineOperations.getUsers(
                  request: GetUsersRequest(userId: widget.userId)))
              ?.users ??
          [];
      userData = users.singleOrNull;
    }
    setState(() {
      usernameController.text = userData?.username ?? '';
      this.account = account;
      this.userData = userData;
      loading = false;
    });
    // This keeps the rest of the app consistent with the new server data.
    if (widget.accountId != null) {
      appState.updateAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accountId == null &&
        JonlineServer.selectedServer.server != widget.server) {
      context.replaceRoute(const PeopleRoute());
    }
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: RefreshIndicator(
              displacement: mq.padding.top + 40,
              onRefresh: () async => await updateProfileData(),
              child: ScrollConfiguration(
                  // key: Key("postListScrollConfiguration-${postList.length}"),
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 16 + mq.padding.top,
                                left: 8.0,
                                right: 8.0,
                                bottom: 8 + mq.padding.bottom),
                            child: Center(
                                child: Stack(
                              children: [
                                AnimatedOpacity(
                                    opacity: !loaded ? 0 : 1,
                                    duration: animationDuration,
                                    child: IgnorePointer(
                                        ignoring: !loaded,
                                        child: buildConfiguration())),
                                AnimatedOpacity(
                                    opacity: !loaded ? 1 : 0,
                                    duration: animationDuration,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(height: mq.size.height * 0.3),
                                        const Center(
                                            child: CircularProgressIndicator()),
                                      ],
                                    ))
                              ],
                            )),
                          ),
                        ),
                      ),
                    ],
                  ))),
        ),
      ],
    ));
  }

  buildHeading(String name) =>
      Text(ownProfile ? 'Your $name' : name, style: textTheme.subtitle1);

  Widget buildConfiguration() {
    if (!loaded) return const SizedBox();
    return Center(
        child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Card(
                color: appState.selectedAccount?.id == userData?.id
                    ? appState.navColor
                    : null,
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  height: 48,
                                  width: 48,
                                  child: Icon(Icons.account_circle,
                                      size: 32, color: Colors.white),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                '${JonlineServer.selectedServer.server}/',
                                                style: textTheme.caption,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: Text(
                                      //         userData?.username ?? '...',
                                      //         style: textTheme.headline6
                                      //             ?.copyWith(
                                      //                 color: appState
                                      //                             .selectedAccount
                                      //                             ?.userId ==
                                      //                         userData?.id
                                      //                     ? appState
                                      //                         .primaryColor
                                      //                     : null),
                                      //         maxLines: 1,
                                      //         overflow: TextOverflow.ellipsis,
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),

                                      TextField(
                                        // focusNode: titleFocus,
                                        controller: usernameController,
                                        keyboardType: TextInputType.url,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        enableSuggestions: true,
                                        autocorrect: true,
                                        maxLines: 1,
                                        cursorColor: Colors.white,
                                        style: textTheme.headline6?.copyWith(
                                            color: appState.selectedAccount
                                                        ?.userId ==
                                                    userData?.id
                                                ? appState.primaryColor
                                                : null),
                                        enabled: ownProfile || admin,
                                        decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Username",
                                            isDense: true),
                                        onChanged: (value) {},
                                      ),
                                      if (ownProfile || admin)
                                        const Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              "Username may be updated.",
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12),
                                            )),
                                    ],
                                  ),
                                ),
                                if (userData?.permissions
                                        .contains(Permission.ADMIN) ??
                                    false)
                                  Tooltip(
                                    message:
                                        "${userData!.username} is an admin",
                                    child: const SizedBox(
                                      height: 32,
                                      width: 32,
                                      child: Icon(
                                          Icons.admin_panel_settings_outlined,
                                          size: 24,
                                          color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Text(
                                          "User ID: ",
                                          style: textTheme.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Expanded(
                                          child: Text(
                                            userData?.id ?? '...',
                                            style: textTheme.caption,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(height: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // buildHeading("Avatar"),
              // Text('(TODO) 🚧🛠', style: textTheme.subtitle1),
              // const SizedBox(height: 16),
              // buildHeading("Contact Information"),
              // Text('(TODO) 🚧🛠', style: textTheme.subtitle1),
              // const SizedBox(height: 16),
              buildHeading("Visibility"),
              const SizedBox(height: 8),
              if (admin || ownProfile)
                Container(
                  key: Key(
                      "visibility-control-${(account ?? JonlineAccount.selectedAccount)?.id}"),
                  child: MultiSelectChipField<vm.Visibility?>(
                    decoration: const BoxDecoration(),
                    // decoration: null,
                    // title: const Text("Select Visibility"),
                    // buttonText: const Text("Select Permissions"),

                    showHeader: false,
                    // searchable: true,
                    selectedChipColor: appState.navColor,
                    selectedTextStyle:
                        TextStyle(color: appState.navColor.textColor),
                    items: vm.Visibility.values
                        .where((v) {
                          final account =
                              this.account ?? JonlineAccount.selectedAccount;
                          return v != vm.Visibility.VISIBILITY_UNKNOWN &&
                              (account?.permissions.contains(
                                          Permission.GLOBALLY_PUBLISH_USERS) ==
                                      true ||
                                  account?.permissions
                                          .contains(Permission.ADMIN) ==
                                      true ||
                                  userData?.visibility ==
                                      vm.Visibility.GLOBAL_PUBLIC ||
                                  v != vm.Visibility.GLOBAL_PUBLIC);
                        })
                        .map((e) => MultiSelectItem(e, e.displayName))
                        .toList(),
                    // listType: MultiSelectListType.CHIP,
                    initialValue: <vm.Visibility?>[
                      userData?.visibility ?? vm.Visibility.VISIBILITY_UNKNOWN
                    ],

                    onTap: (List<vm.Visibility?> values) {
                      if (values.length > 1) {
                        values.remove(userData?.visibility ??
                            vm.Visibility.VISIBILITY_UNKNOWN);
                        setState(() => userData?.visibility = values.first!);
                      } else {
                        values.add(userData?.visibility ??
                            vm.Visibility.VISIBILITY_UNKNOWN);
                        setState(() => userData?.visibility = values.first!);
                      }
                      print("User visibility: ${userData?.visibility}");
                    },
                  ),
                ),
              if (!admin && !ownProfile)
                MultiSelectChipDisplay<vm.Visibility>(
                  // chipColor: appState.navColor,
                  textStyle: TextStyle(color: appState.navColor.textColor),
                  items: userData == null
                      ? []
                      : [userData!.visibility]
                          .map((e) => MultiSelectItem(e, e.displayName))
                          .toList(),
                ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                        "Require${admin || ownProfile ? '' : 's'} Approval to Follow",
                        style: textTheme.labelLarge),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                      value: userData?.defaultFollowModeration ==
                          vm.Moderation.PENDING,
                      activeColor: appState.primaryColor,
                      onChanged: admin || ownProfile
                          ? (value) {
                              setState(() => userData?.defaultFollowModeration =
                                  value
                                      ? vm.Moderation.PENDING
                                      : vm.Moderation.UNMODERATED);
                            }
                          : null)
                ],
              ),
              const SizedBox(height: 16),
              buildHeading("Permissions"),
              const SizedBox(height: 8),
              if (admin)
                MultiSelectDialogField(
                  title: const Text("Select Permissions"),
                  buttonText: const Text("Select Permissions"),
                  searchable: true,
                  items: Permission.values
                      .where((p) => p != Permission.PERMISSION_UNKNOWN)
                      .map((p) => MultiSelectItem(p, p.displayName))
                      .toList(),
                  listType: MultiSelectListType.CHIP,
                  initialValue: userData?.permissions ?? [],
                  selectedColor: appState.navColor,
                  selectedItemsTextStyle:
                      TextStyle(color: appState.navColor.textColor),
                  onConfirm: (values) {
                    setState(() {
                      userData = userData?.jonRebuild((u) {
                        u.permissions.clear();
                        u.permissions.addAll(values.cast<Permission>());
                      });
                    });
                  },
                ),
              if (!admin)
                MultiSelectChipDisplay<Permission>(
                  chipColor: appState.navColor,
                  textStyle: TextStyle(color: appState.navColor.textColor),
                  items: (userData?.permissions ?? <Permission>[])
                      .map((p) => MultiSelectItem(p, p.displayName))
                      .toList(),
                ),
              if (ownProfile || admin || moderator)
                TextButton(
                  child: SizedBox(
                    height: 20 + 20 * mq.textScaleFactor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check),
                        Text('Apply Changes'),
                      ],
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final account = (widget.accountId != null)
                          ? this.account
                          : JonlineAccount.selectedAccount;
                      await account!.ensureRefreshToken();
                      await (await account.getClient())!.updateUser(userData!,
                          options: account.authenticatedCallOptions);
                      showSnackBar("User Data Updated 🎉");
                      homePage.titleUsername = account.username;
                      await appState.updateAccounts();
                    } catch (e) {
                      showSnackBar(formatServerError(e));
                      await communicationDelay;
                      showSnackBar("Failed to update user.");
                      // rethrow;
                    }
                  },
                ),
              const SizedBox(height: 16),
            ])));
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
