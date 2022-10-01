// ignore_for_file: invalid_use_of_protected_member

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/jonline_account.dart';
import '../screens/accounts/account_chooser.dart';
import '../screens/home_page.dart';

extension HomePageAppBar on HomePageState {
  AppBar get appBar {
    return AppBar(
      title: titleWidget ?? Text(title),
      leading: showLeadingNav
          ? const AutoLeadingButton(
              // showIfChildCanPop: false,
              showIfParentCanPop: false,
              ignorePagelessRoutes: true,
            )
          : null,
      automaticallyImplyLeading: false,
      actions: actions,
    );
  }

  bool get showLeadingNav {
    switch (context.topRoute.name) {
      case 'PostListRoute':
      case 'PostsTab':
      case 'EventListRoute':
      case 'EventsTab':
      case 'AccountsRoute':
      case 'AccountsTab':
        return false;
    }
    return true;
  }

  Widget? get titleWidget {
    switch (context.topRoute.name) {
      case 'MyActivityRoute':
        // context.topRoute.args[0] as String;
        if (titleServer == null || titleUsername == null) {
          // final Object? accountId = context.topRoute.args;
          final String accountId = context.topRoute.pathParams.get('accountId');
          Future.microtask(() async {
            final account = (await JonlineAccount.accounts).firstWhere(
              (account) => account.id == accountId,
            );
            setState(() {
              titleServer = account.server;
              titleUsername = account.username;
            });
          });
        }
        return Row(
          children: [
            Text("${titleServer ?? '...'}/", style: textTheme.caption),
            Text(titleUsername ?? '...', style: textTheme.subtitle2),
          ],
        );
      case 'AdminRoute':
        // context.topRoute.args[0] as String;
        if (titleServer == null || titleUsername == null) {
          // final Object? accountId = context.topRoute.args;
          final String accountId = context.topRoute.pathParams.get('accountId');
          Future.microtask(() async {
            final account = (await JonlineAccount.accounts).firstWhere(
              (account) => account.id == accountId,
            );
            setState(() {
              titleServer = account.server;
              titleUsername = account.username;
            });
          });
        }
        return Row(
          children: [
            Text('Admin: ', style: textTheme.subtitle2),
            // Text(' for ', style: textTheme.bodyText2),
            // SizedBox(width: 7 * MediaQuery.of(context).textScaleFactor),
            Text("${titleServer ?? '...'}/", style: textTheme.caption),
            Text(titleUsername ?? '...', style: textTheme.subtitle2),
          ],
        );
      default:
        titleServer = null;
        titleUsername = null;
        return null;
    }
  }

  String get title {
    switch (context.topRoute.name) {
      case 'PostListRoute':
      case 'PostsTab':
        return 'Posts';
      case 'PostDetailsRoute':
        return 'Post Details';
      case 'EventListRoute':
      case 'EventsTab':
        return 'Events';
      case 'EventDetailsRoute':
        return 'Event Details';
      case 'ProfileRoute':
      case 'AccountsRoute':
      case 'AccountsTab':
        return 'Accounts & Profiles';
      case 'CreatePostRoute':
        return 'Create Post';
      case 'CreateReplyRoute':
      case 'CreateDeepReplyRoute':
        return 'Create Reply';
      case 'SettingsRoute':
      case 'SettingsTab':
        return 'Settings';
    }
    return context.topRoute.name;
  }

  List<Widget>? get actions {
    switch (context.topRoute.name) {
      case 'PostDetailsRoute':
        return [const AccountChooser()];
      case 'PostListRoute':
      case 'PostsTab':
        return [
          if (JonlineAccount.selectedAccount != null)
            TextButton(
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                context.navigateNamedTo('/posts/create');
              },
            ),
          const AccountChooser(),
        ];
      case 'EventListRoute':
      case 'EventsTab':
        return [
          if (JonlineAccount.selectedAccount != null)
            const TextButton(
              onPressed: null,
              child: Icon(
                Icons.add,
                // color: Colors.white,
              ),
            ),
          const AccountChooser(),
        ];
      case 'CreatePostRoute':
        return [
          if (JonlineAccount.selectedAccount != null)
            SizedBox(
              width: 72,
              child: ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                    foregroundColor: MaterialStateProperty.all(
                        Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
                    overlayColor:
                        MaterialStateProperty.all(Colors.white.withAlpha(100)),
                    splashFactory: InkSparkle.splashFactory),
                onPressed: canCreatePost.value ? () => createPost() : null,
                // doingStuff || username.isEmpty || password.isEmpty
                //     ? null
                //     : createAccount,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Opacity(
                    opacity: canCreatePost.value ? 1 : 0.5,
                    child: Column(
                      children: const [
                        Expanded(child: SizedBox()),
                        Icon(Icons.add),
                        // Text('jonline.io/', style: TextStyle(fontSize: 11)),
                        Text('CREATE', style: TextStyle(fontSize: 12)),
                        Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const AccountChooser(),
        ];
      case 'CreateDeepReplyRoute':
      case 'CreateReplyRoute':
        return [
          if (JonlineAccount.selectedAccount != null)
            SizedBox(
              width: 72,
              child: ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                    foregroundColor: MaterialStateProperty.all(
                        Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
                    overlayColor:
                        MaterialStateProperty.all(Colors.white.withAlpha(100)),
                    splashFactory: InkSparkle.splashFactory),
                onPressed: canCreateReply.value ? () => createReply() : null,
                // doingStuff || username.isEmpty || password.isEmpty
                //     ? null
                //     : createAccount,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Opacity(
                    opacity: canCreateReply.value ? 1 : 0.5,
                    child: Column(
                      children: const [
                        Expanded(child: SizedBox()),
                        Icon(Icons.reply),
                        // Text('jonline.io/', style: TextStyle(fontSize: 11)),
                        Text('REPLY', style: TextStyle(fontSize: 12)),
                        Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const AccountChooser(),
        ];
      case 'ProfileRoute':
      case 'AccountsTab':
        return null;
      case 'SettingsRoute':
      case 'SettingsTab':
        return null;
    }
    return null;
  }
}
