import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
Color topColor = const Color(0xFF2E86AB);
Color bottomColor = const Color(0xFFA23B72);
Color authorColor = const Color(0xFF2eab54);
Color adminColor = const Color(0xFFab372e);

class AppState extends State<MyApp> {
  final authService = AuthService();
  final ValueJonotifer<List<JonlineAccount>> accounts =
      ValueJonotifer(<JonlineAccount>[]);
  final ValueJonotifer<List<JonlineServer>> servers =
      ValueJonotifer(<JonlineServer>[]);
  final ValueJonotifer<Posts> posts = ValueJonotifer(Posts());
  final Jonotifier updateReplies = Jonotifier();

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
      JonlineServer.selectedServer = JonlineServer(account.server);
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

  @override
  void initState() {
    super.initState();
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
      updateServerList();
      updateAccountList();
      updatePosts();
    });
    accounts.addListener(updatePosts);
    Settings.initialize(notifyAccountsListeners);
  }

  @override
  void dispose() {
    accounts.removeListener(updatePosts);
    accounts.dispose();
    updateReplies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark().copyWith(
        // bottomAppBarColor: const Color(0xFF884DF2),
        // splashColor: const Color(0xFFFFC145),
        // buttonColor: const Color(0xFF884DF2),
        colorScheme: ColorScheme.fromSeed(seedColor: topColor),
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
