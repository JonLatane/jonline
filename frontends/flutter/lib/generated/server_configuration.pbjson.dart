///
//  Generated code. Do not modify.
//  source: server_configuration.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use authenticationFeatureDescriptor instead')
const AuthenticationFeature$json = const {
  '1': 'AuthenticationFeature',
  '2': const [
    const {'1': 'AUTHENTICATION_FEATURE_UNKNOWN', '2': 0},
    const {'1': 'CREATE_ACCOUNT', '2': 1},
    const {'1': 'LOGIN', '2': 2},
  ],
};

/// Descriptor for `AuthenticationFeature`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List authenticationFeatureDescriptor = $convert.base64Decode('ChVBdXRoZW50aWNhdGlvbkZlYXR1cmUSIgoeQVVUSEVOVElDQVRJT05fRkVBVFVSRV9VTktOT1dOEAASEgoOQ1JFQVRFX0FDQ09VTlQQARIJCgVMT0dJThAC');
@$core.Deprecated('Use privateUserStrategyDescriptor instead')
const PrivateUserStrategy$json = const {
  '1': 'PrivateUserStrategy',
  '2': const [
    const {'1': 'ACCOUNT_IS_FROZEN', '2': 0},
    const {'1': 'LIMITED_CREEPINESS', '2': 1},
    const {'1': 'LET_ME_CREEP_ON_PPL', '2': 2},
  ],
};

/// Descriptor for `PrivateUserStrategy`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List privateUserStrategyDescriptor = $convert.base64Decode('ChNQcml2YXRlVXNlclN0cmF0ZWd5EhUKEUFDQ09VTlRfSVNfRlJPWkVOEAASFgoSTElNSVRFRF9DUkVFUElORVNTEAESFwoTTEVUX01FX0NSRUVQX09OX1BQTBAC');
@$core.Deprecated('Use webUserInterfaceDescriptor instead')
const WebUserInterface$json = const {
  '1': 'WebUserInterface',
  '2': const [
    const {'1': 'FLUTTER_WEB', '2': 0},
    const {
      '1': 'HANDLEBARS_TEMPLATES',
      '2': 1,
      '3': const {'1': true},
    },
    const {'1': 'REACT_TAMAGUI', '2': 2},
  ],
};

/// Descriptor for `WebUserInterface`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List webUserInterfaceDescriptor = $convert.base64Decode('ChBXZWJVc2VySW50ZXJmYWNlEg8KC0ZMVVRURVJfV0VCEAASHAoUSEFORExFQkFSU19URU1QTEFURVMQARoCCAESEQoNUkVBQ1RfVEFNQUdVSRAC');
@$core.Deprecated('Use serverConfigurationDescriptor instead')
const ServerConfiguration$json = const {
  '1': 'ServerConfiguration',
  '2': const [
    const {'1': 'server_info', '3': 1, '4': 1, '5': 11, '6': '.jonline.ServerInfo', '9': 0, '10': 'serverInfo', '17': true},
    const {'1': 'anonymous_user_permissions', '3': 10, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'anonymousUserPermissions'},
    const {'1': 'default_user_permissions', '3': 11, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'defaultUserPermissions'},
    const {'1': 'basic_user_permissions', '3': 12, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'basicUserPermissions'},
    const {'1': 'people_settings', '3': 20, '4': 1, '5': 11, '6': '.jonline.FeatureSettings', '10': 'peopleSettings'},
    const {'1': 'group_settings', '3': 21, '4': 1, '5': 11, '6': '.jonline.FeatureSettings', '10': 'groupSettings'},
    const {'1': 'post_settings', '3': 22, '4': 1, '5': 11, '6': '.jonline.FeatureSettings', '10': 'postSettings'},
    const {'1': 'event_settings', '3': 23, '4': 1, '5': 11, '6': '.jonline.FeatureSettings', '10': 'eventSettings'},
    const {'1': 'private_user_strategy', '3': 100, '4': 1, '5': 14, '6': '.jonline.PrivateUserStrategy', '10': 'privateUserStrategy'},
    const {'1': 'authentication_features', '3': 101, '4': 3, '5': 14, '6': '.jonline.AuthenticationFeature', '10': 'authenticationFeatures'},
  ],
  '8': const [
    const {'1': '_server_info'},
  ],
};

