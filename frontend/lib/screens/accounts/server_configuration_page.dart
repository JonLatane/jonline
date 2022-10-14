import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/models/jonline_account_operations.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:jonline/utils/colors.dart';
import 'package:jonline/utils/enum_conversions.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../generated/google/protobuf/empty.pb.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/visibility_moderation.pbenum.dart' as vm;
import '../../models/demo_data.dart';
import '../../models/jonline_server.dart';
import '../../utils/proto_utils.dart';

import '../../generated/admin.pb.dart';
import '../../app_state.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_clients.dart';
import '../home_page.dart';

const Color defaultPrimaryColor = Color(0xFF2E86AB);
const Color defaultNavColor = Color(0xFFA23B72);
const Color defaultAuthorColor = Color(0xFF2eab54);
const Color defaultAdminColor = Color(0xFFab372e);

class ServerConfigurationPage extends StatefulWidget {
  final String? server;
  final String? accountId;
  const ServerConfigurationPage({
    Key? key,
    @pathParam this.server,
    this.accountId,
  }) : super(key: key);

  @override
  State<ServerConfigurationPage> createState() => _AdminPageState();
}

class AdminPage extends ServerConfigurationPage {
  const AdminPage({Key? key, @pathParam accountId})
      : super(key: key, accountId: accountId);

  @override
  State<ServerConfigurationPage> createState() => _AdminPageState();
}

class _AdminPageState extends JonlineState<ServerConfigurationPage> {
  JonlineAccount? account;
  JonlineServer? server;
  JonlineClient? client;
  ServerConfiguration? config;
  ThemeData get theme => Theme.of(context);
  TextTheme get textTheme => theme.textTheme;
  String? get serverHost => account?.server;
  bool get isAdmin =>
      account != null && account!.permissions.contains(Permission.ADMIN);

  Color get primaryColor =>
      resolveColor(config?.serverInfo.colors.primary, defaultPrimaryColor);
  set primaryColor(Color value) => applyColor((c) => c.primary = value.value);
  Color get navColor =>
      resolveColor(config?.serverInfo.colors.navigation, defaultNavColor);
  set navColor(Color value) => applyColor((c) => c.navigation = value.value);

  applyColor(Function(ServerColors) update) {
    setState(() {
      config = config?.jonRebuild((c) {
        c.serverInfo = c.serverInfo.jonRebuild((i) {
          i.colors = i.colors.jonRebuild(update);
        });
      });
    });
    if (config != null) {
      appState.colorTheme.value = config!.serverInfo.colors;
    }
  }

  resolveColor(int? serverConfigValue, Color defaultColor) {
    final result = Color(serverConfigValue ?? defaultColor.value);
    if (result.alpha == 0) return defaultColor;
    return result;
  }

  refreshServerConfiguration() async {
    final account = widget.accountId == null
        ? null
        : this.account ??
            (await JonlineAccount.accounts)
                .firstWhere((a) => a.id == widget.accountId);

    final JonlineServer server = this.server ??
        (await JonlineServer.servers)
            .firstWhere((a) => a.server == (account?.server ?? widget.server!));
    final client = this.client ??
        await JonlineClients.getServerClient(server,
            allowInsecure:
                server.server == "localhost" || server.server == "Armothy");
    await server.updateServiceVersion();
    await server.updateConfiguration();

    final config = server.configuration;
    setState(() {
      this.account = account;
      this.server = server;
      this.client = client;
      this.config = config;
    });
  }

  applyServerConfiguration() async {
    try {
      await account!.ensureRefreshToken(showMessage: showSnackBar);
      final response = await client!
          .configureServer(config!, options: account!.authenticatedCallOptions);
      server!.configuration = response;
      setState(() {
        config = response.jonCopy();
      });
      await server!.save();
      if (server == JonlineServer.selectedServer) {
        appState.colorTheme.value = config!.serverInfo.colors;
      }
      showSnackBar("Configuration Updated 🎉");
      await refreshServerConfiguration();
    } catch (e) {
      showSnackBar(formatServerError(e));
      rethrow;
    }
  }

