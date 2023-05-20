// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i18;
import 'package:auto_route/empty_router_widgets.dart' as _i3;
import 'package:flutter/cupertino.dart' as _i21;
import 'package:flutter/material.dart' as _i19;

import '../screens/accounts/accounts_page.dart' as _i16;
import '../screens/accounts/server_configuration_page.dart' as _i17;
import '../screens/accounts/user_profile_page.dart' as _i9;
import '../screens/events/event_details_page.dart' as _i15;
import '../screens/events/event_list_page.dart' as _i14;
import '../screens/groups/create_group_page.dart' as _i12;
import '../screens/groups/group_details_page.dart' as _i11;
import '../screens/groups/groups_page.dart' as _i10;
import '../screens/home_page.dart' as _i1;
import '../screens/login_page.dart' as _i2;
import '../screens/people/people_page.dart' as _i13;
import '../screens/posts/create_post_page.dart' as _i7;
import '../screens/posts/create_reply_page.dart' as _i8;
import '../screens/posts/post_details_page.dart' as _i6;
import '../screens/posts/posts_page.dart' as _i5;
import '../screens/settings_page.dart' as _i4;
import 'auth_guard.dart' as _i20;

class RootRouter extends _i18.RootStackRouter {
  RootRouter({
    _i19.GlobalKey<_i19.NavigatorState>? navigatorKey,
    required this.authGuard,
  }) : super(navigatorKey);

  final _i20.AuthGuard authGuard;

