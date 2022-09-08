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
import 'package:auto_route/auto_route.dart' as _i14;
import 'package:auto_route/empty_router_widgets.dart' deferred as _i4;
import 'package:flutter/cupertino.dart' as _i18;
import 'package:flutter/material.dart' as _i15;

import '../screens/events/event_details_page.dart' as _i9;
import '../screens/events/event_list_page.dart' as _i8;
import '../screens/home_page.dart' deferred as _i1;
import '../screens/login_page.dart' as _i3;
import '../screens/posts/post_details_page.dart' as _i7;
import '../screens/posts/post_list_page.dart' as _i6;
import '../screens/profile/my_books_page.dart' as _i11;
import '../screens/profile/profile_page.dart' as _i10;
import '../screens/settings.dart' as _i5;
import '../screens/user-data/data_collector.dart' as _i17;
import '../screens/user-data/single_field_page.dart' as _i12;
import '../screens/user-data/user_data_collector_page.dart' as _i2;
import '../screens/user-data/user_data_page.dart' as _i13;
import 'auth_guard.dart' as _i16;

class RootRouter extends _i14.RootStackRouter {
  RootRouter(
      {_i15.GlobalKey<_i15.NavigatorState>? navigatorKey,
      required this.authGuard})
      : super(navigatorKey);

  final _i16.AuthGuard authGuard;

  @override
  final Map<String, _i14.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i14.MaterialPageX<String>(
          routeData: routeData,
          child: _i14.DeferredWidget(
              _i1.loadLibrary, () => _i14.WrappedRoute(child: _i1.HomePage())));
    },
    UserDataCollectorRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataCollectorRouteArgs>(
          orElse: () => const UserDataCollectorRouteArgs());
      return _i14.MaterialPageX<_i17.UserData>(
          routeData: routeData,
          child: _i14.WrappedRoute(
              child: _i2.UserDataCollectorPage(
                  key: args.key, onResult: args.onResult)));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i3.LoginPage(
              key: args.key,
              onLoginResult: args.onLoginResult,
              showBackButton: args.showBackButton));
    },
    PostsTab.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i14.DeferredWidget(
              _i4.loadLibrary, () => _i4.EmptyRouterPage()));
    },
    EventsTab.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i14.DeferredWidget(
              _i4.loadLibrary, () => _i4.EmptyRouterPage()));
    },
    ProfileTab.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i14.DeferredWidget(
              _i4.loadLibrary, () => _i4.EmptyRouterPage()));
    },
    SettingsTab.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<SettingsTabArgs>(
          orElse: () => SettingsTabArgs(
              tab: pathParams.getString('tab'),
              query: queryParams.getString('query', 'none')));
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i5.SettingsPage(
              key: args.key, tab: args.tab, query: args.query));
    },
    PostListRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i6.PostListScreen());
    },
    PostDetailsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<PostDetailsRouteArgs>(
          orElse: () => PostDetailsRouteArgs(id: pathParams.getInt('id', -1)));
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i7.PostDetailsPage(key: args.key, id: args.id),
          fullscreenDialog: true);
    },
    EventListRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i8.EventListScreen());
    },
    EventDetailsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<EventDetailsRouteArgs>(
          orElse: () => EventDetailsRouteArgs(id: pathParams.getInt('id', -1)));
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i9.EventDetailsPage(key: args.key, id: args.id),
          fullscreenDialog: true);
    },
    ProfileRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i10.ProfilePage());
    },
    MyActivityRoute.name: (routeData) {
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<MyActivityRouteArgs>(
          orElse: () => MyActivityRouteArgs(
              filter: queryParams.optString('filter', 'none')));
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i11.MyActivityPage(key: args.key, filter: args.filter));
    },
    NameFieldRoute.name: (routeData) {
      final args = routeData.argsAs<NameFieldRouteArgs>(
          orElse: () => const NameFieldRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i12.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext));
    },
    FavoriteBookFieldRoute.name: (routeData) {
      final args = routeData.argsAs<FavoriteBookFieldRouteArgs>(
          orElse: () => const FavoriteBookFieldRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i12.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext));
    },
    UserDataRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataRouteArgs>(
          orElse: () => const UserDataRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i13.UserDataPage(key: args.key, onResult: args.onResult));
    }
  };

  @override
  List<_i14.RouteConfig> get routes => [
        _i14.RouteConfig(HomeRoute.name,
            path: '/',
            deferredLoading: true,
            guards: [
              authGuard
            ],
            children: [
              _i14.RouteConfig('#redirect',
                  path: '',
                  parent: HomeRoute.name,
                  redirectTo: 'posts',
                  fullMatch: true),
              _i14.RouteConfig(PostsTab.name,
                  path: 'posts',
                  parent: HomeRoute.name,
                  deferredLoading: true,
                  children: [
                    _i14.RouteConfig(PostListRoute.name,
                        path: '', parent: PostsTab.name),
                    _i14.RouteConfig(PostDetailsRoute.name,
                        path: ':id', parent: PostsTab.name)
                  ]),
              _i14.RouteConfig(EventsTab.name,
                  path: 'events',
                  parent: HomeRoute.name,
                  deferredLoading: true,
                  children: [
                    _i14.RouteConfig(EventListRoute.name,
                        path: '', parent: EventsTab.name),
                    _i14.RouteConfig(EventDetailsRoute.name,
                        path: ':id', parent: EventsTab.name)
                  ]),
              _i14.RouteConfig(ProfileTab.name,
                  path: 'profile',
                  parent: HomeRoute.name,
                  children: [
                    _i14.RouteConfig(ProfileRoute.name,
                        path: '', parent: ProfileTab.name),
                    _i14.RouteConfig(MyActivityRoute.name,
                        path: 'activity', parent: ProfileTab.name)
                  ]),
              _i14.RouteConfig(SettingsTab.name,
                  path: 'settings/:tab', parent: HomeRoute.name)
            ]),
        _i14.RouteConfig(UserDataCollectorRoute.name,
            path: '/user-data',
            children: [
              _i14.RouteConfig(NameFieldRoute.name,
                  path: 'name', parent: UserDataCollectorRoute.name),
              _i14.RouteConfig(FavoriteBookFieldRoute.name,
                  path: 'favorite-book', parent: UserDataCollectorRoute.name),
              _i14.RouteConfig(UserDataRoute.name,
                  path: 'results', parent: UserDataCollectorRoute.name)
            ]),
        _i14.RouteConfig(LoginRoute.name, path: '/login'),
        _i14.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

/// generated route for
/// [_i1.HomePage]
class HomeRoute extends _i14.PageRouteInfo<void> {
  const HomeRoute({List<_i14.PageRouteInfo>? children})
      : super(HomeRoute.name, path: '/', initialChildren: children);

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i2.UserDataCollectorPage]
class UserDataCollectorRoute
    extends _i14.PageRouteInfo<UserDataCollectorRouteArgs> {
  UserDataCollectorRoute(
      {_i18.Key? key,
      dynamic Function(_i17.UserData)? onResult,
      List<_i14.PageRouteInfo>? children})
      : super(UserDataCollectorRoute.name,
            path: '/user-data',
            args: UserDataCollectorRouteArgs(key: key, onResult: onResult),
            initialChildren: children);

  static const String name = 'UserDataCollectorRoute';
}

class UserDataCollectorRouteArgs {
  const UserDataCollectorRouteArgs({this.key, this.onResult});

  final _i18.Key? key;

  final dynamic Function(_i17.UserData)? onResult;

  @override
  String toString() {
    return 'UserDataCollectorRouteArgs{key: $key, onResult: $onResult}';
  }
}

/// generated route for
/// [_i3.LoginPage]
class LoginRoute extends _i14.PageRouteInfo<LoginRouteArgs> {
  LoginRoute(
      {_i18.Key? key,
      void Function(bool)? onLoginResult,
      bool showBackButton = true})
      : super(LoginRoute.name,
            path: '/login',
            args: LoginRouteArgs(
                key: key,
                onLoginResult: onLoginResult,
                showBackButton: showBackButton));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs(
      {this.key, this.onLoginResult, this.showBackButton = true});

  final _i18.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onLoginResult: $onLoginResult, showBackButton: $showBackButton}';
  }
}

