// ignore_for_file: invalid_use_of_protected_member

import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';

import '../models/jonline_account.dart';
import '../screens/accounts/account_chooser.dart';
import '../screens/home_page.dart';

extension HomePageAppBar on HomePageState {
  PreferredSizeWidget get appBar {
    return PreferredSize(
      preferredSize: Size(MediaQuery.of(context).size.width, 48),
      child: ClipRRect(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                title: titleWidget ?? Text(title),
                key: Key("appbar-${appState.colorTheme.value?.hashCode}"),
                leading: leadingNavWidget,
                automaticallyImplyLeading: false,
                actions: actions,
              ))),
    );
    // return AppBar(
    //   title: titleWidget ?? Text(title),
    //   key: Key("appbar-${appState.colorTheme.value?.hashCode}"),
    //   leading: showLeadingNav
    //       ? const AutoLeadingButton(
    //           // showIfChildCanPop: false,
    //           showIfParentCanPop: false,
    //           ignorePagelessRoutes: true,
    //         )
    //       : null,
    //   automaticallyImplyLeading: false,
    //   actions: actions,
    // );
  }

  bool get showLeadingNav {
    switch (context.topRoute.name) {
      case 'PostsRoute':
      case 'PostsTab':
      case 'EventListRoute':
      case 'EventsTab':
      case 'AccountsRoute':
      case 'AccountsTab':
        return false;
    }
    return true;
  }

  Widget? get leadingNavWidget {
    if (!showLeadingNav) return null;
    switch (context.topRoute.name) {
      case 'PeopleRoute':
        return peopleSearch.value == false
            ? Tooltip(
                message: "Search People",
                child: TextButton(
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    peopleSearch.value = true;
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      peopleSearchFocus.requestFocus();
                    });
                  },
                ))
            : null;
      case 'GroupsRoute':
        return groupsSearch.value == false
            ? Tooltip(
                message: "Search Groups",
                child: TextButton(
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    groupsSearch.value = true;
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      groupsSearchFocus.requestFocus();
                    });
                  },
                ),
              )
            : null;
    }
    return const AutoLeadingButton(
      // showIfChildCanPop: false,
      showIfParentCanPop: false,
      ignorePagelessRoutes: true,
    );
  }

  Widget? get titleWidget {
    switch (context.topRoute.name) {
      case 'PeopleRoute':
        if (peopleSearch.value == true) {
          return TextField(
            autofocus: true,
            focusNode: peopleSearchFocus,
            controller: peopleSearchController,
            onChanged: (value) {
              // peopleSearch.value = value;
            },
            decoration: const InputDecoration(
              hintText: 'Search People',
              border: InputBorder.none,
              // hintStyle: TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          );
        } else {
          return null;
        }
      case 'GroupsRoute':
        if (groupsSearch.value == true) {
          return TextField(
            autofocus: true,
            focusNode: groupsSearchFocus,
            controller: groupsSearchController,
            onChanged: (value) {
              // peopleSearch.value = value;
            },
            decoration: const InputDecoration(
              hintText: 'Search Groups',
              border: InputBorder.none,
              // hintStyle: TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          );
        } else {
          return null;
        }
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
      case 'ServerConfigurationRoute':
        final String server = context.topRoute.pathParams.get('server');
        return Row(
          children: [
            Text('Server Configuration: ', style: textTheme.subtitle2),
            Text("$server/", style: textTheme.caption),
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
      case 'GroupsRoute':
      case 'GroupsTab':
        return 'Groups';
      case 'CreateGroupRoute':
        return 'Create Group';
      case 'PeopleRoute':
      case 'PeopleTab':
        return 'People';
      case 'PersonDetailsRoute':
        return 'Person Details [Mock]';
      case 'PostsRoute':
      case 'PostsTab':
        return 'Posts';
      case 'PostDetailsRoute':
        return 'Post Details';
      case 'EventListRoute':
      case 'EventsTab':
        return 'Events [Mock]';
      case 'EventDetailsRoute':
        return 'Event Details [Mock]';
      case 'ProfileRoute':
      case 'AccountsRoute':
      case 'AccountsTab':
        return 'Accounts';
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
      case 'PeopleRoute':
        return [
          if (peopleSearch.value == true)
            TextButton(
              child: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () {
                peopleSearchController.text = '';
                peopleSearch.value = false;
                // context.navigateNamedTo('/posts/create');
              },
            ),
          const AccountChooser(),
        ];
      case 'GroupsRoute':
      case 'GroupsTab':
        bool showSearch = groupsSearch.value;
        bool showAddButton =
            !showSearch && JonlineAccount.selectedAccount != null;
        return [
          if (showSearch || showAddButton)
            Tooltip(
              message: showSearch ? 'Cancel Search' : 'Add Group',
              child: TextButton(
                onPressed: showSearch
                    ? () {
                        groupsSearchController.text = '';
                        groupsSearch.value = false;
                      }
                    : () {
                        context.navigateNamedTo('/groups/create');
                      },
                child: AnimatedRotation(
                  duration: animationDuration,
                  turns: showSearch ? 0.125 : 0,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const AccountChooser(),
        ];
      case 'CreateGroupRoute':
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
                onPressed: canCreateGroup.value ? () => createGroup() : null,
                // doingStuff || username.isEmpty || password.isEmpty
                //     ? null
                //     : createAccount,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Opacity(
                    opacity: canCreateGroup.value ? 1 : 0.5,
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
      case 'AccountsRoute':
      case 'PostDetailsRoute':
        return [const AccountChooser()];
      case 'PostsRoute':
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
