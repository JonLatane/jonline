import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/models/demo_data.dart';
import 'package:jonline/models/jonline_account.dart';

class MyActivityPage extends StatefulWidget {
  final String? filter;
  final String accountId;

  const MyActivityPage({
    Key? key,
    @queryParam this.filter = 'none',
    @PathParam('account_id') this.accountId = '',
  }) : super(key: key);

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  JonlineAccount? account;
  TextTheme get textTheme => Theme.of(context).textTheme;

  @override
  initState() {
    super.initState();
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
        children: [
          TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Really post demo data?'),
                    action: SnackBarAction(
                      label: 'Post it!', // or some operation you would like
                      onPressed: () {
                        if (account == null) {
                          showSnackBar("Account not ready.");
                        }
                        postDemoData(account!, showSnackBar);
                      },
                    )));
              },
              child: const Text("Post demo data"))
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
