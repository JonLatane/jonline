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
import 'posts.pb.dart' as $3;
import 'post_query.pb.dart' as $4;
import 'authentication.pb.dart' as $5;
import 'users.pb.dart' as $6;
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
  static final _$getPosts = $grpc.ClientMethod<$3.GetPostsRequest, $3.Posts>(
      '/jonline.Jonline/GetPosts',
      ($3.GetPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.Posts.fromBuffer(value));
  static final _$queryPosts = $grpc.ClientMethod<$4.PostQuery, $3.Posts>(
      '/jonline.Jonline/QueryPosts',
      ($4.PostQuery value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.Posts.fromBuffer(value));
  static final _$createAccount =
      $grpc.ClientMethod<$5.CreateAccountRequest, $5.AuthTokenResponse>(
          '/jonline.Jonline/CreateAccount',
          ($5.CreateAccountRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $5.AuthTokenResponse.fromBuffer(value));
  static final _$login =
      $grpc.ClientMethod<$5.LoginRequest, $5.AuthTokenResponse>(
          '/jonline.Jonline/Login',
          ($5.LoginRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $5.AuthTokenResponse.fromBuffer(value));
  static final _$refreshToken =
      $grpc.ClientMethod<$5.RefreshTokenRequest, $5.ExpirableToken>(
          '/jonline.Jonline/RefreshToken',
          ($5.RefreshTokenRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $5.ExpirableToken.fromBuffer(value));
  static final _$getCurrentUser = $grpc.ClientMethod<$0.Empty, $6.User>(
      '/jonline.Jonline/GetCurrentUser',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.User.fromBuffer(value));
  static final _$createPost = $grpc.ClientMethod<$3.CreatePostRequest, $3.Post>(
      '/jonline.Jonline/CreatePost',
      ($3.CreatePostRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.Post.fromBuffer(value));
  static final _$updatePost = $grpc.ClientMethod<$3.Post, $3.Post>(
      '/jonline.Jonline/UpdatePost',
      ($3.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.Post.fromBuffer(value));
  static final _$deletePost = $grpc.ClientMethod<$3.Post, $3.Post>(
      '/jonline.Jonline/DeletePost',
      ($3.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.Post.fromBuffer(value));
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

  $grpc.ResponseFuture<$3.Posts> getPosts($3.GetPostsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getPosts, request, options: options);
  }

  $grpc.ResponseFuture<$3.Posts> queryPosts($4.PostQuery request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryPosts, request, options: options);
  }

  $grpc.ResponseFuture<$5.AuthTokenResponse> createAccount(
      $5.CreateAccountRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  $grpc.ResponseFuture<$5.AuthTokenResponse> login($5.LoginRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$5.ExpirableToken> refreshToken(
      $5.RefreshTokenRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$refreshToken, request, options: options);
  }

  $grpc.ResponseFuture<$6.User> getCurrentUser($0.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getCurrentUser, request, options: options);
  }

  $grpc.ResponseFuture<$3.Post> createPost($3.CreatePostRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  $grpc.ResponseFuture<$3.Post> updatePost($3.Post request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updatePost, request, options: options);
  }

  $grpc.ResponseFuture<$3.Post> deletePost($3.Post request,
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
    $addMethod($grpc.ServiceMethod<$3.GetPostsRequest, $3.Posts>(
        'GetPosts',
        getPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.GetPostsRequest.fromBuffer(value),
        ($3.Posts value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.PostQuery, $3.Posts>(
        'QueryPosts',
        queryPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.PostQuery.fromBuffer(value),
        ($3.Posts value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$5.CreateAccountRequest, $5.AuthTokenResponse>(
            'CreateAccount',
            createAccount_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $5.CreateAccountRequest.fromBuffer(value),
            ($5.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.LoginRequest, $5.AuthTokenResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.LoginRequest.fromBuffer(value),
        ($5.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.RefreshTokenRequest, $5.ExpirableToken>(
        'RefreshToken',
        refreshToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $5.RefreshTokenRequest.fromBuffer(value),
        ($5.ExpirableToken value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $6.User>(
        'GetCurrentUser',
        getCurrentUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($6.User value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.CreatePostRequest, $3.Post>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.CreatePostRequest.fromBuffer(value),
        ($3.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.Post, $3.Post>(
        'UpdatePost',
        updatePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.Post.fromBuffer(value),
        ($3.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.Post, $3.Post>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.Post.fromBuffer(value),
        ($3.Post value) => value.writeToBuffer()));
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

  $async.Future<$3.Posts> getPosts_Pre(
      $grpc.ServiceCall call, $async.Future<$3.GetPostsRequest> request) async {
    return getPosts(call, await request);
  }

  $async.Future<$3.Posts> queryPosts_Pre(
      $grpc.ServiceCall call, $async.Future<$4.PostQuery> request) async {
    return queryPosts(call, await request);
  }

  $async.Future<$5.AuthTokenResponse> createAccount_Pre($grpc.ServiceCall call,
      $async.Future<$5.CreateAccountRequest> request) async {
    return createAccount(call, await request);
  }

  $async.Future<$5.AuthTokenResponse> login_Pre(
      $grpc.ServiceCall call, $async.Future<$5.LoginRequest> request) async {
    return login(call, await request);
  }

  $async.Future<$5.ExpirableToken> refreshToken_Pre($grpc.ServiceCall call,
      $async.Future<$5.RefreshTokenRequest> request) async {
    return refreshToken(call, await request);
  }

  $async.Future<$6.User> getCurrentUser_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getCurrentUser(call, await request);
  }

  $async.Future<$3.Post> createPost_Pre($grpc.ServiceCall call,
      $async.Future<$3.CreatePostRequest> request) async {
    return createPost(call, await request);
  }

  $async.Future<$3.Post> updatePost_Pre(
      $grpc.ServiceCall call, $async.Future<$3.Post> request) async {
    return updatePost(call, await request);
  }

  $async.Future<$3.Post> deletePost_Pre(
      $grpc.ServiceCall call, $async.Future<$3.Post> request) async {
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
  $async.Future<$3.Posts> getPosts(
      $grpc.ServiceCall call, $3.GetPostsRequest request);
  $async.Future<$3.Posts> queryPosts(
      $grpc.ServiceCall call, $4.PostQuery request);
  $async.Future<$5.AuthTokenResponse> createAccount(
      $grpc.ServiceCall call, $5.CreateAccountRequest request);
  $async.Future<$5.AuthTokenResponse> login(
      $grpc.ServiceCall call, $5.LoginRequest request);
  $async.Future<$5.ExpirableToken> refreshToken(
      $grpc.ServiceCall call, $5.RefreshTokenRequest request);
  $async.Future<$6.User> getCurrentUser(
      $grpc.ServiceCall call, $0.Empty request);
  $async.Future<$3.Post> createPost(
      $grpc.ServiceCall call, $3.CreatePostRequest request);
  $async.Future<$3.Post> updatePost($grpc.ServiceCall call, $3.Post request);
  $async.Future<$3.Post> deletePost($grpc.ServiceCall call, $3.Post request);
  $async.Future<$2.ServerConfiguration> configureServer(
      $grpc.ServiceCall call, $2.ServerConfiguration request);
}
