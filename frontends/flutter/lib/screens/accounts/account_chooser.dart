import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fa_solid.dart';
import 'package:jonline/jonline_state.dart';

import '../../app_state.dart';
import '../../generated/permissions.pbenum.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';

// import 'package:jonline/db.dart';

class AccountChooser extends StatefulWidget {
  const AccountChooser({
    Key? key,
  }) : super(key: key);

  @override
  AccountChooserState createState() => AccountChooserState();
}

class AccountChooserState extends JonlineState<AccountChooser> {
  int currentServerIndex = 0;
  List<String> servers = ['', ''];
  String get currentServer => servers[currentServerIndex];
  set currentServer(String name) {
    currentServerIndex = (currentServerIndex + 1) % 2;
    servers[currentServerIndex] = name;
  }

  int currentUsernameIndex = 0;
  List<String> usernames = ['', ''];
  String get currentUsername => usernames[currentUsernameIndex];
  set currentUsername(String name) {
    currentUsernameIndex = (currentUsernameIndex + 1) % 2;
    usernames[currentUsernameIndex] = name;
  }

  @override
  void initState() {
    super.initState();
    appState.accounts.addListener(onAccountsChanged);
  }

  @override
  dispose() {
    appState.accounts.removeListener(onAccountsChanged);
    super.dispose();
  }

  onAccountsChanged() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if ("${JonlineServer.selectedServer.server}/" != currentServer) {
      currentServer = "${JonlineServer.selectedServer.server}/";
    }
    if ((appState.selectedAccount?.username ?? noOne) != currentUsername) {
      currentUsername = appState.selectedAccount?.username ?? noOne;
    }
    return Tooltip(
      message: "Select Account",
      child: SizedBox(
        width: 72 * mq.textScaleFactor,
        child: TextButton(
          style: ButtonStyle(
              padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
              foregroundColor:
                  MaterialStateProperty.all(Colors.white.withAlpha(255)),
              overlayColor:
                  MaterialStateProperty.all(Colors.white.withAlpha(100)),
              splashFactory: InkSparkle.splashFactory),
          onPressed: () {
            // HapticFeedback.lightImpact();
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox? overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox?;
            final RelativeRect position = RelativeRect.fromRect(
              Rect.fromPoints(
                button.localToGlobal(Offset.zero, ancestor: overlay),
                button.localToGlobal(button.size.bottomRight(Offset.zero),
                    ancestor: overlay),
              ),
              Offset.zero & (overlay?.size ?? Size.zero),
            );
            showAccountsMenu(context, position);
            // context.router.pop();
          },
          child: Stack(
            children: [
              Center(
                  child: AnimatedOpacity(
                duration: animationDuration,
                opacity: JonlineAccount.selectedAccount?.permissions
                            .contains(Permission.ADMIN) ??
                        false
                    ? 0.5
                    : 0,
                child: const Icon(Icons.admin_panel_settings_outlined),
              )),
              Center(
                  child: AnimatedOpacity(
                duration: animationDuration,
                opacity: JonlineAccount.selectedAccount?.permissions
                            .contains(Permission.RUN_BOTS) ??
                        false
                    ? 0.5
                    : 0,
                child:
                    const Iconify(FaSolid.robot, color: Colors.white, size: 18),
              )),
              Column(
                children: [
                  const Expanded(child: SizedBox()),
                  Stack(
                    children: [
                      ...servers.map(
                        (name) => AnimatedOpacity(
                          opacity:
                              "${JonlineServer.selectedServer.server}/" == name
                                  ? 1
                                  : 0,
                          duration: animationDuration,
                          child: Center(
                              child: Text(
                            name,
                            style: textTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // textAlign: TextAlign.center,
                          )),
                        ),
                      )
                    ],
                  ),
                  Stack(
                    children: [
                      ...usernames.map(
                        (name) => AnimatedOpacity(
                          opacity:
                              (appState.selectedAccount?.username ?? noOne) ==
                                      name
                                  ? 1
                                  : 0,
                          duration: animationDuration,
                          child: Center(
                              child: Text(
                            name,
                            style: textTheme.subtitle2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // textAlign: TextAlign.center,
                          )),
                        ),
                      )
                    ],
                  ),
                  // Text('${JonlineServer.selectedServer.server}/',
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: textTheme.caption),
                  // Text(JonlineAccount.selectedAccount?.username ?? noOne,
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: textTheme.subtitle2),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Object> showAccountsMenu(
    BuildContext context, RelativeRect position) async {
  ThemeData theme = Theme.of(context);
  TextTheme textTheme = theme.textTheme;
  ThemeData darkTheme = theme;
  final accounts = await JonlineAccount.accounts;
  final servers = await JonlineServer.servers;

  final accountsHere =
      accounts.where((a) => a.server == JonlineServer.selectedServer.server);
  final accountsElsewhere =
      accounts.where((a) => a.server != JonlineServer.selectedServer.server);
  return showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // color: (musicBackgroundColor.luminance < 0.5
      //         ? subBackgroundColor
      //         : musicBackgroundColor)
      //     .withOpacity(0.95),
      items: [
        // PopupMenuItem(
        //   padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        //   mouseCursor: SystemMouseCursors.basic,
        //   value: null,
        //   enabled: false,
        //   child: Text(
        //     'Accounts',
        //     style: darkTheme.textTheme.titleLarge,
        //   ),
        // ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          mouseCursor: SystemMouseCursors.basic,
          value: null,
          enabled: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    accountsHere.isEmpty ? 'No Accounts on ' : 'Accounts on ',
                    style: accountsHere.isEmpty
                        ? darkTheme.textTheme.titleMedium
                        : darkTheme.textTheme.titleLarge,
                  ),
                  Text(
                    "${JonlineServer.selectedServer.server}/",
                    style: darkTheme.textTheme.caption,
                  ),
                ],
              ),
            ),
            ...accountsHere.map((a) => _accountItem(a, context)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                accountsElsewhere.isEmpty
                    ? 'No Accounts Elsewhere'
                    : 'Accounts Elsewhere',
                style: accountsElsewhere.isEmpty
                    ? darkTheme.textTheme.titleMedium
                    : darkTheme.textTheme.titleLarge,
              ),
            ),
            ...accountsElsewhere.map((a) => _accountItem(a, context)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Servers',
                style: darkTheme.textTheme.titleLarge,
              ),
            ),
            ...servers.map((s) => _serverItem(s, context)),
            Material(
              // color: backgroundColor,
              color: Colors.transparent,
              child: InkWell(
                  mouseCursor: SystemMouseCursors.basic,
                  onTap: () {
                    Navigator.pop(context);
                    context.navigateNamedTo('/login');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text("Add Account/Server...",
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.subtitle2),
                            ),
                            const Icon(Icons.arrow_right, color: Colors.white)
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
          ]),
        ),
      ]);
}