  onAdminPageFocused() {
    if (config != null) {
      appState.colorTheme.value = config!.serverInfo.colors;
    }
  }

  @override
  initState() {
    super.initState();
    homePage.serverConfigPageFocused.addListener(onAdminPageFocused);
    Future.microtask(() async {
      await refreshServerConfiguration();
      onAdminPageFocused();
    });
  }

  @override
  dispose() {
    homePage.serverConfigPageFocused.removeListener(onAdminPageFocused);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: RefreshIndicator(
              displacement: mq.padding.top + 40,
              onRefresh: () async => await refreshServerConfiguration(),
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
                              opacity: config == null ? 0 : 1,
                              duration: animationDuration,
                              child: IgnorePointer(
                                  ignoring: account == null,
                                  child: buildConfiguration())),
                          AnimatedOpacity(
                              opacity: config == null ? 1 : 0,
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

  bool addedGloballyPublishProfilePermissionToMeetInvariant = false;
  Widget buildConfiguration() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Server Info', style: textTheme.subtitle1),
            Row(
              children: [
                Expanded(
                    child:
                        Text("Jonline Version", style: textTheme.labelLarge)),
                Text("v${server?.serviceVersion}", style: textTheme.caption),
              ],
            ),
            const SizedBox(height: 24),
            Text('Feature Settings', style: textTheme.subtitle1),
            // Row(
            //   children: [
            //     Expanded(
            //         child: Text("Enable People", style: textTheme.labelLarge)),
            //     Switch(
            //         activeColor: appState.primaryColor,
            //         value: config?.peopleSettings.visible ?? false,
            //         onChanged: account != null
            //             ? (v) {
            //                 setState(() => config!.peopleSettings.visible = v);
            //               }
            //             : null),
            //   ],
            // ),
            Row(
              children: [
                Expanded(
                    child: Text("Enable Groups", style: textTheme.labelLarge)),
                Switch(
                    activeColor: appState.primaryColor,
                    value: config?.groupSettings.visible ?? false,
                    onChanged: account != null
                        ? (v) {
                            setState(() => config!.groupSettings.visible = v);
                          }
                        : null),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: Text("Enable Posts", style: textTheme.labelLarge)),
                Switch(
                    activeColor: appState.primaryColor,
                    value: config?.postSettings.visible ?? false,
                    onChanged: account != null
                        ? (v) {
                            setState(() => config!.postSettings.visible = v);
                          }
                        : null),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: Text("Enable Events", style: textTheme.labelLarge)),
                Switch(
                    activeColor: appState.primaryColor,
                    value: config?.eventSettings.visible ?? false,
                    onChanged: account != null
                        ? (v) {
                            setState(() => config!.eventSettings.visible = v);
                          }
                        : null),
              ],
            ),
            const SizedBox(height: 24),
            Text('Appearance Settings', style: textTheme.subtitle1),
            Row(
              children: [
                Expanded(
                    child: Text("Primary Color", style: textTheme.labelLarge)),
                TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(primaryColor)),
                  onPressed: () => account == null
                      ? null
                      : showColorPicker("Primary Color", primaryColor,
                          (c) => primaryColor = c),
                  child: Icon(Icons.palette, color: primaryColor.textColor),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child:
                        Text("Navigation Color", style: textTheme.labelLarge)),
                TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(navColor)),
                  onPressed: () => account == null
                      ? null
                      : showColorPicker(
                          "Navigation Color", navColor, (c) => navColor = c),
                  child: Icon(Icons.palette, color: navColor.textColor),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Default User Visibility', style: textTheme.subtitle1),
            const SizedBox(height: 8),
            if (isAdmin)
              Container(
                key: Key(
                    "visibility-control-${(account ?? JonlineAccount.selectedAccount)?.id}-${config?.peopleSettings.defaultVisibility}"),
                child: MultiSelectChipField<vm.Visibility?>(
                  decoration: const BoxDecoration(),
                  showHeader: false,
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
                                config?.peopleSettings.defaultVisibility ==
                                    vm.Visibility.GLOBAL_PUBLIC ||
                                v != vm.Visibility.GLOBAL_PUBLIC);
                      })
                      .map((e) => MultiSelectItem(e, e.displayName))
                      .toList(),
                  // listType: MultiSelectListType.CHIP,
                  initialValue: <vm.Visibility?>[
                    config?.peopleSettings.defaultVisibility ??
                        vm.Visibility.VISIBILITY_UNKNOWN
                  ],

                  onTap: (List<vm.Visibility?> values) {
                    if (values.length > 1) {
                      values.remove(config?.peopleSettings.defaultVisibility ??
                          vm.Visibility.VISIBILITY_UNKNOWN);
                      setState(() => config?.peopleSettings.defaultVisibility =
                          values.first!);
                      if (values.first == vm.Visibility.GLOBAL_PUBLIC &&
                          !config!.defaultUserPermissions
                              .contains(Permission.GLOBALLY_PUBLISH_USERS) &&
                          !addedGloballyPublishProfilePermissionToMeetInvariant) {
                        addedGloballyPublishProfilePermissionToMeetInvariant =
                            true;
                        config!.defaultUserPermissions
                            .add(Permission.GLOBALLY_PUBLISH_USERS);
                      } else if (values.first != vm.Visibility.GLOBAL_PUBLIC &&
                          addedGloballyPublishProfilePermissionToMeetInvariant) {
                        addedGloballyPublishProfilePermissionToMeetInvariant =
                            false;
                        config!.defaultUserPermissions
                            .remove(Permission.GLOBALLY_PUBLISH_USERS);
                      }
                    } else {
                      values.add(config?.peopleSettings.defaultVisibility ??
                          vm.Visibility.VISIBILITY_UNKNOWN);
                      setState(() => config?.peopleSettings.defaultVisibility =
                          values.first!);
                    }
                  },
                ),
              ),
            const SizedBox(height: 24),
            Text('Default User Permissions', style: textTheme.subtitle1),
            const SizedBox(height: 8),
            if (isAdmin)
              Container(
                key: Key(
                    "default-permissions-control-${config!.defaultUserPermissions}"),
                child: MultiSelectDialogField(
                  title: const Text("Select Default\nUser Permissions"),
                  buttonText: const Text("Select Default User Permissions"),
                  searchable: true,
                  items: Permission.values
                      .where((p) => p != Permission.PERMISSION_UNKNOWN)
                      .map((p) => MultiSelectItem(p, p.displayName))
                      .toList(),
                  listType: MultiSelectListType.CHIP,
                  initialValue: config?.defaultUserPermissions ?? [],
                  selectedColor: appState.navColor,
                  selectedItemsTextStyle:
                      TextStyle(color: appState.navColor.textColor),
                  onConfirm: (values) {
                    setState(() {
                      config!.defaultUserPermissions
                        ..clear()
                        ..addAll(values.cast<Permission>());
                      if (!values.contains(Permission.GLOBALLY_PUBLISH_USERS) &&
                          config!.peopleSettings.defaultVisibility ==
                              vm.Visibility.GLOBAL_PUBLIC) {
                        addedGloballyPublishProfilePermissionToMeetInvariant =
                            false;
                        config!.peopleSettings.defaultVisibility =
                            vm.Visibility.SERVER_PUBLIC;
                      }
                    });
                  },
                ),
              ),
            if (!isAdmin)
              MultiSelectChipDisplay<Permission>(
                chipColor: appState.navColor,
                textStyle: TextStyle(color: appState.navColor.textColor),
                items: (config?.defaultUserPermissions ?? [])
                    .map((p) => MultiSelectItem(p, p.displayName))
                    .toList(),
              ),
            const SizedBox(height: 24),
            if (isAdmin)
              TextButton(
                onPressed: applyServerConfiguration,
                child: SizedBox(
                  height: 20 + 20 * mq.textScaleFactor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check),
                      Text('Apply Configuration Changes'),
                    ],
                  ),
                ),
              ),
            if (isAdmin) const SizedBox(height: 16),
            if (isAdmin) Text('Admin/Dev Tools', style: textTheme.subtitle1),
            if (isAdmin) const SizedBox(height: 8),
            if (isAdmin)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Really post demo data?'),
                      action: SnackBarAction(
                        label: 'Post it!', // or some operation you would like
                        onPressed: () {
                          if (account == null) {
                            showSnackBar("Account not ready.");
                          }
                          postDemoData(account!, showSnackBar, appState);
                        },
                      )));
                },
                child: SizedBox(
                  height: 20 + 20 * mq.textScaleFactor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.developer_mode),
                      Text('Post Demo Data'),
                    ],
                  ),
                ),
              ),
            if (isAdmin)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Really post randomized demo data?'),
                      action: SnackBarAction(
                        label: 'Post it!', // or some operation you would like
                        onPressed: () {
                          if (account == null) {
                            showSnackBar("Account not ready.");
                          }
                          postDemoData(account!, showSnackBar, appState,
                              randomize: true);
                        },
                      )));
                },
                child: SizedBox(
                  height: 20 + 20 * mq.textScaleFactor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.developer_mode),
                      Text('Post *Randomized* Demo Data'),
                    ],
                  ),
                ),
              ),
            if (isAdmin) const SizedBox(height: 8),
            if (isAdmin)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Really Reset Server Data?'),
                      action: SnackBarAction(
                        label: 'Delete it!', // or some operation you would like
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('REALLY DELETE IT ALL???'),
                              action: SnackBarAction(
                                label:
                                    'DELETE IT ALL!!!', // or some operation you would like
                                onPressed: () async {
                                  try {
                                    if (account == null) {
                                      showSnackBar("Account not ready.");
                                    }
                                    (await account!.getClient())!.resetData(
                                        Empty(),
                                        options:
                                            account!.authenticatedCallOptions);
                                    showSnackBar(
                                        "Server data reset. All Groups/Posts/Comments/Users (except ${account!.username}) deleted.");
                                    for (var a in appState.accounts.value) {
                                      if (a.server == account!.server &&
                                          a.id != account!.id) {
                                        await a.delete();
                                      }
                                    }
                                    appState.updateAccountList();
                                    appState.updateAccounts();
                                    appState.notifyAccountsListeners();
                                    // appState.updateGroups();
                                    // appState.updatePosts();
                                  } catch (e) {
                                    showSnackBar(formatServerError(e));
                                  }
                                  // postDemoData(account!, showSnackBar, appState);
                                },
                              )));
                        },
                      )));
                },
                child: SizedBox(
                  height: 20 + 20 * mq.textScaleFactor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.developer_mode),
                      Expanded(
                        child: Text(
                          'DELETE EVERYTHING: Posts, Groups, Users (except ${account!.username})',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.warning),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 48)
          ],
        ),
      ),
    );
  }

  Color _pickerColor = Colors.transparent;
  showColorPicker(
    String title,
    Color color,
    Function(Color) onColorChanged,
  ) {
    _pickerColor = color;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ColorPicker(
                    pickerColor: color,
                    onColorChanged: (c) {
                      _pickerColor = c;
                    }),
              ),
            ),
            TextButton(
              child: SizedBox(
                height: 20 + 20 * mq.textScaleFactor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check),
                    Text('Apply'),
                  ],
                ),
              ),
              onPressed: () {
                onColorChanged(_pickerColor);
                // setState(() => currentColor = pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        // Use Material color picker:
        //
        // child: MaterialPicker(
        //   pickerColor: pickerColor,
        //   onColorChanged: changeColor,
        //   showLabel: true, // only on portrait mode
        // ),
        //
        // Use Block color picker:
        //
        // child: BlockPicker(
        //   pickerColor: currentColor,
        //   onColorChanged: changeColor,
        // ),
        //
        // child: MultipleChoiceBlockPicker(
        //   pickerColors: currentColors,
        //   onColorsChanged: changeColors,
        // ),
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
