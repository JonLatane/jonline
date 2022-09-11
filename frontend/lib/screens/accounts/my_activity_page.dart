import 'package:auto_route/auto_route.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: account == null
            ? null
            : Row(
                children: [
                  Text("${account!.server}/", style: textTheme.caption),
                  Text(account!.username, style: textTheme.subtitle2),
                ],
              ),
        leading: const AutoLeadingButton(
          ignorePagelessRoutes: true,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'My Books -> filter: ${widget.filter}',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            Text(
              'Fragment Support? ${context.routeData.fragment}',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.navigateTo(
                  SettingsTab(tab: 'newSegment', query: 'newQuery'),
                );
              },
              child: const Text('navigate to /settings/newSegment'),
            ),
            ElevatedButton(
              onPressed: () {
                context.navigateBack();
              },
              child: const Text('Navigate back'),
            )
          ],
        ),
      ),
    );
  }
}
