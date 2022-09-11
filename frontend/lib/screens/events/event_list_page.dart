import 'package:auto_route/auto_route.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/material.dart';

import 'package:jonline/db.dart';
import 'package:jonline/screens/accounts/account_chooser.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  EventListScreenState createState() => EventListScreenState();
}

class EventListScreenState extends State<EventListScreen>
    with AutoRouteAwareStateMixin<EventListScreen> {
  late AppState appState;
  @override
  void didPushNext() {
    print('didPushNext');
  }

  @override
  void initState() {
    // print("PostListPage.initState");
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    appState.accounts.addListener(onAccountsChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("PostListPage.dispose");
    appState.accounts.removeListener(onAccountsChanged);
    super.dispose();
  }

  onAccountsChanged() {
    // print("PostListPage.onAccountsChanged");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var booksDb = BooksDBProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        actions: [
          if (JonlineAccount.selectedAccount != null)
            TextButton(
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                // context.router.pop();
              },
            ),
          const AccountChooser(),
        ],
      ),
      body: ListView(
        children: booksDb?.books
                .map((book) => Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(book.name),
                            subtitle:
                                SizedBox(height: 200, child: Text(book.genre)),
                            // trailing: SizedBox(width: 20, height: 200),
                            onTap: () {
                              context.pushRoute(EventDetailsRoute(id: book.id));
                            },
                          ),
                        ),
                      ],
                    ))
                .toList() ??
            const [],
      ),
    );
  }
}
