import 'package:auto_route/auto_route.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/material.dart';

import 'package:jonline/db.dart';
import 'package:jonline/screens/accounts/account_chooser.dart';
import 'package:jonline/screens/posts/post_preview.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);

  @override
  PostListScreenState createState() => PostListScreenState();
}

class PostListScreenState extends State<PostListScreen>
    with AutoRouteAwareStateMixin<PostListScreen> {
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
        // automaticallyImplyLeading: false,
        title: const Text(
          "Posts",
        ),
        // leading:
        actions: [
          if (JonlineAccount.selectedAccount != null)
            TextButton(
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                context.navigateNamedTo('/posts/create');
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
                        PostPreview(
                            onTap: () {
                              context.pushRoute(PostDetailsRoute(id: book.id));
                            },
                            post: Post(
                                title: book.name,
                                author: Post_Author(username: book.genre))),

                        // Card(
                        //   margin: const EdgeInsets.symmetric(
                        //       horizontal: 16, vertical: 8),
                        //   child: ListTile(
                        //     title: Text(book.name),
                        //     subtitle: Text(book.genre),
                        //     onTap: () {
                        //       context.pushRoute(PostDetailsRoute(id: book.id));
                        //     },
                        //   ),
                        // ),
                      ],
                    ))
                .toList() ??
            const [],
      ),
    );
  }
}
