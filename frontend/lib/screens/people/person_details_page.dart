import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../db.dart';

class PersonDetailsPage extends StatefulWidget {
  final int id;

  const PersonDetailsPage({
    Key? key,
    @pathParam this.id = -1,
  }) : super(key: key);

  @override
  PersonDetailsPageState createState() => PersonDetailsPageState();
}

class PersonDetailsPageState extends State<PersonDetailsPage> {
  int counter = 1;

  @override
  Widget build(BuildContext context) {
    final booksDb = BooksDBProvider.of(context);
    final book = booksDb?.findBookById(widget.id);

    return book == null
        ? const Text('Book null')
        : Scaffold(
            body: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: Hero(
                  tag: 'Hero${book.id}',
                  child: Card(
                    margin: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Book Details/${book.id}'),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            'Reads  $counter',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FloatingActionButton(
                          heroTag: null,
                          onPressed: () {
                            setState(() {
                              counter++;
                            });
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
