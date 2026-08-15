//
//  Generated code. Do not modify.
//  source: server_configuration.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use authenticationFeatureDescriptor instead')
const AuthenticationFeature$json = {
  '1': 'AuthenticationFeature',
  '2': [
    {'1': 'AUTHENTICATION_FEATURE_UNKNOWN', '2': 0},
    {'1': 'CREATE_ACCOUNT', '2': 1},
    {'1': 'LOGIN', '2': 2},
  ],
};

/// Descriptor for `AuthenticationFeature`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List authenticationFeatureDescriptor = $convert.base64Decode(
    'ChVBdXRoZW50aWNhdGlvbkZlYXR1cmUSIgoeQVVUSEVOVElDQVRJT05fRkVBVFVSRV9VTktOT1'
    'dOEAASEgoOQ1JFQVRFX0FDQ09VTlQQARIJCgVMT0dJThAC');

@$core.Deprecated('Use calendarDisplayModeDescriptor instead')
const CalendarDisplayMode$json = {
  '1': 'CalendarDisplayMode',
  '2': [
    {'1': 'CALENDAR_DISPLAY_WEEK', '2': 0},
    {'1': 'CALENDAR_DISPLAY_MONTH', '2': 1},
    {'1': 'CALENDAR_DISPLAY_DAY', '2': 3},
  ],
};

/// Descriptor for `CalendarDisplayMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List calendarDisplayModeDescriptor = $convert.base64Decode(
    'ChNDYWxlbmRhckRpc3BsYXlNb2RlEhkKFUNBTEVOREFSX0RJU1BMQVlfV0VFSxAAEhoKFkNBTE'
    'VOREFSX0RJU1BMQVlfTU9OVEgQARIYChRDQUxFTkRBUl9ESVNQTEFZX0RBWRAD');

@$core.Deprecated('Use privateUserStrategyDescriptor instead')
const PrivateUserStrategy$json = {
  '1': 'PrivateUserStrategy',
  '2': [
    {'1': 'ACCOUNT_IS_FROZEN', '2': 0},
    {'1': 'LIMITED_CREEPINESS', '2': 1},
    {'1': 'LET_ME_CREEP_ON_PPL', '2': 2},
  ],
};

/// Descriptor for `PrivateUserStrategy`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List privateUserStrategyDescriptor = $convert.base64Decode(
    'ChNQcml2YXRlVXNlclN0cmF0ZWd5EhUKEUFDQ09VTlRfSVNfRlJPWkVOEAASFgoSTElNSVRFRF'
    '9DUkVFUElORVNTEAESFwoTTEVUX01FX0NSRUVQX09OX1BQTBAC');

@$core.Deprecated('Use webUserInterfaceDescriptor instead')
const WebUserInterface$json = {
  '1': 'WebUserInterface',
  '2': [
    {'1': 'FLUTTER_WEB', '2': 0},
    {
      '1': 'HANDLEBARS_TEMPLATES',
      '2': 1,
      '3': {'1': true},
    },
    {'1': 'REACT_TAMAGUI', '2': 2},
    {'1': 'ELM_SPA', '2': 3},
  ],
};

/// Descriptor for `WebUserInterface`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List webUserInterfaceDescriptor = $convert.base64Decode(
    'ChBXZWJVc2VySW50ZXJmYWNlEg8KC0ZMVVRURVJfV0VCEAASHAoUSEFORExFQkFSU19URU1QTE'
    'FURVMQARoCCAESEQoNUkVBQ1RfVEFNQUdVSRACEgsKB0VMTV9TUEEQAw==');

@$core.Deprecated('Use navigationTabDescriptor instead')
const NavigationTab$json = {
  '1': 'NavigationTab',
  '2': [
    {'1': 'HOME_TAB', '2': 0},
    {'1': 'EVENTS_TAB', '2': 10},
    {'1': 'POSTS_TAB', '2': 11},
    {'1': 'PEOPLE_TAB', '2': 12},
    {'1': 'ABOUT_TAB', '2': 15},
  ],
};

