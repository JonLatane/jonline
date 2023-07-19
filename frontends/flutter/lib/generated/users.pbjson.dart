//
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use userListingTypeDescriptor instead')
const UserListingType$json = {
  '1': 'UserListingType',
  '2': [
    {'1': 'EVERYONE', '2': 0},
    {'1': 'FOLLOWING', '2': 1},
    {'1': 'FRIENDS', '2': 2},
    {'1': 'FOLLOWERS', '2': 3},
    {'1': 'FOLLOW_REQUESTS', '2': 4},
  ],
};

/// Descriptor for `UserListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userListingTypeDescriptor = $convert.base64Decode(
    'Cg9Vc2VyTGlzdGluZ1R5cGUSDAoIRVZFUllPTkUQABINCglGT0xMT1dJTkcQARILCgdGUklFTk'
    'RTEAISDQoJRk9MTE9XRVJTEAMSEwoPRk9MTE9XX1JFUVVFU1RTEAQ=');

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'real_name', '3': 3, '4': 1, '5': 9, '10': 'realName'},
    {'1': 'email', '3': 4, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 0, '10': 'email', '17': true},
    {'1': 'phone', '3': 5, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 1, '10': 'phone', '17': true},
    {'1': 'permissions', '3': 6, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'permissions'},
    {'1': 'avatar_media_id', '3': 7, '4': 1, '5': 9, '9': 2, '10': 'avatarMediaId', '17': true},
    {'1': 'bio', '3': 8, '4': 1, '5': 9, '10': 'bio'},
    {'1': 'visibility', '3': 20, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    {'1': 'moderation', '3': 21, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'moderation'},
    {'1': 'default_follow_moderation', '3': 30, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultFollowModeration'},
    {'1': 'follower_count', '3': 31, '4': 1, '5': 5, '9': 3, '10': 'followerCount', '17': true},
    {'1': 'following_count', '3': 32, '4': 1, '5': 5, '9': 4, '10': 'followingCount', '17': true},
    {'1': 'group_count', '3': 33, '4': 1, '5': 5, '9': 5, '10': 'groupCount', '17': true},
    {'1': 'post_count', '3': 34, '4': 1, '5': 5, '9': 6, '10': 'postCount', '17': true},
    {'1': 'response_count', '3': 35, '4': 1, '5': 5, '9': 7, '10': 'responseCount', '17': true},
    {'1': 'current_user_follow', '3': 50, '4': 1, '5': 11, '6': '.jonline.Follow', '9': 8, '10': 'currentUserFollow', '17': true},
    {'1': 'target_current_user_follow', '3': 51, '4': 1, '5': 11, '6': '.jonline.Follow', '9': 9, '10': 'targetCurrentUserFollow', '17': true},
    {'1': 'current_group_membership', '3': 52, '4': 1, '5': 11, '6': '.jonline.Membership', '9': 10, '10': 'currentGroupMembership', '17': true},
    {'1': 'created_at', '3': 100, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 101, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 11, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': '_email'},
    {'1': '_phone'},
    {'1': '_avatar_media_id'},
    {'1': '_follower_count'},
    {'1': '_following_count'},
    {'1': '_group_count'},
    {'1': '_post_count'},
    {'1': '_response_count'},
    {'1': '_current_user_follow'},
    {'1': '_target_current_user_follow'},
    {'1': '_current_group_membership'},
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWUSGwoJcm'
    'VhbF9uYW1lGAMgASgJUghyZWFsTmFtZRIxCgVlbWFpbBgEIAEoCzIWLmpvbmxpbmUuQ29udGFj'
    'dE1ldGhvZEgAUgVlbWFpbIgBARIxCgVwaG9uZRgFIAEoCzIWLmpvbmxpbmUuQ29udGFjdE1ldG'
    'hvZEgBUgVwaG9uZYgBARI1CgtwZXJtaXNzaW9ucxgGIAMoDjITLmpvbmxpbmUuUGVybWlzc2lv'
    'blILcGVybWlzc2lvbnMSKwoPYXZhdGFyX21lZGlhX2lkGAcgASgJSAJSDWF2YXRhck1lZGlhSW'
    'SIAQESEAoDYmlvGAggASgJUgNiaW8SMwoKdmlzaWJpbGl0eRgUIAEoDjITLmpvbmxpbmUuVmlz'
    'aWJpbGl0eVIKdmlzaWJpbGl0eRIzCgptb2RlcmF0aW9uGBUgASgOMhMuam9ubGluZS5Nb2Rlcm'
    'F0aW9uUgptb2RlcmF0aW9uEk8KGWRlZmF1bHRfZm9sbG93X21vZGVyYXRpb24YHiABKA4yEy5q'
    'b25saW5lLk1vZGVyYXRpb25SF2RlZmF1bHRGb2xsb3dNb2RlcmF0aW9uEioKDmZvbGxvd2VyX2'
    'NvdW50GB8gASgFSANSDWZvbGxvd2VyQ291bnSIAQESLAoPZm9sbG93aW5nX2NvdW50GCAgASgF'
    'SARSDmZvbGxvd2luZ0NvdW50iAEBEiQKC2dyb3VwX2NvdW50GCEgASgFSAVSCmdyb3VwQ291bn'
    'SIAQESIgoKcG9zdF9jb3VudBgiIAEoBUgGUglwb3N0Q291bnSIAQESKgoOcmVzcG9uc2VfY291'
    'bnQYIyABKAVIB1INcmVzcG9uc2VDb3VudIgBARJEChNjdXJyZW50X3VzZXJfZm9sbG93GDIgAS'
    'gLMg8uam9ubGluZS5Gb2xsb3dICFIRY3VycmVudFVzZXJGb2xsb3eIAQESUQoadGFyZ2V0X2N1'
    'cnJlbnRfdXNlcl9mb2xsb3cYMyABKAsyDy5qb25saW5lLkZvbGxvd0gJUhd0YXJnZXRDdXJyZW'
    '50VXNlckZvbGxvd4gBARJSChhjdXJyZW50X2dyb3VwX21lbWJlcnNoaXAYNCABKAsyEy5qb25s'
    'aW5lLk1lbWJlcnNoaXBIClIWY3VycmVudEdyb3VwTWVtYmVyc2hpcIgBARI5CgpjcmVhdGVkX2'
    'F0GGQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0Ej4KCnVwZGF0'
    'ZWRfYXQYZSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSAtSCXVwZGF0ZWRBdIgBAU'
    'IICgZfZW1haWxCCAoGX3Bob25lQhIKEF9hdmF0YXJfbWVkaWFfaWRCEQoPX2ZvbGxvd2VyX2Nv'
    'dW50QhIKEF9mb2xsb3dpbmdfY291bnRCDgoMX2dyb3VwX2NvdW50Qg0KC19wb3N0X2NvdW50Qh'
    'EKD19yZXNwb25zZV9jb3VudEIWChRfY3VycmVudF91c2VyX2ZvbGxvd0IdChtfdGFyZ2V0X2N1'
    'cnJlbnRfdXNlcl9mb2xsb3dCGwoZX2N1cnJlbnRfZ3JvdXBfbWVtYmVyc2hpcEINCgtfdXBkYX'
    'RlZF9hdA==');

@$core.Deprecated('Use followDescriptor instead')
const Follow$json = {
  '1': 'Follow',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'target_user_id', '3': 2, '4': 1, '5': 9, '10': 'targetUserId'},
    {'1': 'target_user_moderation', '3': 3, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'targetUserModeration'},
    {'1': 'created_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `Follow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List followDescriptor = $convert.base64Decode(
    'CgZGb2xsb3cSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEiQKDnRhcmdldF91c2VyX2lkGAIgAS'
    'gJUgx0YXJnZXRVc2VySWQSSQoWdGFyZ2V0X3VzZXJfbW9kZXJhdGlvbhgDIAEoDjITLmpvbmxp'
    'bmUuTW9kZXJhdGlvblIUdGFyZ2V0VXNlck1vZGVyYXRpb24SOQoKY3JlYXRlZF9hdBgEIAEoCz'
    'IaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GAUg'
    'ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUgl1cGRhdGVkQXSIAQFCDQoLX3VwZG'
    'F0ZWRfYXQ=');

@$core.Deprecated('Use membershipDescriptor instead')
const Membership$json = {
  '1': 'Membership',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'group_id', '3': 2, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'permissions', '3': 3, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'permissions'},
    {'1': 'group_moderation', '3': 4, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'groupModeration'},
    {'1': 'user_moderation', '3': 5, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'userModeration'},
    {'1': 'created_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `Membership`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List membershipDescriptor = $convert.base64Decode(
    'CgpNZW1iZXJzaGlwEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIZCghncm91cF9pZBgCIAEoCV'
    'IHZ3JvdXBJZBI1CgtwZXJtaXNzaW9ucxgDIAMoDjITLmpvbmxpbmUuUGVybWlzc2lvblILcGVy'
    'bWlzc2lvbnMSPgoQZ3JvdXBfbW9kZXJhdGlvbhgEIAEoDjITLmpvbmxpbmUuTW9kZXJhdGlvbl'
    'IPZ3JvdXBNb2RlcmF0aW9uEjwKD3VzZXJfbW9kZXJhdGlvbhgFIAEoDjITLmpvbmxpbmUuTW9k'
    'ZXJhdGlvblIOdXNlck1vZGVyYXRpb24SOQoKY3JlYXRlZF9hdBgGIAEoCzIaLmdvb2dsZS5wcm'
    '90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GAcgASgLMhouZ29vZ2xl'
    'LnByb3RvYnVmLlRpbWVzdGFtcEgAUgl1cGRhdGVkQXSIAQFCDQoLX3VwZGF0ZWRfYXQ=');

@$core.Deprecated('Use contactMethodDescriptor instead')
const ContactMethod$json = {
  '1': 'ContactMethod',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'value', '17': true},
    {'1': 'visibility', '3': 2, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    {'1': 'supported_by_server', '3': 3, '4': 1, '5': 8, '10': 'supportedByServer'},
    {'1': 'verified', '3': 4, '4': 1, '5': 8, '10': 'verified'},
  ],
  '8': [
    {'1': '_value'},
  ],
};

/// Descriptor for `ContactMethod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contactMethodDescriptor = $convert.base64Decode(
    'Cg1Db250YWN0TWV0aG9kEhkKBXZhbHVlGAEgASgJSABSBXZhbHVliAEBEjMKCnZpc2liaWxpdH'
    'kYAiABKA4yEy5qb25saW5lLlZpc2liaWxpdHlSCnZpc2liaWxpdHkSLgoTc3VwcG9ydGVkX2J5'
    'X3NlcnZlchgDIAEoCFIRc3VwcG9ydGVkQnlTZXJ2ZXISGgoIdmVyaWZpZWQYBCABKAhSCHZlcm'
    'lmaWVkQggKBl92YWx1ZQ==');