  @override
  final Map<String, _i18.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i18.MaterialPageX<String>(
        routeData: routeData,
        child: _i18.WrappedRoute(child: const _i1.HomePage()),
      );
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i2.LoginPage(
          key: args.key,
          onLoginResult: args.onLoginResult,
          showBackButton: args.showBackButton,
        ),
      );
    },
    PostsTab.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i3.EmptyRouterPage(),
      );
    },
    GroupsTab.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i3.EmptyRouterPage(),
      );
    },
    PeopleTab.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i3.EmptyRouterPage(),
      );
    },
    EventsTab.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i3.EmptyRouterPage(),
      );
    },
    AccountsTab.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i3.EmptyRouterPage(),
      );
    },
    SettingsTab.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<SettingsTabArgs>(
          orElse: () => SettingsTabArgs(
                tab: pathParams.getString('tab'),
                query: queryParams.getString(
                  'query',
                  'none',
                ),
              ));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i4.SettingsPage(
          key: args.key,
          tab: args.tab,
          query: args.query,
        ),
      );
    },
    PostsRoute.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i5.PostsScreen(),
      );
    },
    PostDetailsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<PostDetailsRouteArgs>(
          orElse: () => PostDetailsRouteArgs(
                server: pathParams.getString(
                  'server',
                  "INVALID",
                ),
                postId: pathParams.getString(
                  'postId',
                  "INVALID",
                ),
              ));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i6.PostDetailsPage(
          key: args.key,
          server: args.server,
          postId: args.postId,
        ),
      );
    },
    CreatePostRoute.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i7.CreatePostPage(),
      );
    },
    CreateReplyRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<CreateReplyRouteArgs>(
          orElse: () => CreateReplyRouteArgs(
                server: pathParams.getString(
                  'server',
                  "",
                ),
                postId: pathParams.getString(
                  'postId',
                  "",
                ),
              ));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i8.CreateReplyPage(
          key: args.key,
          server: args.server,
          postId: args.postId,
          discussionPostId: args.discussionPostId,
        ),
      );
    },
    CreateDeepReplyRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<CreateDeepReplyRouteArgs>(
          orElse: () => CreateDeepReplyRouteArgs(
                server: pathParams.getString(
                  'server',
                  "",
                ),
                postId: pathParams.getString(
                  'subjectPostId',
                  "",
                ),
                discussionPostId: pathParams.getString(
                  'postId',
                  "",
                ),
              ));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i8.CreateDeepReplyPage(
          key: args.key,
          server: args.server,
          postId: args.postId,
          discussionPostId: args.discussionPostId,
        ),
      );
    },
    AuthorProfileRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<AuthorProfileRouteArgs>(
          orElse: () => AuthorProfileRouteArgs(
                server: pathParams.optString('server'),
                userId: pathParams.optString('userId'),
              ));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i9.AuthorProfilePage(
          key: args.key,
          server: args.server,
          userId: args.userId,
        ),
      );
    },
    GroupsRoute.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i10.GroupsScreen(),
      );
    },
    GroupDetailsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupDetailsRouteArgs>(
          orElse: () => GroupDetailsRouteArgs(
                server: pathParams.getString(
                  'server',
                  '',
                ),
                groupId: pathParams.getString(
                  'groupId',
                  '',
                ),
              ));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i11.GroupDetailsPage(
          key: args.key,
          server: args.server,
          groupId: args.groupId,
        ),
      );
    },
    CreateGroupRoute.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i12.CreateGroupPage(),
      );
    },
    PeopleRoute.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i13.PeopleScreen(),
      );
    },
    UserProfileRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<UserProfileRouteArgs>(
          orElse: () => UserProfileRouteArgs(
                server: pathParams.optString('server'),
                userId: pathParams.optString('userId'),
              ));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i9.UserProfilePage(
          key: args.key,
          server: args.server,
          userId: args.userId,
          accountId: args.accountId,
        ),
      );
    },
    EventListRoute.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i14.EventListScreen(),
      );
    },
    EventDetailsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<EventDetailsRouteArgs>(
          orElse: () => EventDetailsRouteArgs(
                  id: pathParams.getInt(
                'id',
                -1,
              )));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i15.EventDetailsPage(
          key: args.key,
          id: args.id,
        ),
      );
    },
    AccountsRoute.name: (routeData) {
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i16.AccountsPage(),
      );
    },
    MyProfileRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<MyProfileRouteArgs>(
          orElse: () =>
              MyProfileRouteArgs(accountId: pathParams.optString('accountId')));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i9.MyProfilePage(
          key: args.key,
          accountId: args.accountId,
        ),
      );
    },
    ServerConfigurationRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<ServerConfigurationRouteArgs>(
          orElse: () => ServerConfigurationRouteArgs(
              server: pathParams.optString('server')));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i17.ServerConfigurationPage(
          key: args.key,
          server: args.server,
          accountId: args.accountId,
        ),
      );
    },
    AdminRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<AdminRouteArgs>(
          orElse: () => AdminRouteArgs(accountId: pathParams.get('accountId')));
      return _i18.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i17.AdminPage(
          key: args.key,
          accountId: args.accountId,
        ),
      );
    },
  };

  @override
  List<_i18.RouteConfig> get routes => [
        _i18.RouteConfig(
          HomeRoute.name,
          path: '/',
          guards: [authGuard],
          children: [
            _i18.RouteConfig(
              PostsTab.name,
              path: 'posts',
              parent: HomeRoute.name,
              children: [
                _i18.RouteConfig(
                  PostsRoute.name,
                  path: '',
                  parent: PostsTab.name,
                ),
                _i18.RouteConfig(
                  PostDetailsRoute.name,
                  path: 'post/:server/:postId',
                  parent: PostsTab.name,
                  usesPathAsKey: true,
                ),
                _i18.RouteConfig(
                  CreatePostRoute.name,
                  path: 'create',
                  parent: PostsTab.name,
                  usesPathAsKey: true,
                  guards: [authGuard],
                ),
                _i18.RouteConfig(
                  CreateReplyRoute.name,
                  path: 'post/:server/:postId/reply',
                  parent: PostsTab.name,
                  usesPathAsKey: true,
                  guards: [authGuard],
                ),
                _i18.RouteConfig(
                  CreateDeepReplyRoute.name,
                  path: 'post/:server/:postId/reply/:subjectPostId/reply',
                  parent: PostsTab.name,
                  usesPathAsKey: true,
                  guards: [authGuard],
                ),
                _i18.RouteConfig(
                  AuthorProfileRoute.name,
                  path: 'author/:server/:userId',
                  parent: PostsTab.name,
                  usesPathAsKey: true,
                ),
              ],
            ),
            _i18.RouteConfig(
              GroupsTab.name,
              path: 'groups',
              parent: HomeRoute.name,
              children: [
                _i18.RouteConfig(
                  GroupsRoute.name,
                  path: '',
                  parent: GroupsTab.name,
                ),
                _i18.RouteConfig(
                  GroupDetailsRoute.name,
                  path: 'group/:server/:groupId',
                  parent: GroupsTab.name,
                  usesPathAsKey: true,
                ),
                _i18.RouteConfig(
                  CreateGroupRoute.name,
                  path: 'create',
                  parent: GroupsTab.name,
                  usesPathAsKey: true,
                  guards: [authGuard],
                ),
              ],
            ),
            _i18.RouteConfig(
              PeopleTab.name,
              path: 'people',
              parent: HomeRoute.name,
              children: [
                _i18.RouteConfig(
                  PeopleRoute.name,
                  path: '',
                  parent: PeopleTab.name,
                ),
                _i18.RouteConfig(
                  UserProfileRoute.name,
                  path: 'person/:server/:userId',
                  parent: PeopleTab.name,
                  usesPathAsKey: true,
                ),
              ],
            ),
            _i18.RouteConfig(
              EventsTab.name,
              path: 'events',
              parent: HomeRoute.name,
              children: [
                _i18.RouteConfig(
                  EventListRoute.name,
                  path: '',
                  parent: EventsTab.name,
                ),
                _i18.RouteConfig(
                  EventDetailsRoute.name,
                  path: 'event/:id',
                  parent: EventsTab.name,
                  usesPathAsKey: true,
                  guards: [authGuard],
                ),
              ],
            ),
            _i18.RouteConfig(
              AccountsTab.name,
              path: 'accounts',
              parent: HomeRoute.name,
              children: [
                _i18.RouteConfig(
                  AccountsRoute.name,
                  path: '',
                  parent: AccountsTab.name,
                ),
                _i18.RouteConfig(
                  MyProfileRoute.name,
                  path: 'account/:accountId/profile',
                  parent: AccountsTab.name,
                  usesPathAsKey: true,
                ),
                _i18.RouteConfig(
                  ServerConfigurationRoute.name,
                  path: 'server/:server/configuration',
                  parent: AccountsTab.name,
                  usesPathAsKey: true,
                ),
                _i18.RouteConfig(
                  AdminRoute.name,
                  path: 'account/:accountId/admin',
                  parent: AccountsTab.name,
                  usesPathAsKey: true,
                ),
              ],
            ),
            _i18.RouteConfig(
              SettingsTab.name,
              path: 'settings/:tab',
              parent: HomeRoute.name,
            ),
          ],
        ),
        _i18.RouteConfig(
          LoginRoute.name,
          path: '/login',
        ),
        _i18.RouteConfig(
          '*#redirect',
          path: '*',
          redirectTo: '/',
          fullMatch: true,
        ),
      ];
}

