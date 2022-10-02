import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jonline/models/jonline_account_operations.dart';
import 'package:jonline/models/server_errors.dart';
import '../../generated/permissions.pbenum.dart';
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
  ServerConfiguration? serverConfiguration;
  ThemeData get theme => Theme.of(context);
  TextTheme get textTheme => theme.textTheme;
  String? get serverHost => account?.server;
  // bool? get isAdmin => account

  Color get primaryColor => resolveColor(
      serverConfiguration?.serverInfo.colors.primary, defaultPrimaryColor);
  set primaryColor(Color value) => applyColor((c) => c.primary = value.value);
  Color get navColor => resolveColor(
      serverConfiguration?.serverInfo.colors.navigation, defaultNavColor);
  set navColor(Color value) => applyColor((c) => c.navigation = value.value);

  applyColor(Function(ServerColors) update) {
    setState(() {
      serverConfiguration = serverConfiguration?.jonRebuild((c) {
        c.serverInfo = c.serverInfo.jonRebuild((i) {
          i.colors = i.colors.jonRebuild(update);
        });
      });
    });
    if (serverConfiguration != null) {
      appState.colorTheme.value = serverConfiguration!.serverInfo.colors;
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
    final client = await JonlineClients.getServerClient(server);
    await server.updateServiceVersion();
    await server.updateConfiguration();

    final serverConfiguration = server.configuration;
    setState(() {
      this.account = account;
      this.server = server;
      this.client = client;
      this.serverConfiguration = serverConfiguration;
    });
  }

  onAdminPageFocused() {
    if (serverConfiguration != null) {
      appState.colorTheme.value = serverConfiguration!.serverInfo.colors;
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
              padding: const EdgeInsets.only(
                  top: 56.0, left: 8.0, right: 8.0, bottom: 8.0),
              child: Center(
                  child: Stack(
                children: [
                  AnimatedOpacity(
                      opacity: serverConfiguration == null ? 0 : 1,
                      duration: animationDuration,
                      child: IgnorePointer(
                          ignoring: account == null,
                          child: buildConfiguration())),
                  AnimatedOpacity(
                      opacity: serverConfiguration == null ? 1 : 0,
                      duration: animationDuration,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Center(child: CircularProgressIndicator()),
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
                    value: serverConfiguration?.postSettings.visible ?? false,
                    onChanged: account != null
                        ? (v) {
                            setState(() =>
                                serverConfiguration!.postSettings.visible = v);
                          }
                        : null),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: Text("Enable Events", style: textTheme.labelLarge)),
                Switch(
                    value: serverConfiguration?.eventSettings.visible ?? false,
                    onChanged: account != null
                        ? (v) {
                            setState(() =>
                                serverConfiguration!.eventSettings.visible = v);
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
                  child: const Icon(Icons.palette),
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
                  child: const Icon(Icons.palette),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (account != null &&
                account!.permissions.contains(Permission.ADMIN))
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
                        .updateRefreshToken(showMessage: showSnackBar);
                    final response = await client!.configureServer(
                        serverConfiguration!,
                        options: account!.authenticatedCallOptions);
                    server!.configuration = response;
                    setState(() {
                      serverConfiguration = response.jonCopy();
                    });
                    await server!.save();
                    showSnackBar("Configuration Updated 🎉");
                  } catch (e) {
                    print(e);
                    showSnackBar(formatServerError(e));
                  }
                },
              ),
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