@$core.Deprecated('Use getUsersRequestDescriptor instead')
const GetUsersRequest$json = {
  '1': 'GetUsersRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'userId', '17': true},
    {'1': 'page', '3': 99, '4': 1, '5': 5, '9': 2, '10': 'page', '17': true},
    {'1': 'listing_type', '3': 100, '4': 1, '5': 14, '6': '.jonline.UserListingType', '10': 'listingType'},
  ],
  '8': [
    {'1': '_username'},
    {'1': '_user_id'},
    {'1': '_page'},
  ],
};

/// Descriptor for `GetUsersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUsersRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRVc2Vyc1JlcXVlc3QSHwoIdXNlcm5hbWUYASABKAlIAFIIdXNlcm5hbWWIAQESHAoHdX'
    'Nlcl9pZBgCIAEoCUgBUgZ1c2VySWSIAQESFwoEcGFnZRhjIAEoBUgCUgRwYWdliAEBEjsKDGxp'
    'c3RpbmdfdHlwZRhkIAEoDjIYLmpvbmxpbmUuVXNlckxpc3RpbmdUeXBlUgtsaXN0aW5nVHlwZU'
    'ILCglfdXNlcm5hbWVCCgoIX3VzZXJfaWRCBwoFX3BhZ2U=');

@$core.Deprecated('Use getUsersResponseDescriptor instead')
const GetUsersResponse$json = {
  '1': 'GetUsersResponse',
  '2': [
    {'1': 'users', '3': 1, '4': 3, '5': 11, '6': '.jonline.User', '10': 'users'},
    {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetUsersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUsersResponseDescriptor = $convert.base64Decode(
    'ChBHZXRVc2Vyc1Jlc3BvbnNlEiMKBXVzZXJzGAEgAygLMg0uam9ubGluZS5Vc2VyUgV1c2Vycx'
    'IiCg1oYXNfbmV4dF9wYWdlGAIgASgIUgtoYXNOZXh0UGFnZQ==');

