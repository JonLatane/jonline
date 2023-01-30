import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/jonline_account_operations.dart';
import '../screens/accounts/server_configuration_page.dart';
import '../screens/login_page.dart';
import 'db.dart';
import 'generated/server_configuration.pb.dart';
import 'generated/groups.pb.dart';
import 'generated/users.pb.dart';
import 'generated/users.pb.dart' as u;
import 'jonotifier.dart';
import 'main.dart';
import 'models/jonline_account.dart';
import 'models/jonline_operations.dart';
import 'models/jonline_server.dart';
import 'models/settings.dart';
import 'my_platform.dart';
import 'models/post_cache.dart';
import 'router/auth_guard.dart';
import 'router/router.gr.dart';
import 'utils/fake_js.dart' if (dart.library.js) 'dart:js';
// import 'package:smooth/smooth.dart';

const noOne = 'no one';
const blurSigma = 10.0;
const animationDuration = Duration(milliseconds: 300);
const communicationDuration = Duration(milliseconds: 1000);
get animationDelay => Future.delayed(animationDuration);
get communicationDelay => Future.delayed(communicationDuration);

class AppState extends State<MyApp> {
  Color primaryColor = const Color(0xFF2E86AB);
  Color navColor = const Color(0xFFA23B72);
  Color authorColor = const Color(0xFF2eab54);
  Color adminColor = const Color(0xFFab372e);
  final ValueJonotifier<ServerColors?> colorTheme =
      ValueJonotifier<ServerColors?>(null);

  final authService = AuthService();
  final ValueJonotifier<List<JonlineAccount>> accounts =
      ValueJonotifier(<JonlineAccount>[]);
  final ValueJonotifier<List<JonlineServer>> servers =
      ValueJonotifier(<JonlineServer>[]);
  final PostCache posts = PostCache();

  final ValueJonotifier<List<u.User>> users = ValueJonotifier(<u.User>[]);
  bool get viewingGroup => selectedGroup.value != null;
  final ValueJonotifier<Group?> selectedGroup = ValueJonotifier(null);
  final ValueJonotifier<List<Group>> groups = ValueJonotifier(<Group>[]);
  final Jonotifier updateReplies = Jonotifier();
  final Jonotifier selectedServerChanged = Jonotifier();
  final Jonotifier selectedAccountChanged = Jonotifier();

  final _rootRouter = RootRouter(
    authGuard: AuthGuard(),
  );

  ValueNotifier<bool> updatingUsers = ValueNotifier(true);
  ValueNotifier<bool> errorUpdatingUsers = ValueNotifier(false);
  ValueNotifier<bool> didUpdateUsers = ValueNotifier(false);
  Future<void> updateUsers({Function(String)? showMessage}) async {
    updatingUsers.value = true;
    final GetUsersResponse? response = await JonlineOperations.getUsers();
    if (response == null) {
      setState(() {
        errorUpdatingUsers.value = true;
        updatingUsers.value = false;
        // showSnackBar
      });
      return;
    }

    didUpdateUsers.value = true;
    setState(() {
      updatingUsers.value = false;
      users.value = response.users;
    });
    didUpdateUsers.value = false;
    // await communicationDelay;
    // showMessage?.call("Users updated! 🎉");
  }

  ValueNotifier<bool> updatingGroups = ValueNotifier(true);
  ValueNotifier<bool> errorUpdatingGroups = ValueNotifier(false);
  ValueNotifier<bool> didUpdateGroups = ValueNotifier(false);
  Future<void> updateGroups({Function(String)? showMessage}) async {
    updatingGroups.value = true;
    final GetGroupsResponse? response = await JonlineOperations.getGroups();
    if (response == null) {
      setState(() {
        errorUpdatingGroups.value = true;
        updatingGroups.value = false;
        // showSnackBar
      });
      return;
    }

    didUpdateGroups.value = true;
    setState(() {
      updatingGroups.value = false;
      groups.value = response.groups;
    });
    didUpdateGroups.value = false;
    if (selectedGroup.value != null) {
      selectedGroup.value = groups.value.cast<Group?>().firstWhere(
          (group) => group?.id == selectedGroup.value?.id,
          orElse: () => selectedGroup.value);
    }
    // await communicationDelay;
    // showMessage?.call("Groups updated! 🎉");
  }

  bool get loggedIn => JonlineAccount.loggedIn;
  JonlineAccount? get selectedAccount => JonlineAccount.selectedAccount;
  set selectedAccount(JonlineAccount? account) {
    if (account != null) {
      Future.sync(() async => JonlineServer.selectedServer =
          (await JonlineServer.servers).firstWhere(
              (s) => s.server == account.server,
              orElse: () => JonlineServer(account.server)));
    }
    if (account != null &&
        JonlineServer.selectedServer.server != account.server) {
      selectedGroup.value = null;
    }
    JonlineAccount.selectedAccount = account;
    updateAccountList();
    posts.hardReset();
    resetPeople();
    resetGroups();
  }

  resetPeople() {
    setState(() {
      updatingUsers.value = true;
      users.value = <u.User>[];
    });
    updateUsers();
  }