/// Descriptor for `NavigationTab`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List navigationTabDescriptor = $convert.base64Decode(
    'Cg1OYXZpZ2F0aW9uVGFiEgwKCEhPTUVfVEFCEAASDgoKRVZFTlRTX1RBQhAKEg0KCVBPU1RTX1'
    'RBQhALEg4KClBFT1BMRV9UQUIQDBINCglBQk9VVF9UQUIQDw==');

@$core.Deprecated('Use serverConfigurationDescriptor instead')
const ServerConfiguration$json = {
  '1': 'ServerConfiguration',
  '2': [
    {'1': 'server_info', '3': 1, '4': 1, '5': 11, '6': '.jonline.ServerInfo', '9': 0, '10': 'serverInfo', '17': true},
    {'1': 'federation_info', '3': 2, '4': 1, '5': 11, '6': '.jonline.FederationInfo', '9': 1, '10': 'federationInfo', '17': true},
    {'1': 'anonymous_user_permissions', '3': 10, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'anonymousUserPermissions'},
    {'1': 'default_user_permissions', '3': 11, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'defaultUserPermissions'},
    {'1': 'basic_user_permissions', '3': 12, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'basicUserPermissions'},
    {'1': 'custom_tabs', '3': 19, '4': 1, '5': 11, '6': '.jonline.CustomNavigationTabSet', '9': 2, '10': 'customTabs', '17': true},
    {'1': 'people_settings', '3': 20, '4': 1, '5': 11, '6': '.jonline.FeatureSettings', '10': 'peopleSettings'},
    {'1': 'group_settings', '3': 21, '4': 1, '5': 11, '6': '.jonline.FeatureSettings', '10': 'groupSettings'},
    {'1': 'post_settings', '3': 22, '4': 1, '5': 11, '6': '.jonline.PostSettings', '10': 'postSettings'},
    {'1': 'event_settings', '3': 23, '4': 1, '5': 11, '6': '.jonline.EventSettings', '10': 'eventSettings'},
    {'1': 'media_settings', '3': 24, '4': 1, '5': 11, '6': '.jonline.MediaSettings', '10': 'mediaSettings'},
    {'1': 'external_cdn_config', '3': 90, '4': 1, '5': 11, '6': '.jonline.ExternalCDNConfig', '9': 3, '10': 'externalCdnConfig', '17': true},
    {'1': 'private_user_strategy', '3': 100, '4': 1, '5': 14, '6': '.jonline.PrivateUserStrategy', '10': 'privateUserStrategy'},
    {'1': 'authentication_features', '3': 101, '4': 3, '5': 14, '6': '.jonline.AuthenticationFeature', '10': 'authenticationFeatures'},
    {'1': 'web_push_config', '3': 110, '4': 1, '5': 11, '6': '.jonline.WebPushConfig', '9': 4, '10': 'webPushConfig', '17': true},
  ],
  '8': [
    {'1': '_server_info'},
    {'1': '_federation_info'},
    {'1': '_custom_tabs'},
    {'1': '_external_cdn_config'},
    {'1': '_web_push_config'},
  ],
};

