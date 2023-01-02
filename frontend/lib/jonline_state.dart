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

// ignore: must_be_immutable
abstract class JonlineStatelessWidget extends StatelessWidget {
  late AppState appState;
  late TextTheme textTheme;
  late MediaQueryData mq;

  List<Permission> get userPermissions =>
      JonlineAccount.selectedAccount?.permissions ?? [];

  JonlineStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    appState = context.findRootAncestorStateOfType<AppState>()!;
    textTheme = Theme.of(context).textTheme;
    mq = MediaQuery.of(context);

    return buildWidget(context);
  }

  Widget buildWidget(BuildContext context);
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
