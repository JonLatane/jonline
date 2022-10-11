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
import 'authentication.pb.dart' as $3;
import 'users.pb.dart' as $4;
import 'groups.pb.dart' as $5;
import 'posts.pb.dart' as $6;
import 'post_query.pb.dart' as $7;
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
  static final _$createAccount =
      $grpc.ClientMethod<$3.CreateAccountRequest, $3.AuthTokenResponse>(
          '/jonline.Jonline/CreateAccount',
          ($3.CreateAccountRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $3.AuthTokenResponse.fromBuffer(value));
  static final _$login =
      $grpc.ClientMethod<$3.LoginRequest, $3.AuthTokenResponse>(
          '/jonline.Jonline/Login',
          ($3.LoginRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $3.AuthTokenResponse.fromBuffer(value));
  static final _$refreshToken =
      $grpc.ClientMethod<$3.RefreshTokenRequest, $3.ExpirableToken>(
          '/jonline.Jonline/RefreshToken',
          ($3.RefreshTokenRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $3.ExpirableToken.fromBuffer(value));
  static final _$getCurrentUser = $grpc.ClientMethod<$0.Empty, $4.User>(
      '/jonline.Jonline/GetCurrentUser',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.User.fromBuffer(value));
  static final _$getUsers =
      $grpc.ClientMethod<$4.GetUsersRequest, $4.GetUsersResponse>(
          '/jonline.Jonline/GetUsers',
          ($4.GetUsersRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $4.GetUsersResponse.fromBuffer(value));
  static final _$updateUser = $grpc.ClientMethod<$4.User, $4.User>(
      '/jonline.Jonline/UpdateUser',
      ($4.User value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.User.fromBuffer(value));
  static final _$createFollow = $grpc.ClientMethod<$4.Follow, $4.Follow>(
      '/jonline.Jonline/CreateFollow',
      ($4.Follow value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Follow.fromBuffer(value));
  static final _$updateFollow = $grpc.ClientMethod<$4.Follow, $4.Follow>(
      '/jonline.Jonline/UpdateFollow',
      ($4.Follow value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Follow.fromBuffer(value));
  static final _$deleteFollow = $grpc.ClientMethod<$4.Follow, $0.Empty>(
      '/jonline.Jonline/DeleteFollow',
      ($4.Follow value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getGroups =
      $grpc.ClientMethod<$5.GetGroupsRequest, $5.GetGroupsResponse>(
          '/jonline.Jonline/GetGroups',
          ($5.GetGroupsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $5.GetGroupsResponse.fromBuffer(value));
  static final _$createGroup = $grpc.ClientMethod<$5.Group, $5.Group>(
      '/jonline.Jonline/CreateGroup',
      ($5.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.Group.fromBuffer(value));
  static final _$updateGroup = $grpc.ClientMethod<$5.Group, $5.Group>(
      '/jonline.Jonline/UpdateGroup',
      ($5.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.Group.fromBuffer(value));
  static final _$deleteGroup = $grpc.ClientMethod<$5.Group, $0.Empty>(
      '/jonline.Jonline/DeleteGroup',
      ($5.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$createMembership =
      $grpc.ClientMethod<$5.Membership, $5.Membership>(
          '/jonline.Jonline/CreateMembership',
          ($5.Membership value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $5.Membership.fromBuffer(value));
  static final _$updateMembership =
      $grpc.ClientMethod<$5.Membership, $5.Membership>(
          '/jonline.Jonline/UpdateMembership',
          ($5.Membership value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $5.Membership.fromBuffer(value));
  static final _$deleteMembership = $grpc.ClientMethod<$5.Membership, $0.Empty>(
      '/jonline.Jonline/DeleteMembership',
      ($5.Membership value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getPosts = $grpc.ClientMethod<$6.GetPostsRequest, $6.Posts>(
      '/jonline.Jonline/GetPosts',
      ($6.GetPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Posts.fromBuffer(value));
  static final _$queryPosts = $grpc.ClientMethod<$7.PostQuery, $6.Posts>(
      '/jonline.Jonline/QueryPosts',
      ($7.PostQuery value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Posts.fromBuffer(value));
  static final _$createPost = $grpc.ClientMethod<$6.CreatePostRequest, $6.Post>(
      '/jonline.Jonline/CreatePost',
      ($6.CreatePostRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Post.fromBuffer(value));
  static final _$updatePost = $grpc.ClientMethod<$6.Post, $6.Post>(
      '/jonline.Jonline/UpdatePost',
      ($6.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Post.fromBuffer(value));
  static final _$deletePost = $grpc.ClientMethod<$6.Post, $6.Post>(
      '/jonline.Jonline/DeletePost',
      ($6.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Post.fromBuffer(value));
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

  $grpc.ResponseFuture<$3.AuthTokenResponse> createAccount(
      $3.CreateAccountRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  $grpc.ResponseFuture<$3.AuthTokenResponse> login($3.LoginRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$3.ExpirableToken> refreshToken(
      $3.RefreshTokenRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$refreshToken, request, options: options);
  }

  $grpc.ResponseFuture<$4.User> getCurrentUser($0.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getCurrentUser, request, options: options);
  }

  $grpc.ResponseFuture<$4.GetUsersResponse> getUsers($4.GetUsersRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getUsers, request, options: options);
  }

  $grpc.ResponseFuture<$4.User> updateUser($4.User request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateUser, request, options: options);
  }

  $grpc.ResponseFuture<$4.Follow> createFollow($4.Follow request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createFollow, request, options: options);
  }

  $grpc.ResponseFuture<$4.Follow> updateFollow($4.Follow request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateFollow, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteFollow($4.Follow request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteFollow, request, options: options);
  }

  $grpc.ResponseFuture<$5.GetGroupsResponse> getGroups(
      $5.GetGroupsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroups, request, options: options);
  }

  $grpc.ResponseFuture<$5.Group> createGroup($5.Group request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroup, request, options: options);
  }

  $grpc.ResponseFuture<$5.Group> updateGroup($5.Group request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroup, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteGroup($5.Group request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteGroup, request, options: options);
  }

  $grpc.ResponseFuture<$5.Membership> createMembership($5.Membership request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createMembership, request, options: options);
  }

  $grpc.ResponseFuture<$5.Membership> updateMembership($5.Membership request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateMembership, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteMembership($5.Membership request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteMembership, request, options: options);
  }

  $grpc.ResponseFuture<$6.Posts> getPosts($6.GetPostsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getPosts, request, options: options);
  }

  $grpc.ResponseFuture<$6.Posts> queryPosts($7.PostQuery request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryPosts, request, options: options);
  }

  $grpc.ResponseFuture<$6.Post> createPost($6.CreatePostRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  $grpc.ResponseFuture<$6.Post> updatePost($6.Post request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updatePost, request, options: options);
  }

  $grpc.ResponseFuture<$6.Post> deletePost($6.Post request,
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
    $addMethod(
        $grpc.ServiceMethod<$3.CreateAccountRequest, $3.AuthTokenResponse>(
            'CreateAccount',
            createAccount_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $3.CreateAccountRequest.fromBuffer(value),
            ($3.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.LoginRequest, $3.AuthTokenResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.LoginRequest.fromBuffer(value),
        ($3.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.RefreshTokenRequest, $3.ExpirableToken>(
        'RefreshToken',
        refreshToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $3.RefreshTokenRequest.fromBuffer(value),
        ($3.ExpirableToken value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $4.User>(
        'GetCurrentUser',
        getCurrentUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($4.User value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.GetUsersRequest, $4.GetUsersResponse>(
        'GetUsers',
        getUsers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.GetUsersRequest.fromBuffer(value),
        ($4.GetUsersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.User, $4.User>(
        'UpdateUser',
        updateUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.User.fromBuffer(value),
        ($4.User value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Follow, $4.Follow>(
        'CreateFollow',
        createFollow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Follow.fromBuffer(value),
        ($4.Follow value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Follow, $4.Follow>(
        'UpdateFollow',
        updateFollow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Follow.fromBuffer(value),
        ($4.Follow value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Follow, $0.Empty>(
        'DeleteFollow',
        deleteFollow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Follow.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.GetGroupsRequest, $5.GetGroupsResponse>(
        'GetGroups',
        getGroups_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.GetGroupsRequest.fromBuffer(value),
        ($5.GetGroupsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Group, $5.Group>(
        'CreateGroup',
        createGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Group.fromBuffer(value),
        ($5.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Group, $5.Group>(
        'UpdateGroup',
        updateGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Group.fromBuffer(value),
        ($5.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Group, $0.Empty>(
        'DeleteGroup',
        deleteGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Group.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Membership, $5.Membership>(
        'CreateMembership',
        createMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Membership.fromBuffer(value),
        ($5.Membership value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Membership, $5.Membership>(
        'UpdateMembership',
        updateMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Membership.fromBuffer(value),
        ($5.Membership value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Membership, $0.Empty>(
        'DeleteMembership',
        deleteMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Membership.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.GetPostsRequest, $6.Posts>(
        'GetPosts',
        getPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.GetPostsRequest.fromBuffer(value),
        ($6.Posts value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.PostQuery, $6.Posts>(
        'QueryPosts',
        queryPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.PostQuery.fromBuffer(value),
        ($6.Posts value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.CreatePostRequest, $6.Post>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.CreatePostRequest.fromBuffer(value),
        ($6.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Post, $6.Post>(
        'UpdatePost',
        updatePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Post.fromBuffer(value),
        ($6.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Post, $6.Post>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Post.fromBuffer(value),
        ($6.Post value) => value.writeToBuffer()));
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

  $async.Future<$3.AuthTokenResponse> createAccount_Pre($grpc.ServiceCall call,
      $async.Future<$3.CreateAccountRequest> request) async {
    return createAccount(call, await request);
  }

  $async.Future<$3.AuthTokenResponse> login_Pre(
      $grpc.ServiceCall call, $async.Future<$3.LoginRequest> request) async {
    return login(call, await request);
  }

  $async.Future<$3.ExpirableToken> refreshToken_Pre($grpc.ServiceCall call,
      $async.Future<$3.RefreshTokenRequest> request) async {
    return refreshToken(call, await request);
  }

  $async.Future<$4.User> getCurrentUser_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getCurrentUser(call, await request);
  }

  $async.Future<$4.GetUsersResponse> getUsers_Pre(
      $grpc.ServiceCall call, $async.Future<$4.GetUsersRequest> request) async {
    return getUsers(call, await request);
  }

  $async.Future<$4.User> updateUser_Pre(
      $grpc.ServiceCall call, $async.Future<$4.User> request) async {
    return updateUser(call, await request);
  }

  $async.Future<$4.Follow> createFollow_Pre(
      $grpc.ServiceCall call, $async.Future<$4.Follow> request) async {
    return createFollow(call, await request);
  }

  $async.Future<$4.Follow> updateFollow_Pre(
      $grpc.ServiceCall call, $async.Future<$4.Follow> request) async {
    return updateFollow(call, await request);
  }

  $async.Future<$0.Empty> deleteFollow_Pre(
      $grpc.ServiceCall call, $async.Future<$4.Follow> request) async {
    return deleteFollow(call, await request);
  }

  $async.Future<$5.GetGroupsResponse> getGroups_Pre($grpc.ServiceCall call,
      $async.Future<$5.GetGroupsRequest> request) async {
    return getGroups(call, await request);
  }

  $async.Future<$5.Group> createGroup_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Group> request) async {
    return createGroup(call, await request);
  }

  $async.Future<$5.Group> updateGroup_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Group> request) async {
    return updateGroup(call, await request);
  }

  $async.Future<$0.Empty> deleteGroup_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Group> request) async {
    return deleteGroup(call, await request);
  }

  $async.Future<$5.Membership> createMembership_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Membership> request) async {
    return createMembership(call, await request);
  }

  $async.Future<$5.Membership> updateMembership_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Membership> request) async {
    return updateMembership(call, await request);
  }

  $async.Future<$0.Empty> deleteMembership_Pre(
      $grpc.ServiceCall call, $async.Future<$5.Membership> request) async {
    return deleteMembership(call, await request);
  }

  $async.Future<$6.Posts> getPosts_Pre(
      $grpc.ServiceCall call, $async.Future<$6.GetPostsRequest> request) async {
    return getPosts(call, await request);
  }

  $async.Future<$6.Posts> queryPosts_Pre(
      $grpc.ServiceCall call, $async.Future<$7.PostQuery> request) async {
    return queryPosts(call, await request);
  }

  $async.Future<$6.Post> createPost_Pre($grpc.ServiceCall call,
      $async.Future<$6.CreatePostRequest> request) async {
    return createPost(call, await request);
  }

  $async.Future<$6.Post> updatePost_Pre(
      $grpc.ServiceCall call, $async.Future<$6.Post> request) async {
    return updatePost(call, await request);
  }

  $async.Future<$6.Post> deletePost_Pre(
      $grpc.ServiceCall call, $async.Future<$6.Post> request) async {
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
  $async.Future<$3.AuthTokenResponse> createAccount(
      $grpc.ServiceCall call, $3.CreateAccountRequest request);
  $async.Future<$3.AuthTokenResponse> login(
      $grpc.ServiceCall call, $3.LoginRequest request);
  $async.Future<$3.ExpirableToken> refreshToken(
      $grpc.ServiceCall call, $3.RefreshTokenRequest request);
  $async.Future<$4.User> getCurrentUser(
      $grpc.ServiceCall call, $0.Empty request);
  $async.Future<$4.GetUsersResponse> getUsers(
      $grpc.ServiceCall call, $4.GetUsersRequest request);
  $async.Future<$4.User> updateUser($grpc.ServiceCall call, $4.User request);
  $async.Future<$4.Follow> createFollow(
      $grpc.ServiceCall call, $4.Follow request);
  $async.Future<$4.Follow> updateFollow(
      $grpc.ServiceCall call, $4.Follow request);
  $async.Future<$0.Empty> deleteFollow(
      $grpc.ServiceCall call, $4.Follow request);
  $async.Future<$5.GetGroupsResponse> getGroups(
      $grpc.ServiceCall call, $5.GetGroupsRequest request);
  $async.Future<$5.Group> createGroup($grpc.ServiceCall call, $5.Group request);
  $async.Future<$5.Group> updateGroup($grpc.ServiceCall call, $5.Group request);
  $async.Future<$0.Empty> deleteGroup($grpc.ServiceCall call, $5.Group request);
  $async.Future<$5.Membership> createMembership(
      $grpc.ServiceCall call, $5.Membership request);
  $async.Future<$5.Membership> updateMembership(
      $grpc.ServiceCall call, $5.Membership request);
  $async.Future<$0.Empty> deleteMembership(
      $grpc.ServiceCall call, $5.Membership request);
  $async.Future<$6.Posts> getPosts(
      $grpc.ServiceCall call, $6.GetPostsRequest request);
  $async.Future<$6.Posts> queryPosts(
      $grpc.ServiceCall call, $7.PostQuery request);
  $async.Future<$6.Post> createPost(
      $grpc.ServiceCall call, $6.CreatePostRequest request);
  $async.Future<$6.Post> updatePost($grpc.ServiceCall call, $6.Post request);
  $async.Future<$6.Post> deletePost($grpc.ServiceCall call, $6.Post request);
  $async.Future<$2.ServerConfiguration> configureServer(
      $grpc.ServiceCall call, $2.ServerConfiguration request);
}
