import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/screens/accounts/admin_page.dart';
import 'package:provider/provider.dart';
import 'generated/admin.pb.dart';
import 'generated/google/protobuf/empty.pb.dart';
import 'models/jonline_clients.dart';
import 'utils/fake_js.dart' if (dart.library.js) 'dart:js';

import 'db.dart';
import 'generated/posts.pb.dart';
import 'jonotifier.dart';
import 'main.dart';
import 'models/jonline_account.dart';
import 'models/jonline_operations.dart';
import 'models/jonline_server.dart';
import 'models/settings.dart';
import 'my_platform.dart';
import 'router/auth_guard.dart';
import 'router/router.gr.dart';

const defaultServer = 'jonline.io';
const noOne = 'no one';
const animationDuration = Duration(milliseconds: 300);
const communicationDuration = Duration(milliseconds: 1000);
get animationDelay => Future.delayed(animationDuration);
get communicationDelay => Future.delayed(communicationDuration);

class AppState extends State<MyApp> {
  Color primaryColor = const Color(0xFF2E86AB);
  Color navColor = const Color(0xFFA23B72);
  Color authorColor = const Color(0xFF2eab54);
  Color adminColor = const Color(0xFFab372e);
  final ValueJonotifer<ServerColors?> colorTheme =
      ValueJonotifer<ServerColors?>(null);

  final authService = AuthService();
  final ValueJonotifer<List<JonlineAccount>> accounts =
      ValueJonotifer(<JonlineAccount>[]);
  final ValueJonotifer<List<JonlineServer>> servers =
      ValueJonotifer(<JonlineServer>[]);
  final ValueJonotifer<Posts> posts = ValueJonotifer(Posts());
  final Jonotifier updateReplies = Jonotifier();
  final Jonotifier selectedServerChanged = Jonotifier();
  final Jonotifier selectedAccountChanged = Jonotifier();

  final _rootRouter = RootRouter(
    authGuard: AuthGuard(),
  );

  ValueNotifier<bool> updatingPosts = ValueNotifier(true);
  ValueNotifier<bool> didUpdatePosts = ValueNotifier(false);
  Future<void> updatePosts({Function(String)? showMessage}) async {
    updatingPosts.value = true;
    final Posts? posts = await JonlineOperations.getPosts();
    if (posts == null) {
      setState(() {
        updatingPosts.value = false;
        // showSnackBar
      });
      return;
    }

    didUpdatePosts.value = true;
    // await animationDelay;

    setState(() {
      updatingPosts.value = false;
      this.posts.value = posts;
    });
    didUpdatePosts.value = false;
    // await communicationDelay;
    // showMessage?.call("Posts updated! 🎉");
  }

  JonlineAccount? get selectedAccount => JonlineAccount.selectedAccount;
  set selectedAccount(JonlineAccount? account) {
    if (account != null) {
      Future.sync(() async => JonlineServer.selectedServer =
          (await JonlineServer.servers).firstWhere(
              (s) => s.server == account.server,
              orElse: () => JonlineServer(account.server)));
    }
    JonlineAccount.selectedAccount = account;
    updateAccountList();
    resetPosts();
  }

  resetPosts() {
    setState(() {
      updatingPosts.value = true;
      posts.value = Posts();
    });
    updatePosts();
  }

  updateAccountList() async {
    accounts.value = await JonlineAccount.accounts;
  }

  updateServerList() async {
    servers.value = await JonlineServer.servers;
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

  @override
  void initState() {
    super.initState();
    accounts.addListener(updatePosts);
    accounts.addListener(monitorAccountChange);
    accounts.addListener(monitorServerChange);
    selectedServerChanged.addListener(updateColorTheme);
    colorTheme.addListener(updateColors);
    Settings.initialize(notifyAccountsListeners);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // For web, ensure the actual URL hostname is used as the default server.
      if (MyPlatform.isWeb) {
        final String serverHost = context.callMethod("getJonlineServer", []);
        final JonlineServer server = JonlineServer(serverHost);
        final List<JonlineServer> servers = await JonlineServer.servers;
        if (!servers.contains(server)) {
          await server.saveNew(atBeginning: true);
          JonlineServer.selectedServer = server;
        }
      }
      await updateColorTheme();
      await updateServerList();
      await updateAccountList();
      await updatePosts();
    });
  }

  @override
  void dispose() {
    accounts.removeListener(monitorAccountChange);
    accounts.removeListener(monitorServerChange);
    selectedServerChanged.removeListener(updateColorTheme);
    colorTheme.removeListener(updateColors);
    colorTheme.removeListener(updateColors);
    accounts.removeListener(updatePosts);
    accounts.dispose();
    updateReplies.dispose();
    colorTheme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark().copyWith(
        // bottomAppBarColor: const Color(0xFF884DF2),
        // splashColor: const Color(0xFFFFC145),
        // buttonColor: const Color(0xFF884DF2),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
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
          ),
        );
      },
    );
  }
}