/// Descriptor for `ServerConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverConfigurationDescriptor = $convert.base64Decode(
    'ChNTZXJ2ZXJDb25maWd1cmF0aW9uEjkKC3NlcnZlcl9pbmZvGAEgASgLMhMuam9ubGluZS5TZX'
    'J2ZXJJbmZvSABSCnNlcnZlckluZm+IAQESRQoPZmVkZXJhdGlvbl9pbmZvGAIgASgLMhcuam9u'
    'bGluZS5GZWRlcmF0aW9uSW5mb0gBUg5mZWRlcmF0aW9uSW5mb4gBARJRChphbm9ueW1vdXNfdX'
    'Nlcl9wZXJtaXNzaW9ucxgKIAMoDjITLmpvbmxpbmUuUGVybWlzc2lvblIYYW5vbnltb3VzVXNl'
    'clBlcm1pc3Npb25zEk0KGGRlZmF1bHRfdXNlcl9wZXJtaXNzaW9ucxgLIAMoDjITLmpvbmxpbm'
    'UuUGVybWlzc2lvblIWZGVmYXVsdFVzZXJQZXJtaXNzaW9ucxJJChZiYXNpY191c2VyX3Blcm1p'
    'c3Npb25zGAwgAygOMhMuam9ubGluZS5QZXJtaXNzaW9uUhRiYXNpY1VzZXJQZXJtaXNzaW9ucx'
    'JFCgtjdXN0b21fdGFicxgTIAEoCzIfLmpvbmxpbmUuQ3VzdG9tTmF2aWdhdGlvblRhYlNldEgC'
    'UgpjdXN0b21UYWJziAEBEkEKD3Blb3BsZV9zZXR0aW5ncxgUIAEoCzIYLmpvbmxpbmUuRmVhdH'
    'VyZVNldHRpbmdzUg5wZW9wbGVTZXR0aW5ncxI/Cg5ncm91cF9zZXR0aW5ncxgVIAEoCzIYLmpv'
    'bmxpbmUuRmVhdHVyZVNldHRpbmdzUg1ncm91cFNldHRpbmdzEjoKDXBvc3Rfc2V0dGluZ3MYFi'
    'ABKAsyFS5qb25saW5lLlBvc3RTZXR0aW5nc1IMcG9zdFNldHRpbmdzEj0KDmV2ZW50X3NldHRp'
    'bmdzGBcgASgLMhYuam9ubGluZS5FdmVudFNldHRpbmdzUg1ldmVudFNldHRpbmdzEj0KDm1lZG'
    'lhX3NldHRpbmdzGBggASgLMhYuam9ubGluZS5NZWRpYVNldHRpbmdzUg1tZWRpYVNldHRpbmdz'
    'Ek8KE2V4dGVybmFsX2Nkbl9jb25maWcYWiABKAsyGi5qb25saW5lLkV4dGVybmFsQ0ROQ29uZm'
    'lnSANSEWV4dGVybmFsQ2RuQ29uZmlniAEBElAKFXByaXZhdGVfdXNlcl9zdHJhdGVneRhkIAEo'
    'DjIcLmpvbmxpbmUuUHJpdmF0ZVVzZXJTdHJhdGVneVITcHJpdmF0ZVVzZXJTdHJhdGVneRJXCh'
    'dhdXRoZW50aWNhdGlvbl9mZWF0dXJlcxhlIAMoDjIeLmpvbmxpbmUuQXV0aGVudGljYXRpb25G'
    'ZWF0dXJlUhZhdXRoZW50aWNhdGlvbkZlYXR1cmVzEkMKD3dlYl9wdXNoX2NvbmZpZxhuIAEoCz'
    'IWLmpvbmxpbmUuV2ViUHVzaENvbmZpZ0gEUg13ZWJQdXNoQ29uZmlniAEBQg4KDF9zZXJ2ZXJf'
    'aW5mb0ISChBfZmVkZXJhdGlvbl9pbmZvQg4KDF9jdXN0b21fdGFic0IWChRfZXh0ZXJuYWxfY2'
    'RuX2NvbmZpZ0ISChBfd2ViX3B1c2hfY29uZmln');

@$core.Deprecated('Use externalCDNConfigDescriptor instead')
const ExternalCDNConfig$json = {
  '1': 'ExternalCDNConfig',
  '2': [
    {'1': 'frontend_host', '3': 1, '4': 1, '5': 9, '10': 'frontendHost'},
    {'1': 'backend_host', '3': 2, '4': 1, '5': 9, '10': 'backendHost'},
    {'1': 'secure_media', '3': 3, '4': 1, '5': 8, '10': 'secureMedia'},
    {'1': 'media_ipv4_allowlist', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'mediaIpv4Allowlist', '17': true},
    {'1': 'media_ipv6_allowlist', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'mediaIpv6Allowlist', '17': true},
    {'1': 'cdn_grpc', '3': 6, '4': 1, '5': 8, '10': 'cdnGrpc'},
  ],
  '8': [
    {'1': '_media_ipv4_allowlist'},
    {'1': '_media_ipv6_allowlist'},
  ],
};

