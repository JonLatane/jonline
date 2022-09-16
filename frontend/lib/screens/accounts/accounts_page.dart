import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

import '../../app_state.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_account_operations.dart';
import '../../models/settings.dart';
import '../home_page.dart';
import '../user-data/data_collector.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({Key? key}) : super(key: key);

  @override
  AccountsPageState createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> {
  UserData? userData;
  List<JonlineAccount> get accounts => appState.accounts.value;
  late AppState appState;
  late HomePageState homePage;
  TextTheme get textTheme => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    Settings.showSettingsTabListener.addListener(onSettingsTabChanged);
    appState.accounts.addListener(onAccountsChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    Settings.showSettingsTabListener.removeListener(onSettingsTabChanged);
    appState.accounts.removeListener(onAccountsChanged);
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
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      onPressed: () {
                        context.navigateNamedTo('/login');
                      },
                      child: const Text(
                        'Login/Create Account…',
                        maxLines: 2,
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
                      child: TextButton(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  const Text('Really delete all accounts?'),
                              action: SnackBarAction(
                                label:
                                    'Delete all', // or some operation you would like
                                onPressed: deleteAllAccounts,
                              )));
                        },
                        child: const Icon(Icons.delete_forever),
                      )),
                  Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: toggleSettingsTab,
                        child: Stack(
                          children: [
                            const Icon(Icons.settings),
                            Transform.translate(
                              offset: const Offset(20, 0),
                              child: Icon(Settings.showSettingsTab
                                  ? Icons.close
                                  : Icons.arrow_right),
                            ),
                          ],
                        ),
                      )),
                  // const SizedBox(width: 8)
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    buildList(),
                    AnimatedOpacity(
                      opacity: accounts.isEmpty ? 1.0 : 0.0,
                      duration: animationDuration,
                      child: IgnorePointer(
                        child: Center(
                          child: Text(
                            'No Accounts Created',
                            style: Theme.of(context).textTheme.headline5,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void toggleSettingsTab() {
    if (!Settings.showSettingsTab) {
      setState(() {
        Settings.showSettingsTab = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        context.navigateNamedTo('settings/main');
      });
    } else {
      setState(() {
        Settings.showSettingsTab = false;
      });
    }
  }

  deleteAccount(JonlineAccount account) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Really delete ${account.server}/${account.username}?'),
        action: SnackBarAction(
          label: 'Delete', // or some operation you would like
          onPressed: () async {
            await account.delete();
            setState(() {
              appState.updateAccountList();
            });
          },
        )));
  }

  refreshAccount(JonlineAccount account) async {
    await account.updateServiceVersion(showMessage: showSnackBar);
    showSnackBar('Service version updated.');
    await communicationDelay;
    await account.updateRefreshToken(showMessage: showSnackBar);
    showSnackBar('Refresh token updated.');
    await communicationDelay;
    await account.updateUserData(showMessage: showSnackBar);
    showSnackBar('User details updated.');
    appState.updateAccountList();
  }

  void deleteAllAccounts() async {
    await JonlineAccount.updateAccountList([]);
    appState.updateAccountList();
  }

  buildList() {
    return ImplicitlyAnimatedReorderableList<JonlineAccount>(
      items: accounts,
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, from, to, newItems) {
        JonlineAccount.updateAccountList(newItems);
      },
      itemBuilder: (context, animation, account, index) {
        return Reorderable(
          key: ValueKey(account.id),
          builder: (context, dragAnimation, inDrag) => SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: animation,
              child: buildAccountItem(account)),
        );
      },
    );
  }

  Widget buildAccountItem(JonlineAccount account) {
    return Center(
      child: AnimatedContainer(
        constraints: const BoxConstraints(maxWidth: 600),
        duration: animationDuration,
        height: 103.0 + (23.0 * MediaQuery.of(context).textScaleFactor),
        child: Card(
          color:
              appState.selectedAccount?.id == account.id ? bottomColor : null,
          child: InkWell(
            onTap: () {
              if (appState.selectedAccount?.id == account.id) {
                showSnackBar(
                    "Browsing anonymously on ${JonlineAccount.selectedServer}.");
                appState.selectedAccount = null;
              } else {
                showSnackBar(
                    "Browsing ${account.server} as ${account.username}.");
                appState.selectedAccount = account;
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 48,
                            child: TextButton(
                              onPressed: () {
                                context.navigateNamedTo(
                                    'account/${account.id}/activity');
                              },
                              child: const Icon(Icons.account_circle,
                                  size: 32, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('${account.server}/',
                                          style: textTheme.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (Settings.powerUserMode)
                                      if (account.serviceVersion != "")
                                        Transform.translate(
                                            offset: const Offset(0, 3),
                                            child: Text(
                                              "v${account.serviceVersion}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.caption,
                                            )),
                                    if (account.allowInsecure)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Transform.translate(
                                            offset: const Offset(0, 4),
                                            child: const Tooltip(
                                              message:
                                                  "The connection is insecure.",
                                              child:
                                                  Icon(Icons.warning, size: 16),
                                            )),
                                      ),
                                    const SizedBox(width: 36)
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        account.username,
                                        style: textTheme.headline6,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                                    style: textTheme.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Expanded(
                                    child: Text(
                                      account.userId,
                                      style: textTheme.caption,
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
                                  style: textTheme.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            if (Settings.developerMode)
                              Expanded(
                                flex: 1,
                                child: Text(account.refreshToken,
                                    style: textTheme.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (Settings.developerMode)
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: TextButton(
                                    style: ButtonStyle(
                                        padding: MaterialStateProperty.all(
                                            const EdgeInsets.all(0))),
                                    // padding: const EdgeInsets.all(0),
                                    onPressed: () => refreshAccount(account),
                                    child: const Icon(Icons.refresh)),
                              ),
                            ),
                          Expanded(
                              child: SizedBox(
                                  height: 32,
                                  child: TextButton(
                                      style: ButtonStyle(
                                          padding: MaterialStateProperty.all(
                                              const EdgeInsets.all(0))),
                                      onPressed: () => deleteAccount(account),
                                      child: const Icon(Icons.delete))))
                        ],
                      )
                    ],
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Transform.translate(
                      offset: const Offset(0, 0),
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
                  )
                ],
              ),
            ),
          ),
        ),
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