/// generated route for
/// [_i1.HomePage]
class HomeRoute extends _i18.PageRouteInfo<void> {
  const HomeRoute({List<_i18.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          path: '/',
          initialChildren: children,
        );

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i2.LoginPage]
class LoginRoute extends _i18.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i21.Key? key,
    void Function(bool)? onLoginResult,
    bool showBackButton = true,
  }) : super(
          LoginRoute.name,
          path: '/login',
          args: LoginRouteArgs(
            key: key,
            onLoginResult: onLoginResult,
            showBackButton: showBackButton,
          ),
        );

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({
    this.key,
    this.onLoginResult,
    this.showBackButton = true,
  });

  final _i21.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onLoginResult: $onLoginResult, showBackButton: $showBackButton}';
  }
}

/// generated route for
/// [_i3.EmptyRouterPage]
class PostsTab extends _i18.PageRouteInfo<void> {
  const PostsTab({List<_i18.PageRouteInfo>? children})
      : super(
          PostsTab.name,
          path: 'posts',
          initialChildren: children,
        );

  static const String name = 'PostsTab';
}

/// generated route for
/// [_i3.EmptyRouterPage]
class GroupsTab extends _i18.PageRouteInfo<void> {
  const GroupsTab({List<_i18.PageRouteInfo>? children})
      : super(
          GroupsTab.name,
          path: 'groups',
          initialChildren: children,
        );

  static const String name = 'GroupsTab';
}

/// generated route for
/// [_i3.EmptyRouterPage]
class PeopleTab extends _i18.PageRouteInfo<void> {
  const PeopleTab({List<_i18.PageRouteInfo>? children})
      : super(
          PeopleTab.name,
          path: 'people',
          initialChildren: children,
        );

