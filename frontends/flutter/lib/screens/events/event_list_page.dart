import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../db.dart';
import '../../router/router.gr.dart';
import '../home_page.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  EventListScreenState createState() => EventListScreenState();
}

class EventListScreenState extends State<EventListScreen>
    with AutoRouteAwareStateMixin<EventListScreen> {
  late AppState appState;
  late HomePageState homePage;

  @override
  void initState() {
    // print("PostsPage.initState");
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    homePage = context.findRootAncestorStateOfType<HomePageState>()!;
    appState.accounts.addListener(onAccountsChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.updateAccountList());
  }

  @override
  dispose() {
    // print("PostsPage.dispose");
    appState.accounts.removeListener(onAccountsChanged);
    super.dispose();
  }

  onAccountsChanged() {
    // print("PostsPage.onAccountsChanged");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var booksDb = BooksDBProvider.of(context);
    return Scaffold(
      body: ListView(
        children: booksDb?.books
                .map((book) => Column(
                      children: [
                        Card(
                          color: Colors.grey[400],
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
