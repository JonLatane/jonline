//
//  Generated code. Do not modify.
//  source: location.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use locationDescriptor instead')
const Location$json = {
  '1': 'Location',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'creator_id', '3': 2, '4': 1, '5': 9, '10': 'creatorId'},
    {'1': 'uniformly_formatted_address', '3': 3, '4': 1, '5': 9, '10': 'uniformlyFormattedAddress'},
  ],
};

/// Descriptor for `Location`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locationDescriptor = $convert.base64Decode(
    'CghMb2NhdGlvbhIOCgJpZBgBIAEoCVICaWQSHQoKY3JlYXRvcl9pZBgCIAEoCVIJY3JlYXRvck'
    'lkEj4KG3VuaWZvcm1seV9mb3JtYXR0ZWRfYWRkcmVzcxgDIAEoCVIZdW5pZm9ybWx5Rm9ybWF0'
    'dGVkQWRkcmVzcw==');

@$core.Deprecated('Use locationAliasDescriptor instead')
const LocationAlias$json = {
  '1': 'LocationAlias',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'alias', '3': 2, '4': 1, '5': 9, '10': 'alias'},
    {'1': 'creator_id', '3': 3, '4': 1, '5': 9, '10': 'creatorId'},
  ],
};

/// Descriptor for `LocationAlias`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locationAliasDescriptor = $convert.base64Decode(
    'Cg1Mb2NhdGlvbkFsaWFzEg4KAmlkGAEgASgJUgJpZBIUCgVhbGlhcxgCIAEoCVIFYWxpYXMSHQ'
    'oKY3JlYXRvcl9pZBgDIAEoCVIJY3JlYXRvcklk');

