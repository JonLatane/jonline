///
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use groupListingTypeDescriptor instead')
const GroupListingType$json = const {
  '1': 'GroupListingType',
  '2': const [
    const {'1': 'ALL_GROUPS', '2': 0},
    const {'1': 'MY_GROUPS', '2': 1},
    const {'1': 'REQUESTED_GROUPS', '2': 2},
    const {'1': 'INVITED_GROUPS', '2': 3},
  ],
};

/// Descriptor for `GroupListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List groupListingTypeDescriptor = $convert.base64Decode('ChBHcm91cExpc3RpbmdUeXBlEg4KCkFMTF9HUk9VUFMQABINCglNWV9HUk9VUFMQARIUChBSRVFVRVNURURfR1JPVVBTEAISEgoOSU5WSVRFRF9HUk9VUFMQAw==');
@$core.Deprecated('Use groupDescriptor instead')
const Group$json = const {
  '1': 'Group',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'shortname', '3': 3, '4': 1, '5': 9, '10': 'shortname'},
    const {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    const {'1': 'avatar_media_id', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'avatarMediaId', '17': true},
    const {'1': 'default_membership_permissions', '3': 6, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'defaultMembershipPermissions'},
    const {'1': 'default_membership_moderation', '3': 7, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultMembershipModeration'},
    const {'1': 'default_post_moderation', '3': 8, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultPostModeration'},
    const {'1': 'default_event_moderation', '3': 9, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultEventModeration'},
    const {'1': 'visibility', '3': 10, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    const {'1': 'member_count', '3': 11, '4': 1, '5': 13, '10': 'memberCount'},
    const {'1': 'post_count', '3': 12, '4': 1, '5': 13, '10': 'postCount'},
    const {'1': 'current_user_membership', '3': 13, '4': 1, '5': 11, '6': '.jonline.Membership', '9': 1, '10': 'currentUserMembership', '17': true},
    const {'1': 'created_at', '3': 14, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    const {'1': 'updated_at', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'updatedAt', '17': true},
  ],
  '8': const [
    const {'1': '_avatar_media_id'},
    const {'1': '_current_user_membership'},
    const {'1': '_updated_at'},
  ],
};

/// Descriptor for `Group`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDescriptor = $convert.base64Decode('CgVHcm91cBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIcCglzaG9ydG5hbWUYAyABKAlSCXNob3J0bmFtZRIgCgtkZXNjcmlwdGlvbhgEIAEoCVILZGVzY3JpcHRpb24SKwoPYXZhdGFyX21lZGlhX2lkGAUgASgJSABSDWF2YXRhck1lZGlhSWSIAQESWQoeZGVmYXVsdF9tZW1iZXJzaGlwX3Blcm1pc3Npb25zGAYgAygOMhMuam9ubGluZS5QZXJtaXNzaW9uUhxkZWZhdWx0TWVtYmVyc2hpcFBlcm1pc3Npb25zElcKHWRlZmF1bHRfbWVtYmVyc2hpcF9tb2RlcmF0aW9uGAcgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUhtkZWZhdWx0TWVtYmVyc2hpcE1vZGVyYXRpb24SSwoXZGVmYXVsdF9wb3N0X21vZGVyYXRpb24YCCABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SFWRlZmF1bHRQb3N0TW9kZXJhdGlvbhJNChhkZWZhdWx0X2V2ZW50X21vZGVyYXRpb24YCSABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SFmRlZmF1bHRFdmVudE1vZGVyYXRpb24SMwoKdmlzaWJpbGl0eRgKIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIKdmlzaWJpbGl0eRIhCgxtZW1iZXJfY291bnQYCyABKA1SC21lbWJlckNvdW50Eh0KCnBvc3RfY291bnQYDCABKA1SCXBvc3RDb3VudBJQChdjdXJyZW50X3VzZXJfbWVtYmVyc2hpcBgNIAEoCzITLmpvbmxpbmUuTWVtYmVyc2hpcEgBUhVjdXJyZW50VXNlck1lbWJlcnNoaXCIAQESOQoKY3JlYXRlZF9hdBgOIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GA8gASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgCUgl1cGRhdGVkQXSIAQFCEgoQX2F2YXRhcl9tZWRpYV9pZEIaChhfY3VycmVudF91c2VyX21lbWJlcnNoaXBCDQoLX3VwZGF0ZWRfYXQ=');
@$core.Deprecated('Use getGroupsRequestDescriptor instead')
const GetGroupsRequest$json = const {
  '1': 'GetGroupsRequest',
  '2': const [
    const {'1': 'group_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'groupId', '17': true},
    const {'1': 'group_name', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'groupName', '17': true},
    const {'1': 'group_shortname', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'groupShortname', '17': true},
    const {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.jonline.GroupListingType', '10': 'listingType'},
    const {'1': 'page', '3': 11, '4': 1, '5': 5, '9': 3, '10': 'page', '17': true},
  ],
  '8': const [
    const {'1': '_group_id'},
    const {'1': '_group_name'},
    const {'1': '_group_shortname'},
    const {'1': '_page'},
  ],
};

/// Descriptor for `GetGroupsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupsRequestDescriptor = $convert.base64Decode('ChBHZXRHcm91cHNSZXF1ZXN0Eh4KCGdyb3VwX2lkGAEgASgJSABSB2dyb3VwSWSIAQESIgoKZ3JvdXBfbmFtZRgCIAEoCUgBUglncm91cE5hbWWIAQESLAoPZ3JvdXBfc2hvcnRuYW1lGAMgASgJSAJSDmdyb3VwU2hvcnRuYW1liAEBEjwKDGxpc3RpbmdfdHlwZRgKIAEoDjIZLmpvbmxpbmUuR3JvdXBMaXN0aW5nVHlwZVILbGlzdGluZ1R5cGUSFwoEcGFnZRgLIAEoBUgDUgRwYWdliAEBQgsKCV9ncm91cF9pZEINCgtfZ3JvdXBfbmFtZUISChBfZ3JvdXBfc2hvcnRuYW1lQgcKBV9wYWdl');
@$core.Deprecated('Use getGroupsResponseDescriptor instead')
const GetGroupsResponse$json = const {
  '1': 'GetGroupsResponse',
  '2': const [
    const {'1': 'groups', '3': 1, '4': 3, '5': 11, '6': '.jonline.Group', '10': 'groups'},
    const {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetGroupsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupsResponseDescriptor = $convert.base64Decode('ChFHZXRHcm91cHNSZXNwb25zZRImCgZncm91cHMYASADKAsyDi5qb25saW5lLkdyb3VwUgZncm91cHMSIgoNaGFzX25leHRfcGFnZRgCIAEoCFILaGFzTmV4dFBhZ2U=');
@$core.Deprecated('Use memberDescriptor instead')
const Member$json = const {
  '1': 'Member',
  '2': const [
    const {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.jonline.User', '10': 'user'},
    const {'1': 'membership', '3': 2, '4': 1, '5': 11, '6': '.jonline.Membership', '10': 'membership'},
  ],
};

/// Descriptor for `Member`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberDescriptor = $convert.base64Decode('CgZNZW1iZXISIQoEdXNlchgBIAEoCzINLmpvbmxpbmUuVXNlclIEdXNlchIzCgptZW1iZXJzaGlwGAIgASgLMhMuam9ubGluZS5NZW1iZXJzaGlwUgptZW1iZXJzaGlw');
@$core.Deprecated('Use getMembersRequestDescriptor instead')
const GetMembersRequest$json = const {
  '1': 'GetMembersRequest',
  '2': const [
    const {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'username', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
    const {'1': 'group_moderation', '3': 3, '4': 1, '5': 14, '6': '.jonline.Moderation', '9': 1, '10': 'groupModeration', '17': true},
    const {'1': 'page', '3': 10, '4': 1, '5': 5, '9': 2, '10': 'page', '17': true},
  ],
  '8': const [
    const {'1': '_username'},
    const {'1': '_group_moderation'},
    const {'1': '_page'},
  ],
};

/// Descriptor for `GetMembersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMembersRequestDescriptor = $convert.base64Decode('ChFHZXRNZW1iZXJzUmVxdWVzdBIZCghncm91cF9pZBgBIAEoCVIHZ3JvdXBJZBIfCgh1c2VybmFtZRgCIAEoCUgAUgh1c2VybmFtZYgBARJDChBncm91cF9tb2RlcmF0aW9uGAMgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uSAFSD2dyb3VwTW9kZXJhdGlvbogBARIXCgRwYWdlGAogASgFSAJSBHBhZ2WIAQFCCwoJX3VzZXJuYW1lQhMKEV9ncm91cF9tb2RlcmF0aW9uQgcKBV9wYWdl');
@$core.Deprecated('Use getMembersResponseDescriptor instead')
const GetMembersResponse$json = const {
  '1': 'GetMembersResponse',
  '2': const [
    const {'1': 'members', '3': 1, '4': 3, '5': 11, '6': '.jonline.Member', '10': 'members'},
    const {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetMembersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMembersResponseDescriptor = $convert.base64Decode('ChJHZXRNZW1iZXJzUmVzcG9uc2USKQoHbWVtYmVycxgBIAMoCzIPLmpvbmxpbmUuTWVtYmVyUgdtZW1iZXJzEiIKDWhhc19uZXh0X3BhZ2UYAiABKAhSC2hhc05leHRQYWdl');
