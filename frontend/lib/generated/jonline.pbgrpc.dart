///
//  Generated code. Do not modify.
//  source: jonline.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'google/protobuf/empty.pb.dart' as $0;
import 'federation.pb.dart' as $1;
import 'admin.pb.dart' as $2;
import 'users.pb.dart' as $3;
import 'groups.pb.dart' as $4;
import 'posts.pb.dart' as $5;
import 'post_query.pb.dart' as $6;
import 'authentication.pb.dart' as $7;
export 'jonline.pb.dart';

class JonlineClient extends $grpc.Client {
  static final _$getServiceVersion =
      $grpc.ClientMethod<$0.Empty, $1.GetServiceVersionResponse>(
          '/jonline.Jonline/GetServiceVersion',
          ($0.Empty value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $1.GetServiceVersionResponse.fromBuffer(value));
  static final _$getServerConfiguration =
      $grpc.ClientMethod<$0.Empty, $2.ServerConfiguration>(
          '/jonline.Jonline/GetServerConfiguration',
          ($0.Empty value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.ServerConfiguration.fromBuffer(value));
  static final _$getUsers =
      $grpc.ClientMethod<$3.GetUsersRequest, $3.GetUsersResponse>(
          '/jonline.Jonline/GetUsers',
          ($3.GetUsersRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $3.GetUsersResponse.fromBuffer(value));
  static final _$getGroups =
      $grpc.ClientMethod<$4.GetGroupsRequest, $4.GetGroupsResponse>(
          '/jonline.Jonline/GetGroups',
          ($4.GetGroupsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $4.GetGroupsResponse.fromBuffer(value));
  static final _$createGroup = $grpc.ClientMethod<$4.Group, $4.Group>(
      '/jonline.Jonline/CreateGroup',
      ($4.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Group.fromBuffer(value));
  static final _$updateGroup = $grpc.ClientMethod<$4.Group, $4.Group>(
      '/jonline.Jonline/UpdateGroup',
      ($4.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Group.fromBuffer(value));
  static final _$createMembership =
      $grpc.ClientMethod<$4.Membership, $4.Membership>(
          '/jonline.Jonline/CreateMembership',
          ($4.Membership value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $4.Membership.fromBuffer(value));
  static final _$updateMembership =
      $grpc.ClientMethod<$4.Membership, $4.Membership>(
          '/jonline.Jonline/UpdateMembership',
          ($4.Membership value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $4.Membership.fromBuffer(value));
  static final _$getPosts = $grpc.ClientMethod<$5.GetPostsRequest, $5.Posts>(
      '/jonline.Jonline/GetPosts',
      ($5.GetPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.Posts.fromBuffer(value));
  static final _$queryPosts = $grpc.ClientMethod<$6.PostQuery, $5.Posts>(
      '/jonline.Jonline/QueryPosts',
      ($6.PostQuery value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.Posts.fromBuffer(value));
  static final _$createAccount =
      $grpc.ClientMethod<$7.CreateAccountRequest, $7.AuthTokenResponse>(
          '/jonline.Jonline/CreateAccount',
          ($7.CreateAccountRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $7.AuthTokenResponse.fromBuffer(value));
  static final _$login =
      $grpc.ClientMethod<$7.LoginRequest, $7.AuthTokenResponse>(
          '/jonline.Jonline/Login',
          ($7.LoginRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $7.AuthTokenResponse.fromBuffer(value));
  static final _$refreshToken =
      $grpc.ClientMethod<$7.RefreshTokenRequest, $7.ExpirableToken>(
          '/jonline.Jonline/RefreshToken',
          ($7.RefreshTokenRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $7.ExpirableToken.fromBuffer(value));
  static final _$getCurrentUser = $grpc.ClientMethod<$0.Empty, $3.User>(
      '/jonline.Jonline/GetCurrentUser',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.User.fromBuffer(value));
  static final _$createPost = $grpc.ClientMethod<$5.CreatePostRequest, $5.Post>(
      '/jonline.Jonline/CreatePost',
      ($5.CreatePostRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.Post.fromBuffer(value));
  static final _$updatePost = $grpc.ClientMethod<$5.Post, $5.Post>(
      '/jonline.Jonline/UpdatePost',
      ($5.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.Post.fromBuffer(value));
  static final _$deletePost = $grpc.ClientMethod<$5.Post, $5.Post>(
      '/jonline.Jonline/DeletePost',
      ($5.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.Post.fromBuffer(value));
  static final _$configureServer =
      $grpc.ClientMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
          '/jonline.Jonline/ConfigureServer',
          ($2.ServerConfiguration value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.ServerConfiguration.fromBuffer(value));

  JonlineClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$1.GetServiceVersionResponse> getServiceVersion(
      $0.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getServiceVersion, request, options: options);
  }

  $grpc.ResponseFuture<$2.ServerConfiguration> getServerConfiguration(
      $0.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getServerConfiguration, request,
        options: options);
  }

  $grpc.ResponseFuture<$3.GetUsersResponse> getUsers($3.GetUsersRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getUsers, request, options: options);
  }

  $grpc.ResponseFuture<$4.GetGroupsResponse> getGroups(
      $4.GetGroupsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroups, request, options: options);
  }

  $grpc.ResponseFuture<$4.Group> createGroup($4.Group request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroup, request, options: options);
  }

  $grpc.ResponseFuture<$4.Group> updateGroup($4.Group request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroup, request, options: options);
  }

  $grpc.ResponseFuture<$4.Membership> createMembership($4.Membership request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createMembership, request, options: options);
  }

  $grpc.ResponseFuture<$4.Membership> updateMembership($4.Membership request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateMembership, request, options: options);
  }

  $grpc.ResponseFuture<$5.Posts> getPosts($5.GetPostsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getPosts, request, options: options);
  }

  $grpc.ResponseFuture<$5.Posts> queryPosts($6.PostQuery request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryPosts, request, options: options);
  }

  $grpc.ResponseFuture<$7.AuthTokenResponse> createAccount(
      $7.CreateAccountRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  $grpc.ResponseFuture<$7.AuthTokenResponse> login($7.LoginRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$7.ExpirableToken> refreshToken(
      $7.RefreshTokenRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$refreshToken, request, options: options);
  }

  $grpc.ResponseFuture<$3.User> getCurrentUser($0.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getCurrentUser, request, options: options);
  }

  $grpc.ResponseFuture<$5.Post> createPost($5.CreatePostRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  $grpc.ResponseFuture<$5.Post> updatePost($5.Post request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updatePost, request, options: options);
  }

  $grpc.ResponseFuture<$5.Post> deletePost($5.Post request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deletePost, request, options: options);
  }

  $grpc.ResponseFuture<$2.ServerConfiguration> configureServer(
      $2.ServerConfiguration request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$configureServer, request, options: options);
  }
}

abstract class JonlineServiceBase extends $grpc.Service {
  $core.String get $name => 'jonline.Jonline';

  JonlineServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetServiceVersionResponse>(
        'GetServiceVersion',
        getServiceVersion_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetServiceVersionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $2.ServerConfiguration>(
        'GetServerConfiguration',
        getServerConfiguration_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($2.ServerConfiguration value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.GetUsersRequest, $3.GetUsersResponse>(
        'GetUsers',
        getUsers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.GetUsersRequest.fromBuffer(value),
        ($3.GetUsersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.GetGroupsRequest, $4.GetGroupsResponse>(
        'GetGroups',
        getGroups_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.GetGroupsRequest.fromBuffer(value),
        ($4.GetGroupsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Group, $4.Group>(
        'CreateGroup',
        createGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Group.fromBuffer(value),
        ($4.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Group, $4.Group>(
        'UpdateGroup',
        updateGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Group.fromBuffer(value),
        ($4.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Membership, $4.Membership>(
        'CreateMembership',
        createMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Membership.fromBuffer(value),
        ($4.Membership value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Membership, $4.Membership>(
        'UpdateMembership',
        updateMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Membership.fromBuffer(value),
        ($4.Membership value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.GetPostsRequest, $5.Posts>(
        'GetPosts',
        getPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.GetPostsRequest.fromBuffer(value),
        ($5.Posts value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.PostQuery, $5.Posts>(
        'QueryPosts',
        queryPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.PostQuery.fromBuffer(value),
        ($5.Posts value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$7.CreateAccountRequest, $7.AuthTokenResponse>(
            'CreateAccount',
            createAccount_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $7.CreateAccountRequest.fromBuffer(value),
            ($7.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.LoginRequest, $7.AuthTokenResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.LoginRequest.fromBuffer(value),
        ($7.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.RefreshTokenRequest, $7.ExpirableToken>(
        'RefreshToken',
        refreshToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $7.RefreshTokenRequest.fromBuffer(value),
        ($7.ExpirableToken value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $3.User>(
        'GetCurrentUser',
        getCurrentUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($3.User value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.CreatePostRequest, $5.Post>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.CreatePostRequest.fromBuffer(value),
        ($5.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Post, $5.Post>(
        'UpdatePost',
        updatePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Post.fromBuffer(value),
        ($5.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Post, $5.Post>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Post.fromBuffer(value),
        ($5.Post value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
            'ConfigureServer',
            configureServer_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.ServerConfiguration.fromBuffer(value),
            ($2.ServerConfiguration value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getServiceVersion(call, await request);
  }

  $async.Future<$2.ServerConfiguration> getServerConfiguration_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getServerConfiguration(call, await request);
  }

  $async.Future<$3.GetUsersResponse> getUsers_Pre(
      $grpc.ServiceCall call, $async.Future<$3.GetUsersRequest> request) async {
    return getUsers(call, await request);
  }

  $async.Future<$4.GetGroupsResponse> getGroups_Pre($grpc.ServiceCall call,
      $async.Future<$4.GetGroupsRequest> request) async {
    return getGroups(call, await request);
  }

  $async.Future<$4.Group> createGroup_Pre(
      $grpc.ServiceCall call, $async.Future<$4.Group> request) async {
    return createGroup(call, await request);
  }

  $async.Future<$4.Group> updateGroup_Pre(
      $grpc.ServiceCall call, $async.Future<$4.Group> request) async {
    return updateGroup(call, await request);
  }

  $async.Future<$4.Membership> createMembership_Pre(
      $grpc.ServiceCall call, $async.Future<$4.Membership> request) async {
    return createMembership(call, await request);
  }

  $async.Future<$4.Membership> updateMembership_Pre(
      $grpc.ServiceCall call, $async.Future<$4.Membership> request) async {
    return updateMembership(call, await request);
  }

  $async.Future<$5.Posts> getPosts_Pre(
      $grpc.ServiceCall call, $async.Future<$5.GetPostsRequest> request) async {
    return getPosts(call, await request);
  }

  $async.Future<$5.Posts> queryPosts_Pre(
      $grpc.ServiceCall call, $async.Future<$6.PostQuery> request) async {
    return queryPosts(call, await request);
  }

  $async.Future<$7.AuthTokenResponse> createAccount_Pre($grpc.ServiceCall call,
      $async.Future<$7.CreateAccountRequest> request) async {
    return createAccount(call, await request);
  }

  $async.Future<$7.AuthTokenResponse> login_Pre(
      $grpc.ServiceCall call, $async.Future<$7.LoginRequest> request) async {
    return login(call, await request);
  }

  $async.Future<$7.ExpirableToken> refreshToken_Pre($grpc.ServiceCall call,
      $async.Future<$7.RefreshTokenRequest> request) async {
    return refreshToken(call, await request);
  }

  $async.Future<$3.User> getCurrentUser_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getCurrentUser(call, await request);
  }

  $async.Future<$5.Post> createPost_Pre($grpc.ServiceCall call,
      $async.Future<$5.CreatePostRequest> request) async {
    return createPost(call, await request);
  }

  $async.Future<$5.Post> updatePost_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Post> request) async {
    return updatePost(call, await request);
  }

  $async.Future<$5.Post> deletePost_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Post> request) async {
    return deletePost(call, await request);
  }

  $async.Future<$2.ServerConfiguration> configureServer_Pre(
      $grpc.ServiceCall call,
      $async.Future<$2.ServerConfiguration> request) async {
    return configureServer(call, await request);
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion(
      $grpc.ServiceCall call, $0.Empty request);
  $async.Future<$2.ServerConfiguration> getServerConfiguration(
      $grpc.ServiceCall call, $0.Empty request);
  $async.Future<$3.GetUsersResponse> getUsers(
      $grpc.ServiceCall call, $3.GetUsersRequest request);
  $async.Future<$4.GetGroupsResponse> getGroups(
      $grpc.ServiceCall call, $4.GetGroupsRequest request);
  $async.Future<$4.Group> createGroup($grpc.ServiceCall call, $4.Group request);
  $async.Future<$4.Group> updateGroup($grpc.ServiceCall call, $4.Group request);
  $async.Future<$4.Membership> createMembership(
      $grpc.ServiceCall call, $4.Membership request);
  $async.Future<$4.Membership> updateMembership(
      $grpc.ServiceCall call, $4.Membership request);
  $async.Future<$5.Posts> getPosts(
      $grpc.ServiceCall call, $5.GetPostsRequest request);
  $async.Future<$5.Posts> queryPosts(
      $grpc.ServiceCall call, $6.PostQuery request);
  $async.Future<$7.AuthTokenResponse> createAccount(
      $grpc.ServiceCall call, $7.CreateAccountRequest request);
  $async.Future<$7.AuthTokenResponse> login(
      $grpc.ServiceCall call, $7.LoginRequest request);
  $async.Future<$7.ExpirableToken> refreshToken(
      $grpc.ServiceCall call, $7.RefreshTokenRequest request);
  $async.Future<$3.User> getCurrentUser(
      $grpc.ServiceCall call, $0.Empty request);
  $async.Future<$5.Post> createPost(
      $grpc.ServiceCall call, $5.CreatePostRequest request);
  $async.Future<$5.Post> updatePost($grpc.ServiceCall call, $5.Post request);
  $async.Future<$5.Post> deletePost($grpc.ServiceCall call, $5.Post request);
  $async.Future<$2.ServerConfiguration> configureServer(
      $grpc.ServiceCall call, $2.ServerConfiguration request);
}
