import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:protobuf/protobuf.dart';
import '../../utils/proto_utils.dart';

import '../../generated/admin.pb.dart';
import '../../app_state.dart';
import '../../generated/google/protobuf/empty.pb.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_clients.dart';
import '../../models/settings.dart';

const Color defaultPrimaryColor = Color(0xFF2E86AB);
const Color defaultNavColor = Color(0xFFA23B72);
const Color defaultAuthorColor = Color(0xFF2eab54);
const Color defaultAdminColor = Color(0xFFab372e);

class AdminPage extends StatefulWidget {
  final String? filter;
  final String accountId;

  const AdminPage({
    Key? key,
    @queryParam this.filter = 'none',
    @pathParam this.accountId = '',
  }) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late AppState appState;

  JonlineAccount? account;
  JonlineClient? client;
  ServerConfiguration? serverConfiguration;
  ThemeData get theme => Theme.of(context);
  TextTheme get textTheme => theme.textTheme;
  String? get server => account?.server;
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
    final account = this.account ??
        (await JonlineAccount.accounts)
            .firstWhere((a) => a.id == widget.accountId);
    final client = this.client ?? await account.getClient();
    final serverConfiguration =
        (await client!.getServerConfiguration(Empty())).jonCopy();
    setState(() {
      this.account = account;
      this.client = client;
      this.serverConfiguration = serverConfiguration;
    });
  }

  @override
  initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    Future.microtask(updateServerConfiguration);
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
            child: Stack(
          children: [
            AnimatedOpacity(
                opacity: account == null ? 0 : 1,
                duration: animationDuration,
                child: IgnorePointer(
                    ignoring: account == null, child: buildConfiguration())),
            AnimatedOpacity(
                opacity: account == null ? 1 : 0,
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
    ));
  }

  Widget buildConfiguration() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Feature Settings', style: textTheme.subtitle1),
            Row(
              children: [
                Expanded(
                    child: Text("Enable Posts", style: textTheme.labelLarge)),
                Switch(
                    value: serverConfiguration?.postSettings.visible ?? false,
                    onChanged: serverConfiguration != null
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
                    onChanged: serverConfiguration != null
                        ? (v) {
                            setState(() =>
                                serverConfiguration!.eventSettings.visible = v);
                          }
                        : null),
              ],
            ),
            Text('Appearance Settings', style: textTheme.subtitle1),
            Row(
              children: [
                Expanded(
                    child: Text("Primary Color", style: textTheme.labelLarge)),
                TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(primaryColor)),
                  onPressed: () => showColorPicker(
                      "Primary Color", primaryColor, (c) => primaryColor = c),
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
                  onPressed: () => showColorPicker(
                      "Navigation Color", navColor, (c) => navColor = c),
                  child: const Icon(Icons.palette),
                ),
              ],
            ),
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
                  print(
                      "Sending configuration: ${serverConfiguration!.toProto3Json()}");
                  final response = await client!.configureServer(
                      serverConfiguration!,
                      options: account!.authenticatedCallOptions);
                  print("Response configuration: ${response.toProto3Json()}");
                } catch (e) {
                  print(e);
                  showSnackBar(formatServerError(e));
                }
                showSnackBar("Configuration Updated 🎉");
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