Widget _accountItem(JonlineAccount a, BuildContext context) {
  ThemeData darkTheme = Theme.of(context);
  ThemeData lightTheme = ThemeData.light();
  bool selected = a.id == JonlineAccount.selectedAccount?.id;
  ThemeData theme = selected ? lightTheme : darkTheme;
  TextTheme textTheme = theme.textTheme;
  return Theme(
    data: theme,
    child: Material(
      // color: backgroundColor,
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            Navigator.pop(context);
            AppState appState =
                context.findRootAncestorStateOfType<AppState>()!;
            if (selected) {
              appState.selectedAccount = null;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "Browsing anonymously on ${JonlineServer.selectedServer.server}.")),
              );
            } else {
              appState.selectedAccount = a;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Browsing ${a.server} as ${a.username}.")),
              );
            }
            // onSelected(part);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                    height: 36,
                    width: 36,
                    child: ((a.user?.avatar ?? []).isNotEmpty)
                        ? CircleAvatar(
                            key: Key('avatar-${a.id}'),
                            backgroundImage:
                                MemoryImage(Uint8List.fromList(a.user!.avatar)),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("${a.server}/",
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.caption),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(a.username,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.subtitle1),
                      ),
                    ],
                  ),
                ),
                if (a.permissions.contains(Permission.RUN_BOTS))
                  const Iconify(FaSolid.robot, size: 12, color: Colors.white),
                if (a.permissions.contains(Permission.ADMIN))
                  const Icon(Icons.admin_panel_settings_outlined, size: 16)
              ],
            ),
          )),
    ),
  );
}

Widget _serverItem(JonlineServer s, BuildContext context) {
  ThemeData darkTheme = Theme.of(context);
  ThemeData lightTheme = ThemeData.light();
  bool selected = s == JonlineServer.selectedServer;
  ThemeData theme = selected ? lightTheme : darkTheme;
  TextTheme textTheme = theme.textTheme;
  return Theme(
    data: theme,
    child: Material(
      // color: backgroundColor,
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            Navigator.pop(context);
            AppState appState =
                context.findRootAncestorStateOfType<AppState>()!;
            JonlineServer.selectedServer = s;
            appState.selectedAccount = null;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "Browsing anonymously on ${JonlineServer.selectedServer.server}.")),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Column(
                  children: const [Icon(Icons.computer, size: 20)],
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("${s.server}/",
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.caption),
                    ),
                  ],
                ),
              ],
            ),
          )),
    ),
  );
}
