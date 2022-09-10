import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/db.dart';
import 'package:jonline/router/auth_guard.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'models/jonline_account.dart';

const animationDuration = Duration(milliseconds: 300);

class AppState extends State<MyApp> {
  final authService = AuthService();
  ValueNotifier<List<JonlineAccount>> accounts = ValueNotifier([]);

  final _rootRouter = RootRouter(
    authGuard: AuthGuard(),
  );

  updateAccountList() async {
    print("updateAccountList");
    accounts.value = await JonlineAccount.accounts;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => updateAccountList());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark().copyWith(
        // bottomAppBarColor: const Color(0xFF884DF2),
        // splashColor: const Color(0xFFFFC145),
        // buttonColor: const Color(0xFF884DF2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E86AB)),
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
