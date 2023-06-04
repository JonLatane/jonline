///
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class EventListingType extends $pb.ProtobufEnum {
  static const EventListingType PUBLIC_EVENTS = EventListingType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLIC_EVENTS');
  static const EventListingType FOLLOWING_EVENTS = EventListingType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FOLLOWING_EVENTS');
  static const EventListingType MY_GROUPS_EVENTS = EventListingType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MY_GROUPS_EVENTS');
  static const EventListingType DIRECT_EVENTS = EventListingType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DIRECT_EVENTS');
  static const EventListingType EVENTS_PENDING_MODERATION = EventListingType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EVENTS_PENDING_MODERATION');
  static const EventListingType GROUP_EVENTS = EventListingType._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GROUP_EVENTS');
  static const EventListingType GROUP_EVENTS_PENDING_MODERATION = EventListingType._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GROUP_EVENTS_PENDING_MODERATION');

  static const $core.List<EventListingType> values = <EventListingType> [
    PUBLIC_EVENTS,
    FOLLOWING_EVENTS,
    MY_GROUPS_EVENTS,
    DIRECT_EVENTS,
    EVENTS_PENDING_MODERATION,
    GROUP_EVENTS,
    GROUP_EVENTS_PENDING_MODERATION,
  ];

  static final $core.Map<$core.int, EventListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EventListingType? valueOf($core.int value) => _byValue[value];

  const EventListingType._($core.int v, $core.String n) : super(v, n);
}

class AttendanceStatus extends $pb.ProtobufEnum {
  static const AttendanceStatus INTERESTED = AttendanceStatus._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INTERESTED');
  static const AttendanceStatus GOING = AttendanceStatus._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GOING');
  static const AttendanceStatus NOT_GOING = AttendanceStatus._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NOT_GOING');
  static const AttendanceStatus REQUESTED = AttendanceStatus._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REQUESTED');
  static const AttendanceStatus WENT = AttendanceStatus._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WENT');
  static const AttendanceStatus DID_NOT_GO = AttendanceStatus._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DID_NOT_GO');

  static const $core.List<AttendanceStatus> values = <AttendanceStatus> [
    INTERESTED,
    GOING,
    NOT_GOING,
    REQUESTED,
    WENT,
    DID_NOT_GO,
  ];

  static final $core.Map<$core.int, AttendanceStatus> _byValue = $pb.ProtobufEnum.initByValue(values);
  static AttendanceStatus? valueOf($core.int value) => _byValue[value];

  const AttendanceStatus._($core.int v, $core.String n) : super(v, n);
}

