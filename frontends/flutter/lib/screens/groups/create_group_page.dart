import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/utils/colors.dart';
import 'package:jonline/utils/enum_conversions.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/visibility_moderation.pbenum.dart' as vm;
import '../../generated/visibility_moderation.pbenum.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_clients.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';

// import 'package:jonline/db.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  CreateGroupPageState createState() => CreateGroupPageState();
}

class CreateGroupPageState extends JonlineState<CreateGroupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  String get name => nameController.value.text;
  String get description => descriptionController.value.text;

  bool get canCreate => name.isNotEmpty;
  vm.Visibility visibility = vm.Visibility.SERVER_PUBLIC;
  vm.Moderation defaultMembershipModeration = vm.Moderation.UNMODERATED;

  @override
  void initState() {
    super.initState();
    homePage.createGroup.addListener(doCreate);
    nameController.addListener(() {
      setState(() {});
      updateHomepage();
    });
    descriptionController.addListener(() {
      setState(() {});
      updateHomepage();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateHomepage();
    });
  }

  updateHomepage() {
    homePage.canCreateGroup.value = canCreate && !doingCreate;
  }

  @override
  dispose() {
    homePage.createGroup.removeListener(doCreate);
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  bool _doingCreate = false;
  bool get doingCreate => _doingCreate;
  set doingCreate(bool value) {
    setState(() {
      enabled.value = !value;
      _doingCreate = value;
    });
    homePage.canCreateGroup.value = canCreate && !value;
  }

  doCreate() async {
    doingCreate = true;
    if (JonlineAccount.selectedAccount == null) {
      showSnackBar("No account selected.");
      return;
    }
    final account = JonlineAccount.selectedAccount!;

    // showSnackBar("Updating refresh token...");
    await account.ensureAccessToken(showMessage: showSnackBar);
    // await communicationDelay;
    final JonlineClient? client =
        await (account.getClient(showMessage: showSnackBar));
    if (client == null) {
      showSnackBar("Account not ready.");
    }
    showSnackBar("Creating Group...");
    final startTime = DateTime.now();
    final Group group;
    try {
      group = await client!.createGroup(
          Group()
            ..name = name
            ..description = description
            ..visibility = visibility
            ..defaultMembershipModeration = defaultMembershipModeration
            ..defaultPostModeration = Moderation.UNMODERATED
            ..defaultEventModeration = Moderation.UNMODERATED,
          options: account.authenticatedCallOptions);
    } catch (e) {
      await communicationDelay;
      showSnackBar("Error creating Group 😔");
      await communicationDelay;
      showSnackBar(formatServerError(e));
      doingCreate = false;
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch -
            startTime.millisecondsSinceEpoch <
        500) {
      await communicationDelay;
    }
    showSnackBar("Group created! 🎉");
    if (!mounted) {
      doingCreate = false;
      return;
    }
    context.replaceRoute(GroupDetailsRoute(
        groupId: group.id, server: JonlineServer.selectedServer.server));

    appState.groups.value = [group] + appState.groups.value;
    Future.delayed(const Duration(seconds: 3),
        () => appState.updateGroups(showMessage: showSnackBar));

    doingCreate = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(height: mq.padding.top),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(children: [
                    TextField(
                      // focusNode: titleFocus,
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      enableSuggestions: true,
                      autocorrect: true,
                      maxLines: 1,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 14),
                      enabled: enabled.value,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Group Name",
                          isDense: true),
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        // focusNode: contentFocus,
                        controller: descriptionController,
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
                        enabled: enabled.value,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Description",
                            isDense: true),
                        onChanged: (value) {},
                      ),
                    ),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Markdown content is supported.",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 12),
                        )),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text("Visibility", style: textTheme.labelLarge),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            key: Key(
                                "visibility-control-${(JonlineAccount.selectedAccount)?.id}"),
                            child: MultiSelectChipField<vm.Visibility?>(
                              decoration: const BoxDecoration(),
                              showHeader: false,
                              selectedChipColor: appState.navColor,
                              selectedTextStyle:
                                  TextStyle(color: appState.navColor.textColor),
                              items: vm.Visibility.values
                                  .where((v) {
                                    final account =
                                        JonlineAccount.selectedAccount;
                                    return v !=
                                            vm.Visibility.VISIBILITY_UNKNOWN &&
                                        (account?.permissions.contains(Permission
                                                    .PUBLISH_GROUPS_GLOBALLY) ==
                                                true ||
                                            account?.permissions.contains(
                                                    Permission.ADMIN) ==
                                                true ||
                                            visibility ==
                                                vm.Visibility.GLOBAL_PUBLIC ||
                                            v != vm.Visibility.GLOBAL_PUBLIC);
                                  })
                                  .map((v) => MultiSelectItem(v, v.displayName))
                                  .toList(),
                              initialValue: <vm.Visibility?>[visibility],
                              onTap: (List<vm.Visibility?> values) {
                                if (values.length > 1) {
                                  values.remove(visibility);
                                  setState(() => visibility = values.first!);
                                } else {
                                  values.add(visibility);
                                  setState(() => visibility = values.first!);
                                }
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Require Approval to Join",
                              style: textTheme.labelLarge),
                        ),
                        const SizedBox(width: 16),
                        Switch(
                            value: defaultMembershipModeration ==
                                vm.Moderation.PENDING,
                            onChanged: (value) {
                              setState(() => defaultMembershipModeration = value
                                  ? vm.Moderation.PENDING
                                  : vm.Moderation.UNMODERATED);
                            })
                      ],
                    )
                  ]),
                ),
              ],
            ),
          ),
          SizedBox(height: mq.padding.bottom),
        ],
      ),
    ));
  }

  showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