/// Descriptor for `ExternalCDNConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List externalCDNConfigDescriptor = $convert.base64Decode(
    'ChFFeHRlcm5hbENETkNvbmZpZxIjCg1mcm9udGVuZF9ob3N0GAEgASgJUgxmcm9udGVuZEhvc3'
    'QSIQoMYmFja2VuZF9ob3N0GAIgASgJUgtiYWNrZW5kSG9zdBIhCgxzZWN1cmVfbWVkaWEYAyAB'
    'KAhSC3NlY3VyZU1lZGlhEjUKFG1lZGlhX2lwdjRfYWxsb3dsaXN0GAQgASgJSABSEm1lZGlhSX'
    'B2NEFsbG93bGlzdIgBARI1ChRtZWRpYV9pcHY2X2FsbG93bGlzdBgFIAEoCUgBUhJtZWRpYUlw'
    'djZBbGxvd2xpc3SIAQESGQoIY2RuX2dycGMYBiABKAhSB2NkbkdycGNCFwoVX21lZGlhX2lwdj'
    'RfYWxsb3dsaXN0QhcKFV9tZWRpYV9pcHY2X2FsbG93bGlzdA==');

@$core.Deprecated('Use mediaSettingsDescriptor instead')
const MediaSettings$json = {
  '1': 'MediaSettings',
  '2': [
    {'1': 'visible', '3': 1, '4': 1, '5': 8, '10': 'visible'},
    {'1': 'default_moderation', '3': 2, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultModeration'},
    {'1': 'default_visibility', '3': 3, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'defaultVisibility'},
  ],
};

/// Descriptor for `MediaSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaSettingsDescriptor = $convert.base64Decode(
    'Cg1NZWRpYVNldHRpbmdzEhgKB3Zpc2libGUYASABKAhSB3Zpc2libGUSQgoSZGVmYXVsdF9tb2'
    'RlcmF0aW9uGAIgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUhFkZWZhdWx0TW9kZXJhdGlvbhJC'
    'ChJkZWZhdWx0X3Zpc2liaWxpdHkYAyABKA4yEy5qb25saW5lLlZpc2liaWxpdHlSEWRlZmF1bH'
    'RWaXNpYmlsaXR5');

@$core.Deprecated('Use featureSettingsDescriptor instead')
const FeatureSettings$json = {
  '1': 'FeatureSettings',
  '2': [
    {'1': 'visible', '3': 1, '4': 1, '5': 8, '10': 'visible'},
    {'1': 'default_moderation', '3': 2, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultModeration'},
    {'1': 'default_visibility', '3': 3, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'defaultVisibility'},
    {'1': 'alias_singular', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'aliasSingular', '17': true},
    {'1': 'alias_plural', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'aliasPlural', '17': true},
  ],
  '8': [
    {'1': '_alias_singular'},
    {'1': '_alias_plural'},
  ],
};

/// Descriptor for `FeatureSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List featureSettingsDescriptor = $convert.base64Decode(
    'Cg9GZWF0dXJlU2V0dGluZ3MSGAoHdmlzaWJsZRgBIAEoCFIHdmlzaWJsZRJCChJkZWZhdWx0X2'
    '1vZGVyYXRpb24YAiABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SEWRlZmF1bHRNb2RlcmF0aW9u'
    'EkIKEmRlZmF1bHRfdmlzaWJpbGl0eRgDIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIRZGVmYX'
    'VsdFZpc2liaWxpdHkSKgoOYWxpYXNfc2luZ3VsYXIYBCABKAlIAFINYWxpYXNTaW5ndWxhcogB'
    'ARImCgxhbGlhc19wbHVyYWwYBSABKAlIAVILYWxpYXNQbHVyYWyIAQFCEQoPX2FsaWFzX3Npbm'
    'd1bGFyQg8KDV9hbGlhc19wbHVyYWw=');

