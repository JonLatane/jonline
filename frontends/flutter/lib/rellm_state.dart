import 'package:flutter/material.dart';

import 'app_state.dart';
import 'generated/permissions.pb.dart';
import 'models/rellm_account.dart';
import 'screens/home_page.dart';

abstract class RellmState<T extends StatefulWidget>
    extends RellmBaseState<T> {
  late HomePageState homePage;

  @override
  void initState() {
    super.initState();
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
  }
}

// ignore: must_be_immutable
abstract class RellmStatelessWidget extends StatelessWidget {
  late AppState appState;
  late TextTheme textTheme;
  late MediaQueryData mq;

  List<Permission> get userPermissions =>
      RellmAccount.selectedAccount?.permissions ?? [];

  RellmStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    appState = context.findRootAncestorStateOfType<AppState>()!;
    textTheme = Theme.of(context).textTheme;
    mq = MediaQuery.of(context);

    return buildWidget(context);
  }

  Widget buildWidget(BuildContext context);
}

abstract class RellmBaseState<T extends StatefulWidget> extends State<T> {
  late AppState appState;
  TextTheme get textTheme => Theme.of(context).textTheme;
  MediaQueryData get mq => MediaQuery.of(context);
  List<Permission> get userPermissions =>
      RellmAccount.selectedAccount?.permissions ?? [];

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
