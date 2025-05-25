//
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// The listing type, e.g. `ALL_ACCESSIBLE_EVENTS`, `FOLLOWING_EVENTS`, `MY_GROUPS_EVENTS`, `DIRECT_EVENTS`, `GROUP_EVENTS`, `GROUP_EVENTS_PENDING_MODERATION`.
///
/// Events returned are ordered by start time unless otherwise specified (specifically, `NEWLY_ADDED_EVENTS`).
class EventListingType extends $pb.ProtobufEnum {
  /// Gets `SERVER_PUBLIC` and `GLOBAL_PUBLIC` events depending on whether the user is logged in, `LIMITED` events from authors the user is following, and `PRIVATE` events owned by, or directly addressed to, the current user.
  static const EventListingType ALL_ACCESSIBLE_EVENTS = EventListingType._(0, _omitEnumNames ? '' : 'ALL_ACCESSIBLE_EVENTS');
  /// Returns events from users the user is following.
  static const EventListingType FOLLOWING_EVENTS = EventListingType._(1, _omitEnumNames ? '' : 'FOLLOWING_EVENTS');
  /// Returns events from any group the user is a member of.
  static const EventListingType MY_GROUPS_EVENTS = EventListingType._(2, _omitEnumNames ? '' : 'MY_GROUPS_EVENTS');
  /// Returns `DIRECT` events that are directly addressed to the user.
  static const EventListingType DIRECT_EVENTS = EventListingType._(3, _omitEnumNames ? '' : 'DIRECT_EVENTS');
  /// Returns events pending moderation by the server-level mods/admins.
  static const EventListingType EVENTS_PENDING_MODERATION = EventListingType._(4, _omitEnumNames ? '' : 'EVENTS_PENDING_MODERATION');
  /// Returns events from a specific group. Requires group_id parameterRequires group_id parameter
  static const EventListingType GROUP_EVENTS = EventListingType._(10, _omitEnumNames ? '' : 'GROUP_EVENTS');
  /// Returns pending_moderation events from a specific group. Requires group_id
  /// parameter and user must have group (or server) admin permissions.
  static const EventListingType GROUP_EVENTS_PENDING_MODERATION = EventListingType._(11, _omitEnumNames ? '' : 'GROUP_EVENTS_PENDING_MODERATION');
  /// Returns events from either `ALL_ACCESSIBLE_EVENTS` or a specific author (with optional author_user_id parameter).
  /// Returned EventInstances will be ordered by creation time rather than start time.
  static const EventListingType NEWLY_ADDED_EVENTS = EventListingType._(20, _omitEnumNames ? '' : 'NEWLY_ADDED_EVENTS');

  static const $core.List<EventListingType> values = <EventListingType> [
    ALL_ACCESSIBLE_EVENTS,
    FOLLOWING_EVENTS,
    MY_GROUPS_EVENTS,
    DIRECT_EVENTS,
    EVENTS_PENDING_MODERATION,
    GROUP_EVENTS,
    GROUP_EVENTS_PENDING_MODERATION,
    NEWLY_ADDED_EVENTS,
  ];

  static final $core.Map<$core.int, EventListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EventListingType? valueOf($core.int value) => _byValue[value];

  const EventListingType._(super.v, super.n);
}

/// EventInstance attendance statuses. State transitions may generally happen
/// in any direction, but:
/// * `REQUESTED` can only be selected if another user invited the user whose attendance is being described.
/// * `GOING` and `NOT_GOING` cannot be selected if the EventInstance has ended (end time is in the past).
/// * `WENT` and `DID_NOT_GO` cannot be selected if the EventInstance has not started (start time is in the future).
/// `INTERESTED` and `REQUESTED` can apply regardless of whether an event has started or ended.
class AttendanceStatus extends $pb.ProtobufEnum {
  /// The user is (or was) interested in attending. This is the default status.
  static const AttendanceStatus INTERESTED = AttendanceStatus._(0, _omitEnumNames ? '' : 'INTERESTED');
  /// Another user has invited the user to the event.
  static const AttendanceStatus REQUESTED = AttendanceStatus._(1, _omitEnumNames ? '' : 'REQUESTED');
  /// The user plans to go to the event, or went to the event.
  static const AttendanceStatus GOING = AttendanceStatus._(2, _omitEnumNames ? '' : 'GOING');
  /// The user does not plan to go to the event, or did not go to the event.
  static const AttendanceStatus NOT_GOING = AttendanceStatus._(3, _omitEnumNames ? '' : 'NOT_GOING');

  static const $core.List<AttendanceStatus> values = <AttendanceStatus> [
    INTERESTED,
    REQUESTED,
    GOING,
    NOT_GOING,
  ];

  static final $core.List<AttendanceStatus?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static AttendanceStatus? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AttendanceStatus._(super.v, super.n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
