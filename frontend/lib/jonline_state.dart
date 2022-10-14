import 'package:flutter/material.dart';

import 'app_state.dart';
import 'generated/permissions.pb.dart';
import 'models/jonline_account.dart';
import 'screens/home_page.dart';

abstract class JonlineState<T extends StatefulWidget>
    extends JonlineBaseState<T> {
  late HomePageState homePage;

  @override
  void initState() {
    super.initState();
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

abstract class JonlineBaseState<T extends StatefulWidget> extends State<T> {
  late AppState appState;
  TextTheme get textTheme => Theme.of(context).textTheme;
  MediaQueryData get mq => MediaQuery.of(context);
  List<Permission> get userPermissions =>
      JonlineAccount.selectedAccount?.permissions ?? [];

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