@$core.Deprecated('Use postSettingsDescriptor instead')
const PostSettings$json = {
  '1': 'PostSettings',
  '2': [
    {'1': 'visible', '3': 1, '4': 1, '5': 8, '10': 'visible'},
    {'1': 'default_moderation', '3': 2, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultModeration'},
    {'1': 'default_visibility', '3': 3, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'defaultVisibility'},
    {'1': 'alias_singular', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'aliasSingular', '17': true},
    {'1': 'alias_plural', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'aliasPlural', '17': true},
    {'1': 'enable_replies', '3': 6, '4': 1, '5': 8, '9': 2, '10': 'enableReplies', '17': true},
  ],
  '8': [
    {'1': '_alias_singular'},
    {'1': '_alias_plural'},
    {'1': '_enable_replies'},
  ],
};

/// Descriptor for `PostSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List postSettingsDescriptor = $convert.base64Decode(
    'CgxQb3N0U2V0dGluZ3MSGAoHdmlzaWJsZRgBIAEoCFIHdmlzaWJsZRJCChJkZWZhdWx0X21vZG'
    'VyYXRpb24YAiABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SEWRlZmF1bHRNb2RlcmF0aW9uEkIK'
    'EmRlZmF1bHRfdmlzaWJpbGl0eRgDIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIRZGVmYXVsdF'
    'Zpc2liaWxpdHkSKgoOYWxpYXNfc2luZ3VsYXIYBCABKAlIAFINYWxpYXNTaW5ndWxhcogBARIm'
    'CgxhbGlhc19wbHVyYWwYBSABKAlIAVILYWxpYXNQbHVyYWyIAQESKgoOZW5hYmxlX3JlcGxpZX'
    'MYBiABKAhIAlINZW5hYmxlUmVwbGllc4gBAUIRCg9fYWxpYXNfc2luZ3VsYXJCDwoNX2FsaWFz'
    'X3BsdXJhbEIRCg9fZW5hYmxlX3JlcGxpZXM=');

@$core.Deprecated('Use eventSettingsDescriptor instead')
const EventSettings$json = {
  '1': 'EventSettings',
  '2': [
    {'1': 'visible', '3': 1, '4': 1, '5': 8, '10': 'visible'},
    {'1': 'default_moderation', '3': 2, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'defaultModeration'},
    {'1': 'default_visibility', '3': 3, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'defaultVisibility'},
    {'1': 'alias_singular', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'aliasSingular', '17': true},
    {'1': 'alias_plural', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'aliasPlural', '17': true},
    {'1': 'enable_replies', '3': 6, '4': 1, '5': 8, '9': 2, '10': 'enableReplies', '17': true},
    {'1': 'calendar_lookback_days', '3': 7, '4': 1, '5': 13, '9': 3, '10': 'calendarLookbackDays', '17': true},
    {'1': 'default_calendar_display_mode', '3': 8, '4': 1, '5': 14, '6': '.jonline.CalendarDisplayMode', '10': 'defaultCalendarDisplayMode'},
  ],
  '8': [
    {'1': '_alias_singular'},
    {'1': '_alias_plural'},
    {'1': '_enable_replies'},
    {'1': '_calendar_lookback_days'},
  ],
};

/// Descriptor for `EventSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventSettingsDescriptor = $convert.base64Decode(
    'Cg1FdmVudFNldHRpbmdzEhgKB3Zpc2libGUYASABKAhSB3Zpc2libGUSQgoSZGVmYXVsdF9tb2'
    'RlcmF0aW9uGAIgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUhFkZWZhdWx0TW9kZXJhdGlvbhJC'
    'ChJkZWZhdWx0X3Zpc2liaWxpdHkYAyABKA4yEy5qb25saW5lLlZpc2liaWxpdHlSEWRlZmF1bH'
    'RWaXNpYmlsaXR5EioKDmFsaWFzX3Npbmd1bGFyGAQgASgJSABSDWFsaWFzU2luZ3VsYXKIAQES'
    'JgoMYWxpYXNfcGx1cmFsGAUgASgJSAFSC2FsaWFzUGx1cmFsiAEBEioKDmVuYWJsZV9yZXBsaW'
    'VzGAYgASgISAJSDWVuYWJsZVJlcGxpZXOIAQESOQoWY2FsZW5kYXJfbG9va2JhY2tfZGF5cxgH'
    'IAEoDUgDUhRjYWxlbmRhckxvb2tiYWNrRGF5c4gBARJfCh1kZWZhdWx0X2NhbGVuZGFyX2Rpc3'
    'BsYXlfbW9kZRgIIAEoDjIcLmpvbmxpbmUuQ2FsZW5kYXJEaXNwbGF5TW9kZVIaZGVmYXVsdENh'
    'bGVuZGFyRGlzcGxheU1vZGVCEQoPX2FsaWFzX3Npbmd1bGFyQg8KDV9hbGlhc19wbHVyYWxCEQ'
    'oPX2VuYWJsZV9yZXBsaWVzQhkKF19jYWxlbmRhcl9sb29rYmFja19kYXlz');

