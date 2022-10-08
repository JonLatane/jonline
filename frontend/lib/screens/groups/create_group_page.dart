import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/screens/posts/editor_with_preview.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_clients.dart';
import '../../models/jonline_server.dart';
import '../../models/server_errors.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';

// import 'package:jonline/db.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  CreateGroupPageState createState() => CreateGroupPageState();
}

class CreateGroupPageState extends State<CreateGroupPage> {
  late AppState appState;
  late HomePageState homePage;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  String get name => nameController.value.text;
  String get description => descriptionController.value.text;

  bool get canCreate => name.isNotEmpty;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
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
    await account.ensureRefreshToken(showMessage: showSnackBar);
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
          Group(
              name: name,
              description: description.isNotEmpty ? description : null),
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
    context.navigateBack();
    // context.replaceRoute(PostDetailsRoute(
    //     postId: group.id, server: JonlineServer.selectedServer.server));
    final appState = context.findRootAncestorStateOfType<AppState>();
    if (appState == null) {
      doingCreate = false;

      return;
    }

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
          SizedBox(height: MediaQuery.of(context).padding.top),
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
                  ]),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ));
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