/// generated route for
/// [_i4.EmptyRouterPage]
class PostsTab extends _i14.PageRouteInfo<void> {
  const PostsTab({List<_i14.PageRouteInfo>? children})
      : super(PostsTab.name, path: 'posts', initialChildren: children);

  static const String name = 'PostsTab';
}

/// generated route for
/// [_i4.EmptyRouterPage]
class EventsTab extends _i14.PageRouteInfo<void> {
  const EventsTab({List<_i14.PageRouteInfo>? children})
      : super(EventsTab.name, path: 'events', initialChildren: children);

  static const String name = 'EventsTab';
}

/// generated route for
/// [_i4.EmptyRouterPage]
class ProfileTab extends _i14.PageRouteInfo<void> {
  const ProfileTab({List<_i14.PageRouteInfo>? children})
      : super(ProfileTab.name, path: 'profile', initialChildren: children);

  static const String name = 'ProfileTab';
}

/// generated route for
/// [_i5.SettingsPage]
class SettingsTab extends _i14.PageRouteInfo<SettingsTabArgs> {
  SettingsTab({_i18.Key? key, required String tab, String query = 'none'})
      : super(SettingsTab.name,
            path: 'settings/:tab',
            args: SettingsTabArgs(key: key, tab: tab, query: query),
            rawPathParams: {'tab': tab},
            rawQueryParams: {'query': query});

  static const String name = 'SettingsTab';
}

class SettingsTabArgs {
  const SettingsTabArgs({this.key, required this.tab, this.query = 'none'});

  final _i18.Key? key;

  final String tab;

  final String query;

  @override
  String toString() {
    return 'SettingsTabArgs{key: $key, tab: $tab, query: $query}';
  }
}

/// generated route for
/// [_i6.PostListScreen]
class PostListRoute extends _i14.PageRouteInfo<void> {
  const PostListRoute() : super(PostListRoute.name, path: '');

