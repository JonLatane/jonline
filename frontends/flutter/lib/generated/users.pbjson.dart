///
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userListingTypeDescriptor instead')
const UserListingType$json = const {
  '1': 'UserListingType',
  '2': const [
    const {'1': 'EVERYONE', '2': 0},
    const {'1': 'FOLLOWING', '2': 1},
    const {'1': 'FRIENDS', '2': 2},
    const {'1': 'FOLLOWERS', '2': 3},
    const {'1': 'FOLLOW_REQUESTS', '2': 4},
  ],
};

/// Descriptor for `UserListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userListingTypeDescriptor = $convert.base64Decode('Cg9Vc2VyTGlzdGluZ1R5cGUSDAoIRVZFUllPTkUQABINCglGT0xMT1dJTkcQARILCgdGUklFTkRTEAISDQoJRk9MTE9XRVJTEAMSEwoPRk9MTE9XX1JFUVVFU1RTEAQ=');
@$core.Deprecated('Use userDescriptor instead')
const User$json = const {
  '1': 'User',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    const {'1': 'real_name', '3': 3, '4': 1, '5': 9, '10': 'realName'},
    const {'1': 'email', '3': 4, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 0, '10': 'email', '17': true},
    const {'1': 'phone', '3': 5, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 1, '10': 'phone', '17': true},
    const {'1': 'permissions', '3': 6, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'permissions'},
    const {'1': 'avatar_media_id', '3': 7, '4': 1, '5': 9, '9': 2, '10': 'avatarMediaId', '17': true},
    const {'1': 'bio', '3': 8, '4': 1, '5': 9, '10': 'bio'},
    const {'1': 'visibility', '3': 20, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    const {'1': 'moderation', '3': 21, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'moderation'},
    const {'1': 'default_follow_moderation', '3': 30, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultFollowModeration'},
    const {'1': 'follower_count', '3': 31, '4': 1, '5': 5, '9': 3, '10': 'followerCount', '17': true},
    const {'1': 'following_count', '3': 32, '4': 1, '5': 5, '9': 4, '10': 'followingCount', '17': true},
    const {'1': 'group_count', '3': 33, '4': 1, '5': 5, '9': 5, '10': 'groupCount', '17': true},
    const {'1': 'post_count', '3': 34, '4': 1, '5': 5, '9': 6, '10': 'postCount', '17': true},
    const {'1': 'response_count', '3': 35, '4': 1, '5': 5, '9': 7, '10': 'responseCount', '17': true},
    const {'1': 'current_user_follow', '3': 50, '4': 1, '5': 11, '6': '.jonline.Follow', '9': 8, '10': 'currentUserFollow', '17': true},
    const {'1': 'target_current_user_follow', '3': 51, '4': 1, '5': 11, '6': '.jonline.Follow', '9': 9, '10': 'targetCurrentUserFollow', '17': true},
    const {'1': 'current_group_membership', '3': 52, '4': 1, '5': 11, '6': '.jonline.Membership', '9': 10, '10': 'currentGroupMembership', '17': true},
    const {'1': 'created_at', '3': 100, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    const {'1': 'updated_at', '3': 101, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 11, '10': 'updatedAt', '17': true},
  ],
  '8': const [
    const {'1': '_email'},
    const {'1': '_phone'},
    const {'1': '_avatar_media_id'},
    const {'1': '_follower_count'},
    const {'1': '_following_count'},
    const {'1': '_group_count'},
    const {'1': '_post_count'},
    const {'1': '_response_count'},
    const {'1': '_current_user_follow'},
    const {'1': '_target_current_user_follow'},
    const {'1': '_current_group_membership'},
    const {'1': '_updated_at'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode('CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWUSGwoJcmVhbF9uYW1lGAMgASgJUghyZWFsTmFtZRIxCgVlbWFpbBgEIAEoCzIWLmpvbmxpbmUuQ29udGFjdE1ldGhvZEgAUgVlbWFpbIgBARIxCgVwaG9uZRgFIAEoCzIWLmpvbmxpbmUuQ29udGFjdE1ldGhvZEgBUgVwaG9uZYgBARI1CgtwZXJtaXNzaW9ucxgGIAMoDjITLmpvbmxpbmUuUGVybWlzc2lvblILcGVybWlzc2lvbnMSKwoPYXZhdGFyX21lZGlhX2lkGAcgASgJSAJSDWF2YXRhck1lZGlhSWSIAQESEAoDYmlvGAggASgJUgNiaW8SMwoKdmlzaWJpbGl0eRgUIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIKdmlzaWJpbGl0eRIzCgptb2RlcmF0aW9uGBUgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUgptb2RlcmF0aW9uEk8KGWRlZmF1bHRfZm9sbG93X21vZGVyYXRpb24YHiABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SF2RlZmF1bHRGb2xsb3dNb2RlcmF0aW9uEioKDmZvbGxvd2VyX2NvdW50GB8gASgFSANSDWZvbGxvd2VyQ291bnSIAQESLAoPZm9sbG93aW5nX2NvdW50GCAgASgFSARSDmZvbGxvd2luZ0NvdW50iAEBEiQKC2dyb3VwX2NvdW50GCEgASgFSAVSCmdyb3VwQ291bnSIAQESIgoKcG9zdF9jb3VudBgiIAEoBUgGUglwb3N0Q291bnSIAQESKgoOcmVzcG9uc2VfY291bnQYIyABKAVIB1INcmVzcG9uc2VDb3VudIgBARJEChNjdXJyZW50X3VzZXJfZm9sbG93GDIgASgLMg8uam9ubGluZS5Gb2xsb3dICFIRY3VycmVudFVzZXJGb2xsb3eIAQESUQoadGFyZ2V0X2N1cnJlbnRfdXNlcl9mb2xsb3cYMyABKAsyDy5qb25saW5lLkZvbGxvd0gJUhd0YXJnZXRDdXJyZW50VXNlckZvbGxvd4gBARJSChhjdXJyZW50X2dyb3VwX21lbWJlcnNoaXAYNCABKAsyEy5qb25saW5lLk1lbWJlcnNoaXBIClIWY3VycmVudEdyb3VwTWVtYmVyc2hpcIgBARI5CgpjcmVhdGVkX2F0GGQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0Ej4KCnVwZGF0ZWRfYXQYZSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSAtSCXVwZGF0ZWRBdIgBAUIICgZfZW1haWxCCAoGX3Bob25lQhIKEF9hdmF0YXJfbWVkaWFfaWRCEQoPX2ZvbGxvd2VyX2NvdW50QhIKEF9mb2xsb3dpbmdfY291bnRCDgoMX2dyb3VwX2NvdW50Qg0KC19wb3N0X2NvdW50QhEKD19yZXNwb25zZV9jb3VudEIWChRfY3VycmVudF91c2VyX2ZvbGxvd0IdChtfdGFyZ2V0X2N1cnJlbnRfdXNlcl9mb2xsb3dCGwoZX2N1cnJlbnRfZ3JvdXBfbWVtYmVyc2hpcEINCgtfdXBkYXRlZF9hdA==');
@$core.Deprecated('Use followDescriptor instead')
const Follow$json = const {
  '1': 'Follow',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'target_user_id', '3': 2, '4': 1, '5': 9, '10': 'targetUserId'},
    const {'1': 'target_user_moderation', '3': 3, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'targetUserModeration'},
    const {'1': 'created_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    const {'1': 'updated_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'updatedAt', '17': true},
  ],
  '8': const [
    const {'1': '_updated_at'},
  ],
};

/// Descriptor for `Follow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List followDescriptor = $convert.base64Decode('CgZGb2xsb3cSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEiQKDnRhcmdldF91c2VyX2lkGAIgASgJUgx0YXJnZXRVc2VySWQSSQoWdGFyZ2V0X3VzZXJfbW9kZXJhdGlvbhgDIAEoDjITLmpvbmxpbmUuTW9kZXJhdGlvblIUdGFyZ2V0VXNlck1vZGVyYXRpb24SOQoKY3JlYXRlZF9hdBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUgl1cGRhdGVkQXSIAQFCDQoLX3VwZGF0ZWRfYXQ=');
@$core.Deprecated('Use membershipDescriptor instead')
const Membership$json = const {
  '1': 'Membership',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'group_id', '3': 2, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'permissions', '3': 3, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'permissions'},
    const {'1': 'group_moderation', '3': 4, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'groupModeration'},
    const {'1': 'user_moderation', '3': 5, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'userModeration'},
    const {'1': 'created_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    const {'1': 'updated_at', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'updatedAt', '17': true},
  ],
  '8': const [
    const {'1': '_updated_at'},
  ],
};

/// Descriptor for `Membership`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List membershipDescriptor = $convert.base64Decode('CgpNZW1iZXJzaGlwEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIZCghncm91cF9pZBgCIAEoCVIHZ3JvdXBJZBI1CgtwZXJtaXNzaW9ucxgDIAMoDjITLmpvbmxpbmUuUGVybWlzc2lvblILcGVybWlzc2lvbnMSPgoQZ3JvdXBfbW9kZXJhdGlvbhgEIAEoDjITLmpvbmxpbmUuTW9kZXJhdGlvblIPZ3JvdXBNb2RlcmF0aW9uEjwKD3VzZXJfbW9kZXJhdGlvbhgFIAEoDjITLmpvbmxpbmUuTW9kZXJhdGlvblIOdXNlck1vZGVyYXRpb24SOQoKY3JlYXRlZF9hdBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUgl1cGRhdGVkQXSIAQFCDQoLX3VwZGF0ZWRfYXQ=');
@$core.Deprecated('Use contactMethodDescriptor instead')
const ContactMethod$json = const {
  '1': 'ContactMethod',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'value', '17': true},
    const {'1': 'visibility', '3': 2, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
  ],
  '8': const [
    const {'1': '_value'},
  ],
};

/// Descriptor for `ContactMethod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contactMethodDescriptor = $convert.base64Decode('Cg1Db250YWN0TWV0aG9kEhkKBXZhbHVlGAEgASgJSABSBXZhbHVliAEBEjMKCnZpc2liaWxpdHkYAiABKA4yEy5qb25saW5lLlZpc2liaWxpdHlSCnZpc2liaWxpdHlCCAoGX3ZhbHVl');
@$core.Deprecated('Use getUsersRequestDescriptor instead')
const GetUsersRequest$json = const {
  '1': 'GetUsersRequest',
  '2': const [
    const {'1': 'username', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
    const {'1': 'user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'userId', '17': true},
    const {'1': 'page', '3': 99, '4': 1, '5': 5, '9': 2, '10': 'page', '17': true},
    const {'1': 'listing_type', '3': 100, '4': 1, '5': 14, '6': '.jonline.UserListingType', '10': 'listingType'},
  ],
  '8': const [
    const {'1': '_username'},
    const {'1': '_user_id'},
    const {'1': '_page'},
  ],
};

/// Descriptor for `GetUsersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUsersRequestDescriptor = $convert.base64Decode('Cg9HZXRVc2Vyc1JlcXVlc3QSHwoIdXNlcm5hbWUYASABKAlIAFIIdXNlcm5hbWWIAQESHAoHdXNlcl9pZBgCIAEoCUgBUgZ1c2VySWSIAQESFwoEcGFnZRhjIAEoBUgCUgRwYWdliAEBEjsKDGxpc3RpbmdfdHlwZRhkIAEoDjIYLmpvbmxpbmUuVXNlckxpc3RpbmdUeXBlUgtsaXN0aW5nVHlwZUILCglfdXNlcm5hbWVCCgoIX3VzZXJfaWRCBwoFX3BhZ2U=');
@$core.Deprecated('Use getUsersResponseDescriptor instead')
const GetUsersResponse$json = const {
  '1': 'GetUsersResponse',
  '2': const [
    const {'1': 'users', '3': 1, '4': 3, '5': 11, '6': '.jonline.User', '10': 'users'},
    const {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetUsersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUsersResponseDescriptor = $convert.base64Decode('ChBHZXRVc2Vyc1Jlc3BvbnNlEiMKBXVzZXJzGAEgAygLMg0uam9ubGluZS5Vc2VyUgV1c2VycxIiCg1oYXNfbmV4dF9wYWdlGAIgASgIUgtoYXNOZXh0UGFnZQ==');