  resetGroups() {
    setState(() {
      updatingGroups.value = true;
      groups.value = <Group>[];
    });
    updateGroups();
  }

  Future<void> updateAccountList() async {
    accounts.value = await JonlineAccount.accounts;
  }

  Future<void> updateAccounts() async {
    List<Future> futures = [];
    for (JonlineAccount account in accounts.value) {
      futures += [account.updateUserData()];
    }
    await Future.wait(futures);
    notifyAccountsListeners();
  }

  Future<void> updateServerList() async {
    servers.value = await JonlineServer.servers;
  }

  Future<void> updateServers() async {
    List<Future> futures = [];
    for (JonlineServer server in servers.value) {
      futures += [server.updateConfiguration(), server.updateServiceVersion()];
    }
    await Future.wait(futures);
    notifyAccountsListeners();
  }

  notifyAccountsListeners() {
    accounts.notify();
  }

  notifyServerListeners() {
    servers.notify();
  }

  updateColors() {
    final theme = colorTheme.value;
    if (theme != null) {
      var primary = Color(theme.primary);
      if (primary.alpha == 0) primary = defaultPrimaryColor;
      var nav = Color(theme.navigation);
      if (nav.alpha == 0) nav = defaultNavColor;
      setState(() {
        primaryColor = primary;
        navColor = nav;
        // primaryColor = Color(theme.primary);
        // primaryColor = Color(theme.primary);
      });
    } else {
      setState(() {
        primaryColor = defaultPrimaryColor;
        navColor = defaultNavColor;
      });
    }
  }

  JonlineAccount? _lastSelectedAccount;
  JonlineServer _lastSelectedServer = JonlineServer.selectedServer;
  monitorAccountChange() {
    if (_lastSelectedAccount?.id != selectedAccount?.id) {
      selectedAccountChanged();
    }
    _lastSelectedAccount = selectedAccount;
  }

  monitorServerChange() {
    if (_lastSelectedServer != JonlineServer.selectedServer) {
      selectedServerChanged();
    }
    _lastSelectedServer = JonlineServer.selectedServer;
  }

  updateColorTheme() async {
    ServerConfiguration? configuration =
        JonlineServer.selectedServer.configuration ??
            await JonlineServer.selectedServer.updateConfiguration();

    ServerColors? colors = configuration?.serverInfo.colors;
    colorTheme.value = colors;
  }

  // This is detected using the JS method getJonlineServerHost.
  String primaryServerHost = "jonline.io";

  @override
  void initState() {
    super.initState();
    posts.getCurrentKey =
        () => PostDataKey(selectedGroup.value?.id, posts.listingType);
    accounts.addListener(posts.update);
    accounts.addListener(updateUsers);
    accounts.addListener(updateGroups);
    accounts.addListener(monitorAccountChange);
    accounts.addListener(monitorServerChange);
    selectedServerChanged.addListener(updateColorTheme);
    colorTheme.addListener(updateColors);
    Settings.initialize(notifyAccountsListeners);
    selectedGroup.addListener(notifyAccountsListeners);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // For web, ensure the actual URL hostname is used as the default server.
      if (MyPlatform.isWeb) {
        primaryServerHost = context.callMethod("getJonlineServerHost", []);
        final JonlineServer server = JonlineServer(primaryServerHost);
        final List<JonlineServer> servers = await JonlineServer.servers;
        LoginPage.defaultServer = primaryServerHost;
        if (!servers.contains(server)) {
          await server.saveNew(atBeginning: true);
          JonlineServer.selectedServer = server;
        }
      }
      updatingUsers.addListener(() {
        if (updatingUsers.value) errorUpdatingUsers.value = false;
      });
      updatingGroups.addListener(() {
        if (updatingGroups.value) errorUpdatingGroups.value = false;
      });
      await updateServersAndAccounts();
      await Future.wait([posts.update(), updateUsers(), updateGroups()]);
    });
  }

  updateServersAndAccounts() async {
    await updateServerList();
    await updateColorTheme();
    await updateServers();
    await updateAccountList();
    await updateAccounts();
  }

  @override
  void dispose() {
    selectedGroup.removeListener(notifyAccountsListeners);
    accounts.removeListener(monitorAccountChange);
    accounts.removeListener(monitorServerChange);
    selectedServerChanged.removeListener(updateColorTheme);
    colorTheme.removeListener(updateColors);
    colorTheme.removeListener(updateColors);
    accounts.removeListener(posts.update);
    accounts.removeListener(updateUsers);
    accounts.dispose();
    updateReplies.dispose();
    colorTheme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'PublicSans',
            ),
        primaryTextTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'PublicSans',
            ),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.macOS: NoShadowCupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: NoShadowCupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        }),
      ),
      routerDelegate: _rootRouter.delegate(
        navigatorObservers: () => [AutoRouteObserver()],
      ),
      // routeInformationProvider: _rootRouter.routeInfoProvider(),
      routeInformationParser: _rootRouter.defaultRouteParser(),
      builder: (_, router) {
        return ChangeNotifierProvider<AuthService>(
          create: (_) => authService,
          child: BooksDBProvider(
            child: router!,
            // child: SmoothParent(child: router!),
          ),
        );
      },
    );
  }
}