  static const String name = 'PostListRoute';
}

/// generated route for
/// [_i7.PostDetailsPage]
class PostDetailsRoute extends _i14.PageRouteInfo<PostDetailsRouteArgs> {
  PostDetailsRoute({_i18.Key? key, int id = -1})
      : super(PostDetailsRoute.name,
            path: ':id',
            args: PostDetailsRouteArgs(key: key, id: id),
            rawPathParams: {'id': id});

  static const String name = 'PostDetailsRoute';
}

class PostDetailsRouteArgs {
  const PostDetailsRouteArgs({this.key, this.id = -1});

  final _i18.Key? key;

  final int id;

  @override
  String toString() {
    return 'PostDetailsRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i8.EventListScreen]
class EventListRoute extends _i14.PageRouteInfo<void> {
  const EventListRoute() : super(EventListRoute.name, path: '');

  static const String name = 'EventListRoute';
}

/// generated route for
/// [_i9.EventDetailsPage]
class EventDetailsRoute extends _i14.PageRouteInfo<EventDetailsRouteArgs> {
  EventDetailsRoute({_i18.Key? key, int id = -1})
      : super(EventDetailsRoute.name,
            path: ':id',
            args: EventDetailsRouteArgs(key: key, id: id),
            rawPathParams: {'id': id});

  static const String name = 'EventDetailsRoute';
}

class EventDetailsRouteArgs {
  const EventDetailsRouteArgs({this.key, this.id = -1});

  final _i18.Key? key;

  final int id;

  @override
  String toString() {
    return 'EventDetailsRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i10.ProfilePage]
class ProfileRoute extends _i14.PageRouteInfo<void> {
  const ProfileRoute() : super(ProfileRoute.name, path: '');

  static const String name = 'ProfileRoute';
}

/// generated route for
/// [_i11.MyActivityPage]
class MyActivityRoute extends _i14.PageRouteInfo<MyActivityRouteArgs> {
  MyActivityRoute({_i18.Key? key, String? filter = 'none'})
      : super(MyActivityRoute.name,
            path: 'activity',
            args: MyActivityRouteArgs(key: key, filter: filter),
            rawQueryParams: {'filter': filter});

  static const String name = 'MyActivityRoute';
}

class MyActivityRouteArgs {
  const MyActivityRouteArgs({this.key, this.filter = 'none'});

  final _i18.Key? key;

  final String? filter;

  @override
  String toString() {
    return 'MyActivityRouteArgs{key: $key, filter: $filter}';
  }
}

/// generated route for
/// [_i12.SingleFieldPage]
class NameFieldRoute extends _i14.PageRouteInfo<NameFieldRouteArgs> {
  NameFieldRoute(
      {_i18.Key? key,
      String message = '',
      String willPopMessage = '',
      void Function(String)? onNext})
      : super(NameFieldRoute.name,
            path: 'name',
            args: NameFieldRouteArgs(
                key: key,
                message: message,
                willPopMessage: willPopMessage,
                onNext: onNext));

  static const String name = 'NameFieldRoute';
}

class NameFieldRouteArgs {
  const NameFieldRouteArgs(
      {this.key, this.message = '', this.willPopMessage = '', this.onNext});

  final _i18.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;

  @override
  String toString() {
    return 'NameFieldRouteArgs{key: $key, message: $message, willPopMessage: $willPopMessage, onNext: $onNext}';
  }
}

/// generated route for
/// [_i12.SingleFieldPage]
class FavoriteBookFieldRoute
    extends _i14.PageRouteInfo<FavoriteBookFieldRouteArgs> {
  FavoriteBookFieldRoute(
      {_i18.Key? key,
      String message = '',
      String willPopMessage = '',
      void Function(String)? onNext})
      : super(FavoriteBookFieldRoute.name,
            path: 'favorite-book',
            args: FavoriteBookFieldRouteArgs(
                key: key,
                message: message,
                willPopMessage: willPopMessage,
                onNext: onNext));

  static const String name = 'FavoriteBookFieldRoute';
}

class FavoriteBookFieldRouteArgs {
  const FavoriteBookFieldRouteArgs(
      {this.key, this.message = '', this.willPopMessage = '', this.onNext});

  final _i18.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;

  @override
  String toString() {
    return 'FavoriteBookFieldRouteArgs{key: $key, message: $message, willPopMessage: $willPopMessage, onNext: $onNext}';
  }
}

/// generated route for
/// [_i13.UserDataPage]
class UserDataRoute extends _i14.PageRouteInfo<UserDataRouteArgs> {
  UserDataRoute({_i18.Key? key, dynamic Function(_i17.UserData)? onResult})
      : super(UserDataRoute.name,
            path: 'results',
            args: UserDataRouteArgs(key: key, onResult: onResult));

  static const String name = 'UserDataRoute';
}

class UserDataRouteArgs {
  const UserDataRouteArgs({this.key, this.onResult});

  final _i18.Key? key;

  final dynamic Function(_i17.UserData)? onResult;

  @override
  String toString() {
    return 'UserDataRouteArgs{key: $key, onResult: $onResult}';
  }
}
