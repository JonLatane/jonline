import 'package:auto_route/auto_route.dart';
import 'package:jonline/db.dart';
import 'package:jonline/router/auth_guard.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authService = AuthService();

  final _rootRouter = RootRouter(
    authGuard: AuthGuard(),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark().copyWith(
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