  static const String name = 'PeopleTab';
}

/// generated route for
/// [_i3.EmptyRouterPage]
class EventsTab extends _i18.PageRouteInfo<void> {
  const EventsTab({List<_i18.PageRouteInfo>? children})
      : super(
          EventsTab.name,
          path: 'events',
          initialChildren: children,
        );

  static const String name = 'EventsTab';
}

/// generated route for
/// [_i3.EmptyRouterPage]
class AccountsTab extends _i18.PageRouteInfo<void> {
  const AccountsTab({List<_i18.PageRouteInfo>? children})
      : super(
          AccountsTab.name,
          path: 'accounts',
          initialChildren: children,
        );

  static const String name = 'AccountsTab';
}

/// generated route for
/// [_i4.SettingsPage]
class SettingsTab extends _i18.PageRouteInfo<SettingsTabArgs> {
  SettingsTab({
    _i21.Key? key,
    required String tab,
    String query = 'none',
  }) : super(
          SettingsTab.name,
          path: 'settings/:tab',
          args: SettingsTabArgs(
            key: key,
            tab: tab,
            query: query,
          ),
          rawPathParams: {'tab': tab},
          rawQueryParams: {'query': query},
        );

  static const String name = 'SettingsTab';
}

class SettingsTabArgs {
  const SettingsTabArgs({
    this.key,
    required this.tab,
    this.query = 'none',
  });

  final _i21.Key? key;

  final String tab;

  final String query;

  @override
  String toString() {
    return 'SettingsTabArgs{key: $key, tab: $tab, query: $query}';
  }
}

/// generated route for
/// [_i5.PostsScreen]
class PostsRoute extends _i18.PageRouteInfo<void> {
  const PostsRoute()
      : super(
          PostsRoute.name,
          path: '',
        );

  static const String name = 'PostsRoute';
}

/// generated route for
/// [_i6.PostDetailsPage]
class PostDetailsRoute extends _i18.PageRouteInfo<PostDetailsRouteArgs> {
  PostDetailsRoute({
    _i21.Key? key,
    String server = "INVALID",
    String postId = "INVALID",
  }) : super(
          PostDetailsRoute.name,
          path: 'post/:server/:postId',
          args: PostDetailsRouteArgs(
            key: key,
            server: server,
            postId: postId,
          ),
          rawPathParams: {
            'server': server,
            'postId': postId,
          },
        );

  static const String name = 'PostDetailsRoute';
}

class PostDetailsRouteArgs {
  const PostDetailsRouteArgs({
    this.key,
    this.server = "INVALID",
    this.postId = "INVALID",
  });

  final _i21.Key? key;

  final String server;

  final String postId;

  @override
  String toString() {
    return 'PostDetailsRouteArgs{key: $key, server: $server, postId: $postId}';
  }
}

/// generated route for
/// [_i7.CreatePostPage]
class CreatePostRoute extends _i18.PageRouteInfo<void> {
  const CreatePostRoute()
      : super(
          CreatePostRoute.name,
          path: 'create',
        );

  static const String name = 'CreatePostRoute';
}

/// generated route for
/// [_i8.CreateReplyPage]
class CreateReplyRoute extends _i18.PageRouteInfo<CreateReplyRouteArgs> {
  CreateReplyRoute({
    _i21.Key? key,
    String server = "",
    String postId = "",
    String discussionPostId = "",
  }) : super(
          CreateReplyRoute.name,
          path: 'post/:server/:postId/reply',
          args: CreateReplyRouteArgs(
            key: key,
            server: server,
            postId: postId,
            discussionPostId: discussionPostId,
          ),
          rawPathParams: {
            'server': server,
            'postId': postId,
          },
        );

  static const String name = 'CreateReplyRoute';
}

class CreateReplyRouteArgs {
  const CreateReplyRouteArgs({
    this.key,
    this.server = "",
    this.postId = "",
    this.discussionPostId = "",
  });

  final _i21.Key? key;

  final String server;

  final String postId;

  final String discussionPostId;

  @override
  String toString() {
    return 'CreateReplyRouteArgs{key: $key, server: $server, postId: $postId, discussionPostId: $discussionPostId}';
  }
}

