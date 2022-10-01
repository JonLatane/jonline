import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../generated/admin.pb.dart';
import '../../app_state.dart';
import '../../models/jonline_account.dart';

class AdminPage extends StatefulWidget {
  final String? filter;
  final String accountId;

  const AdminPage({
    Key? key,
    @queryParam this.filter = 'none',
    @pathParam this.accountId = '',
  }) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late AppState appState;

  JonlineAccount? account;
  TextTheme get textTheme => Theme.of(context).textTheme;
  String? get server => account?.server;
  ServerConfiguration? serverConfiguration;

  @override
  initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    Future.microtask(() async {
      final account = (await JonlineAccount.accounts).firstWhere(
        (account) => account.id == widget.accountId,
      );
      setState(() {
        this.account = account;
      });
    });
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Admin Page 👷🏼‍♂️🛠'),
          // TextButton(
          //     onPressed: () {
          //       ScaffoldMessenger.of(context).hideCurrentSnackBar();
          //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //           content: const Text('Really post demo data?'),
          //           action: SnackBarAction(
          //             label: 'Post it!', // or some operation you would like
          //             onPressed: () {
          //               if (account == null) {
          //                 showSnackBar("Account not ready.");
          //               }
          //               postDemoData(account!, showSnackBar, appState);
          //             },
          //           )));
          //     },
          //     child: const Text("Post demo data"))
        ],
      ),
    )
        // body: Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Text(
        //         'My Books -> filter: ${widget.filter}',
        //         style: Theme.of(context).textTheme.headline6,
        //       ),
        //       const SizedBox(height: 16),
        //       Text(
        //         'Fragment Support? ${context.routeData.fragment}',
        //         style: Theme.of(context).textTheme.bodyText1,
        //       ),
        //       const SizedBox(height: 32),
        //       ElevatedButton(
        //         onPressed: () {
        //           context.navigateTo(
        //             SettingsTab(tab: 'newSegment', query: 'newQuery'),
        //           );
        //         },
        //         child: const Text('navigate to /settings/newSegment'),
        //       ),
        //       ElevatedButton(
        //         onPressed: () {
        //           context.navigateBack();
        //         },
        //         child: const Text('Navigate back'),
        //       )
        //     ],
        //   ),
        // ),
        );
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
