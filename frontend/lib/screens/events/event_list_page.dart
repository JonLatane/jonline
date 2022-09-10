import 'package:auto_route/auto_route.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/material.dart';

import 'package:jonline/db.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  EventListScreenState createState() => EventListScreenState();
}

class EventListScreenState extends State<EventListScreen>
    with AutoRouteAwareStateMixin<EventListScreen> {
  @override
  void didPushNext() {
    print('didPushNext');
  }

  @override
  Widget build(BuildContext context) {
    var booksDb = BooksDBProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        actions: [
          TextButton(
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              // context.router.pop();
            },
          ),
          SizedBox(
            width: 72,
            child: TextButton(
              style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                  foregroundColor:
                      MaterialStateProperty.all(Colors.white.withAlpha(100)),
                  overlayColor:
                      MaterialStateProperty.all(Colors.white.withAlpha(100)),
                  splashFactory: InkSparkle.splashFactory),
              onPressed: () {
                // context.router.pop();
              },
              child: Column(
                children: const [
                  Expanded(child: SizedBox()),
                  Text('jonline.io/', style: TextStyle(fontSize: 11)),
                  Text('jon', style: TextStyle(fontSize: 12)),
                  Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
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
