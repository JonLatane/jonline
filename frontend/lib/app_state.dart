import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/db.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:jonline/router/auth_guard.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'models/jonline_account.dart';

const defaultServer = 'jonline.io';
const noOne = 'no one';
const animationDuration = Duration(milliseconds: 300);
const communicationDuration = Duration(milliseconds: 500);
final communicationDelay = Future.delayed(communicationDuration);
Color topColor = const Color(0xFF2E86AB);
Color bottomColor = const Color(0xFFA23B72);

class AppState extends State<MyApp> {
  final authService = AuthService();
  final ValueNotifier<List<JonlineAccount>> accounts = ValueNotifier([]);
  final ValueNotifier<Posts> posts = ValueNotifier(Posts());

  final _rootRouter = RootRouter(
    authGuard: AuthGuard(),
  );

  Future<void> updatePosts({Function(String)? showMessage}) async {
    final client = await JonlineAccount.getSelectedOrDefaultClient(
        showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return;
    }
    showMessage?.call("Loading posts...");
    final Posts posts;
    try {
      posts = await client.getPosts(GetPostsRequest(),
          options: JonlineAccount.selectedAccount?.authenticatedCallOptions);
    } catch (e) {
      showMessage?.call("Error loading posts.");
      await communicationDelay;
      showMessage?.call(formatServerError(e));
      return;
    }
    await communicationDelay;
    showMessage?.call("Updating posts...");
    setState(() {
      this.posts.value = posts;
    });
    await communicationDelay;
    showMessage?.call("Posts updated! 🎉");
  }

  JonlineAccount? get selectedAccount => JonlineAccount.selectedAccount;
  set selectedAccount(JonlineAccount? account) {
    JonlineAccount.selectedAccount = account;
    updateAccountList();
  }

  updateAccountList() async {
    print("updateAccountList");
    accounts.value = await JonlineAccount.accounts;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      updateAccountList();
      updatePosts();
    });
    accounts.addListener(updatePosts);
  }

  @override
  void dispose() {
    accounts.removeListener(updatePosts);
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
