//
//  Generated code. Do not modify.
//  source: sync.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// The HTTP `User-Agent` a [`SyncSource`](#rellm-SyncSource) sends when fetching its feed. Some feeds
/// sit behind bot protection that only admits certain clients (e.g. raleighnc.gov's Cloudflare rules let
/// `curl/*` through and challenge everything else, including a request with no `User-Agent` at all).
class SyncSourceUserAgent extends $pb.ProtobufEnum {
  static const SyncSourceUserAgent NO_USER_AGENT = SyncSourceUserAgent._(0, _omitEnumNames ? '' : 'NO_USER_AGENT');
  static const SyncSourceUserAgent RELLM = SyncSourceUserAgent._(1, _omitEnumNames ? '' : 'RELLM');
  static const SyncSourceUserAgent CURL = SyncSourceUserAgent._(2, _omitEnumNames ? '' : 'CURL');

  static const $core.List<SyncSourceUserAgent> values = <SyncSourceUserAgent> [
    NO_USER_AGENT,
    RELLM,
    CURL,
  ];

  static final $core.Map<$core.int, SyncSourceUserAgent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SyncSourceUserAgent? valueOf($core.int value) => _byValue[value];

  const SyncSourceUserAgent._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