/// generated route for
/// [_i8.CreateDeepReplyPage]
class CreateDeepReplyRoute
    extends _i18.PageRouteInfo<CreateDeepReplyRouteArgs> {
  CreateDeepReplyRoute({
    _i21.Key? key,
    String server = "",
    String postId = "",
    String discussionPostId = "",
  }) : super(
          CreateDeepReplyRoute.name,
          path: 'post/:server/:postId/reply/:subjectPostId/reply',
          args: CreateDeepReplyRouteArgs(
            key: key,
            server: server,
            postId: postId,
            discussionPostId: discussionPostId,
          ),
          rawPathParams: {
            'server': server,
            'subjectPostId': postId,
            'postId': discussionPostId,
          },
        );

  static const String name = 'CreateDeepReplyRoute';
}

class CreateDeepReplyRouteArgs {
  const CreateDeepReplyRouteArgs({
    this.key,
    this.server = "",
    this.postId = "",
    this.discussionPostId = "",
  });

  final _i21.Key? key;

  final String server;

  final String postId;

  final String discussionPostId;

  @override
  String toString() {
    return 'CreateDeepReplyRouteArgs{key: $key, server: $server, postId: $postId, discussionPostId: $discussionPostId}';
  }
}

/// generated route for
/// [_i9.AuthorProfilePage]
class AuthorProfileRoute extends _i18.PageRouteInfo<AuthorProfileRouteArgs> {
  AuthorProfileRoute({
    _i21.Key? key,
    String? server,
    String? userId,
  }) : super(
          AuthorProfileRoute.name,
          path: 'author/:server/:userId',
          args: AuthorProfileRouteArgs(
            key: key,
            server: server,
            userId: userId,
          ),
          rawPathParams: {
            'server': server,
            'userId': userId,
          },
        );

  static const String name = 'AuthorProfileRoute';
}

class AuthorProfileRouteArgs {
  const AuthorProfileRouteArgs({
    this.key,
    this.server,
    this.userId,
  });

  final _i21.Key? key;

  final String? server;

  final String? userId;

  @override
  String toString() {
    return 'AuthorProfileRouteArgs{key: $key, server: $server, userId: $userId}';
  }
}

/// generated route for
/// [_i10.GroupsScreen]
class GroupsRoute extends _i18.PageRouteInfo<void> {
  const GroupsRoute()
      : super(
          GroupsRoute.name,
          path: '',
        );

  static const String name = 'GroupsRoute';
}

/// generated route for
/// [_i11.GroupDetailsPage]
class GroupDetailsRoute extends _i18.PageRouteInfo<GroupDetailsRouteArgs> {
  GroupDetailsRoute({
    _i21.Key? key,
    String server = '',
    String groupId = '',
  }) : super(
          GroupDetailsRoute.name,
          path: 'group/:server/:groupId',
          args: GroupDetailsRouteArgs(
            key: key,
            server: server,
            groupId: groupId,
          ),
          rawPathParams: {
            'server': server,
            'groupId': groupId,
          },
        );

  static const String name = 'GroupDetailsRoute';
}

class GroupDetailsRouteArgs {
  const GroupDetailsRouteArgs({
    this.key,
    this.server = '',
    this.groupId = '',
  });

  final _i21.Key? key;

  final String server;

  final String groupId;

  @override
  String toString() {
    return 'GroupDetailsRouteArgs{key: $key, server: $server, groupId: $groupId}';
  }
}

/// generated route for
/// [_i12.CreateGroupPage]
class CreateGroupRoute extends _i18.PageRouteInfo<void> {
  const CreateGroupRoute()
      : super(
          CreateGroupRoute.name,
          path: 'create',
        );

  static const String name = 'CreateGroupRoute';
}

/// generated route for
/// [_i13.PeopleScreen]
class PeopleRoute extends _i18.PageRouteInfo<void> {
  const PeopleRoute()
      : super(
          PeopleRoute.name,
          path: '',
        );

  static const String name = 'PeopleRoute';
}