@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo$json = {
  '1': 'ServerInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {'1': 'short_name', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'shortName', '17': true},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'description', '17': true},
    {'1': 'privacy_policy', '3': 4, '4': 1, '5': 9, '9': 3, '10': 'privacyPolicy', '17': true},
    {'1': 'logo', '3': 5, '4': 1, '5': 11, '6': '.jonline.ServerLogo', '9': 4, '10': 'logo', '17': true},
    {'1': 'web_user_interface', '3': 6, '4': 1, '5': 14, '6': '.jonline.WebUserInterface', '9': 5, '10': 'webUserInterface', '17': true},
    {'1': 'colors', '3': 7, '4': 1, '5': 11, '6': '.jonline.ServerColors', '9': 6, '10': 'colors', '17': true},
    {'1': 'media_policy', '3': 8, '4': 1, '5': 9, '9': 7, '10': 'mediaPolicy', '17': true},
    {
      '1': 'recommended_server_hosts',
      '3': 9,
      '4': 3,
      '5': 9,
      '8': {'3': true},
      '10': 'recommendedServerHosts',
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_short_name'},
    {'1': '_description'},
    {'1': '_privacy_policy'},
    {'1': '_logo'},
    {'1': '_web_user_interface'},
    {'1': '_colors'},
    {'1': '_media_policy'},
  ],
};

/// Descriptor for `ServerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverInfoDescriptor = $convert.base64Decode(
    'CgpTZXJ2ZXJJbmZvEhcKBG5hbWUYASABKAlIAFIEbmFtZYgBARIiCgpzaG9ydF9uYW1lGAIgAS'
    'gJSAFSCXNob3J0TmFtZYgBARIlCgtkZXNjcmlwdGlvbhgDIAEoCUgCUgtkZXNjcmlwdGlvbogB'
    'ARIqCg5wcml2YWN5X3BvbGljeRgEIAEoCUgDUg1wcml2YWN5UG9saWN5iAEBEiwKBGxvZ28YBS'
    'ABKAsyEy5qb25saW5lLlNlcnZlckxvZ29IBFIEbG9nb4gBARJMChJ3ZWJfdXNlcl9pbnRlcmZh'
    'Y2UYBiABKA4yGS5qb25saW5lLldlYlVzZXJJbnRlcmZhY2VIBVIQd2ViVXNlckludGVyZmFjZY'
    'gBARIyCgZjb2xvcnMYByABKAsyFS5qb25saW5lLlNlcnZlckNvbG9yc0gGUgZjb2xvcnOIAQES'
    'JgoMbWVkaWFfcG9saWN5GAggASgJSAdSC21lZGlhUG9saWN5iAEBEjwKGHJlY29tbWVuZGVkX3'
    'NlcnZlcl9ob3N0cxgJIAMoCUICGAFSFnJlY29tbWVuZGVkU2VydmVySG9zdHNCBwoFX25hbWVC'
    'DQoLX3Nob3J0X25hbWVCDgoMX2Rlc2NyaXB0aW9uQhEKD19wcml2YWN5X3BvbGljeUIHCgVfbG'
    '9nb0IVChNfd2ViX3VzZXJfaW50ZXJmYWNlQgkKB19jb2xvcnNCDwoNX21lZGlhX3BvbGljeQ==');

