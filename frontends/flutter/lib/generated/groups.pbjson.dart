//
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use groupListingTypeDescriptor instead')
const GroupListingType$json = {
  '1': 'GroupListingType',
  '2': [
    {'1': 'ALL_GROUPS', '2': 0},
    {'1': 'MY_GROUPS', '2': 1},
    {'1': 'REQUESTED_GROUPS', '2': 2},
    {'1': 'INVITED_GROUPS', '2': 3},
  ],
};

/// Descriptor for `GroupListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List groupListingTypeDescriptor = $convert.base64Decode(
    'ChBHcm91cExpc3RpbmdUeXBlEg4KCkFMTF9HUk9VUFMQABINCglNWV9HUk9VUFMQARIUChBSRV'
    'FVRVNURURfR1JPVVBTEAISEgoOSU5WSVRFRF9HUk9VUFMQAw==');

@$core.Deprecated('Use groupDescriptor instead')
const Group$json = {
  '1': 'Group',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'shortname', '3': 3, '4': 1, '5': 9, '10': 'shortname'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {'1': 'avatar', '3': 5, '4': 1, '5': 11, '6': '.jonline.MediaReference', '9': 0, '10': 'avatar', '17': true},
    {'1': 'default_membership_permissions', '3': 6, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'defaultMembershipPermissions'},
    {'1': 'default_membership_moderation', '3': 7, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultMembershipModeration'},
    {'1': 'default_post_moderation', '3': 8, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultPostModeration'},
    {'1': 'default_event_moderation', '3': 9, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultEventModeration'},
    {'1': 'visibility', '3': 10, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    {'1': 'member_count', '3': 11, '4': 1, '5': 13, '10': 'memberCount'},
    {'1': 'post_count', '3': 12, '4': 1, '5': 13, '10': 'postCount'},
    {'1': 'event_count', '3': 13, '4': 1, '5': 13, '10': 'eventCount'},
    {'1': 'non_member_permissions', '3': 18, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'nonMemberPermissions'},
    {'1': 'current_user_membership', '3': 19, '4': 1, '5': 11, '6': '.jonline.Membership', '9': 1, '10': 'currentUserMembership', '17': true},
    {'1': 'created_at', '3': 20, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 21, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': '_avatar'},
    {'1': '_current_user_membership'},
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `Group`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDescriptor = $convert.base64Decode(
    'CgVHcm91cBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIcCglzaG9ydG5hbW'
    'UYAyABKAlSCXNob3J0bmFtZRIgCgtkZXNjcmlwdGlvbhgEIAEoCVILZGVzY3JpcHRpb24SNAoG'
    'YXZhdGFyGAUgASgLMhcuam9ubGluZS5NZWRpYVJlZmVyZW5jZUgAUgZhdmF0YXKIAQESWQoeZG'
    'VmYXVsdF9tZW1iZXJzaGlwX3Blcm1pc3Npb25zGAYgAygOMhMuam9ubGluZS5QZXJtaXNzaW9u'
    'UhxkZWZhdWx0TWVtYmVyc2hpcFBlcm1pc3Npb25zElcKHWRlZmF1bHRfbWVtYmVyc2hpcF9tb2'
    'RlcmF0aW9uGAcgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUhtkZWZhdWx0TWVtYmVyc2hpcE1v'
    'ZGVyYXRpb24SSwoXZGVmYXVsdF9wb3N0X21vZGVyYXRpb24YCCABKA4yEy5qb25saW5lLk1vZG'
    'VyYXRpb25SFWRlZmF1bHRQb3N0TW9kZXJhdGlvbhJNChhkZWZhdWx0X2V2ZW50X21vZGVyYXRp'
    'b24YCSABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SFmRlZmF1bHRFdmVudE1vZGVyYXRpb24SMw'
    'oKdmlzaWJpbGl0eRgKIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIKdmlzaWJpbGl0eRIhCgxt'
    'ZW1iZXJfY291bnQYCyABKA1SC21lbWJlckNvdW50Eh0KCnBvc3RfY291bnQYDCABKA1SCXBvc3'
    'RDb3VudBIfCgtldmVudF9jb3VudBgNIAEoDVIKZXZlbnRDb3VudBJJChZub25fbWVtYmVyX3Bl'
    'cm1pc3Npb25zGBIgAygOMhMuam9ubGluZS5QZXJtaXNzaW9uUhRub25NZW1iZXJQZXJtaXNzaW'
    '9ucxJQChdjdXJyZW50X3VzZXJfbWVtYmVyc2hpcBgTIAEoCzITLmpvbmxpbmUuTWVtYmVyc2hp'
    'cEgBUhVjdXJyZW50VXNlck1lbWJlcnNoaXCIAQESOQoKY3JlYXRlZF9hdBgUIAEoCzIaLmdvb2'
    'dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GBUgASgLMhou'
    'Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgCUgl1cGRhdGVkQXSIAQFCCQoHX2F2YXRhckIaCh'
    'hfY3VycmVudF91c2VyX21lbWJlcnNoaXBCDQoLX3VwZGF0ZWRfYXQ=');

@$core.Deprecated('Use getGroupsRequestDescriptor instead')
const GetGroupsRequest$json = {
  '1': 'GetGroupsRequest',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'groupId', '17': true},
    {'1': 'group_name', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'groupName', '17': true},
    {'1': 'group_shortname', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'groupShortname', '17': true},
    {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.jonline.GroupListingType', '10': 'listingType'},
    {'1': 'page', '3': 11, '4': 1, '5': 5, '9': 3, '10': 'page', '17': true},
  ],
  '8': [
    {'1': '_group_id'},
    {'1': '_group_name'},
    {'1': '_group_shortname'},
    {'1': '_page'},
  ],
};

/// Descriptor for `GetGroupsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupsRequestDescriptor = $convert.base64Decode(
    'ChBHZXRHcm91cHNSZXF1ZXN0Eh4KCGdyb3VwX2lkGAEgASgJSABSB2dyb3VwSWSIAQESIgoKZ3'
    'JvdXBfbmFtZRgCIAEoCUgBUglncm91cE5hbWWIAQESLAoPZ3JvdXBfc2hvcnRuYW1lGAMgASgJ'
    'SAJSDmdyb3VwU2hvcnRuYW1liAEBEjwKDGxpc3RpbmdfdHlwZRgKIAEoDjIZLmpvbmxpbmUuR3'
    'JvdXBMaXN0aW5nVHlwZVILbGlzdGluZ1R5cGUSFwoEcGFnZRgLIAEoBUgDUgRwYWdliAEBQgsK'
    'CV9ncm91cF9pZEINCgtfZ3JvdXBfbmFtZUISChBfZ3JvdXBfc2hvcnRuYW1lQgcKBV9wYWdl');

@$core.Deprecated('Use getGroupsResponseDescriptor instead')
const GetGroupsResponse$json = {
  '1': 'GetGroupsResponse',
  '2': [
    {'1': 'groups', '3': 1, '4': 3, '5': 11, '6': '.jonline.Group', '10': 'groups'},
    {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetGroupsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupsResponseDescriptor = $convert.base64Decode(
    'ChFHZXRHcm91cHNSZXNwb25zZRImCgZncm91cHMYASADKAsyDi5qb25saW5lLkdyb3VwUgZncm'
    '91cHMSIgoNaGFzX25leHRfcGFnZRgCIAEoCFILaGFzTmV4dFBhZ2U=');

@$core.Deprecated('Use memberDescriptor instead')
const Member$json = {
  '1': 'Member',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.jonline.User', '10': 'user'},
    {'1': 'membership', '3': 2, '4': 1, '5': 11, '6': '.jonline.Membership', '10': 'membership'},
  ],
};

/// Descriptor for `Member`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberDescriptor = $convert.base64Decode(
    'CgZNZW1iZXISIQoEdXNlchgBIAEoCzINLmpvbmxpbmUuVXNlclIEdXNlchIzCgptZW1iZXJzaG'
    'lwGAIgASgLMhMuam9ubGluZS5NZW1iZXJzaGlwUgptZW1iZXJzaGlw');

@$core.Deprecated('Use getMembersRequestDescriptor instead')
const GetMembersRequest$json = {
  '1': 'GetMembersRequest',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
    {'1': 'group_moderation', '3': 3, '4': 1, '5': 14, '6': '.jonline.Moderation', '9': 1, '10': 'groupModeration', '17': true},
    {'1': 'page', '3': 10, '4': 1, '5': 5, '9': 2, '10': 'page', '17': true},
  ],
  '8': [
    {'1': '_username'},
    {'1': '_group_moderation'},
    {'1': '_page'},
  ],
};

/// Descriptor for `GetMembersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMembersRequestDescriptor = $convert.base64Decode(
    'ChFHZXRNZW1iZXJzUmVxdWVzdBIZCghncm91cF9pZBgBIAEoCVIHZ3JvdXBJZBIfCgh1c2Vybm'
    'FtZRgCIAEoCUgAUgh1c2VybmFtZYgBARJDChBncm91cF9tb2RlcmF0aW9uGAMgASgOMhMuam9u'
    'bGluZS5Nb2RlcmF0aW9uSAFSD2dyb3VwTW9kZXJhdGlvbogBARIXCgRwYWdlGAogASgFSAJSBH'
    'BhZ2WIAQFCCwoJX3VzZXJuYW1lQhMKEV9ncm91cF9tb2RlcmF0aW9uQgcKBV9wYWdl');

@$core.Deprecated('Use getMembersResponseDescriptor instead')
const GetMembersResponse$json = {
  '1': 'GetMembersResponse',
  '2': [
    {'1': 'members', '3': 1, '4': 3, '5': 11, '6': '.jonline.Member', '10': 'members'},
    {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetMembersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMembersResponseDescriptor = $convert.base64Decode(
    'ChJHZXRNZW1iZXJzUmVzcG9uc2USKQoHbWVtYmVycxgBIAMoCzIPLmpvbmxpbmUuTWVtYmVyUg'
    'dtZW1iZXJzEiIKDWhhc19uZXh0X3BhZ2UYAiABKAhSC2hhc05leHRQYWdl');

