import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jonline/models/jonline_account_operations.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:jonline/utils/colors.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:recase/recase.dart';
import '../../generated/permissions.pbenum.dart';
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

class _AdminPageState extends State<ServerConfigurationPage> {
  late AppState appState;
  late HomePageState homePage;

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

  updateServerConfiguration() async {
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

  onAdminPageFocused() {
    if (config != null) {
      appState.colorTheme.value = config!.serverInfo.colors;
    }
  }

  @override
  initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    homePage.serverConfigPageFocused.addListener(onAdminPageFocused);
    Future.microtask(() async {
      await updateServerConfiguration();
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                  top: 16 + MediaQuery.of(context).padding.top,
                  left: 8.0,
                  right: 8.0,
                  bottom: 8 + MediaQuery.of(context).padding.bottom),
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
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ))
                ],
              )),
            ),
          ),
        ),
      ],
    ));
  }

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
            Text('Default User Permissions', style: textTheme.subtitle1),
            const SizedBox(height: 8),
            if (isAdmin)
              MultiSelectDialogField(
                title: const Text("Select Default\nUser Permissions"),
                buttonText: const Text("Select Default User Permissions"),
                searchable: true,
                items: Permission.values
                    .where((p) => p != Permission.PERMISSION_UNKNOWN)
                    .map((e) => MultiSelectItem(
                        e, e.name.replaceAll('_', ' ').titleCase))
                    .toList(),
                listType: MultiSelectListType.CHIP,
                initialValue: config?.defaultUserPermissions ?? [],
                selectedColor: appState.navColor,
                selectedItemsTextStyle:
                    TextStyle(color: appState.navColor.textColor),
                onConfirm: (values) {
                  setState(() {
                    config = config?.jonRebuild((c) {
                      c.defaultUserPermissions
                          .addAll(values.cast<Permission>());
                    });
                    // account?.user = account?.user?.jonRebuild((u) {
                    //   u.permissions.clear();
                    //   u.permissions.addAll(values.map((e) => e as Permission));
                    // });
                  });
                },
                // padding: const EdgeInsets.all(0),
              ),
            if (!isAdmin)
              MultiSelectChipDisplay<Permission>(
                chipColor: appState.navColor,
                textStyle: TextStyle(color: appState.navColor.textColor),
                items: (config?.defaultUserPermissions ?? [])
                    .map((e) => MultiSelectItem(
                        e, e.name.replaceAll('_', ' ').titleCase))
                    .toList(),
              ),
            const SizedBox(height: 24),
            if (isAdmin)
              TextButton(
                child: SizedBox(
                  height: 20 + 20 * MediaQuery.of(context).textScaleFactor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check),
                      Text('Apply Configuration Changes'),
                    ],
                  ),
                ),
                onPressed: () async {
                  try {
                    await account!
                        .ensureRefreshToken(showMessage: showSnackBar);
                    final response = await client!.configureServer(config!,
                        options: account!.authenticatedCallOptions);
                    server!.configuration = response;
                    setState(() {
                      config = response.jonCopy();
                    });
                    await server!.save();
                    if (server == JonlineServer.selectedServer) {
                      appState.colorTheme.value = config!.serverInfo.colors;
                    }
                    showSnackBar("Configuration Updated 🎉");
                  } catch (e) {
                    showSnackBar(formatServerError(e));
                    rethrow;
                  }
                },
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
                  height: 20 + 20 * MediaQuery.of(context).textScaleFactor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.developer_mode),
                      Text('Post Demo Data'),
                    ],
                  ),
                ),
              )
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
                height: 20 + 20 * MediaQuery.of(context).textScaleFactor,
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