@$core.Deprecated('Use serverLogoDescriptor instead')
const ServerLogo$json = {
  '1': 'ServerLogo',
  '2': [
    {'1': 'squareMediaId', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'squareMediaId', '17': true},
    {'1': 'squareMediaIdDark', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'squareMediaIdDark', '17': true},
    {'1': 'wideMediaId', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'wideMediaId', '17': true},
    {'1': 'wideMediaIdDark', '3': 4, '4': 1, '5': 9, '9': 3, '10': 'wideMediaIdDark', '17': true},
  ],
  '8': [
    {'1': '_squareMediaId'},
    {'1': '_squareMediaIdDark'},
    {'1': '_wideMediaId'},
    {'1': '_wideMediaIdDark'},
  ],
};

/// Descriptor for `ServerLogo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverLogoDescriptor = $convert.base64Decode(
    'CgpTZXJ2ZXJMb2dvEikKDXNxdWFyZU1lZGlhSWQYASABKAlIAFINc3F1YXJlTWVkaWFJZIgBAR'
    'IxChFzcXVhcmVNZWRpYUlkRGFyaxgCIAEoCUgBUhFzcXVhcmVNZWRpYUlkRGFya4gBARIlCgt3'
    'aWRlTWVkaWFJZBgDIAEoCUgCUgt3aWRlTWVkaWFJZIgBARItCg93aWRlTWVkaWFJZERhcmsYBC'
    'ABKAlIA1IPd2lkZU1lZGlhSWREYXJriAEBQhAKDl9zcXVhcmVNZWRpYUlkQhQKEl9zcXVhcmVN'
    'ZWRpYUlkRGFya0IOCgxfd2lkZU1lZGlhSWRCEgoQX3dpZGVNZWRpYUlkRGFyaw==');

@$core.Deprecated('Use customNavigationTabSetDescriptor instead')
const CustomNavigationTabSet$json = {
  '1': 'CustomNavigationTabSet',
  '2': [
    {'1': 'home', '3': 1, '4': 1, '5': 11, '6': '.jonline.CustomNavigationTab', '9': 0, '10': 'home', '17': true},
    {'1': 'tabs', '3': 2, '4': 3, '5': 11, '6': '.jonline.CustomNavigationTabWithPath', '10': 'tabs'},
  ],
  '8': [
    {'1': '_home'},
  ],
};

/// Descriptor for `CustomNavigationTabSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List customNavigationTabSetDescriptor = $convert.base64Decode(
    'ChZDdXN0b21OYXZpZ2F0aW9uVGFiU2V0EjUKBGhvbWUYASABKAsyHC5qb25saW5lLkN1c3RvbU'
    '5hdmlnYXRpb25UYWJIAFIEaG9tZYgBARI4CgR0YWJzGAIgAygLMiQuam9ubGluZS5DdXN0b21O'
    'YXZpZ2F0aW9uVGFiV2l0aFBhdGhSBHRhYnNCBwoFX2hvbWU=');

@$core.Deprecated('Use customNavigationTabDescriptor instead')
const CustomNavigationTab$json = {
  '1': 'CustomNavigationTab',
  '2': [
    {'1': 'tab', '3': 1, '4': 1, '5': 14, '6': '.jonline.NavigationTab', '9': 0, '10': 'tab'},
    {'1': 'post_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'postId'},
    {'1': 'emoji_icon', '3': 10, '4': 1, '5': 9, '9': 1, '10': 'emojiIcon'},
    {'1': 'icon_media_id', '3': 11, '4': 1, '5': 9, '9': 1, '10': 'iconMediaId'},
    {'1': 'title', '3': 12, '4': 1, '5': 9, '9': 2, '10': 'title', '17': true},
  ],
  '8': [
    {'1': 'target'},
    {'1': 'icon'},
    {'1': '_title'},
  ],
};

/// Descriptor for `CustomNavigationTab`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List customNavigationTabDescriptor = $convert.base64Decode(
    'ChNDdXN0b21OYXZpZ2F0aW9uVGFiEioKA3RhYhgBIAEoDjIWLmpvbmxpbmUuTmF2aWdhdGlvbl'
    'RhYkgAUgN0YWISGQoHcG9zdF9pZBgCIAEoCUgAUgZwb3N0SWQSHwoKZW1vamlfaWNvbhgKIAEo'
    'CUgBUgllbW9qaUljb24SJAoNaWNvbl9tZWRpYV9pZBgLIAEoCUgBUgtpY29uTWVkaWFJZBIZCg'
    'V0aXRsZRgMIAEoCUgCUgV0aXRsZYgBAUIICgZ0YXJnZXRCBgoEaWNvbkIICgZfdGl0bGU=');

