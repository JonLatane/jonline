import 'dart:typed_data';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fa_solid.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/screens/accounts/server_configuration_page.dart';

import '../../app_state.dart';
import '../../generated/permissions.pbenum.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/jonline_server.dart';
import '../../utils/colors.dart';
import '../../models/settings.dart';
import '../home_page.dart';
import '../media/media_image.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({Key? key}) : super(key: key);

  @override
  AccountsPageState createState() => AccountsPageState();
}

class AccountsPageState extends JonlineState<AccountsPage> {
  List<JonlineAccount> get allAccounts => appState.accounts.value;
  List<JonlineAccount> get accounts {
    final result = allAccounts;
    if (showServers && uiSelectedServer != null) {
      return result.where((a) => a.server == uiSelectedServer!.server).toList();
    }
    return result;
  }

  List<JonlineServer> get servers => appState.servers.value;
  JonlineServer? uiSelectedServer;
  bool get showServers => Settings.showServers;
  set showServers(bool value) {
    Settings.showServers = value;
    if (!Settings.showServers) {
      setState(() => uiSelectedServer = null);
    }
  }

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    Settings.showSettingsTabListener.addListener(onSettingsTabChanged);
    appState.accounts.addListener(onAccountsChanged);
    appState.servers.addListener(onAccountsChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    Settings.showSettingsTabListener.removeListener(onSettingsTabChanged);
    appState.accounts.removeListener(onAccountsChanged);
    appState.servers.removeListener(onAccountsChanged);
    super.dispose();
  }

  onSettingsTabChanged() {
    setState(() {});
  }

