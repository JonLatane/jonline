import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'generated/posts.pb.dart';
import 'jonotifier.dart';
import 'main.dart';
import 'models/jonline_account.dart';
import 'models/jonline_operations.dart';
import 'models/settings.dart';
import 'router/auth_guard.dart';
import 'router/router.gr.dart';

const defaultServer = 'jonline.io';
const noOne = 'no one';
const animationDuration = Duration(milliseconds: 300);
const communicationDuration = Duration(milliseconds: 1000);
get communicationDelay => Future.delayed(communicationDuration);
Color topColor = const Color(0xFF2E86AB);
Color bottomColor = const Color(0xFFA23B72);

class AppState extends State<MyApp> {
  final authService = AuthService();
  final ValueNotifier<List<JonlineAccount>> accounts = ValueNotifier([]);
  final ValueNotifier<Posts> posts = ValueNotifier(Posts());
  final Jonotifier updateReplies = Jonotifier();

  final _rootRouter = RootRouter(
    authGuard: AuthGuard(),
  );

  Future<void> updatePosts({Function(String)? showMessage}) async {
    final Posts? posts = await JonlineOperations.getSelectedPosts();
    if (posts == null) return;

    setState(() {
      this.posts.value = posts;
    });
    await communicationDelay;
    // showMessage?.call("Posts updated! 🎉");
  }

  JonlineAccount? get selectedAccount => JonlineAccount.selectedAccount;
  set selectedAccount(JonlineAccount? account) {
    JonlineAccount.selectedAccount = account;
    updateAccountList();
  }

  updateAccountList() async {
    accounts.value = await JonlineAccount.accounts;
  }

  updateAccountDependents() {
    accounts.value = accounts.value;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      updateAccountList();
      updatePosts();
    });
    accounts.addListener(updatePosts);
    Settings.initialize(updateAccountDependents);
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