@$core.Deprecated('Use customNavigationTabWithPathDescriptor instead')
const CustomNavigationTabWithPath$json = {
  '1': 'CustomNavigationTabWithPath',
  '2': [
    {'1': 'custom_tab', '3': 1, '4': 1, '5': 11, '6': '.jonline.CustomNavigationTab', '10': 'customTab'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `CustomNavigationTabWithPath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List customNavigationTabWithPathDescriptor = $convert.base64Decode(
    'ChtDdXN0b21OYXZpZ2F0aW9uVGFiV2l0aFBhdGgSOwoKY3VzdG9tX3RhYhgBIAEoCzIcLmpvbm'
    'xpbmUuQ3VzdG9tTmF2aWdhdGlvblRhYlIJY3VzdG9tVGFiEhIKBHBhdGgYAiABKAlSBHBhdGg=');

@$core.Deprecated('Use serverColorsDescriptor instead')
const ServerColors$json = {
  '1': 'ServerColors',
  '2': [
    {'1': 'primary', '3': 1, '4': 1, '5': 13, '9': 0, '10': 'primary', '17': true},
    {'1': 'navigation', '3': 2, '4': 1, '5': 13, '9': 1, '10': 'navigation', '17': true},
    {'1': 'author', '3': 3, '4': 1, '5': 13, '9': 2, '10': 'author', '17': true},
    {'1': 'admin', '3': 4, '4': 1, '5': 13, '9': 3, '10': 'admin', '17': true},
    {'1': 'moderator', '3': 5, '4': 1, '5': 13, '9': 4, '10': 'moderator', '17': true},
  ],
  '8': [
    {'1': '_primary'},
    {'1': '_navigation'},
    {'1': '_author'},
    {'1': '_admin'},
    {'1': '_moderator'},
  ],
};

/// Descriptor for `ServerColors`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverColorsDescriptor = $convert.base64Decode(
    'CgxTZXJ2ZXJDb2xvcnMSHQoHcHJpbWFyeRgBIAEoDUgAUgdwcmltYXJ5iAEBEiMKCm5hdmlnYX'
    'Rpb24YAiABKA1IAVIKbmF2aWdhdGlvbogBARIbCgZhdXRob3IYAyABKA1IAlIGYXV0aG9yiAEB'
    'EhkKBWFkbWluGAQgASgNSANSBWFkbWluiAEBEiEKCW1vZGVyYXRvchgFIAEoDUgEUgltb2Rlcm'
    'F0b3KIAQFCCgoIX3ByaW1hcnlCDQoLX25hdmlnYXRpb25CCQoHX2F1dGhvckIICgZfYWRtaW5C'
    'DAoKX21vZGVyYXRvcg==');

@$core.Deprecated('Use webPushConfigDescriptor instead')
const WebPushConfig$json = {
  '1': 'WebPushConfig',
  '2': [
    {'1': 'public_vapid_key', '3': 1, '4': 1, '5': 9, '10': 'publicVapidKey'},
    {'1': 'private_vapid_key', '3': 2, '4': 1, '5': 9, '10': 'privateVapidKey'},
  ],
};

/// Descriptor for `WebPushConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webPushConfigDescriptor = $convert.base64Decode(
    'Cg1XZWJQdXNoQ29uZmlnEigKEHB1YmxpY192YXBpZF9rZXkYASABKAlSDnB1YmxpY1ZhcGlkS2'
    'V5EioKEXByaXZhdGVfdmFwaWRfa2V5GAIgASgJUg9wcml2YXRlVmFwaWRLZXk=');