  onAccountsChanged() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool showHeader = showServers && accounts.isNotEmpty;
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Stack(
            children: [
              Center(
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                          duration: animationDuration,
                          constraints: const BoxConstraints(maxWidth: 600),
                          // height: showServers ? 120 : 0,
                          child: buildAccountsView()),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  ClipRRect(
                      child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: blurSigma, sigmaY: blurSigma),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                height: mq.padding.top,
                                color: Theme.of(context)
                                    .canvasColor
                                    .withOpacity(0.5),
                              ),
                              Container(
                                height: 48,
                                color: Theme.of(context)
                                    .canvasColor
                                    .withOpacity(0.5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 6,
                                          child: ElevatedButton(
                                            style: ButtonStyle(
                                                padding:
                                                    WidgetStateProperty.all(
                                              const EdgeInsets.all(8),
                                            )),
                                            onPressed: () {
                                              context.navigateNamedTo('/login');
                                            },
                                            child: const Text(
                                              'Add Account/Server…',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        // const SizedBox(width: 8),
                                        // Expanded(
                                        //     flex: 2,
                                        //     child: TextButton(
                                        //       onPressed: () {
                                        //         appState.updateAccountList();
                                        //       },
                                        //       child: const Icon(Icons.refresh),
                                        //     )),
                                        // const SizedBox(width: 8),
                                        Expanded(
                                            flex: 2,
                                            child: Tooltip(
                                              message: showServers
                                                  ? 'Hide Servers'
                                                  : 'Show Servers',
                                              child: TextButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    showServers = !showServers;
                                                  });
                                                },
                                                child: Icon(Icons.computer,
                                                    color: showServers
                                                        ? Colors.white
                                                        : null),
                                              ),
                                            )),
                                        // Expanded(
                                        //     flex: 2,
                                        //     child: Tooltip(
                                        //       message:
                                        //           'Refresh Servers & Accounts',
                                        //       child: TextButton(
                                        //         onPressed: () async {
                                        //           showSnackBar(
                                        //               'Refreshing Servers & Accounts…');
                                        //           await appState
                                        //               .updateServersAndAccounts();
                                        //           showSnackBar(
                                        //               'Servers & Accounts Refreshed! 🎉');
                                        //         },
                                        //         child: const Icon(
                                        //           Icons.refresh,
                                        //         ),
                                        //       ),
                                        //     )),
                                        if (Settings.powerUserMode)
                                          Expanded(
                                              flex: 2,
                                              child: Tooltip(
                                                message:
                                                    'Delete All Accounts & Servers',
                                                child: TextButton(
                                                  onPressed: () async {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .hideCurrentSnackBar();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            content: const Text(
                                                                'Really delete all accounts and servers?'),
                                                            action:
                                                                SnackBarAction(
                                                              label:
                                                                  'Delete all', // or some operation you would like
                                                              onPressed:
                                                                  () async {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .hideCurrentSnackBar();
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                        SnackBar(
                                                                            content:
                                                                                const Text('Really REALLY delete them all??'),
                                                                            action: SnackBarAction(
                                                                              label: 'Delete all', // or some operation you would like
                                                                              onPressed: deleteAllAccounts,
                                                                            )));
                                                              },
                                                            )));
                                                  },
                                                  child: const Icon(
                                                      Icons.delete_forever),
                                                ),
                                              )),
                                        if (!Settings.showSettingsTab)
                                          Expanded(
                                              flex: 2,
                                              child: Tooltip(
                                                message:
                                                    Settings.showSettingsTab
                                                        ? 'Hide Settings Tab'
                                                        : 'Open Settings',
                                                child: TextButton(
                                                  onPressed: toggleSettingsTab,
                                                  child: Stack(
                                                    children: [
                                                      const Icon(
                                                          Icons.settings),
                                                      Transform.translate(
                                                        offset:
                                                            const Offset(20, 0),
                                                        child: Icon(Settings
                                                                .showSettingsTab
                                                            ? Icons.close
                                                            : Icons
                                                                .arrow_right),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                        // const SizedBox(width: 8)
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 4,
                                color: Theme.of(context)
                                    .canvasColor
                                    .withOpacity(0.5),
                              ),
                              AnimatedOpacity(
                                  opacity: showHeader ? 1 : 0,
                                  duration: animationDuration,
                                  child: AnimatedContainer(
                                    color: Theme.of(context)
                                        .canvasColor
                                        .withOpacity(0.5),
                                    height: showHeader ? serverHeaderHeight : 0,
                                    duration: animationDuration,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Transform.translate(
                                          offset: Offset(
                                              0, -5 * mq.textScaleFactor),
                                          child: Text("Servers",
                                              style: textTheme.titleMedium),
                                        ),
                                      ],
                                    ),
                                  )),
                              AnimatedOpacity(
                                opacity: showServers ? 1 : 0,
                                duration: animationDuration,
                                child: AnimatedContainer(
                                    color: Theme.of(context)
                                        .canvasColor
                                        .withOpacity(0.5),
                                    duration: animationDuration,
                                    constraints:
                                        const BoxConstraints(maxWidth: 600),
                                    height: showServers ? serverItemHeight : 0,
                                    child: buildServerList()),
                              ),
                              AnimatedOpacity(
                                opacity: showHeader ? 1 : 0,
                                duration: animationDuration,
                                child: AnimatedContainer(
                                  color: Theme.of(context)
                                      .canvasColor
                                      .withOpacity(0.5),
                                  height: showHeader ? accountHeaderHeight : 0,
                                  duration: animationDuration,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (uiSelectedServer == null)
                                        Text("All Accounts",
                                            style: textTheme.titleMedium),
                                      if (uiSelectedServer != null)
                                        Text("Accounts on ",
                                            style: textTheme.titleMedium),
                                      Text(
                                          uiSelectedServer != null
                                              ? "${uiSelectedServer!.server}/"
                                              : '',
                                          style: textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get serverHeaderHeight => 18 * mq.textScaleFactor;
  double get accountHeaderHeight => 32 * mq.textScaleFactor;

  void toggleSettingsTab() {
    // if (!Settings.showSettingsTab) {
    //   setState(() {
    //     Settings.showSettingsTab = true;
    //   });
    Future.delayed(const Duration(milliseconds: 100), () {
      context.navigateNamedTo('settings/main');
    });
    // } else {
    //   setState(() {
    //     Settings.showSettingsTab = false;
    //   });
    // }
  }

  deleteAccount(JonlineAccount account) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Really delete ${account.server}/${account.username}?'),
        action: SnackBarAction(
          label: 'Delete',
          onPressed: () async {
            await account.delete();
            setState(() {
              appState.updateAccountList();
            });
          },
        )));
  }

  deleteServer(JonlineServer server) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Really delete ${server.server}?'),
        action: SnackBarAction(
          label: 'Delete',
          onPressed: () async {
            await server.delete();
            setState(() {
              appState.updateServerList();
            });
          },
        )));
  }

  refreshAccount(JonlineAccount account) async {
    if (!await account.ensureAccessToken(showMessage: showSnackBar)) {
      await communicationDelay;
      showSnackBar('Failed to update account details.');
      return;
    }
    if (await account.updateUserData(showMessage: showSnackBar) == null) {
      await communicationDelay;
      showSnackBar('Failed to update account details.');
      return;
    }
    showSnackBar('Account details updated.');
    appState.updateAccountList();
  }

  refreshServer(JonlineServer server) async {
    await server.updateConfiguration();
    await appState.updateColorTheme();
    showSnackBar('Server configuration updated.');
  }

  void deleteAllAccounts() async {
    await JonlineAccount.updateAccountList([]);
    await JonlineServer.updateServerList([]);
    appState.updateAccountList();
    appState.updateServerList();
  }

  Widget buildAccountsView() {
    bool showHeader = showServers && accounts.isNotEmpty;
    return Column(
      children: [
        AnimatedContainer(
          duration: animationDuration,
          height: showServers
              ? serverItemHeight +
                  (showHeader ? accountHeaderHeight + serverHeaderHeight : 0)
              : 0,
        ),
        Expanded(
          child: Stack(
            children: [
              buildAccountList(),
              AnimatedOpacity(
                opacity: accounts.isEmpty ? 1.0 : 0.0,
                duration: animationDuration,
                child: IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No Accounts',
                          style: textTheme.headlineSmall,
                        ),
                        if (showServers && uiSelectedServer != null)
                          Text(
                            'on',
                            style: textTheme.titleLarge,
                          ),
                        if (showServers && uiSelectedServer != null)
                          const SizedBox(height: 4),
                        if (showServers && uiSelectedServer != null)
                          Text(
                            uiSelectedServer!.server,
                            style: textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  ScrollController accountScrollController = ScrollController();
  Widget buildAccountList() {
    return RefreshIndicator(
        displacement: mq.padding.top + 80,
        onRefresh: () async {
          return await appState
              .updateServersAndAccounts()
              .timeout(const Duration(seconds: 30), onTimeout: () {
            showSnackBar('Failed to update accounts.');
          });
        },
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
            child: ImplicitlyAnimatedReorderableList<JonlineAccount>(
              padding: EdgeInsets.only(
                  top: mq.padding.top + 48, bottom: mq.padding.bottom),
              physics: const AlwaysScrollableScrollPhysics(),
              items: accounts,
              areItemsTheSame: (a, b) => a.id == b.id,
              onReorderFinished: (item, from, to, newItems) {
                if (uiSelectedServer == null) {
                  JonlineAccount.updateAccountList(newItems);
                }
              },

              // reorderDuration: Duration.zero,
              itemBuilder: (context, animation, account, index) {
                return Reorderable(
                  key: Key(account.id),
                  builder: (context, dragAnimation, inDrag) =>
                      SizeFadeTransition(
                          sizeFraction: 0.7,
                          curve: Curves.easeInOut,
                          animation: animation,
                          child: buildAccountItem(account)),
                );
              },
            )));
  }

  Map<String, Uint8List?> accountAvatars = {};
  Widget buildAccountItem(JonlineAccount account) {
    final backgroundColor = appState.selectedAccount?.id == account.id
        ? appState.navColor
        : Colors.grey[600];
    final textColor = backgroundColor?.textColor;
    return AnimatedContainer(
      // constraints: const BoxConstraints(maxWidth: 600),
      duration: animationDuration,
      height: 103.0 + (23.0 * mq.textScaleFactor),
      child: Theme(
        data: ThemeData.dark().copyWith(
          // bottomAppBarColor: const Color(0xFF884DF2),
          // splashColor: const Color(0xFFFFC145),
          // buttonColor: const Color(0xFF884DF2),
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color(appState.servers.value
                      .firstWhere((s) => s.server == account.server)
                      .configuration
                      ?.serverInfo
                      .colors
                      .primary ??
                  defaultPrimaryColor.value)),
        ),
        child: Card(
          color: backgroundColor,
          child: InkWell(
            onTap: () {
              if (appState.selectedAccount?.id == account.id) {
                showSnackBar(
                    "Browsing anonymously on ${JonlineServer.selectedServer.server}.");
                appState.selectedAccount = null;
              } else {
                showSnackBar(
                    "Browsing ${account.server} as ${account.username}.");
                appState.selectedAccount = account;
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 48,
                            width: 48,
                            child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(0),
                                  shape: const CircleBorder(),
                                  backgroundColor: backgroundColor,
                                ),
                                onPressed: () {
                                  context.navigateNamedTo(
                                      'account/${account.id}/profile');
                                },
                                child:
                                    (account.user?.hasAvatar() ?? false == true)
                                        ? CircleAvatar(
                                            key: Key('avatar-${account.id}'),
                                            backgroundImage: mediaImageProvider(
                                                account.user!.avatar.id,
                                                serverOverride: account.server))
                                        : const CircleAvatar(
                                            backgroundColor: Colors.black12,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                          )
                                // : Icon(Icons.account_circle,
                                //     size: 32,
                                //     color: textColor ?? Colors.white),
                                ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('${account.server}/',
                                          style: textTheme.bodySmall?.copyWith(
                                              color:
                                                  textColor?.withOpacity(0.5)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        account.username,
                                        style: textTheme.titleLarge
                                            ?.copyWith(color: textColor),
                                        // style: textTheme.titleLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (account.allowInsecure)
                                Tooltip(
                                  message: "The connection may be insecure.",
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8.0,
                                      ),
                                      child: Transform.translate(
                                        offset: const Offset(0, 0),
                                        child: Icon(Icons.warning,
                                            size: 16, color: textColor),
                                      )),
                                ),
                            ],
                          ),
                          if (account.permissions.contains(Permission.RUN_BOTS))
                            Tooltip(
                              message: "This account can run bots.",
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: SizedBox(
                                  height: 18,
                                  child: Transform.translate(
                                    offset: const Offset(0, -1),
                                    child: Iconify(FaSolid.robot,
                                        size: 14,
                                        color: textColor ?? Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          if (account.permissions.contains(Permission.ADMIN))
                            SizedBox(
                              height: 48,
                              width: 48,
                              child: TextButton(
                                onPressed: () {
                                  context.navigateNamedTo(
                                      'account/${account.id}/admin');
                                },
                                child: Icon(Icons.admin_panel_settings_outlined,
                                    size: 32, color: textColor ?? Colors.white),
                              ),
                            ),
                          AnimatedContainer(
                              duration: animationDuration,
                              width: uiSelectedServer == null ? 36 : 8)
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Text(
                                    "User ID: ",
                                    style: textTheme.bodySmall?.copyWith(
                                        color: textColor?.withOpacity(0.5)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Expanded(
                                    child: Text(
                                      account.userId,
                                      style: textTheme.bodySmall?.copyWith(
                                          color: textColor?.withOpacity(0.5)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (Settings.developerMode)
                              const SizedBox(width: 4),
                            if (Settings.developerMode)
                              Text('Refresh Token: ',
                                  style: textTheme.bodySmall?.copyWith(
                                      color: textColor?.withOpacity(0.5)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            if (Settings.developerMode)
                              Expanded(
                                flex: 1,
                                child: Text(account.accessToken,
                                    style: textTheme.bodySmall?.copyWith(
                                        color: textColor?.withOpacity(0.5)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // if (Settings.powerUserMode)
                          //   Expanded(
                          //     child: SizedBox(
                          //       height: 32,
                          //       child: TextButton(
                          //           style: ButtonStyle(
                          //               padding: MaterialStateProperty.all(
                          //                   const EdgeInsets.all(0))),
                          //           // padding: const EdgeInsets.all(0),
                          //           onPressed: () => refreshAccount(account),
                          //           child: const Icon(Icons.refresh)),
                          //     ),
                          //   ),
                          Expanded(
                              child: SizedBox(
                                  height: 32,
                                  child: TextButton(
                                      style: ButtonStyle(
                                          padding: WidgetStateProperty.all(
                                              const EdgeInsets.all(0))),
                                      onPressed: () => deleteAccount(account),
                                      child: const Icon(Icons.delete))))
                        ],
                      )
                    ],
                  ),
                  if (uiSelectedServer == null)
                    const Align(
                      alignment: Alignment.topRight,
                      child: Handle(
                        delay: Duration(milliseconds: 100),
                        child: SizedBox(
                          child: Icon(
                            Icons.menu,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // bool get verticalServerList =>mq.size.width > 600;
  Widget buildServerList() {
    return ImplicitlyAnimatedReorderableList<JonlineServer>(
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      // scrollDirection: verticalServerList ? Axis.vertical : Axis.horizontal,
      items: servers,
      areItemsTheSame: (a, b) => a.server == b.server,
      onReorderFinished: (item, from, to, newItems) {
        JonlineServer.updateServerList(newItems);
      },
      itemBuilder: (context, animation, server, index) {
        return Reorderable(
          key: ValueKey(server.server),
          builder: (context, dragAnimation, inDrag) => SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: animation,
              axis: Axis.horizontal,
              child: buildServerItem(server)),
        );
      },
    );
  }

  double get serverItemHeight => 70 + 10 * mq.textScaleFactor;
  Widget buildServerItem(JonlineServer server) {
    final selectServer = JonlineServer.selectedServer != server
        ? () {
            JonlineServer.selectedServer = server;
            if (appState.selectedAccount != null &&
                appState.selectedAccount!.server != server.server) {
              appState.selectedAccount = null;
              appState.selectedGroup.value = null;
            } else {
              appState.notifyAccountsListeners();
            }
            appState.posts.hardReset();
            showSnackBar("Browsing anonymously on ${server.server}.");
          }
        : null;
    final backgroundColor = uiSelectedServer == server
        ? Color(server.configuration?.serverInfo.colors.primary ??
            defaultPrimaryColor.value)
        : JonlineServer.selectedServer == server
            ? appState.navColor
            : Colors.black26;
    final textColor = backgroundColor.textColor;
    return AnimatedContainer(
      duration: animationDuration,
      width: 163 + 20 * mq.textScaleFactor,
      height: serverItemHeight,
      // height: 103.0 + (23.0 *mq.textScaleFactor),
      child: Stack(
        children: [
          Theme(
              data: ThemeData.dark().copyWith(
                // bottomAppBarColor: const Color(0xFF884DF2),
                // splashColor: const Color(0xFFFFC145),
                // buttonColor: const Color(0xFF884DF2),
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Color(
                        server.configuration?.serverInfo.colors.primary ??
                            defaultPrimaryColor.value)),
              ),
              child: Card(
                color: backgroundColor,
                // color:
                //     appState.selectedServer?.id == server.id ? bottomColor : null,
                child: InkWell(
                  onLongPress: selectServer,
                  onDoubleTap: selectServer,
                  onTap: () {
                    selectServer?.call();
                    if (uiSelectedServer == server) {
                      setState(() {
                        uiSelectedServer = null;
                      });
                    } else {
                      setState(() {
                        uiSelectedServer = server;
                      });
                    }
                    // if (appState.selectedServer?.id == server.id) {
                    //   showSnackBar(
                    //       "Browsing anonymously on ${JonlineServer.selectedServer}.");
                    //   appState.selectedServer = null;
                    // } else {
                    //   showSnackBar(
                    //       "Browsing ${server.server} as ${server.username}.");
                    //   appState.selectedServer = server;
                    // }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 32,
                              width: 32,
                              child: TextButton(
                                  style: ButtonStyle(
                                      padding: WidgetStateProperty.all(
                                          const EdgeInsets.all(0))),
                                  onPressed: () => context.navigateNamedTo(
                                      'server/${server.server}/configuration'),
                                  child: Icon(Icons.info, color: textColor)),
                            ),
                            // if (Settings.powerUserMode)
                            //   SizedBox(
                            //     height: 32,
                            //     width: 32,
                            //     child: TextButton(
                            //         style: ButtonStyle(
                            //             padding: MaterialStateProperty.all(
                            //                 const EdgeInsets.all(0))),
                            //         // padding: const EdgeInsets.all(0),
                            //         onPressed: () => refreshServer(server),
                            //         child: const Icon(Icons.refresh)),
                            //   ),
                          ],
                        ),
                        Expanded(
                          child: Column(children: [
                            const SizedBox(height: 8),
                            Expanded(
                                child: Icon(Icons.computer,
                                    size: 32, color: textColor)),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    server.server,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodySmall
                                        ?.copyWith(color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ]),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                              width: 32,
                              height: 32,
                              child: TextButton(
                                  style: ButtonStyle(
                                      padding: WidgetStateProperty.all(
                                          const EdgeInsets.all(0))),
                                  onPressed: server.server !=
                                              appState.primaryServerHost &&
                                          !allAccounts.any(
                                              (a) => a.server == server.server)
                                      ? () => deleteServer(server)
                                      : null,
                                  child: const Icon(Icons.delete))),
                        )
                      ],
                    ),
                  ),
                ),
              )),
          Align(
            alignment: Alignment.topRight,
            child: Transform.translate(
              offset: const Offset(-5, 5),
              child: const Handle(
                delay: Duration(milliseconds: 100),
                child: SizedBox(
                  child: Icon(
                    Icons.menu,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
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
