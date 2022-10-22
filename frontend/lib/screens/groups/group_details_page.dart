import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/screens/groups/group_preview.dart';
import 'package:jonline/utils/colors.dart';
import 'package:jonline/utils/enum_conversions.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/permissions.pbenum.dart';
import '../../utils/moderation_accessors.dart';
import '../../generated/visibility_moderation.pbenum.dart' as vm;
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_operations.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';
import '../../utils/proto_utils.dart';

class GroupDetailsPage extends StatefulWidget {
  final String server;
  final String groupId;

  const GroupDetailsPage(
      {Key? key, @pathParam this.server = '', @pathParam this.groupId = ''})
      : super(key: key);

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends JonlineState<GroupDetailsPage> {
  bool loading = true;
  Group? group;
  // JonlineAccount? account;
  // User? userData;
  bool get loaded => group != null;
  TextEditingController groupNameController = TextEditingController();
  List<Permission> get groupPermissions =>
      group?.currentUserMembership.permissions ?? [];

  bool get member => group?.member ?? false;
  bool get admin => userPermissions.contains(Permission.ADMIN);
  bool get moderator => userPermissions.contains(Permission.MODERATE_GROUPS);
  bool get groupAdmin => admin || groupPermissions.contains(Permission.ADMIN);

  @override
  initState() {
    super.initState();
    appState.accounts.addListener(updateState);
    groupNameController.addListener(() {
      setState(() {
        group = group?.jonRebuild((u) {
          u.name = groupNameController.text;
        });
      });
    });
    Future.microtask(refreshGroupData);
  }

  @override
  dispose() {
    appState.accounts.removeListener(updateState);
    groupNameController.dispose();
    super.dispose();
  }

  updateState() {
    setState(() {});
  }

  refreshGroupData() async {
    Group? group;

    final groups = (await JonlineOperations.getGroups(
                request: GetGroupsRequest(groupId: widget.groupId)))
            ?.groups ??
        [];
    group = groups.singleOrNull;

    setState(() {
      groupNameController.text = group?.name ?? '';
      this.group = group;
      loading = false;
    });
    // This keeps the rest of the app consistent with the new group data (if
    // this group is within scope).
    appState.updateGroups();
  }

  @override
  Widget build(BuildContext context) {
    if (JonlineServer.selectedServer.server != widget.server) {
      context.replaceRoute(const GroupsRoute());
    }
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: RefreshIndicator(
              displacement: mq.padding.top + 40,
              onRefresh: () async => await refreshGroupData(),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: mq.size.height * 0.3),
                                  const Center(
                                      child: CircularProgressIndicator()),
                                ],
                              ))
                        ],
                      )),
                    ),
                  ))),
        ),
      ],
    ));
  }

  buildHeading(String name) => Text(name, style: textTheme.subtitle1);

  Widget buildConfiguration() {
    if (!loaded) return const SizedBox();
    return Center(
        child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              GroupPreview(
                server: JonlineServer.selectedServer.server,
                group: group!,
                navigable: false,
                groupNameController:
                    (admin || groupAdmin) ? groupNameController : null,
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
              if (admin || groupAdmin)
                Container(
                  key: Key("visibility-control-${group?.id}"),
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
                          return v != vm.Visibility.VISIBILITY_UNKNOWN &&
                              (userPermissions.contains(
                                      Permission.PUBLISH_GROUPS_GLOBALLY) ||
                                  userPermissions.contains(Permission.ADMIN) ||
                                  group?.visibility ==
                                      vm.Visibility.GLOBAL_PUBLIC ||
                                  v != vm.Visibility.GLOBAL_PUBLIC);
                        })
                        .map((e) => MultiSelectItem(e, e.displayName))
                        .toList(),
                    // listType: MultiSelectListType.CHIP,
                    initialValue: <vm.Visibility?>[
                      group?.visibility ?? vm.Visibility.VISIBILITY_UNKNOWN
                    ],

                    onTap: (List<vm.Visibility?> values) {
                      if (values.length > 1) {
                        values.remove(group?.visibility ??
                            vm.Visibility.VISIBILITY_UNKNOWN);
                        setState(() => group?.visibility = values.first!);
                      } else {
                        values.add(group?.visibility ??
                            vm.Visibility.VISIBILITY_UNKNOWN);
                        setState(() => group?.visibility = values.first!);
                      }
                      print("User visibility: ${group?.visibility}");
                    },
                  ),
                ),
              if (!admin && !member)
                MultiSelectChipDisplay<vm.Visibility>(
                  // chipColor: appState.navColor,
                  textStyle: TextStyle(color: appState.navColor.textColor),
                  items: group == null
                      ? []
                      : [group!.visibility]
                          .map((e) => MultiSelectItem(e, e.displayName))
                          .toList(),
                ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                        "Require${admin || member ? '' : 's'} Approval to Join",
                        style: textTheme.labelLarge),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                      value: group?.defaultMembershipModeration ==
                          vm.Moderation.PENDING,
                      activeColor: appState.primaryColor,
                      onChanged: admin || member
                          ? (value) {
                              setState(() =>
                                  group?.defaultMembershipModeration = value
                                      ? vm.Moderation.PENDING
                                      : vm.Moderation.UNMODERATED);
                            }
                          : null)
                ],
              ),
              const SizedBox(height: 16),
              buildHeading("Default Member Permissions"),
              const SizedBox(height: 8),
              if (admin)
                MultiSelectDialogField(
                  title: const Text("Select Group Permissions"),
                  buttonText: const Text("Select Group Permissions"),
                  searchable: true,
                  items: Permission.values
                      .where((p) => [
                            Permission.VIEW_POSTS,
                            Permission.CREATE_POSTS,
                            Permission.MODERATE_POSTS,
                            Permission.VIEW_EVENTS,
                            Permission.CREATE_EVENTS,
                            Permission.MODERATE_EVENTS,
                            Permission.ADMIN,
                            Permission.MODERATE_USERS
                          ].contains(p))
                      .map((p) => MultiSelectItem(p, p.displayName))
                      .toList(),
                  listType: MultiSelectListType.CHIP,
                  initialValue: group?.defaultMembershipPermissions ?? [],
                  selectedColor: appState.navColor,
                  selectedItemsTextStyle:
                      TextStyle(color: appState.navColor.textColor),
                  onConfirm: (values) {
                    setState(() {
                      group = group?.jonRebuild((g) {
                        g.defaultMembershipPermissions.clear();
                        g.defaultMembershipPermissions
                            .addAll(values.cast<Permission>());
                      });
                    });
                  },
                ),
              if (!admin)
                MultiSelectChipDisplay<Permission>(
                  chipColor: appState.navColor,
                  textStyle: TextStyle(color: appState.navColor.textColor),
                  items: (group?.defaultMembershipPermissions ?? <Permission>[])
                      .map((p) => MultiSelectItem(p, p.displayName))
                      .toList(),
                ),
              if (member || admin || moderator)
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
                      final account = JonlineAccount.selectedAccount;
                      await account!.ensureAccessToken();
                      await (await account.getClient())!.updateGroup(group!,
                          options: account.authenticatedCallOptions);
                      showSnackBar("Group Data Updated 🎉");
                      homePage.titleUsername = account.username;
                      await appState.updateAccounts();
                      if (appState.selectedGroup.value?.id == group!.id) {
                        appState.selectedGroup.value = group!;
                      }
                      await appState.groups.notify();
                    } catch (e) {
                      showSnackBar(formatServerError(e));
                      await communicationDelay;
                      showSnackBar("Failed to update group.");
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
