import 'package:auto_route/auto_route.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/material.dart';

import 'package:jonline/db.dart';
import 'package:jonline/screens/posts/post_preview.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);

  @override
  PostListScreenState createState() => PostListScreenState();
}

class PostListScreenState extends State<PostListScreen>
    with AutoRouteAwareStateMixin<PostListScreen> {
  @override
  void didPushNext() {
    print('didPushNext');
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
