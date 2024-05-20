// ignore_for_file: invalid_use_of_protected_member

import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/screens/groups/group_chooser.dart';

import '../models/jonline_account.dart';
import '../my_platform.dart';
import '../router/router.gr.dart';
import '../screens/accounts/account_chooser.dart';
import '../screens/home_page.dart';

extension HomePageAppBar on HomePageState {
  PreferredSizeWidget get appBar {
    Widget bar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
      // backgroundColor: Colors.transparent,
      title: titleWidget ??
          Text(
            title,
            style: const TextStyle(
              // fontSize: 20,
              color: Colors.white,
              // fontWeight: FontWeight.w200,
            ),
          ),
      key: Key("appbar-${appState.colorTheme.value?.hashCode}"),
      leading: leadingNavWidget,
      automaticallyImplyLeading: false,
      actions: actions,
    );
    if (MyPlatform.isMacOS) {
      bar = Column(
        children: [
          Container(
              height: HomePageState.appBarPadding,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
          PreferredSize(
            preferredSize: Size(
                MediaQuery.of(context).size.width, HomePageState.appBarHeight),
            child: bar,
          ),
        ],
      );
    }
    return PreferredSize(
      preferredSize: Size(MediaQuery.of(context).size.width,
          HomePageState.appBarHeight + HomePageState.appBarPadding),
      child: ClipRRect(
          child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: bar,
      )),
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
      case PostsRoute.name:
      case PostsTab.name:
      case EventListRoute.name:
      case EventsTab.name:
      case AccountsRoute.name:
      case AccountsTab.name:
        return false;
    }
    return true;
  }

  Widget? get leadingNavWidget {
    if (!showLeadingNav) return null;
    switch (context.topRoute.name) {
      case PeopleRoute.name:
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
      case GroupsRoute.name:
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
      color: Colors.white,
      showIfParentCanPop: false,
      ignorePagelessRoutes: true,
    );
  }

  Widget? get titleWidget {
    switch (context.topRoute.name) {
      case PeopleRoute.name:
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
      case GroupsRoute.name:
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
      case 'MyProfileRoute':
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
            Text("${titleServer ?? '...'}/", style: textTheme.bodySmall),
            Text(titleUsername ?? '...', style: textTheme.titleSmall),
          ],
        );
      case 'ServerConfigurationRoute':
        final String server = context.topRoute.pathParams.get('server');
        return Row(
          children: [
            Text('Server Configuration: ', style: textTheme.titleSmall),
            Text("$server/", style: textTheme.bodySmall),
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
            // setState(() {
            titleServer = account.server;
            titleUsername = account.username;
            // });
          });
        }
        return Row(
          children: [
            Text('Admin: ', style: textTheme.titleSmall),
            // Text(' for ', style: textTheme.bodyText2),
            // SizedBox(width: 7 *mq.textScaleFactor),
            Text("${titleServer ?? '...'}/", style: textTheme.bodySmall),
            Text(titleUsername ?? '...', style: textTheme.titleSmall),
          ],
        );
      default:
        resetTitleServerAndUser();
        return null;
    }
  }

  resetTitleServerAndUser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleServer = null;
      titleUsername = null;
    });
  }

  bool get showingMembers => appState.selectedGroup.value != null;
  String get people => !showingMembers ? 'People' : 'Members';
  String get person => !showingMembers ? 'Person' : 'Member';
  String get title {
    switch (context.topRoute.name) {
      case GroupsRoute.name:
      case GroupsTab.name:
        return 'Groups';
      case GroupDetailsRoute.name:
        return 'Group Details';
      case CreateGroupRoute.name:
        return 'Create Group';
      case PeopleRoute.name:
      case 'PeopleTab':
        return people;
      case AuthorProfileRoute.name:
        return 'Author Details';
      case UserProfileRoute.name:
        return '$person Details';
      case PostsRoute.name:
      case PostsTab.name:
        return 'Posts';
      case PostDetailsRoute.name:
        return 'Post Details';
      case EventListRoute.name:
      case EventsTab.name:
        return 'Events [Mock]';
      case EventDetailsRoute.name:
        return 'Event Details [Mock]';
      case MyProfileRoute.name:
      case AccountsRoute.name:
      case AccountsTab.name:
        return 'Accounts';
      case CreatePostRoute.name:
        return 'Create Post';
      case CreateReplyRoute.name:
      case CreateDeepReplyRoute.name:
        return 'Create Reply';
      // case SettingsRoute.name:
      case SettingsTab.name:
        return 'Settings';
    }
    return context.topRoute.name;
  }

  List<Widget>? get actions {
    switch (context.topRoute.name) {
      case PeopleRoute.name:
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
          const GroupChooser(),
          const AccountChooser(),
        ];
      case GroupsRoute.name:
      case GroupsTab.name:
        bool showSearch = groupsSearch.value;
        bool showAddButton = !showSearch && JonlineAccount.loggedIn;
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
          const GroupChooser(),
          const AccountChooser(),
        ];
      case CreateGroupRoute.name:
        return [
          if (JonlineAccount.loggedIn)
            SizedBox(
              width: 72,
              child: ElevatedButton(
                style: ButtonStyle(
                    padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                    foregroundColor: WidgetStateProperty.all(
                        Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
                    overlayColor:
                        WidgetStateProperty.all(Colors.white.withAlpha(100)),
                    splashFactory: InkSparkle.splashFactory),
                onPressed: canCreateGroup.value ? () => createGroup() : null,
                // doingStuff || username.isEmpty || password.isEmpty
                //     ? null
                //     : createAccount,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Opacity(
                    opacity: canCreateGroup.value ? 1 : 0.5,
                    child: const Column(
                      children: [
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
      case GroupDetailsRoute.name:
      case AccountsRoute.name:
      case PostDetailsRoute.name:
      case UserProfileRoute.name:
        return [const GroupChooser(), const AccountChooser()];
      // return [const AccountChooser()];
      case PostsRoute.name:
      case PostsTab.name:
        return [
          if (JonlineAccount.loggedIn)
            TextButton(
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                context.navigateNamedTo('/posts/create');
              },
            ),
          const GroupChooser(),
          const AccountChooser(),
        ];
      case EventListRoute.name:
      case EventsTab.name:
        return [
          if (JonlineAccount.loggedIn)
            const TextButton(
              onPressed: null,
              child: Icon(
                Icons.add,
                // color: Colors.white,
              ),
            ),
          const GroupChooser(),
          const AccountChooser(),
        ];
      case CreatePostRoute.name:
        return [
          if (JonlineAccount.loggedIn)
            SizedBox(
              width: 72,
              child: ElevatedButton(
                style: ButtonStyle(
                    padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                    foregroundColor: WidgetStateProperty.all(
                        Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
                    overlayColor:
                        WidgetStateProperty.all(Colors.white.withAlpha(100)),
                    splashFactory: InkSparkle.splashFactory),
                onPressed: canCreatePost.value ? () => createPost() : null,
                // doingStuff || username.isEmpty || password.isEmpty
                //     ? null
                //     : createAccount,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Opacity(
                    opacity: canCreatePost.value ? 1 : 0.5,
                    child: const Column(
                      children: [
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
      case CreateDeepReplyRoute.name:
      case CreateReplyRoute.name:
        return [
          if (JonlineAccount.loggedIn)
            SizedBox(
              width: 72,
              child: ElevatedButton(
                style: ButtonStyle(
                    padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                    foregroundColor: WidgetStateProperty.all(
                        Colors.white.withAlpha(title.isEmpty ? 100 : 255)),
                    overlayColor:
                        WidgetStateProperty.all(Colors.white.withAlpha(100)),
                    splashFactory: InkSparkle.splashFactory),
                onPressed: canCreateReply.value ? () => createReply() : null,
                // doingStuff || username.isEmpty || password.isEmpty
                //     ? null
                //     : createAccount,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Opacity(
                    opacity: canCreateReply.value ? 1 : 0.5,
                    child: const Column(
                      children: [
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
      case MyProfileRoute.name:
      case AccountsTab.name:
        return null;
      // case SettingsRoute.name:
      case SettingsTab.name:
        return null;
    }
    return null;
  }
}
