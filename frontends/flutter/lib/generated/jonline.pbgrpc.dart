//
//  Generated code. Do not modify.
//  source: jonline.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authentication.pb.dart' as $3;
import 'events.pb.dart' as $9;
import 'federation.pb.dart' as $1;
import 'google/protobuf/empty.pb.dart' as $0;
import 'groups.pb.dart' as $7;
import 'media.pb.dart' as $5;
import 'messages.pb.dart' as $6;
import 'posts.pb.dart' as $8;
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
  static final _$resetPassword = $grpc.ClientMethod<$3.ResetPasswordRequest, $0.Empty>(
      '/jonline.Jonline/ResetPassword',
      ($3.ResetPasswordRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getMedia = $grpc.ClientMethod<$5.GetMediaRequest, $5.GetMediaResponse>(
      '/jonline.Jonline/GetMedia',
      ($5.GetMediaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.GetMediaResponse.fromBuffer(value));
  static final _$deleteMedia = $grpc.ClientMethod<$5.Media, $0.Empty>(
      '/jonline.Jonline/DeleteMedia',
      ($5.Media value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
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
  static final _$sendMessage = $grpc.ClientMethod<$6.SendMessageRequest, $6.Message>(
      '/jonline.Jonline/SendMessage',
      ($6.SendMessageRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Message.fromBuffer(value));
  static final _$getMessages = $grpc.ClientMethod<$6.GetMessagesRequest, $6.GetMessagesResponse>(
      '/jonline.Jonline/GetMessages',
      ($6.GetMessagesRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.GetMessagesResponse.fromBuffer(value));
  static final _$markMessagesRead = $grpc.ClientMethod<$6.MarkMessagesReadRequest, $6.MarkMessagesReadResponse>(
      '/jonline.Jonline/MarkMessagesRead',
      ($6.MarkMessagesReadRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.MarkMessagesReadResponse.fromBuffer(value));
  static final _$registerPushSubscription = $grpc.ClientMethod<$6.RegisterPushSubscriptionRequest, $6.PushSubscription>(
      '/jonline.Jonline/RegisterPushSubscription',
      ($6.RegisterPushSubscriptionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.PushSubscription.fromBuffer(value));
  static final _$unregisterPushSubscription = $grpc.ClientMethod<$6.UnregisterPushSubscriptionRequest, $0.Empty>(
      '/jonline.Jonline/UnregisterPushSubscription',
      ($6.UnregisterPushSubscriptionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getPushSubscriptionStatus = $grpc.ClientMethod<$6.GetPushSubscriptionStatusRequest, $6.GetPushSubscriptionStatusResponse>(
      '/jonline.Jonline/GetPushSubscriptionStatus',
      ($6.GetPushSubscriptionStatusRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.GetPushSubscriptionStatusResponse.fromBuffer(value));
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
  static final _$getGroups = $grpc.ClientMethod<$7.GetGroupsRequest, $7.GetGroupsResponse>(
      '/jonline.Jonline/GetGroups',
      ($7.GetGroupsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GetGroupsResponse.fromBuffer(value));
  static final _$createGroup = $grpc.ClientMethod<$7.Group, $7.Group>(
      '/jonline.Jonline/CreateGroup',
      ($7.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Group.fromBuffer(value));
  static final _$updateGroup = $grpc.ClientMethod<$7.Group, $7.Group>(
      '/jonline.Jonline/UpdateGroup',
      ($7.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Group.fromBuffer(value));
  static final _$deleteGroup = $grpc.ClientMethod<$7.Group, $0.Empty>(
      '/jonline.Jonline/DeleteGroup',
      ($7.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getMembers = $grpc.ClientMethod<$7.GetMembersRequest, $7.GetMembersResponse>(
      '/jonline.Jonline/GetMembers',
      ($7.GetMembersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GetMembersResponse.fromBuffer(value));
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
  static final _$getPosts = $grpc.ClientMethod<$8.GetPostsRequest, $8.GetPostsResponse>(
      '/jonline.Jonline/GetPosts',
      ($8.GetPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.GetPostsResponse.fromBuffer(value));
  static final _$createPost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/CreatePost',
      ($8.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Post.fromBuffer(value));
  static final _$updatePost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/UpdatePost',
      ($8.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Post.fromBuffer(value));
  static final _$deletePost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/DeletePost',
      ($8.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Post.fromBuffer(value));
  static final _$starPost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/StarPost',
      ($8.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Post.fromBuffer(value));
  static final _$unstarPost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/UnstarPost',
      ($8.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Post.fromBuffer(value));
  static final _$getGroupPosts = $grpc.ClientMethod<$8.GetGroupPostsRequest, $8.GetGroupPostsResponse>(
      '/jonline.Jonline/GetGroupPosts',
      ($8.GetGroupPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.GetGroupPostsResponse.fromBuffer(value));
  static final _$createGroupPost = $grpc.ClientMethod<$8.GroupPost, $8.GroupPost>(
      '/jonline.Jonline/CreateGroupPost',
      ($8.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value));
  static final _$updateGroupPost = $grpc.ClientMethod<$8.GroupPost, $8.GroupPost>(
      '/jonline.Jonline/UpdateGroupPost',
      ($8.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value));
  static final _$deleteGroupPost = $grpc.ClientMethod<$8.GroupPost, $0.Empty>(
      '/jonline.Jonline/DeleteGroupPost',
      ($8.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getEvents = $grpc.ClientMethod<$9.GetEventsRequest, $9.GetEventsResponse>(
      '/jonline.Jonline/GetEvents',
      ($9.GetEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.GetEventsResponse.fromBuffer(value));
  static final _$createEvent = $grpc.ClientMethod<$9.Event, $9.Event>(
      '/jonline.Jonline/CreateEvent',
      ($9.Event value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.Event.fromBuffer(value));
  static final _$updateEvent = $grpc.ClientMethod<$9.Event, $9.Event>(
      '/jonline.Jonline/UpdateEvent',
      ($9.Event value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.Event.fromBuffer(value));
  static final _$deleteEvent = $grpc.ClientMethod<$9.Event, $9.Event>(
      '/jonline.Jonline/DeleteEvent',
      ($9.Event value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.Event.fromBuffer(value));
  static final _$getEventSyncSources = $grpc.ClientMethod<$4.User, $9.GetEventSyncSourcesResponse>(
      '/jonline.Jonline/GetEventSyncSources',
      ($4.User value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.GetEventSyncSourcesResponse.fromBuffer(value));
  static final _$createEventSyncSource = $grpc.ClientMethod<$4.EventSyncSource, $4.EventSyncSource>(
      '/jonline.Jonline/CreateEventSyncSource',
      ($4.EventSyncSource value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.EventSyncSource.fromBuffer(value));
  static final _$updateEventSyncSource = $grpc.ClientMethod<$4.EventSyncSource, $4.EventSyncSource>(
      '/jonline.Jonline/UpdateEventSyncSource',
      ($4.EventSyncSource value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.EventSyncSource.fromBuffer(value));
  static final _$deleteEventSyncSource = $grpc.ClientMethod<$9.DeleteEventSyncSourceRequest, $0.Empty>(
      '/jonline.Jonline/DeleteEventSyncSource',
      ($9.DeleteEventSyncSourceRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getEventSyncDestinations = $grpc.ClientMethod<$4.User, $9.GetEventSyncDestinationsResponse>(
      '/jonline.Jonline/GetEventSyncDestinations',
      ($4.User value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.GetEventSyncDestinationsResponse.fromBuffer(value));
  static final _$createEventSyncDestination = $grpc.ClientMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
      '/jonline.Jonline/CreateEventSyncDestination',
      ($4.EventSyncDestination value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.EventSyncDestination.fromBuffer(value));
  static final _$updateEventSyncDestination = $grpc.ClientMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
      '/jonline.Jonline/UpdateEventSyncDestination',
      ($4.EventSyncDestination value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.EventSyncDestination.fromBuffer(value));
  static final _$deleteEventSyncDestination = $grpc.ClientMethod<$9.DeleteEventSyncDestinationRequest, $0.Empty>(
      '/jonline.Jonline/DeleteEventSyncDestination',
      ($9.DeleteEventSyncDestinationRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$syncEventInstance = $grpc.ClientMethod<$9.SyncEventInstanceRequest, $9.EventInstance>(
      '/jonline.Jonline/SyncEventInstance',
      ($9.SyncEventInstanceRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.EventInstance.fromBuffer(value));
  static final _$deleteEventInstanceSyncDestination = $grpc.ClientMethod<$9.DeleteEventInstanceSyncDestinationRequest, $0.Empty>(
      '/jonline.Jonline/DeleteEventInstanceSyncDestination',
      ($9.DeleteEventInstanceSyncDestinationRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getEventAttendances = $grpc.ClientMethod<$9.GetEventAttendancesRequest, $9.EventAttendances>(
      '/jonline.Jonline/GetEventAttendances',
      ($9.GetEventAttendancesRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.EventAttendances.fromBuffer(value));
  static final _$upsertEventAttendance = $grpc.ClientMethod<$9.EventAttendance, $9.EventAttendance>(
      '/jonline.Jonline/UpsertEventAttendance',
      ($9.EventAttendance value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $9.EventAttendance.fromBuffer(value));
  static final _$deleteEventAttendance = $grpc.ClientMethod<$9.EventAttendance, $0.Empty>(
      '/jonline.Jonline/DeleteEventAttendance',
      ($9.EventAttendance value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$federateProfile = $grpc.ClientMethod<$1.FederatedAccount, $1.FederatedAccount>(
      '/jonline.Jonline/FederateProfile',
      ($1.FederatedAccount value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.FederatedAccount.fromBuffer(value));
  static final _$defederateProfile = $grpc.ClientMethod<$1.FederatedAccount, $0.Empty>(
      '/jonline.Jonline/DefederateProfile',
      ($1.FederatedAccount value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$configureServer = $grpc.ClientMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
      '/jonline.Jonline/ConfigureServer',
      ($2.ServerConfiguration value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.ServerConfiguration.fromBuffer(value));
  static final _$resetData = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/jonline.Jonline/ResetData',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$streamReplies = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/StreamReplies',
      ($8.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Post.fromBuffer(value));

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

  $grpc.ResponseFuture<$0.Empty> resetPassword($3.ResetPasswordRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$resetPassword, request, options: options);
  }

  $grpc.ResponseFuture<$5.GetMediaResponse> getMedia($5.GetMediaRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMedia, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteMedia($5.Media request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteMedia, request, options: options);
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

  $grpc.ResponseFuture<$6.Message> sendMessage($6.SendMessageRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sendMessage, request, options: options);
  }

  $grpc.ResponseFuture<$6.GetMessagesResponse> getMessages($6.GetMessagesRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMessages, request, options: options);
  }

  $grpc.ResponseFuture<$6.MarkMessagesReadResponse> markMessagesRead($6.MarkMessagesReadRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$markMessagesRead, request, options: options);
  }

  $grpc.ResponseFuture<$6.PushSubscription> registerPushSubscription($6.RegisterPushSubscriptionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$registerPushSubscription, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> unregisterPushSubscription($6.UnregisterPushSubscriptionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$unregisterPushSubscription, request, options: options);
  }

  $grpc.ResponseFuture<$6.GetPushSubscriptionStatusResponse> getPushSubscriptionStatus($6.GetPushSubscriptionStatusRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getPushSubscriptionStatus, request, options: options);
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

  $grpc.ResponseFuture<$7.GetGroupsResponse> getGroups($7.GetGroupsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroups, request, options: options);
  }

  $grpc.ResponseFuture<$7.Group> createGroup($7.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroup, request, options: options);
  }

  $grpc.ResponseFuture<$7.Group> updateGroup($7.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroup, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteGroup($7.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteGroup, request, options: options);
  }

  $grpc.ResponseFuture<$7.GetMembersResponse> getMembers($7.GetMembersRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMembers, request, options: options);
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

  $grpc.ResponseFuture<$8.GetPostsResponse> getPosts($8.GetPostsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getPosts, request, options: options);
  }

  $grpc.ResponseFuture<$8.Post> createPost($8.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  $grpc.ResponseFuture<$8.Post> updatePost($8.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updatePost, request, options: options);
  }

  $grpc.ResponseFuture<$8.Post> deletePost($8.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deletePost, request, options: options);
  }

  $grpc.ResponseFuture<$8.Post> starPost($8.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$starPost, request, options: options);
  }

  $grpc.ResponseFuture<$8.Post> unstarPost($8.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$unstarPost, request, options: options);
  }

  $grpc.ResponseFuture<$8.GetGroupPostsResponse> getGroupPosts($8.GetGroupPostsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroupPosts, request, options: options);
  }

  $grpc.ResponseFuture<$8.GroupPost> createGroupPost($8.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroupPost, request, options: options);
  }

  $grpc.ResponseFuture<$8.GroupPost> updateGroupPost($8.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroupPost, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteGroupPost($8.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteGroupPost, request, options: options);
  }

  $grpc.ResponseFuture<$9.GetEventsResponse> getEvents($9.GetEventsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getEvents, request, options: options);
  }

  $grpc.ResponseFuture<$9.Event> createEvent($9.Event request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createEvent, request, options: options);
  }

  $grpc.ResponseFuture<$9.Event> updateEvent($9.Event request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateEvent, request, options: options);
  }

  $grpc.ResponseFuture<$9.Event> deleteEvent($9.Event request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteEvent, request, options: options);
  }

  $grpc.ResponseFuture<$9.GetEventSyncSourcesResponse> getEventSyncSources($4.User request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getEventSyncSources, request, options: options);
  }

  $grpc.ResponseFuture<$4.EventSyncSource> createEventSyncSource($4.EventSyncSource request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createEventSyncSource, request, options: options);
  }

  $grpc.ResponseFuture<$4.EventSyncSource> updateEventSyncSource($4.EventSyncSource request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateEventSyncSource, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteEventSyncSource($9.DeleteEventSyncSourceRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteEventSyncSource, request, options: options);
  }

  $grpc.ResponseFuture<$9.GetEventSyncDestinationsResponse> getEventSyncDestinations($4.User request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getEventSyncDestinations, request, options: options);
  }

  $grpc.ResponseFuture<$4.EventSyncDestination> createEventSyncDestination($4.EventSyncDestination request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createEventSyncDestination, request, options: options);
  }

  $grpc.ResponseFuture<$4.EventSyncDestination> updateEventSyncDestination($4.EventSyncDestination request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateEventSyncDestination, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteEventSyncDestination($9.DeleteEventSyncDestinationRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteEventSyncDestination, request, options: options);
  }

  $grpc.ResponseFuture<$9.EventInstance> syncEventInstance($9.SyncEventInstanceRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$syncEventInstance, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteEventInstanceSyncDestination($9.DeleteEventInstanceSyncDestinationRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteEventInstanceSyncDestination, request, options: options);
  }

  $grpc.ResponseFuture<$9.EventAttendances> getEventAttendances($9.GetEventAttendancesRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getEventAttendances, request, options: options);
  }

  $grpc.ResponseFuture<$9.EventAttendance> upsertEventAttendance($9.EventAttendance request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$upsertEventAttendance, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteEventAttendance($9.EventAttendance request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteEventAttendance, request, options: options);
  }

  $grpc.ResponseFuture<$1.FederatedAccount> federateProfile($1.FederatedAccount request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$federateProfile, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> defederateProfile($1.FederatedAccount request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$defederateProfile, request, options: options);
  }

  $grpc.ResponseFuture<$2.ServerConfiguration> configureServer($2.ServerConfiguration request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$configureServer, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> resetData($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$resetData, request, options: options);
  }

  $grpc.ResponseStream<$8.Post> streamReplies($8.Post request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$streamReplies, $async.Stream.fromIterable([request]), options: options);
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
    $addMethod($grpc.ServiceMethod<$3.ResetPasswordRequest, $0.Empty>(
        'ResetPassword',
        resetPassword_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.ResetPasswordRequest.fromBuffer(value),
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
    $addMethod($grpc.ServiceMethod<$6.SendMessageRequest, $6.Message>(
        'SendMessage',
        sendMessage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.SendMessageRequest.fromBuffer(value),
        ($6.Message value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.GetMessagesRequest, $6.GetMessagesResponse>(
        'GetMessages',
        getMessages_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.GetMessagesRequest.fromBuffer(value),
        ($6.GetMessagesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.MarkMessagesReadRequest, $6.MarkMessagesReadResponse>(
        'MarkMessagesRead',
        markMessagesRead_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.MarkMessagesReadRequest.fromBuffer(value),
        ($6.MarkMessagesReadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.RegisterPushSubscriptionRequest, $6.PushSubscription>(
        'RegisterPushSubscription',
        registerPushSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.RegisterPushSubscriptionRequest.fromBuffer(value),
        ($6.PushSubscription value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.UnregisterPushSubscriptionRequest, $0.Empty>(
        'UnregisterPushSubscription',
        unregisterPushSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.UnregisterPushSubscriptionRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.GetPushSubscriptionStatusRequest, $6.GetPushSubscriptionStatusResponse>(
        'GetPushSubscriptionStatus',
        getPushSubscriptionStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.GetPushSubscriptionStatusRequest.fromBuffer(value),
        ($6.GetPushSubscriptionStatusResponse value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$7.GetGroupsRequest, $7.GetGroupsResponse>(
        'GetGroups',
        getGroups_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetGroupsRequest.fromBuffer(value),
        ($7.GetGroupsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Group, $7.Group>(
        'CreateGroup',
        createGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Group.fromBuffer(value),
        ($7.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Group, $7.Group>(
        'UpdateGroup',
        updateGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Group.fromBuffer(value),
        ($7.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Group, $0.Empty>(
        'DeleteGroup',
        deleteGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Group.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GetMembersRequest, $7.GetMembersResponse>(
        'GetMembers',
        getMembers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetMembersRequest.fromBuffer(value),
        ($7.GetMembersResponse value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$8.GetPostsRequest, $8.GetPostsResponse>(
        'GetPosts',
        getPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GetPostsRequest.fromBuffer(value),
        ($8.GetPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'UpdatePost',
        updatePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'StarPost',
        starPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'UnstarPost',
        unstarPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GetGroupPostsRequest, $8.GetGroupPostsResponse>(
        'GetGroupPosts',
        getGroupPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GetGroupPostsRequest.fromBuffer(value),
        ($8.GetGroupPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GroupPost, $8.GroupPost>(
        'CreateGroupPost',
        createGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value),
        ($8.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GroupPost, $8.GroupPost>(
        'UpdateGroupPost',
        updateGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value),
        ($8.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GroupPost, $0.Empty>(
        'DeleteGroupPost',
        deleteGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.GetEventsRequest, $9.GetEventsResponse>(
        'GetEvents',
        getEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.GetEventsRequest.fromBuffer(value),
        ($9.GetEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.Event, $9.Event>(
        'CreateEvent',
        createEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.Event.fromBuffer(value),
        ($9.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.Event, $9.Event>(
        'UpdateEvent',
        updateEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.Event.fromBuffer(value),
        ($9.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.Event, $9.Event>(
        'DeleteEvent',
        deleteEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.Event.fromBuffer(value),
        ($9.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.User, $9.GetEventSyncSourcesResponse>(
        'GetEventSyncSources',
        getEventSyncSources_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.User.fromBuffer(value),
        ($9.GetEventSyncSourcesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.EventSyncSource, $4.EventSyncSource>(
        'CreateEventSyncSource',
        createEventSyncSource_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.EventSyncSource.fromBuffer(value),
        ($4.EventSyncSource value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.EventSyncSource, $4.EventSyncSource>(
        'UpdateEventSyncSource',
        updateEventSyncSource_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.EventSyncSource.fromBuffer(value),
        ($4.EventSyncSource value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.DeleteEventSyncSourceRequest, $0.Empty>(
        'DeleteEventSyncSource',
        deleteEventSyncSource_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.DeleteEventSyncSourceRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.User, $9.GetEventSyncDestinationsResponse>(
        'GetEventSyncDestinations',
        getEventSyncDestinations_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.User.fromBuffer(value),
        ($9.GetEventSyncDestinationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
        'CreateEventSyncDestination',
        createEventSyncDestination_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.EventSyncDestination.fromBuffer(value),
        ($4.EventSyncDestination value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
        'UpdateEventSyncDestination',
        updateEventSyncDestination_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.EventSyncDestination.fromBuffer(value),
        ($4.EventSyncDestination value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.DeleteEventSyncDestinationRequest, $0.Empty>(
        'DeleteEventSyncDestination',
        deleteEventSyncDestination_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.DeleteEventSyncDestinationRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.SyncEventInstanceRequest, $9.EventInstance>(
        'SyncEventInstance',
        syncEventInstance_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.SyncEventInstanceRequest.fromBuffer(value),
        ($9.EventInstance value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.DeleteEventInstanceSyncDestinationRequest, $0.Empty>(
        'DeleteEventInstanceSyncDestination',
        deleteEventInstanceSyncDestination_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.DeleteEventInstanceSyncDestinationRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.GetEventAttendancesRequest, $9.EventAttendances>(
        'GetEventAttendances',
        getEventAttendances_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.GetEventAttendancesRequest.fromBuffer(value),
        ($9.EventAttendances value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.EventAttendance, $9.EventAttendance>(
        'UpsertEventAttendance',
        upsertEventAttendance_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.EventAttendance.fromBuffer(value),
        ($9.EventAttendance value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.EventAttendance, $0.Empty>(
        'DeleteEventAttendance',
        deleteEventAttendance_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.EventAttendance.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.FederatedAccount, $1.FederatedAccount>(
        'FederateProfile',
        federateProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.FederatedAccount.fromBuffer(value),
        ($1.FederatedAccount value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.FederatedAccount, $0.Empty>(
        'DefederateProfile',
        defederateProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.FederatedAccount.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'StreamReplies',
        streamReplies_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
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

  $async.Future<$0.Empty> resetPassword_Pre($grpc.ServiceCall call, $async.Future<$3.ResetPasswordRequest> request) async {
    return resetPassword(call, await request);
  }

  $async.Future<$5.GetMediaResponse> getMedia_Pre($grpc.ServiceCall call, $async.Future<$5.GetMediaRequest> request) async {
    return getMedia(call, await request);
  }

  $async.Future<$0.Empty> deleteMedia_Pre($grpc.ServiceCall call, $async.Future<$5.Media> request) async {
    return deleteMedia(call, await request);
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

  $async.Future<$6.Message> sendMessage_Pre($grpc.ServiceCall call, $async.Future<$6.SendMessageRequest> request) async {
    return sendMessage(call, await request);
  }

  $async.Future<$6.GetMessagesResponse> getMessages_Pre($grpc.ServiceCall call, $async.Future<$6.GetMessagesRequest> request) async {
    return getMessages(call, await request);
  }

  $async.Future<$6.MarkMessagesReadResponse> markMessagesRead_Pre($grpc.ServiceCall call, $async.Future<$6.MarkMessagesReadRequest> request) async {
    return markMessagesRead(call, await request);
  }

  $async.Future<$6.PushSubscription> registerPushSubscription_Pre($grpc.ServiceCall call, $async.Future<$6.RegisterPushSubscriptionRequest> request) async {
    return registerPushSubscription(call, await request);
  }

  $async.Future<$0.Empty> unregisterPushSubscription_Pre($grpc.ServiceCall call, $async.Future<$6.UnregisterPushSubscriptionRequest> request) async {
    return unregisterPushSubscription(call, await request);
  }

  $async.Future<$6.GetPushSubscriptionStatusResponse> getPushSubscriptionStatus_Pre($grpc.ServiceCall call, $async.Future<$6.GetPushSubscriptionStatusRequest> request) async {
    return getPushSubscriptionStatus(call, await request);
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

  $async.Future<$7.GetGroupsResponse> getGroups_Pre($grpc.ServiceCall call, $async.Future<$7.GetGroupsRequest> request) async {
    return getGroups(call, await request);
  }

  $async.Future<$7.Group> createGroup_Pre($grpc.ServiceCall call, $async.Future<$7.Group> request) async {
    return createGroup(call, await request);
  }

  $async.Future<$7.Group> updateGroup_Pre($grpc.ServiceCall call, $async.Future<$7.Group> request) async {
    return updateGroup(call, await request);
  }

  $async.Future<$0.Empty> deleteGroup_Pre($grpc.ServiceCall call, $async.Future<$7.Group> request) async {
    return deleteGroup(call, await request);
  }

  $async.Future<$7.GetMembersResponse> getMembers_Pre($grpc.ServiceCall call, $async.Future<$7.GetMembersRequest> request) async {
    return getMembers(call, await request);
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

  $async.Future<$8.GetPostsResponse> getPosts_Pre($grpc.ServiceCall call, $async.Future<$8.GetPostsRequest> request) async {
    return getPosts(call, await request);
  }

  $async.Future<$8.Post> createPost_Pre($grpc.ServiceCall call, $async.Future<$8.Post> request) async {
    return createPost(call, await request);
  }

  $async.Future<$8.Post> updatePost_Pre($grpc.ServiceCall call, $async.Future<$8.Post> request) async {
    return updatePost(call, await request);
  }

  $async.Future<$8.Post> deletePost_Pre($grpc.ServiceCall call, $async.Future<$8.Post> request) async {
    return deletePost(call, await request);
  }

  $async.Future<$8.Post> starPost_Pre($grpc.ServiceCall call, $async.Future<$8.Post> request) async {
    return starPost(call, await request);
  }

  $async.Future<$8.Post> unstarPost_Pre($grpc.ServiceCall call, $async.Future<$8.Post> request) async {
    return unstarPost(call, await request);
  }

  $async.Future<$8.GetGroupPostsResponse> getGroupPosts_Pre($grpc.ServiceCall call, $async.Future<$8.GetGroupPostsRequest> request) async {
    return getGroupPosts(call, await request);
  }

  $async.Future<$8.GroupPost> createGroupPost_Pre($grpc.ServiceCall call, $async.Future<$8.GroupPost> request) async {
    return createGroupPost(call, await request);
  }

  $async.Future<$8.GroupPost> updateGroupPost_Pre($grpc.ServiceCall call, $async.Future<$8.GroupPost> request) async {
    return updateGroupPost(call, await request);
  }

  $async.Future<$0.Empty> deleteGroupPost_Pre($grpc.ServiceCall call, $async.Future<$8.GroupPost> request) async {
    return deleteGroupPost(call, await request);
  }

  $async.Future<$9.GetEventsResponse> getEvents_Pre($grpc.ServiceCall call, $async.Future<$9.GetEventsRequest> request) async {
    return getEvents(call, await request);
  }

  $async.Future<$9.Event> createEvent_Pre($grpc.ServiceCall call, $async.Future<$9.Event> request) async {
    return createEvent(call, await request);
  }

  $async.Future<$9.Event> updateEvent_Pre($grpc.ServiceCall call, $async.Future<$9.Event> request) async {
    return updateEvent(call, await request);
  }

  $async.Future<$9.Event> deleteEvent_Pre($grpc.ServiceCall call, $async.Future<$9.Event> request) async {
    return deleteEvent(call, await request);
  }

  $async.Future<$9.GetEventSyncSourcesResponse> getEventSyncSources_Pre($grpc.ServiceCall call, $async.Future<$4.User> request) async {
    return getEventSyncSources(call, await request);
  }

  $async.Future<$4.EventSyncSource> createEventSyncSource_Pre($grpc.ServiceCall call, $async.Future<$4.EventSyncSource> request) async {
    return createEventSyncSource(call, await request);
  }

  $async.Future<$4.EventSyncSource> updateEventSyncSource_Pre($grpc.ServiceCall call, $async.Future<$4.EventSyncSource> request) async {
    return updateEventSyncSource(call, await request);
  }

  $async.Future<$0.Empty> deleteEventSyncSource_Pre($grpc.ServiceCall call, $async.Future<$9.DeleteEventSyncSourceRequest> request) async {
    return deleteEventSyncSource(call, await request);
  }

  $async.Future<$9.GetEventSyncDestinationsResponse> getEventSyncDestinations_Pre($grpc.ServiceCall call, $async.Future<$4.User> request) async {
    return getEventSyncDestinations(call, await request);
  }

  $async.Future<$4.EventSyncDestination> createEventSyncDestination_Pre($grpc.ServiceCall call, $async.Future<$4.EventSyncDestination> request) async {
    return createEventSyncDestination(call, await request);
  }

  $async.Future<$4.EventSyncDestination> updateEventSyncDestination_Pre($grpc.ServiceCall call, $async.Future<$4.EventSyncDestination> request) async {
    return updateEventSyncDestination(call, await request);
  }

  $async.Future<$0.Empty> deleteEventSyncDestination_Pre($grpc.ServiceCall call, $async.Future<$9.DeleteEventSyncDestinationRequest> request) async {
    return deleteEventSyncDestination(call, await request);
  }

  $async.Future<$9.EventInstance> syncEventInstance_Pre($grpc.ServiceCall call, $async.Future<$9.SyncEventInstanceRequest> request) async {
    return syncEventInstance(call, await request);
  }

  $async.Future<$0.Empty> deleteEventInstanceSyncDestination_Pre($grpc.ServiceCall call, $async.Future<$9.DeleteEventInstanceSyncDestinationRequest> request) async {
    return deleteEventInstanceSyncDestination(call, await request);
  }

  $async.Future<$9.EventAttendances> getEventAttendances_Pre($grpc.ServiceCall call, $async.Future<$9.GetEventAttendancesRequest> request) async {
    return getEventAttendances(call, await request);
  }

  $async.Future<$9.EventAttendance> upsertEventAttendance_Pre($grpc.ServiceCall call, $async.Future<$9.EventAttendance> request) async {
    return upsertEventAttendance(call, await request);
  }

  $async.Future<$0.Empty> deleteEventAttendance_Pre($grpc.ServiceCall call, $async.Future<$9.EventAttendance> request) async {
    return deleteEventAttendance(call, await request);
  }

  $async.Future<$1.FederatedAccount> federateProfile_Pre($grpc.ServiceCall call, $async.Future<$1.FederatedAccount> request) async {
    return federateProfile(call, await request);
  }

  $async.Future<$0.Empty> defederateProfile_Pre($grpc.ServiceCall call, $async.Future<$1.FederatedAccount> request) async {
    return defederateProfile(call, await request);
  }

  $async.Future<$2.ServerConfiguration> configureServer_Pre($grpc.ServiceCall call, $async.Future<$2.ServerConfiguration> request) async {
    return configureServer(call, await request);
  }

  $async.Future<$0.Empty> resetData_Pre($grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return resetData(call, await request);
  }

  $async.Stream<$8.Post> streamReplies_Pre($grpc.ServiceCall call, $async.Future<$8.Post> request) async* {
    yield* streamReplies(call, await request);
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$2.ServerConfiguration> getServerConfiguration($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$3.RefreshTokenResponse> createAccount($grpc.ServiceCall call, $3.CreateAccountRequest request);
  $async.Future<$3.RefreshTokenResponse> login($grpc.ServiceCall call, $3.LoginRequest request);
  $async.Future<$3.AccessTokenResponse> accessToken($grpc.ServiceCall call, $3.AccessTokenRequest request);
  $async.Future<$4.User> getCurrentUser($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$0.Empty> resetPassword($grpc.ServiceCall call, $3.ResetPasswordRequest request);
  $async.Future<$5.GetMediaResponse> getMedia($grpc.ServiceCall call, $5.GetMediaRequest request);
  $async.Future<$0.Empty> deleteMedia($grpc.ServiceCall call, $5.Media request);
  $async.Future<$4.GetUsersResponse> getUsers($grpc.ServiceCall call, $4.GetUsersRequest request);
  $async.Future<$4.User> updateUser($grpc.ServiceCall call, $4.User request);
  $async.Future<$0.Empty> deleteUser($grpc.ServiceCall call, $4.User request);
  $async.Future<$6.Message> sendMessage($grpc.ServiceCall call, $6.SendMessageRequest request);
  $async.Future<$6.GetMessagesResponse> getMessages($grpc.ServiceCall call, $6.GetMessagesRequest request);
  $async.Future<$6.MarkMessagesReadResponse> markMessagesRead($grpc.ServiceCall call, $6.MarkMessagesReadRequest request);
  $async.Future<$6.PushSubscription> registerPushSubscription($grpc.ServiceCall call, $6.RegisterPushSubscriptionRequest request);
  $async.Future<$0.Empty> unregisterPushSubscription($grpc.ServiceCall call, $6.UnregisterPushSubscriptionRequest request);
  $async.Future<$6.GetPushSubscriptionStatusResponse> getPushSubscriptionStatus($grpc.ServiceCall call, $6.GetPushSubscriptionStatusRequest request);
  $async.Future<$4.Follow> createFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$4.Follow> updateFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$0.Empty> deleteFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$7.GetGroupsResponse> getGroups($grpc.ServiceCall call, $7.GetGroupsRequest request);
  $async.Future<$7.Group> createGroup($grpc.ServiceCall call, $7.Group request);
  $async.Future<$7.Group> updateGroup($grpc.ServiceCall call, $7.Group request);
  $async.Future<$0.Empty> deleteGroup($grpc.ServiceCall call, $7.Group request);
  $async.Future<$7.GetMembersResponse> getMembers($grpc.ServiceCall call, $7.GetMembersRequest request);
  $async.Future<$4.Membership> createMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$4.Membership> updateMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$0.Empty> deleteMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$8.GetPostsResponse> getPosts($grpc.ServiceCall call, $8.GetPostsRequest request);
  $async.Future<$8.Post> createPost($grpc.ServiceCall call, $8.Post request);
  $async.Future<$8.Post> updatePost($grpc.ServiceCall call, $8.Post request);
  $async.Future<$8.Post> deletePost($grpc.ServiceCall call, $8.Post request);
  $async.Future<$8.Post> starPost($grpc.ServiceCall call, $8.Post request);
  $async.Future<$8.Post> unstarPost($grpc.ServiceCall call, $8.Post request);
  $async.Future<$8.GetGroupPostsResponse> getGroupPosts($grpc.ServiceCall call, $8.GetGroupPostsRequest request);
  $async.Future<$8.GroupPost> createGroupPost($grpc.ServiceCall call, $8.GroupPost request);
  $async.Future<$8.GroupPost> updateGroupPost($grpc.ServiceCall call, $8.GroupPost request);
  $async.Future<$0.Empty> deleteGroupPost($grpc.ServiceCall call, $8.GroupPost request);
  $async.Future<$9.GetEventsResponse> getEvents($grpc.ServiceCall call, $9.GetEventsRequest request);
  $async.Future<$9.Event> createEvent($grpc.ServiceCall call, $9.Event request);
  $async.Future<$9.Event> updateEvent($grpc.ServiceCall call, $9.Event request);
  $async.Future<$9.Event> deleteEvent($grpc.ServiceCall call, $9.Event request);
  $async.Future<$9.GetEventSyncSourcesResponse> getEventSyncSources($grpc.ServiceCall call, $4.User request);
  $async.Future<$4.EventSyncSource> createEventSyncSource($grpc.ServiceCall call, $4.EventSyncSource request);
  $async.Future<$4.EventSyncSource> updateEventSyncSource($grpc.ServiceCall call, $4.EventSyncSource request);
  $async.Future<$0.Empty> deleteEventSyncSource($grpc.ServiceCall call, $9.DeleteEventSyncSourceRequest request);
  $async.Future<$9.GetEventSyncDestinationsResponse> getEventSyncDestinations($grpc.ServiceCall call, $4.User request);
  $async.Future<$4.EventSyncDestination> createEventSyncDestination($grpc.ServiceCall call, $4.EventSyncDestination request);
  $async.Future<$4.EventSyncDestination> updateEventSyncDestination($grpc.ServiceCall call, $4.EventSyncDestination request);
  $async.Future<$0.Empty> deleteEventSyncDestination($grpc.ServiceCall call, $9.DeleteEventSyncDestinationRequest request);
  $async.Future<$9.EventInstance> syncEventInstance($grpc.ServiceCall call, $9.SyncEventInstanceRequest request);
  $async.Future<$0.Empty> deleteEventInstanceSyncDestination($grpc.ServiceCall call, $9.DeleteEventInstanceSyncDestinationRequest request);
  $async.Future<$9.EventAttendances> getEventAttendances($grpc.ServiceCall call, $9.GetEventAttendancesRequest request);
  $async.Future<$9.EventAttendance> upsertEventAttendance($grpc.ServiceCall call, $9.EventAttendance request);
  $async.Future<$0.Empty> deleteEventAttendance($grpc.ServiceCall call, $9.EventAttendance request);
  $async.Future<$1.FederatedAccount> federateProfile($grpc.ServiceCall call, $1.FederatedAccount request);
  $async.Future<$0.Empty> defederateProfile($grpc.ServiceCall call, $1.FederatedAccount request);
  $async.Future<$2.ServerConfiguration> configureServer($grpc.ServiceCall call, $2.ServerConfiguration request);
  $async.Future<$0.Empty> resetData($grpc.ServiceCall call, $0.Empty request);
  $async.Stream<$8.Post> streamReplies($grpc.ServiceCall call, $8.Post request);
}