/// Descriptor for `ServerConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverConfigurationDescriptor = $convert.base64Decode('ChNTZXJ2ZXJDb25maWd1cmF0aW9uEjkKC3NlcnZlcl9pbmZvGAEgASgLMhMuam9ubGluZS5TZXJ2ZXJJbmZvSABSCnNlcnZlckluZm+IAQESUQoaYW5vbnltb3VzX3VzZXJfcGVybWlzc2lvbnMYCiADKA4yEy5qb25saW5lLlBlcm1pc3Npb25SGGFub255bW91c1VzZXJQZXJtaXNzaW9ucxJNChhkZWZhdWx0X3VzZXJfcGVybWlzc2lvbnMYCyADKA4yEy5qb25saW5lLlBlcm1pc3Npb25SFmRlZmF1bHRVc2VyUGVybWlzc2lvbnMSSQoWYmFzaWNfdXNlcl9wZXJtaXNzaW9ucxgMIAMoDjITLmpvbmxpbmUuUGVybWlzc2lvblIUYmFzaWNVc2VyUGVybWlzc2lvbnMSQQoPcGVvcGxlX3NldHRpbmdzGBQgASgLMhguam9ubGluZS5GZWF0dXJlU2V0dGluZ3NSDnBlb3BsZVNldHRpbmdzEj8KDmdyb3VwX3NldHRpbmdzGBUgASgLMhguam9ubGluZS5GZWF0dXJlU2V0dGluZ3NSDWdyb3VwU2V0dGluZ3MSPQoNcG9zdF9zZXR0aW5ncxgWIAEoCzIYLmpvbmxpbmUuRmVhdHVyZVNldHRpbmdzUgxwb3N0U2V0dGluZ3MSPwoOZXZlbnRfc2V0dGluZ3MYFyABKAsyGC5qb25saW5lLkZlYXR1cmVTZXR0aW5nc1INZXZlbnRTZXR0aW5ncxJQChVwcml2YXRlX3VzZXJfc3RyYXRlZ3kYZCABKA4yHC5qb25saW5lLlByaXZhdGVVc2VyU3RyYXRlZ3lSE3ByaXZhdGVVc2VyU3RyYXRlZ3kSVwoXYXV0aGVudGljYXRpb25fZmVhdHVyZXMYZSADKA4yHi5qb25saW5lLkF1dGhlbnRpY2F0aW9uRmVhdHVyZVIWYXV0aGVudGljYXRpb25GZWF0dXJlc0IOCgxfc2VydmVyX2luZm8=');
@$core.Deprecated('Use featureSettingsDescriptor instead')
const FeatureSettings$json = const {
  '1': 'FeatureSettings',
  '2': const [
    const {'1': 'visible', '3': 1, '4': 1, '5': 8, '10': 'visible'},
    const {'1': 'default_moderation', '3': 2, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultModeration'},
    const {'1': 'default_visibility', '3': 3, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'defaultVisibility'},
    const {'1': 'custom_title', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'customTitle', '17': true},
  ],
  '8': const [
    const {'1': '_custom_title'},
  ],
};

/// Descriptor for `FeatureSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List featureSettingsDescriptor = $convert.base64Decode('Cg9GZWF0dXJlU2V0dGluZ3MSGAoHdmlzaWJsZRgBIAEoCFIHdmlzaWJsZRJCChJkZWZhdWx0X21vZGVyYXRpb24YAiABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SEWRlZmF1bHRNb2RlcmF0aW9uEkIKEmRlZmF1bHRfdmlzaWJpbGl0eRgDIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIRZGVmYXVsdFZpc2liaWxpdHkSJgoMY3VzdG9tX3RpdGxlGAQgASgJSABSC2N1c3RvbVRpdGxliAEBQg8KDV9jdXN0b21fdGl0bGU=');
@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo$json = const {
  '1': 'ServerInfo',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    const {'1': 'short_name', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'shortName', '17': true},
    const {'1': 'description', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'description', '17': true},
    const {'1': 'privacy_policy_link', '3': 4, '4': 1, '5': 9, '9': 3, '10': 'privacyPolicyLink', '17': true},
    const {'1': 'about_link', '3': 5, '4': 1, '5': 9, '9': 4, '10': 'aboutLink', '17': true},
    const {'1': 'web_user_interface', '3': 6, '4': 1, '5': 14, '6': '.jonline.WebUserInterface', '9': 5, '10': 'webUserInterface', '17': true},
    const {'1': 'colors', '3': 7, '4': 1, '5': 11, '6': '.jonline.ServerColors', '9': 6, '10': 'colors', '17': true},
    const {'1': 'logo', '3': 8, '4': 1, '5': 12, '9': 7, '10': 'logo', '17': true},
  ],
  '8': const [
    const {'1': '_name'},
    const {'1': '_short_name'},
    const {'1': '_description'},
    const {'1': '_privacy_policy_link'},
    const {'1': '_about_link'},
    const {'1': '_web_user_interface'},
    const {'1': '_colors'},
    const {'1': '_logo'},
  ],
};

