import 'package:flutter/cupertino.dart';

class Book {
  final int id;
  final String name;
  final String genre;

  const Book({
    required this.id,
    required this.name,
    required this.genre,
  });
}

class BooksDB {
  List<Book> books = const [
    Book(
        id: 1,
        genre: 'jonline.io/bill',
        name:
            'You can create personal posts and stuff like this and share them with friends!'),
    Book(
        id: 2,
        genre: 'jonline.io/bill',
        name:
            'There will probably also be some visibility type stuff to be done here'),
    Book(
        id: 3,
        genre: 'work.com/jeff',
        name:
            'You see things for work-related accounts (i.e. work.com) while browsing on a personal server (i.e. jonline.io) *only if you\'ve federated your work and personal accounts*.'),
    Book(
        id: 4,
        genre: 'work.com/jeff',
        name:
            'So you could only see work Posts (i.e. from work.com) when you choose the work account from the top-right picker.'),
    Book(id: 5, genre: 'work.com/jeff', name: 'Yay work-life balance!'),
    Book(
        id: 6, genre: 'jonline.io/bill', name: 'Also capitalism sucks n stuff'),
    Book(id: 7, genre: 'jonline.io/bill', name: 'Corn'),
  ];

  Book findBookById(int id) {
    return books.firstWhere(
      (book) => book.id == id,
      orElse: () => throw ('Can not find book with id $id'),
    );
  }
}

class BooksDBProvider extends InheritedWidget {
  final booksDb = BooksDB();

  BooksDBProvider({Key? key, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(oldWidget) {
    return false;
  }

  static BooksDB? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BooksDBProvider>()
        ?.booksDb;
  }
}

class UsersDB {
  final List<User> users = [
    User(id: 1, name: 'User one', email: 'userone@email.com', books: [
      const Book(
          id: 1,
          genre: 'jonline.io/bill',
          name:
              'You can create personal posts and stuff like this and share them with friends!'),
      const Book(
          id: 2,
          genre: 'jonline.io/bill',
          name:
              'There will probably also be some visibility type stuff to be done here'),
      const Book(
          id: 3,
          genre: 'work.com/jeff',
          name:
              'You see things for work-related accounts (i.e. from work.com) while browsing on a personal server (i.e. jonline.io) *only if you\'ve federated work and personal modes*.'),
    ]),
    User(id: 2, name: 'User two', email: 'usertwo@email.com', books: [
      const Book(id: 5, genre: 'work.com/jeff', name: 'Yay work-life balance!'),
      const Book(
          id: 6,
          genre: 'jonline.io/bill',
          name: 'Also capitalism sucks n stuff'),
      const Book(id: 7, genre: 'jonline.io/bill', name: 'Corn'),
    ])
  ];

  User findUserById(int id) {
    return users.firstWhere(
      (user) => user.id == id,
      orElse: () => throw ('Can not find user with id $id'),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final List<Book> books;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.books,
  });
}

class UsersDBProvider extends InheritedWidget {
  final usersDB = UsersDB();

  UsersDBProvider({Key? key, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(oldWidget) {
    return false;
  }

  static UsersDB? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UsersDBProvider>()
        ?.usersDB;
  }
}