/// generated route for
/// [_i9.UserProfilePage]
class UserProfileRoute extends _i18.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    _i21.Key? key,
    String? server,
    String? userId,
    String? accountId,
  }) : super(
          UserProfileRoute.name,
          path: 'person/:server/:userId',
          args: UserProfileRouteArgs(
            key: key,
            server: server,
            userId: userId,
            accountId: accountId,
          ),
          rawPathParams: {
            'server': server,
            'userId': userId,
          },
        );

  static const String name = 'UserProfileRoute';
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({
    this.key,
    this.server,
    this.userId,
    this.accountId,
  });

  final _i21.Key? key;

  final String? server;

  final String? userId;

  final String? accountId;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, server: $server, userId: $userId, accountId: $accountId}';
  }
}

/// generated route for
/// [_i14.EventListScreen]
class EventListRoute extends _i18.PageRouteInfo<void> {
  const EventListRoute()
      : super(
          EventListRoute.name,
          path: '',
        );

  static const String name = 'EventListRoute';
}

/// generated route for
/// [_i15.EventDetailsPage]
class EventDetailsRoute extends _i18.PageRouteInfo<EventDetailsRouteArgs> {
  EventDetailsRoute({
    _i21.Key? key,
    int id = -1,
  }) : super(
          EventDetailsRoute.name,
          path: 'event/:id',
          args: EventDetailsRouteArgs(
            key: key,
            id: id,
          ),
          rawPathParams: {'id': id},
        );

  static const String name = 'EventDetailsRoute';
}

class EventDetailsRouteArgs {
  const EventDetailsRouteArgs({
    this.key,
    this.id = -1,
  });

  final _i21.Key? key;

  final int id;

  @override
  String toString() {
    return 'EventDetailsRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i16.AccountsPage]
class AccountsRoute extends _i18.PageRouteInfo<void> {
  const AccountsRoute()
      : super(
          AccountsRoute.name,
          path: '',
        );

  static const String name = 'AccountsRoute';
}

/// generated route for
/// [_i9.MyProfilePage]
class MyProfileRoute extends _i18.PageRouteInfo<MyProfileRouteArgs> {
  MyProfileRoute({
    _i21.Key? key,
    String? accountId,
  }) : super(
          MyProfileRoute.name,
          path: 'account/:accountId/profile',
          args: MyProfileRouteArgs(
            key: key,
            accountId: accountId,
          ),
          rawPathParams: {'accountId': accountId},
        );

  static const String name = 'MyProfileRoute';
}

class MyProfileRouteArgs {
  const MyProfileRouteArgs({
    this.key,
    this.accountId,
  });

  final _i21.Key? key;

  final String? accountId;

  @override
  String toString() {
    return 'MyProfileRouteArgs{key: $key, accountId: $accountId}';
  }
}

/// generated route for
/// [_i17.ServerConfigurationPage]
class ServerConfigurationRoute
    extends _i18.PageRouteInfo<ServerConfigurationRouteArgs> {
  ServerConfigurationRoute({
    _i21.Key? key,
    String? server,
    String? accountId,
  }) : super(
          ServerConfigurationRoute.name,
          path: 'server/:server/configuration',
          args: ServerConfigurationRouteArgs(
            key: key,
            server: server,
            accountId: accountId,
          ),
          rawPathParams: {'server': server},
        );

  static const String name = 'ServerConfigurationRoute';
}

class ServerConfigurationRouteArgs {
  const ServerConfigurationRouteArgs({
    this.key,
    this.server,
    this.accountId,
  });

  final _i21.Key? key;

  final String? server;

  final String? accountId;

  @override
  String toString() {
    return 'ServerConfigurationRouteArgs{key: $key, server: $server, accountId: $accountId}';
  }
}

/// generated route for
/// [_i17.AdminPage]
class AdminRoute extends _i18.PageRouteInfo<AdminRouteArgs> {
  AdminRoute({
    _i21.Key? key,
    dynamic accountId,
  }) : super(
          AdminRoute.name,
          path: 'account/:accountId/admin',
          args: AdminRouteArgs(
            key: key,
            accountId: accountId,
          ),
          rawPathParams: {'accountId': accountId},
        );

  static const String name = 'AdminRoute';
}

class AdminRouteArgs {
  const AdminRouteArgs({
    this.key,
    this.accountId,
  });

  final _i21.Key? key;

  final dynamic accountId;

  @override
  String toString() {
    return 'AdminRouteArgs{key: $key, accountId: $accountId}';
  }
}