/// Descriptor for `ServerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverInfoDescriptor = $convert.base64Decode('CgpTZXJ2ZXJJbmZvEhcKBG5hbWUYASABKAlIAFIEbmFtZYgBARIiCgpzaG9ydF9uYW1lGAIgASgJSAFSCXNob3J0TmFtZYgBARIlCgtkZXNjcmlwdGlvbhgDIAEoCUgCUgtkZXNjcmlwdGlvbogBARIzChNwcml2YWN5X3BvbGljeV9saW5rGAQgASgJSANSEXByaXZhY3lQb2xpY3lMaW5riAEBEiIKCmFib3V0X2xpbmsYBSABKAlIBFIJYWJvdXRMaW5riAEBEkwKEndlYl91c2VyX2ludGVyZmFjZRgGIAEoDjIZLmpvbmxpbmUuV2ViVXNlckludGVyZmFjZUgFUhB3ZWJVc2VySW50ZXJmYWNliAEBEjIKBmNvbG9ycxgHIAEoCzIVLmpvbmxpbmUuU2VydmVyQ29sb3JzSAZSBmNvbG9yc4gBARIXCgRsb2dvGAggASgMSAdSBGxvZ2+IAQFCBwoFX25hbWVCDQoLX3Nob3J0X25hbWVCDgoMX2Rlc2NyaXB0aW9uQhYKFF9wcml2YWN5X3BvbGljeV9saW5rQg0KC19hYm91dF9saW5rQhUKE193ZWJfdXNlcl9pbnRlcmZhY2VCCQoHX2NvbG9yc0IHCgVfbG9nbw==');
@$core.Deprecated('Use serverColorsDescriptor instead')
const ServerColors$json = const {
  '1': 'ServerColors',
  '2': const [
    const {'1': 'primary', '3': 1, '4': 1, '5': 13, '9': 0, '10': 'primary', '17': true},
    const {'1': 'navigation', '3': 2, '4': 1, '5': 13, '9': 1, '10': 'navigation', '17': true},
    const {'1': 'author', '3': 3, '4': 1, '5': 13, '9': 2, '10': 'author', '17': true},
    const {'1': 'admin', '3': 4, '4': 1, '5': 13, '9': 3, '10': 'admin', '17': true},
    const {'1': 'moderator', '3': 5, '4': 1, '5': 13, '9': 4, '10': 'moderator', '17': true},
  ],
  '8': const [
    const {'1': '_primary'},
    const {'1': '_navigation'},
    const {'1': '_author'},
    const {'1': '_admin'},
    const {'1': '_moderator'},
  ],
};

/// Descriptor for `ServerColors`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverColorsDescriptor = $convert.base64Decode('CgxTZXJ2ZXJDb2xvcnMSHQoHcHJpbWFyeRgBIAEoDUgAUgdwcmltYXJ5iAEBEiMKCm5hdmlnYXRpb24YAiABKA1IAVIKbmF2aWdhdGlvbogBARIbCgZhdXRob3IYAyABKA1IAlIGYXV0aG9yiAEBEhkKBWFkbWluGAQgASgNSANSBWFkbWluiAEBEiEKCW1vZGVyYXRvchgFIAEoDUgEUgltb2RlcmF0b3KIAQFCCgoIX3ByaW1hcnlCDQoLX25hdmlnYXRpb25CCQoHX2F1dGhvckIICgZfYWRtaW5CDAoKX21vZGVyYXRvcg==');
