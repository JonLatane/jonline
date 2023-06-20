//
//  Generated code. Do not modify.
//  source: jonline.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authentication.pb.dart' as $3;
import 'events.pb.dart' as $8;
import 'federation.pb.dart' as $1;
import 'google/protobuf/empty.pb.dart' as $0;
import 'groups.pb.dart' as $6;
import 'media.pb.dart' as $5;
import 'posts.pb.dart' as $7;
import 'server_configuration.pb.dart' as $2;
import 'users.pb.dart' as $4;

export 'jonline.pb.dart';

@$pb.GrpcServiceName('jonline.Jonline')
class JonlineClient extends $grpc.Client {
  static final _$getServiceVersion = $grpc.ClientMethod<$0.Empty, $1.GetServiceVersionResponse>(
      '/jonline.Jonline/GetServiceVersion',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetServiceVersionResponse.fromBuffer(value));
  static final _$getServerConfiguration = $grpc.ClientMethod<$0.Empty, $2.ServerConfiguration>(
      '/jonline.Jonline/GetServerConfiguration',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.ServerConfiguration.fromBuffer(value));
  static final _$createAccount = $grpc.ClientMethod<$3.CreateAccountRequest, $3.RefreshTokenResponse>(
      '/jonline.Jonline/CreateAccount',
      ($3.CreateAccountRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.RefreshTokenResponse.fromBuffer(value));
  static final _$login = $grpc.ClientMethod<$3.LoginRequest, $3.RefreshTokenResponse>(
      '/jonline.Jonline/Login',
      ($3.LoginRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.RefreshTokenResponse.fromBuffer(value));
  static final _$accessToken = $grpc.ClientMethod<$3.AccessTokenRequest, $3.AccessTokenResponse>(
      '/jonline.Jonline/AccessToken',
      ($3.AccessTokenRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.AccessTokenResponse.fromBuffer(value));
  static final _$getCurrentUser = $grpc.ClientMethod<$0.Empty, $4.User>(
      '/jonline.Jonline/GetCurrentUser',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.User.fromBuffer(value));
  static final _$getUsers = $grpc.ClientMethod<$4.GetUsersRequest, $4.GetUsersResponse>(
      '/jonline.Jonline/GetUsers',
      ($4.GetUsersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.GetUsersResponse.fromBuffer(value));
  static final _$updateUser = $grpc.ClientMethod<$4.User, $4.User>(
      '/jonline.Jonline/UpdateUser',
      ($4.User value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.User.fromBuffer(value));
  static final _$deleteUser = $grpc.ClientMethod<$4.User, $0.Empty>(
      '/jonline.Jonline/DeleteUser',
      ($4.User value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
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
  static final _$getMedia = $grpc.ClientMethod<$5.GetMediaRequest, $5.GetMediaResponse>(
      '/jonline.Jonline/GetMedia',
      ($5.GetMediaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.GetMediaResponse.fromBuffer(value));
  static final _$deleteMedia = $grpc.ClientMethod<$5.Media, $0.Empty>(
      '/jonline.Jonline/DeleteMedia',
      ($5.Media value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getGroups = $grpc.ClientMethod<$6.GetGroupsRequest, $6.GetGroupsResponse>(
      '/jonline.Jonline/GetGroups',
      ($6.GetGroupsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.GetGroupsResponse.fromBuffer(value));
  static final _$createGroup = $grpc.ClientMethod<$6.Group, $6.Group>(
      '/jonline.Jonline/CreateGroup',
      ($6.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Group.fromBuffer(value));
  static final _$updateGroup = $grpc.ClientMethod<$6.Group, $6.Group>(
      '/jonline.Jonline/UpdateGroup',
      ($6.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Group.fromBuffer(value));
  static final _$deleteGroup = $grpc.ClientMethod<$6.Group, $0.Empty>(
      '/jonline.Jonline/DeleteGroup',
      ($6.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$createMembership = $grpc.ClientMethod<$4.Membership, $4.Membership>(
      '/jonline.Jonline/CreateMembership',
      ($4.Membership value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Membership.fromBuffer(value));
  static final _$updateMembership = $grpc.ClientMethod<$4.Membership, $4.Membership>(
      '/jonline.Jonline/UpdateMembership',
      ($4.Membership value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Membership.fromBuffer(value));
  static final _$deleteMembership = $grpc.ClientMethod<$4.Membership, $0.Empty>(
      '/jonline.Jonline/DeleteMembership',
      ($4.Membership value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getMembers = $grpc.ClientMethod<$6.GetMembersRequest, $6.GetMembersResponse>(
      '/jonline.Jonline/GetMembers',
      ($6.GetMembersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.GetMembersResponse.fromBuffer(value));
  static final _$getPosts = $grpc.ClientMethod<$7.GetPostsRequest, $7.GetPostsResponse>(
      '/jonline.Jonline/GetPosts',
      ($7.GetPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GetPostsResponse.fromBuffer(value));
  static final _$createPost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/CreatePost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$updatePost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/UpdatePost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$deletePost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/DeletePost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$createGroupPost = $grpc.ClientMethod<$7.GroupPost, $7.GroupPost>(
      '/jonline.Jonline/CreateGroupPost',
      ($7.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value));
  static final _$updateGroupPost = $grpc.ClientMethod<$7.GroupPost, $7.GroupPost>(
      '/jonline.Jonline/UpdateGroupPost',
      ($7.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value));
  static final _$deleteGroupPost = $grpc.ClientMethod<$7.GroupPost, $0.Empty>(
      '/jonline.Jonline/DeleteGroupPost',
      ($7.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getGroupPosts = $grpc.ClientMethod<$7.GetGroupPostsRequest, $7.GetGroupPostsResponse>(
      '/jonline.Jonline/GetGroupPosts',
      ($7.GetGroupPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GetGroupPostsResponse.fromBuffer(value));
  static final _$streamReplies = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/StreamReplies',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$createEvent = $grpc.ClientMethod<$8.Event, $8.Event>(
      '/jonline.Jonline/CreateEvent',
      ($8.Event value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Event.fromBuffer(value));
  static final _$getEvents = $grpc.ClientMethod<$8.GetEventsRequest, $8.GetEventsResponse>(
      '/jonline.Jonline/GetEvents',
      ($8.GetEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.GetEventsResponse.fromBuffer(value));
  static final _$configureServer = $grpc.ClientMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
      '/jonline.Jonline/ConfigureServer',
      ($2.ServerConfiguration value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.ServerConfiguration.fromBuffer(value));
  static final _$resetData = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/jonline.Jonline/ResetData',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));

  JonlineClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$1.GetServiceVersionResponse> getServiceVersion($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getServiceVersion, request, options: options);
  }

  $grpc.ResponseFuture<$2.ServerConfiguration> getServerConfiguration($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getServerConfiguration, request, options: options);
  }

  $grpc.ResponseFuture<$3.RefreshTokenResponse> createAccount($3.CreateAccountRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  $grpc.ResponseFuture<$3.RefreshTokenResponse> login($3.LoginRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$3.AccessTokenResponse> accessToken($3.AccessTokenRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$accessToken, request, options: options);
  }

  $grpc.ResponseFuture<$4.User> getCurrentUser($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getCurrentUser, request, options: options);
  }

  $grpc.ResponseFuture<$4.GetUsersResponse> getUsers($4.GetUsersRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getUsers, request, options: options);
  }

  $grpc.ResponseFuture<$4.User> updateUser($4.User request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateUser, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteUser($4.User request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteUser, request, options: options);
  }

  $grpc.ResponseFuture<$4.Follow> createFollow($4.Follow request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createFollow, request, options: options);
  }

  $grpc.ResponseFuture<$4.Follow> updateFollow($4.Follow request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateFollow, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteFollow($4.Follow request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteFollow, request, options: options);
  }

  $grpc.ResponseFuture<$5.GetMediaResponse> getMedia($5.GetMediaRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMedia, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteMedia($5.Media request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteMedia, request, options: options);
  }

  $grpc.ResponseFuture<$6.GetGroupsResponse> getGroups($6.GetGroupsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroups, request, options: options);
  }

  $grpc.ResponseFuture<$6.Group> createGroup($6.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroup, request, options: options);
  }

  $grpc.ResponseFuture<$6.Group> updateGroup($6.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroup, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteGroup($6.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteGroup, request, options: options);
  }

  $grpc.ResponseFuture<$4.Membership> createMembership($4.Membership request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createMembership, request, options: options);
  }

  $grpc.ResponseFuture<$4.Membership> updateMembership($4.Membership request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateMembership, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteMembership($4.Membership request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteMembership, request, options: options);
  }

  $grpc.ResponseFuture<$6.GetMembersResponse> getMembers($6.GetMembersRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMembers, request, options: options);
  }

  $grpc.ResponseFuture<$7.GetPostsResponse> getPosts($7.GetPostsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getPosts, request, options: options);
  }

  $grpc.ResponseFuture<$7.Post> createPost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  $grpc.ResponseFuture<$7.Post> updatePost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updatePost, request, options: options);
  }

  $grpc.ResponseFuture<$7.Post> deletePost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deletePost, request, options: options);
  }

  $grpc.ResponseFuture<$7.GroupPost> createGroupPost($7.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroupPost, request, options: options);
  }

  $grpc.ResponseFuture<$7.GroupPost> updateGroupPost($7.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroupPost, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteGroupPost($7.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteGroupPost, request, options: options);
  }

  $grpc.ResponseFuture<$7.GetGroupPostsResponse> getGroupPosts($7.GetGroupPostsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroupPosts, request, options: options);
  }

  $grpc.ResponseStream<$7.Post> streamReplies($7.Post request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$streamReplies, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$8.Event> createEvent($8.Event request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createEvent, request, options: options);
  }

  $grpc.ResponseFuture<$8.GetEventsResponse> getEvents($8.GetEventsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getEvents, request, options: options);
  }

  $grpc.ResponseFuture<$2.ServerConfiguration> configureServer($2.ServerConfiguration request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$configureServer, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> resetData($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$resetData, request, options: options);
  }
}

@$pb.GrpcServiceName('jonline.Jonline')
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
    $addMethod($grpc.ServiceMethod<$3.CreateAccountRequest, $3.RefreshTokenResponse>(
        'CreateAccount',
        createAccount_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.CreateAccountRequest.fromBuffer(value),
        ($3.RefreshTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.LoginRequest, $3.RefreshTokenResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.LoginRequest.fromBuffer(value),
        ($3.RefreshTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.AccessTokenRequest, $3.AccessTokenResponse>(
        'AccessToken',
        accessToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.AccessTokenRequest.fromBuffer(value),
        ($3.AccessTokenResponse value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$4.User, $0.Empty>(
        'DeleteUser',
        deleteUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.User.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$5.GetMediaRequest, $5.GetMediaResponse>(
        'GetMedia',
        getMedia_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.GetMediaRequest.fromBuffer(value),
        ($5.GetMediaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Media, $0.Empty>(
        'DeleteMedia',
        deleteMedia_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Media.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.GetGroupsRequest, $6.GetGroupsResponse>(
        'GetGroups',
        getGroups_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.GetGroupsRequest.fromBuffer(value),
        ($6.GetGroupsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Group, $6.Group>(
        'CreateGroup',
        createGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Group.fromBuffer(value),
        ($6.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Group, $6.Group>(
        'UpdateGroup',
        updateGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Group.fromBuffer(value),
        ($6.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Group, $0.Empty>(
        'DeleteGroup',
        deleteGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Group.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$4.Membership, $0.Empty>(
        'DeleteMembership',
        deleteMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Membership.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.GetMembersRequest, $6.GetMembersResponse>(
        'GetMembers',
        getMembers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.GetMembersRequest.fromBuffer(value),
        ($6.GetMembersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GetPostsRequest, $7.GetPostsResponse>(
        'GetPosts',
        getPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetPostsRequest.fromBuffer(value),
        ($7.GetPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'UpdatePost',
        updatePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GroupPost, $7.GroupPost>(
        'CreateGroupPost',
        createGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value),
        ($7.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GroupPost, $7.GroupPost>(
        'UpdateGroupPost',
        updateGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value),
        ($7.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GroupPost, $0.Empty>(
        'DeleteGroupPost',
        deleteGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GetGroupPostsRequest, $7.GetGroupPostsResponse>(
        'GetGroupPosts',
        getGroupPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetGroupPostsRequest.fromBuffer(value),
        ($7.GetGroupPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'StreamReplies',
        streamReplies_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Event, $8.Event>(
        'CreateEvent',
        createEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Event.fromBuffer(value),
        ($8.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GetEventsRequest, $8.GetEventsResponse>(
        'GetEvents',
        getEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GetEventsRequest.fromBuffer(value),
        ($8.GetEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
        'ConfigureServer',
        configureServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.ServerConfiguration.fromBuffer(value),
        ($2.ServerConfiguration value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'ResetData',
        resetData_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion_Pre($grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getServiceVersion(call, await request);
  }

  $async.Future<$2.ServerConfiguration> getServerConfiguration_Pre($grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getServerConfiguration(call, await request);
  }

  $async.Future<$3.RefreshTokenResponse> createAccount_Pre($grpc.ServiceCall call, $async.Future<$3.CreateAccountRequest> request) async {
    return createAccount(call, await request);
  }

  $async.Future<$3.RefreshTokenResponse> login_Pre($grpc.ServiceCall call, $async.Future<$3.LoginRequest> request) async {
    return login(call, await request);
  }

  $async.Future<$3.AccessTokenResponse> accessToken_Pre($grpc.ServiceCall call, $async.Future<$3.AccessTokenRequest> request) async {
    return accessToken(call, await request);
  }

  $async.Future<$4.User> getCurrentUser_Pre($grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getCurrentUser(call, await request);
  }

  $async.Future<$4.GetUsersResponse> getUsers_Pre($grpc.ServiceCall call, $async.Future<$4.GetUsersRequest> request) async {
    return getUsers(call, await request);
  }

  $async.Future<$4.User> updateUser_Pre($grpc.ServiceCall call, $async.Future<$4.User> request) async {
    return updateUser(call, await request);
  }

  $async.Future<$0.Empty> deleteUser_Pre($grpc.ServiceCall call, $async.Future<$4.User> request) async {
    return deleteUser(call, await request);
  }

  $async.Future<$4.Follow> createFollow_Pre($grpc.ServiceCall call, $async.Future<$4.Follow> request) async {
    return createFollow(call, await request);
  }

  $async.Future<$4.Follow> updateFollow_Pre($grpc.ServiceCall call, $async.Future<$4.Follow> request) async {
    return updateFollow(call, await request);
  }

  $async.Future<$0.Empty> deleteFollow_Pre($grpc.ServiceCall call, $async.Future<$4.Follow> request) async {
    return deleteFollow(call, await request);
  }

  $async.Future<$5.GetMediaResponse> getMedia_Pre($grpc.ServiceCall call, $async.Future<$5.GetMediaRequest> request) async {
    return getMedia(call, await request);
  }

  $async.Future<$0.Empty> deleteMedia_Pre($grpc.ServiceCall call, $async.Future<$5.Media> request) async {
    return deleteMedia(call, await request);
  }

  $async.Future<$6.GetGroupsResponse> getGroups_Pre($grpc.ServiceCall call, $async.Future<$6.GetGroupsRequest> request) async {
    return getGroups(call, await request);
  }

  $async.Future<$6.Group> createGroup_Pre($grpc.ServiceCall call, $async.Future<$6.Group> request) async {
    return createGroup(call, await request);
  }

  $async.Future<$6.Group> updateGroup_Pre($grpc.ServiceCall call, $async.Future<$6.Group> request) async {
    return updateGroup(call, await request);
  }

  $async.Future<$0.Empty> deleteGroup_Pre($grpc.ServiceCall call, $async.Future<$6.Group> request) async {
    return deleteGroup(call, await request);
  }

  $async.Future<$4.Membership> createMembership_Pre($grpc.ServiceCall call, $async.Future<$4.Membership> request) async {
    return createMembership(call, await request);
  }

  $async.Future<$4.Membership> updateMembership_Pre($grpc.ServiceCall call, $async.Future<$4.Membership> request) async {
    return updateMembership(call, await request);
  }

  $async.Future<$0.Empty> deleteMembership_Pre($grpc.ServiceCall call, $async.Future<$4.Membership> request) async {
    return deleteMembership(call, await request);
  }

  $async.Future<$6.GetMembersResponse> getMembers_Pre($grpc.ServiceCall call, $async.Future<$6.GetMembersRequest> request) async {
    return getMembers(call, await request);
  }

  $async.Future<$7.GetPostsResponse> getPosts_Pre($grpc.ServiceCall call, $async.Future<$7.GetPostsRequest> request) async {
    return getPosts(call, await request);
  }

  $async.Future<$7.Post> createPost_Pre($grpc.ServiceCall call, $async.Future<$7.Post> request) async {
    return createPost(call, await request);
  }

  $async.Future<$7.Post> updatePost_Pre($grpc.ServiceCall call, $async.Future<$7.Post> request) async {
    return updatePost(call, await request);
  }

  $async.Future<$7.Post> deletePost_Pre($grpc.ServiceCall call, $async.Future<$7.Post> request) async {
    return deletePost(call, await request);
  }

  $async.Future<$7.GroupPost> createGroupPost_Pre($grpc.ServiceCall call, $async.Future<$7.GroupPost> request) async {
    return createGroupPost(call, await request);
  }

  $async.Future<$7.GroupPost> updateGroupPost_Pre($grpc.ServiceCall call, $async.Future<$7.GroupPost> request) async {
    return updateGroupPost(call, await request);
  }

  $async.Future<$0.Empty> deleteGroupPost_Pre($grpc.ServiceCall call, $async.Future<$7.GroupPost> request) async {
    return deleteGroupPost(call, await request);
  }

  $async.Future<$7.GetGroupPostsResponse> getGroupPosts_Pre($grpc.ServiceCall call, $async.Future<$7.GetGroupPostsRequest> request) async {
    return getGroupPosts(call, await request);
  }

  $async.Stream<$7.Post> streamReplies_Pre($grpc.ServiceCall call, $async.Future<$7.Post> request) async* {
    yield* streamReplies(call, await request);
  }

  $async.Future<$8.Event> createEvent_Pre($grpc.ServiceCall call, $async.Future<$8.Event> request) async {
    return createEvent(call, await request);
  }

  $async.Future<$8.GetEventsResponse> getEvents_Pre($grpc.ServiceCall call, $async.Future<$8.GetEventsRequest> request) async {
    return getEvents(call, await request);
  }

  $async.Future<$2.ServerConfiguration> configureServer_Pre($grpc.ServiceCall call, $async.Future<$2.ServerConfiguration> request) async {
    return configureServer(call, await request);
  }

  $async.Future<$0.Empty> resetData_Pre($grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return resetData(call, await request);
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$2.ServerConfiguration> getServerConfiguration($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$3.RefreshTokenResponse> createAccount($grpc.ServiceCall call, $3.CreateAccountRequest request);
  $async.Future<$3.RefreshTokenResponse> login($grpc.ServiceCall call, $3.LoginRequest request);
  $async.Future<$3.AccessTokenResponse> accessToken($grpc.ServiceCall call, $3.AccessTokenRequest request);
  $async.Future<$4.User> getCurrentUser($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$4.GetUsersResponse> getUsers($grpc.ServiceCall call, $4.GetUsersRequest request);
  $async.Future<$4.User> updateUser($grpc.ServiceCall call, $4.User request);
  $async.Future<$0.Empty> deleteUser($grpc.ServiceCall call, $4.User request);
  $async.Future<$4.Follow> createFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$4.Follow> updateFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$0.Empty> deleteFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$5.GetMediaResponse> getMedia($grpc.ServiceCall call, $5.GetMediaRequest request);
  $async.Future<$0.Empty> deleteMedia($grpc.ServiceCall call, $5.Media request);
  $async.Future<$6.GetGroupsResponse> getGroups($grpc.ServiceCall call, $6.GetGroupsRequest request);
  $async.Future<$6.Group> createGroup($grpc.ServiceCall call, $6.Group request);
  $async.Future<$6.Group> updateGroup($grpc.ServiceCall call, $6.Group request);
  $async.Future<$0.Empty> deleteGroup($grpc.ServiceCall call, $6.Group request);
  $async.Future<$4.Membership> createMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$4.Membership> updateMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$0.Empty> deleteMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$6.GetMembersResponse> getMembers($grpc.ServiceCall call, $6.GetMembersRequest request);
  $async.Future<$7.GetPostsResponse> getPosts($grpc.ServiceCall call, $7.GetPostsRequest request);
  $async.Future<$7.Post> createPost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.Post> updatePost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.Post> deletePost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.GroupPost> createGroupPost($grpc.ServiceCall call, $7.GroupPost request);
  $async.Future<$7.GroupPost> updateGroupPost($grpc.ServiceCall call, $7.GroupPost request);
  $async.Future<$0.Empty> deleteGroupPost($grpc.ServiceCall call, $7.GroupPost request);
  $async.Future<$7.GetGroupPostsResponse> getGroupPosts($grpc.ServiceCall call, $7.GetGroupPostsRequest request);
  $async.Stream<$7.Post> streamReplies($grpc.ServiceCall call, $7.Post request);
  $async.Future<$8.Event> createEvent($grpc.ServiceCall call, $8.Event request);
  $async.Future<$8.GetEventsResponse> getEvents($grpc.ServiceCall call, $8.GetEventsRequest request);
  $async.Future<$2.ServerConfiguration> configureServer($grpc.ServiceCall call, $2.ServerConfiguration request);
  $async.Future<$0.Empty> resetData($grpc.ServiceCall call, $0.Empty request);
}
