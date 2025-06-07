//
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'events.pbenum.dart';
import 'google/protobuf/timestamp.pb.dart' as $9;
import 'location.pb.dart' as $10;
import 'media.pb.dart' as $5;
import 'permissions.pbenum.dart' as $12;
import 'posts.pb.dart' as $7;
import 'users.pb.dart' as $4;
import 'visibility_moderation.pbenum.dart' as $11;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'events.pbenum.dart';

/// Request to get Events in a formatted *per-EventInstance* structure. i.e. the response will carry duplicate `Event`s with the same ID
/// if that `Event` has multiple `EventInstance`s in the time frame the client asked for.
///
/// These structured EventInstances are ordered by start time unless otherwise specified (specifically, `EventListingType.NEWLY_ADDED_EVENTS`).
///
/// Valid GetEventsRequest formats:
/// - `{[listing_type: PublicEvents]}`                 (TODO: get ServerPublic/GlobalPublic events you can see)
/// - `{listing_type:MyGroupsEvents|FollowingEvents}`  (TODO: get events for groups joined or user followed; auth required)
/// - `{event_id:}`                                    (TODO: get single event including preview data)
/// - `{listing_type: GroupEvents| GroupEventsPendingModeration, group_id:}`
///                                                    (TODO: get events/events needing moderation for a group)
/// - `{author_user_id:, group_id:}`                   (TODO: get events by a user for a group)
/// - `{listing_type: AuthorEvents, author_user_id:}`  (TODO: get events by a user)
class GetEventsRequest extends $pb.GeneratedMessage {
  factory GetEventsRequest({
    $core.String? eventId,
    $core.String? authorUserId,
    $core.String? groupId,
    $core.String? eventInstanceId,
    TimeFilter? timeFilter,
    $core.String? attendeeId,
    $core.Iterable<AttendanceStatus>? attendanceStatuses,
    $core.String? postId,
    EventListingType? listingType,
  }) {
    final result = create();
    if (eventId != null) result.eventId = eventId;
    if (authorUserId != null) result.authorUserId = authorUserId;
    if (groupId != null) result.groupId = groupId;
    if (eventInstanceId != null) result.eventInstanceId = eventInstanceId;
    if (timeFilter != null) result.timeFilter = timeFilter;
    if (attendeeId != null) result.attendeeId = attendeeId;
    if (attendanceStatuses != null) result.attendanceStatuses.addAll(attendanceStatuses);
    if (postId != null) result.postId = postId;
    if (listingType != null) result.listingType = listingType;
    return result;
  }

  GetEventsRequest._();

  factory GetEventsRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetEventsRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetEventsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'eventId')
    ..aOS(2, _omitFieldNames ? '' : 'authorUserId')
    ..aOS(3, _omitFieldNames ? '' : 'groupId')
    ..aOS(4, _omitFieldNames ? '' : 'eventInstanceId')
    ..aOM<TimeFilter>(5, _omitFieldNames ? '' : 'timeFilter', subBuilder: TimeFilter.create)
    ..aOS(6, _omitFieldNames ? '' : 'attendeeId')
    ..pc<AttendanceStatus>(7, _omitFieldNames ? '' : 'attendanceStatuses', $pb.PbFieldType.KE, valueOf: AttendanceStatus.valueOf, enumValues: AttendanceStatus.values, defaultEnumValue: AttendanceStatus.INTERESTED)
    ..aOS(8, _omitFieldNames ? '' : 'postId')
    ..e<EventListingType>(10, _omitFieldNames ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: EventListingType.ALL_ACCESSIBLE_EVENTS, valueOf: EventListingType.valueOf, enumValues: EventListingType.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventsRequest clone() => GetEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventsRequest copyWith(void Function(GetEventsRequest) updates) => super.copyWith((message) => updates(message as GetEventsRequest)) as GetEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEventsRequest create() => GetEventsRequest._();
  @$core.override
  GetEventsRequest createEmptyInstance() => create();
  static $pb.PbList<GetEventsRequest> createRepeated() => $pb.PbList<GetEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetEventsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEventsRequest>(create);
  static GetEventsRequest? _defaultInstance;

  /// Returns the single event with the given ID.
  @$pb.TagNumber(1)
  $core.String get eventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventId() => $_clearField(1);

  /// Limits results to those by the given author user ID.
  @$pb.TagNumber(2)
  $core.String get authorUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthorUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorUserId() => $_clearField(2);

  /// Limits results to those in the given group ID (via `GroupPost` association's for the Event's internal `Post`).
  @$pb.TagNumber(3)
  $core.String get groupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupId() => $_clearField(3);

  /// Limits results to those with the given event instance ID.
  @$pb.TagNumber(4)
  $core.String get eventInstanceId => $_getSZ(3);
  @$pb.TagNumber(4)
  set eventInstanceId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEventInstanceId() => $_has(3);
  @$pb.TagNumber(4)
  void clearEventInstanceId() => $_clearField(4);

  /// Filters returned `EventInstance`s by time.
  @$pb.TagNumber(5)
  TimeFilter get timeFilter => $_getN(4);
  @$pb.TagNumber(5)
  set timeFilter(TimeFilter value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTimeFilter() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimeFilter() => $_clearField(5);
  @$pb.TagNumber(5)
  TimeFilter ensureTimeFilter() => $_ensure(4);

  /// If set, only returns events that the given user is attending. If `attendance_statuses` is also set,
  /// returns events where that user's status is one of the given statuses.
  @$pb.TagNumber(6)
  $core.String get attendeeId => $_getSZ(5);
  @$pb.TagNumber(6)
  set attendeeId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAttendeeId() => $_has(5);
  @$pb.TagNumber(6)
  void clearAttendeeId() => $_clearField(6);

  /// If set, only return events for which the current user's attendance status matches one of the given statuses. If `attendee_id` is also set,
  /// only returns events where the given user's status matches one of the given statuses.
  @$pb.TagNumber(7)
  $pb.PbList<AttendanceStatus> get attendanceStatuses => $_getList(6);

  /// Finds Events for the Post with the given ID. The Post should have a `PostContext` of `EVENT` or `EVENT_INSTANCE`.
  @$pb.TagNumber(8)
  $core.String get postId => $_getSZ(7);
  @$pb.TagNumber(8)
  set postId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPostId() => $_has(7);
  @$pb.TagNumber(8)
  void clearPostId() => $_clearField(8);

  /// The listing type, e.g. `ALL_ACCESSIBLE_EVENTS`, `FOLLOWING_EVENTS`, `MY_GROUPS_EVENTS`, `DIRECT_EVENTS`, `GROUP_EVENTS`, `GROUP_EVENTS_PENDING_MODERATION`.
  @$pb.TagNumber(10)
  EventListingType get listingType => $_getN(8);
  @$pb.TagNumber(10)
  set listingType(EventListingType value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasListingType() => $_has(8);
  @$pb.TagNumber(10)
  void clearListingType() => $_clearField(10);
}

/// Time filter that works on the `starts_at` and `ends_at` fields of `EventInstance`.
/// API currently only supports `ends_after`.
class TimeFilter extends $pb.GeneratedMessage {
  factory TimeFilter({
    $9.Timestamp? startsAfter,
    $9.Timestamp? endsAfter,
    $9.Timestamp? startsBefore,
    $9.Timestamp? endsBefore,
  }) {
    final result = create();
    if (startsAfter != null) result.startsAfter = startsAfter;
    if (endsAfter != null) result.endsAfter = endsAfter;
    if (startsBefore != null) result.startsBefore = startsBefore;
    if (endsBefore != null) result.endsBefore = endsBefore;
    return result;
  }

  TimeFilter._();

  factory TimeFilter.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory TimeFilter.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TimeFilter', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<$9.Timestamp>(1, _omitFieldNames ? '' : 'startsAfter', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(2, _omitFieldNames ? '' : 'endsAfter', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(3, _omitFieldNames ? '' : 'startsBefore', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(4, _omitFieldNames ? '' : 'endsBefore', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeFilter clone() => TimeFilter()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeFilter copyWith(void Function(TimeFilter) updates) => super.copyWith((message) => updates(message as TimeFilter)) as TimeFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeFilter create() => TimeFilter._();
  @$core.override
  TimeFilter createEmptyInstance() => create();
  static $pb.PbList<TimeFilter> createRepeated() => $pb.PbList<TimeFilter>();
  @$core.pragma('dart2js:noInline')
  static TimeFilter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TimeFilter>(create);
  static TimeFilter? _defaultInstance;

  /// Filter to events that start after the given time.
  @$pb.TagNumber(1)
  $9.Timestamp get startsAfter => $_getN(0);
  @$pb.TagNumber(1)
  set startsAfter($9.Timestamp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStartsAfter() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartsAfter() => $_clearField(1);
  @$pb.TagNumber(1)
  $9.Timestamp ensureStartsAfter() => $_ensure(0);

  /// Filter to events that end after the given time.
  @$pb.TagNumber(2)
  $9.Timestamp get endsAfter => $_getN(1);
  @$pb.TagNumber(2)
  set endsAfter($9.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEndsAfter() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndsAfter() => $_clearField(2);
  @$pb.TagNumber(2)
  $9.Timestamp ensureEndsAfter() => $_ensure(1);

  /// Filter to events that start before the given time.
  @$pb.TagNumber(3)
  $9.Timestamp get startsBefore => $_getN(2);
  @$pb.TagNumber(3)
  set startsBefore($9.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStartsBefore() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartsBefore() => $_clearField(3);
  @$pb.TagNumber(3)
  $9.Timestamp ensureStartsBefore() => $_ensure(2);

  /// Filter to events that end before the given time.
  @$pb.TagNumber(4)
  $9.Timestamp get endsBefore => $_getN(3);
  @$pb.TagNumber(4)
  set endsBefore($9.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEndsBefore() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndsBefore() => $_clearField(4);
  @$pb.TagNumber(4)
  $9.Timestamp ensureEndsBefore() => $_ensure(3);
}

/// A list of `Event`s with a maybe-incomplete (see [`GetEventsRequest`](#geteventsrequest)) set of their `EventInstance`s.
///
/// Note that `GetEventsResponse` may often include duplicate Events with the same ID.
/// I.E. something like: `{events: [{id: a, instances: [{id: x}]}, {id: a, instances: [{id: y}]}, ]}` is a valid response.
/// This semantically means: "Event A has both instances X and Y in the time frame the client asked for."
/// The client should be able to handle this.
///
/// In the React/Tamagui client, this is handled by the Redux store, which
/// effectively "compacts" all response into its own internal Events store, in a form something like:
/// `{events: {a: {id: a, instances: [{id: x}, {id: y}]}, ...}, instanceEventIds: {x:a, y:a}}`.
/// (In reality it uses `EntityAdapter` which is a bit more complicated, but the idea is the same.)
class GetEventsResponse extends $pb.GeneratedMessage {
  factory GetEventsResponse({
    $core.Iterable<Event>? events,
  }) {
    final result = create();
    if (events != null) result.events.addAll(events);
    return result;
  }

  GetEventsResponse._();

  factory GetEventsResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetEventsResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetEventsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Event>(1, _omitFieldNames ? '' : 'events', $pb.PbFieldType.PM, subBuilder: Event.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventsResponse clone() => GetEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventsResponse copyWith(void Function(GetEventsResponse) updates) => super.copyWith((message) => updates(message as GetEventsResponse)) as GetEventsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEventsResponse create() => GetEventsResponse._();
  @$core.override
  GetEventsResponse createEmptyInstance() => create();
  static $pb.PbList<GetEventsResponse> createRepeated() => $pb.PbList<GetEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetEventsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEventsResponse>(create);
  static GetEventsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Event> get events => $_getList(0);
}

/// An `Event` is a top-level type used to organize calendar events, RSVPs, and messaging/posting
/// about the `Event`. Actual time data lies in its `EventInstances`.
///
/// (Eventually, Jonline Events should also support ticketing.)
class Event extends $pb.GeneratedMessage {
  factory Event({
    $core.String? id,
    $7.Post? post,
    EventInfo? info,
    $core.Iterable<EventInstance>? instances,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (post != null) result.post = post;
    if (info != null) result.info = info;
    if (instances != null) result.instances.addAll(instances);
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Event', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$7.Post>(2, _omitFieldNames ? '' : 'post', subBuilder: $7.Post.create)
    ..aOM<EventInfo>(3, _omitFieldNames ? '' : 'info', subBuilder: EventInfo.create)
    ..pc<EventInstance>(4, _omitFieldNames ? '' : 'instances', $pb.PbFieldType.PM, subBuilder: EventInstance.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => Event()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) => super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Event create() => Event._();
  @$core.override
  Event createEmptyInstance() => create();
  static $pb.PbList<Event> createRepeated() => $pb.PbList<Event>();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Event>(create);
  static Event? _defaultInstance;

  /// Unique ID for the event generated by the Jonline BE.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The Post containing the underlying data for the event (names). Its `PostContext` should be `EVENT`.
  @$pb.TagNumber(2)
  $7.Post get post => $_getN(1);
  @$pb.TagNumber(2)
  set post($7.Post value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPost() => $_has(1);
  @$pb.TagNumber(2)
  void clearPost() => $_clearField(2);
  @$pb.TagNumber(2)
  $7.Post ensurePost() => $_ensure(1);

  /// Event configuration like whether to allow (anonymous) RSVPs, etc.
  @$pb.TagNumber(3)
  EventInfo get info => $_getN(2);
  @$pb.TagNumber(3)
  set info(EventInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearInfo() => $_clearField(3);
  @$pb.TagNumber(3)
  EventInfo ensureInfo() => $_ensure(2);

  /// A list of instances for the Event. *Events will only include all instances if the request is for a single event.*
  @$pb.TagNumber(4)
  $pb.PbList<EventInstance> get instances => $_getList(3);
}

/// To be used for ticketing, RSVPs, etc.
/// Stored as JSON in the database.
class EventInfo extends $pb.GeneratedMessage {
  factory EventInfo({
    $core.bool? allowsRsvps,
    $core.bool? allowsAnonymousRsvps,
    $core.int? maxAttendees,
    $core.bool? hideLocationUntilRsvpApproved,
    $11.Moderation? defaultRsvpModeration,
  }) {
    final result = create();
    if (allowsRsvps != null) result.allowsRsvps = allowsRsvps;
    if (allowsAnonymousRsvps != null) result.allowsAnonymousRsvps = allowsAnonymousRsvps;
    if (maxAttendees != null) result.maxAttendees = maxAttendees;
    if (hideLocationUntilRsvpApproved != null) result.hideLocationUntilRsvpApproved = hideLocationUntilRsvpApproved;
    if (defaultRsvpModeration != null) result.defaultRsvpModeration = defaultRsvpModeration;
    return result;
  }

  EventInfo._();

  factory EventInfo.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EventInfo.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'allowsRsvps')
    ..aOB(2, _omitFieldNames ? '' : 'allowsAnonymousRsvps')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'maxAttendees', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'hideLocationUntilRsvpApproved')
    ..e<$11.Moderation>(5, _omitFieldNames ? '' : 'defaultRsvpModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInfo clone() => EventInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInfo copyWith(void Function(EventInfo) updates) => super.copyWith((message) => updates(message as EventInfo)) as EventInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventInfo create() => EventInfo._();
  @$core.override
  EventInfo createEmptyInstance() => create();
  static $pb.PbList<EventInfo> createRepeated() => $pb.PbList<EventInfo>();
  @$core.pragma('dart2js:noInline')
  static EventInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventInfo>(create);
  static EventInfo? _defaultInstance;

  /// Whether to allow RSVPs for the event.
  @$pb.TagNumber(1)
  $core.bool get allowsRsvps => $_getBF(0);
  @$pb.TagNumber(1)
  set allowsRsvps($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAllowsRsvps() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllowsRsvps() => $_clearField(1);

  /// Whether to allow anonymous RSVPs for the event.
  @$pb.TagNumber(2)
  $core.bool get allowsAnonymousRsvps => $_getBF(1);
  @$pb.TagNumber(2)
  set allowsAnonymousRsvps($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAllowsAnonymousRsvps() => $_has(1);
  @$pb.TagNumber(2)
  void clearAllowsAnonymousRsvps() => $_clearField(2);

  /// Limit the max number of attendees. No effect unless `allows_rsvps` is true. Not yet supported.
  @$pb.TagNumber(3)
  $core.int get maxAttendees => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxAttendees($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxAttendees() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxAttendees() => $_clearField(3);

  /// Hide the location until the user RSVPs (and it's accepted).
  /// From a system perspective, when this is set, Events will not include the `Location` until the user has RSVP'd.
  /// Location will always be returned in EventAttendances if the request for the EventAttendances came from a (logged in or anonymous)
  /// user whose attendance is approved (or the event owner).
  @$pb.TagNumber(4)
  $core.bool get hideLocationUntilRsvpApproved => $_getBF(3);
  @$pb.TagNumber(4)
  set hideLocationUntilRsvpApproved($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHideLocationUntilRsvpApproved() => $_has(3);
  @$pb.TagNumber(4)
  void clearHideLocationUntilRsvpApproved() => $_clearField(4);

  /// Default moderation for RSVPs from logged-in users (either `PENDING` or `APPROVED`).
  /// Anonymous RSVPs are always moderated (default to `PENDING`).
  @$pb.TagNumber(5)
  $11.Moderation get defaultRsvpModeration => $_getN(4);
  @$pb.TagNumber(5)
  set defaultRsvpModeration($11.Moderation value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDefaultRsvpModeration() => $_has(4);
  @$pb.TagNumber(5)
  void clearDefaultRsvpModeration() => $_clearField(5);
}

/// The time-based component of an `Event`. Has a `starts_at` and `ends_at` time,
/// a `Location`, and an optional `Post` (and discussion thread) specific to this particular
/// `EventInstance` in addition to the parent `Event`.
class EventInstance extends $pb.GeneratedMessage {
  factory EventInstance({
    $core.String? id,
    $core.String? eventId,
    $7.Post? post,
    EventInstanceInfo? info,
    $9.Timestamp? startsAt,
    $9.Timestamp? endsAt,
    $10.Location? location,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (eventId != null) result.eventId = eventId;
    if (post != null) result.post = post;
    if (info != null) result.info = info;
    if (startsAt != null) result.startsAt = startsAt;
    if (endsAt != null) result.endsAt = endsAt;
    if (location != null) result.location = location;
    return result;
  }

  EventInstance._();

  factory EventInstance.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EventInstance.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventInstance', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'eventId')
    ..aOM<$7.Post>(3, _omitFieldNames ? '' : 'post', subBuilder: $7.Post.create)
    ..aOM<EventInstanceInfo>(4, _omitFieldNames ? '' : 'info', subBuilder: EventInstanceInfo.create)
    ..aOM<$9.Timestamp>(5, _omitFieldNames ? '' : 'startsAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(6, _omitFieldNames ? '' : 'endsAt', subBuilder: $9.Timestamp.create)
    ..aOM<$10.Location>(7, _omitFieldNames ? '' : 'location', subBuilder: $10.Location.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInstance clone() => EventInstance()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInstance copyWith(void Function(EventInstance) updates) => super.copyWith((message) => updates(message as EventInstance)) as EventInstance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventInstance create() => EventInstance._();
  @$core.override
  EventInstance createEmptyInstance() => create();
  static $pb.PbList<EventInstance> createRepeated() => $pb.PbList<EventInstance>();
  @$core.pragma('dart2js:noInline')
  static EventInstance getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventInstance>(create);
  static EventInstance? _defaultInstance;

  /// Unique ID for the event instance generated by the Jonline BE.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// ID of the parent `Event`.
  @$pb.TagNumber(2)
  $core.String get eventId => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEventId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventId() => $_clearField(2);

  /// Optional `Post` containing alternate name/link/description for this particular instance. Its `PostContext` should be `EVENT_INSTANCE`.
  @$pb.TagNumber(3)
  $7.Post get post => $_getN(2);
  @$pb.TagNumber(3)
  set post($7.Post value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPost() => $_has(2);
  @$pb.TagNumber(3)
  void clearPost() => $_clearField(3);
  @$pb.TagNumber(3)
  $7.Post ensurePost() => $_ensure(2);

  /// Additional configuration for this instance of this `EventInstance` beyond the `EventInfo` in its parent `Event`.
  @$pb.TagNumber(4)
  EventInstanceInfo get info => $_getN(3);
  @$pb.TagNumber(4)
  set info(EventInstanceInfo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearInfo() => $_clearField(4);
  @$pb.TagNumber(4)
  EventInstanceInfo ensureInfo() => $_ensure(3);

  /// The time the event starts (UTC/Timestamp format).
  @$pb.TagNumber(5)
  $9.Timestamp get startsAt => $_getN(4);
  @$pb.TagNumber(5)
  set startsAt($9.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasStartsAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearStartsAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $9.Timestamp ensureStartsAt() => $_ensure(4);

  /// The time the event ends (UTC/Timestamp format).
  @$pb.TagNumber(6)
  $9.Timestamp get endsAt => $_getN(5);
  @$pb.TagNumber(6)
  set endsAt($9.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasEndsAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndsAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $9.Timestamp ensureEndsAt() => $_ensure(5);

  /// The location of the event.
  @$pb.TagNumber(7)
  $10.Location get location => $_getN(6);
  @$pb.TagNumber(7)
  set location($10.Location value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasLocation() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocation() => $_clearField(7);
  @$pb.TagNumber(7)
  $10.Location ensureLocation() => $_ensure(6);
}

/// To be used for ticketing, RSVPs, etc.
/// Stored as JSON in the database.
class EventInstanceInfo extends $pb.GeneratedMessage {
  factory EventInstanceInfo({
    EventInstanceRsvpInfo? rsvpInfo,
  }) {
    final result = create();
    if (rsvpInfo != null) result.rsvpInfo = rsvpInfo;
    return result;
  }

  EventInstanceInfo._();

  factory EventInstanceInfo.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EventInstanceInfo.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventInstanceInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<EventInstanceRsvpInfo>(1, _omitFieldNames ? '' : 'rsvpInfo', subBuilder: EventInstanceRsvpInfo.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInstanceInfo clone() => EventInstanceInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInstanceInfo copyWith(void Function(EventInstanceInfo) updates) => super.copyWith((message) => updates(message as EventInstanceInfo)) as EventInstanceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventInstanceInfo create() => EventInstanceInfo._();
  @$core.override
  EventInstanceInfo createEmptyInstance() => create();
  static $pb.PbList<EventInstanceInfo> createRepeated() => $pb.PbList<EventInstanceInfo>();
  @$core.pragma('dart2js:noInline')
  static EventInstanceInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventInstanceInfo>(create);
  static EventInstanceInfo? _defaultInstance;

  /// RSVP configuration and metadata for the event instance.
  @$pb.TagNumber(1)
  EventInstanceRsvpInfo get rsvpInfo => $_getN(0);
  @$pb.TagNumber(1)
  set rsvpInfo(EventInstanceRsvpInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRsvpInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearRsvpInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  EventInstanceRsvpInfo ensureRsvpInfo() => $_ensure(0);
}

/// Consolidated type for RSVP info for an `EventInstance`.
/// Curently, the `optional` counts below are *never* returned by the API.
class EventInstanceRsvpInfo extends $pb.GeneratedMessage {
  factory EventInstanceRsvpInfo({
    $core.bool? allowsRsvps,
    $core.bool? allowsAnonymousRsvps,
    $core.int? maxAttendees,
    $core.int? goingRsvps,
    $core.int? goingAttendees,
    $core.int? interestedRsvps,
    $core.int? interestedAttendees,
    $core.int? invitedRsvps,
    $core.int? invitedAttendees,
  }) {
    final result = create();
    if (allowsRsvps != null) result.allowsRsvps = allowsRsvps;
    if (allowsAnonymousRsvps != null) result.allowsAnonymousRsvps = allowsAnonymousRsvps;
    if (maxAttendees != null) result.maxAttendees = maxAttendees;
    if (goingRsvps != null) result.goingRsvps = goingRsvps;
    if (goingAttendees != null) result.goingAttendees = goingAttendees;
    if (interestedRsvps != null) result.interestedRsvps = interestedRsvps;
    if (interestedAttendees != null) result.interestedAttendees = interestedAttendees;
    if (invitedRsvps != null) result.invitedRsvps = invitedRsvps;
    if (invitedAttendees != null) result.invitedAttendees = invitedAttendees;
    return result;
  }

  EventInstanceRsvpInfo._();

  factory EventInstanceRsvpInfo.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EventInstanceRsvpInfo.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventInstanceRsvpInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'allowsRsvps')
    ..aOB(2, _omitFieldNames ? '' : 'allowsAnonymousRsvps')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'maxAttendees', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'goingRsvps', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'goingAttendees', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'interestedRsvps', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'interestedAttendees', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'invitedRsvps', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'invitedAttendees', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInstanceRsvpInfo clone() => EventInstanceRsvpInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventInstanceRsvpInfo copyWith(void Function(EventInstanceRsvpInfo) updates) => super.copyWith((message) => updates(message as EventInstanceRsvpInfo)) as EventInstanceRsvpInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventInstanceRsvpInfo create() => EventInstanceRsvpInfo._();
  @$core.override
  EventInstanceRsvpInfo createEmptyInstance() => create();
  static $pb.PbList<EventInstanceRsvpInfo> createRepeated() => $pb.PbList<EventInstanceRsvpInfo>();
  @$core.pragma('dart2js:noInline')
  static EventInstanceRsvpInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventInstanceRsvpInfo>(create);
  static EventInstanceRsvpInfo? _defaultInstance;

  /// Overrides `EventInfo.allows_rsvps`, if set, for this instance.
  @$pb.TagNumber(1)
  $core.bool get allowsRsvps => $_getBF(0);
  @$pb.TagNumber(1)
  set allowsRsvps($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAllowsRsvps() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllowsRsvps() => $_clearField(1);

  /// Overrides `EventInfo.allows_anonymous_rsvps`, if set, for this instance.
  @$pb.TagNumber(2)
  $core.bool get allowsAnonymousRsvps => $_getBF(1);
  @$pb.TagNumber(2)
  set allowsAnonymousRsvps($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAllowsAnonymousRsvps() => $_has(1);
  @$pb.TagNumber(2)
  void clearAllowsAnonymousRsvps() => $_clearField(2);

  /// Overrides `EventInfo.max_attendees`, if set, for this instance. Not yet supported.
  @$pb.TagNumber(3)
  $core.int get maxAttendees => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxAttendees($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxAttendees() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxAttendees() => $_clearField(3);

  /// The number of users who have RSVP'd to the event.
  @$pb.TagNumber(4)
  $core.int get goingRsvps => $_getIZ(3);
  @$pb.TagNumber(4)
  set goingRsvps($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGoingRsvps() => $_has(3);
  @$pb.TagNumber(4)
  void clearGoingRsvps() => $_clearField(4);

  /// The number of attendees who have RSVP'd to the event. (RSVPs may have multiple attendees, i.e. guests.)
  @$pb.TagNumber(5)
  $core.int get goingAttendees => $_getIZ(4);
  @$pb.TagNumber(5)
  set goingAttendees($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGoingAttendees() => $_has(4);
  @$pb.TagNumber(5)
  void clearGoingAttendees() => $_clearField(5);

  /// The number of users who have signaled interest in the event.
  @$pb.TagNumber(6)
  $core.int get interestedRsvps => $_getIZ(5);
  @$pb.TagNumber(6)
  set interestedRsvps($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasInterestedRsvps() => $_has(5);
  @$pb.TagNumber(6)
  void clearInterestedRsvps() => $_clearField(6);

  /// The number of attendees who have signaled interest in the event. (RSVPs may have multiple attendees, i.e. guests.)
  @$pb.TagNumber(7)
  $core.int get interestedAttendees => $_getIZ(6);
  @$pb.TagNumber(7)
  set interestedAttendees($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasInterestedAttendees() => $_has(6);
  @$pb.TagNumber(7)
  void clearInterestedAttendees() => $_clearField(7);

  /// The number of users who have been invited to the event.
  @$pb.TagNumber(8)
  $core.int get invitedRsvps => $_getIZ(7);
  @$pb.TagNumber(8)
  set invitedRsvps($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasInvitedRsvps() => $_has(7);
  @$pb.TagNumber(8)
  void clearInvitedRsvps() => $_clearField(8);

  /// The number of attendees who have been invited to the event. (RSVPs may have multiple attendees, i.e. guests.)
  @$pb.TagNumber(9)
  $core.int get invitedAttendees => $_getIZ(8);
  @$pb.TagNumber(9)
  set invitedAttendees($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasInvitedAttendees() => $_has(8);
  @$pb.TagNumber(9)
  void clearInvitedAttendees() => $_clearField(9);
}

/// Request to get RSVP data for an event.
class GetEventAttendancesRequest extends $pb.GeneratedMessage {
  factory GetEventAttendancesRequest({
    $core.String? eventInstanceId,
    $core.String? anonymousAttendeeAuthToken,
  }) {
    final result = create();
    if (eventInstanceId != null) result.eventInstanceId = eventInstanceId;
    if (anonymousAttendeeAuthToken != null) result.anonymousAttendeeAuthToken = anonymousAttendeeAuthToken;
    return result;
  }

  GetEventAttendancesRequest._();

  factory GetEventAttendancesRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetEventAttendancesRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetEventAttendancesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'eventInstanceId')
    ..aOS(2, _omitFieldNames ? '' : 'anonymousAttendeeAuthToken')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventAttendancesRequest clone() => GetEventAttendancesRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventAttendancesRequest copyWith(void Function(GetEventAttendancesRequest) updates) => super.copyWith((message) => updates(message as GetEventAttendancesRequest)) as GetEventAttendancesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEventAttendancesRequest create() => GetEventAttendancesRequest._();
  @$core.override
  GetEventAttendancesRequest createEmptyInstance() => create();
  static $pb.PbList<GetEventAttendancesRequest> createRepeated() => $pb.PbList<GetEventAttendancesRequest>();
  @$core.pragma('dart2js:noInline')
  static GetEventAttendancesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEventAttendancesRequest>(create);
  static GetEventAttendancesRequest? _defaultInstance;

  /// The ID of the event to get RSVP data for.
  @$pb.TagNumber(1)
  $core.String get eventInstanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventInstanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEventInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventInstanceId() => $_clearField(1);

  /// If set, and if the token has an RSVP for this even, request that RSVP data
  /// in addition to the rest of the RSVP data. (The event creator can always
  /// see and moderate anonymous RSVPs.)
  @$pb.TagNumber(2)
  $core.String get anonymousAttendeeAuthToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set anonymousAttendeeAuthToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAnonymousAttendeeAuthToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnonymousAttendeeAuthToken() => $_clearField(2);
}

/// Response to get RSVP data for an event.
class EventAttendances extends $pb.GeneratedMessage {
  factory EventAttendances({
    $core.Iterable<EventAttendance>? attendances,
    $10.Location? hiddenLocation,
  }) {
    final result = create();
    if (attendances != null) result.attendances.addAll(attendances);
    if (hiddenLocation != null) result.hiddenLocation = hiddenLocation;
    return result;
  }

  EventAttendances._();

  factory EventAttendances.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EventAttendances.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventAttendances', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<EventAttendance>(1, _omitFieldNames ? '' : 'attendances', $pb.PbFieldType.PM, subBuilder: EventAttendance.create)
    ..aOM<$10.Location>(2, _omitFieldNames ? '' : 'hiddenLocation', subBuilder: $10.Location.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventAttendances clone() => EventAttendances()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventAttendances copyWith(void Function(EventAttendances) updates) => super.copyWith((message) => updates(message as EventAttendances)) as EventAttendances;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventAttendances create() => EventAttendances._();
  @$core.override
  EventAttendances createEmptyInstance() => create();
  static $pb.PbList<EventAttendances> createRepeated() => $pb.PbList<EventAttendances>();
  @$core.pragma('dart2js:noInline')
  static EventAttendances getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventAttendances>(create);
  static EventAttendances? _defaultInstance;

  /// The attendance data for the event, in no particular order.
  @$pb.TagNumber(1)
  $pb.PbList<EventAttendance> get attendances => $_getList(0);

  /// When `hide_location_until_rsvp_approved` is set, the location of the event.
  @$pb.TagNumber(2)
  $10.Location get hiddenLocation => $_getN(1);
  @$pb.TagNumber(2)
  set hiddenLocation($10.Location value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasHiddenLocation() => $_has(1);
  @$pb.TagNumber(2)
  void clearHiddenLocation() => $_clearField(2);
  @$pb.TagNumber(2)
  $10.Location ensureHiddenLocation() => $_ensure(1);
}

enum EventAttendance_Attendee {
  userAttendee, 
  anonymousAttendee, 
  notSet
}

/// Could be called an "RSVP." Describes the attendance of a user at an `EventInstance`. Such as:
/// * A user's RSVP to an `EventInstance` (one of `INTERESTED`, `GOING`, `NOT_GOING`, or , `REQUESTED` (i.e. invited)).
/// * Invitation status of a user to an `EventInstance`.
/// * `ContactMethod`-driven management for anonymous RSVPs to an `EventInstance`.
class EventAttendance extends $pb.GeneratedMessage {
  factory EventAttendance({
    $core.String? id,
    $core.String? eventInstanceId,
    UserAttendee? userAttendee,
    AnonymousAttendee? anonymousAttendee,
    $core.int? numberOfGuests,
    AttendanceStatus? status,
    $core.String? invitingUserId,
    $core.String? privateNote,
    $core.String? publicNote,
    $11.Moderation? moderation,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (eventInstanceId != null) result.eventInstanceId = eventInstanceId;
    if (userAttendee != null) result.userAttendee = userAttendee;
    if (anonymousAttendee != null) result.anonymousAttendee = anonymousAttendee;
    if (numberOfGuests != null) result.numberOfGuests = numberOfGuests;
    if (status != null) result.status = status;
    if (invitingUserId != null) result.invitingUserId = invitingUserId;
    if (privateNote != null) result.privateNote = privateNote;
    if (publicNote != null) result.publicNote = publicNote;
    if (moderation != null) result.moderation = moderation;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  EventAttendance._();

  factory EventAttendance.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EventAttendance.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, EventAttendance_Attendee> _EventAttendance_AttendeeByTag = {
    3 : EventAttendance_Attendee.userAttendee,
    4 : EventAttendance_Attendee.anonymousAttendee,
    0 : EventAttendance_Attendee.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventAttendance', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..oo(0, [3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'eventInstanceId')
    ..aOM<UserAttendee>(3, _omitFieldNames ? '' : 'userAttendee', subBuilder: UserAttendee.create)
    ..aOM<AnonymousAttendee>(4, _omitFieldNames ? '' : 'anonymousAttendee', subBuilder: AnonymousAttendee.create)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'numberOfGuests', $pb.PbFieldType.OU3)
    ..e<AttendanceStatus>(6, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: AttendanceStatus.INTERESTED, valueOf: AttendanceStatus.valueOf, enumValues: AttendanceStatus.values)
    ..aOS(7, _omitFieldNames ? '' : 'invitingUserId')
    ..aOS(8, _omitFieldNames ? '' : 'privateNote')
    ..aOS(9, _omitFieldNames ? '' : 'publicNote')
    ..e<$11.Moderation>(10, _omitFieldNames ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOM<$9.Timestamp>(11, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(12, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventAttendance clone() => EventAttendance()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventAttendance copyWith(void Function(EventAttendance) updates) => super.copyWith((message) => updates(message as EventAttendance)) as EventAttendance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventAttendance create() => EventAttendance._();
  @$core.override
  EventAttendance createEmptyInstance() => create();
  static $pb.PbList<EventAttendance> createRepeated() => $pb.PbList<EventAttendance>();
  @$core.pragma('dart2js:noInline')
  static EventAttendance getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventAttendance>(create);
  static EventAttendance? _defaultInstance;

  EventAttendance_Attendee whichAttendee() => _EventAttendance_AttendeeByTag[$_whichOneof(0)]!;
  void clearAttendee() => $_clearField($_whichOneof(0));

  /// Unique server-generated ID for the attendance.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// ID of the `EventInstance` the attendance is for.
  @$pb.TagNumber(2)
  $core.String get eventInstanceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventInstanceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEventInstanceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventInstanceId() => $_clearField(2);

  /// If the attendance is non-anonymous, core data about the user.
  @$pb.TagNumber(3)
  UserAttendee get userAttendee => $_getN(2);
  @$pb.TagNumber(3)
  set userAttendee(UserAttendee value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUserAttendee() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserAttendee() => $_clearField(3);
  @$pb.TagNumber(3)
  UserAttendee ensureUserAttendee() => $_ensure(2);

  /// If the attendance is anonymous, core data about the anonymous attendee.
  @$pb.TagNumber(4)
  AnonymousAttendee get anonymousAttendee => $_getN(3);
  @$pb.TagNumber(4)
  set anonymousAttendee(AnonymousAttendee value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAnonymousAttendee() => $_has(3);
  @$pb.TagNumber(4)
  void clearAnonymousAttendee() => $_clearField(4);
  @$pb.TagNumber(4)
  AnonymousAttendee ensureAnonymousAttendee() => $_ensure(3);

  /// Number of guests including the RSVPing user. (Minimum 1).
  @$pb.TagNumber(5)
  $core.int get numberOfGuests => $_getIZ(4);
  @$pb.TagNumber(5)
  set numberOfGuests($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNumberOfGuests() => $_has(4);
  @$pb.TagNumber(5)
  void clearNumberOfGuests() => $_clearField(5);

  /// The user's RSVP to an `EventInstance` (one of `INTERESTED`, `REQUESTED` (i.e. invited), `GOING`, `NOT_GOING`)
  @$pb.TagNumber(6)
  AttendanceStatus get status => $_getN(5);
  @$pb.TagNumber(6)
  set status(AttendanceStatus value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearStatus() => $_clearField(6);

  /// User who invited the attendee. (Not yet used.)
  @$pb.TagNumber(7)
  $core.String get invitingUserId => $_getSZ(6);
  @$pb.TagNumber(7)
  set invitingUserId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasInvitingUserId() => $_has(6);
  @$pb.TagNumber(7)
  void clearInvitingUserId() => $_clearField(7);

  /// Public note for everyone who can see the event to see.
  @$pb.TagNumber(8)
  $core.String get privateNote => $_getSZ(7);
  @$pb.TagNumber(8)
  set privateNote($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPrivateNote() => $_has(7);
  @$pb.TagNumber(8)
  void clearPrivateNote() => $_clearField(8);

  /// Private note for the event owner.
  @$pb.TagNumber(9)
  $core.String get publicNote => $_getSZ(8);
  @$pb.TagNumber(9)
  set publicNote($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPublicNote() => $_has(8);
  @$pb.TagNumber(9)
  void clearPublicNote() => $_clearField(9);

  /// Moderation status for the attendance. Moderated by the `Event` owner (or `EventInstance` owner if applicable).
  @$pb.TagNumber(10)
  $11.Moderation get moderation => $_getN(9);
  @$pb.TagNumber(10)
  set moderation($11.Moderation value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasModeration() => $_has(9);
  @$pb.TagNumber(10)
  void clearModeration() => $_clearField(10);

  /// The time the attendance was created.
  @$pb.TagNumber(11)
  $9.Timestamp get createdAt => $_getN(10);
  @$pb.TagNumber(11)
  set createdAt($9.Timestamp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedAt() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedAt() => $_clearField(11);
  @$pb.TagNumber(11)
  $9.Timestamp ensureCreatedAt() => $_ensure(10);

  /// The time the attendance was last updated.
  @$pb.TagNumber(12)
  $9.Timestamp get updatedAt => $_getN(11);
  @$pb.TagNumber(12)
  set updatedAt($9.Timestamp value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasUpdatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdatedAt() => $_clearField(12);
  @$pb.TagNumber(12)
  $9.Timestamp ensureUpdatedAt() => $_ensure(11);
}

/// An anonymous internet user who has RSVP'd to an `EventInstance`.
///
/// (TODO:) The visibility on `AnonymousAttendee` `ContactMethod`s should support the `LIMITED` visibility, which will
/// make them visible to the event creator.
class AnonymousAttendee extends $pb.GeneratedMessage {
  factory AnonymousAttendee({
    $core.String? name,
    $core.Iterable<$4.ContactMethod>? contactMethods,
    $core.String? authToken,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (contactMethods != null) result.contactMethods.addAll(contactMethods);
    if (authToken != null) result.authToken = authToken;
    return result;
  }

  AnonymousAttendee._();

  factory AnonymousAttendee.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory AnonymousAttendee.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AnonymousAttendee', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pc<$4.ContactMethod>(2, _omitFieldNames ? '' : 'contactMethods', $pb.PbFieldType.PM, subBuilder: $4.ContactMethod.create)
    ..aOS(3, _omitFieldNames ? '' : 'authToken')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnonymousAttendee clone() => AnonymousAttendee()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnonymousAttendee copyWith(void Function(AnonymousAttendee) updates) => super.copyWith((message) => updates(message as AnonymousAttendee)) as AnonymousAttendee;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnonymousAttendee create() => AnonymousAttendee._();
  @$core.override
  AnonymousAttendee createEmptyInstance() => create();
  static $pb.PbList<AnonymousAttendee> createRepeated() => $pb.PbList<AnonymousAttendee>();
  @$core.pragma('dart2js:noInline')
  static AnonymousAttendee getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AnonymousAttendee>(create);
  static AnonymousAttendee? _defaultInstance;

  /// A name for the anonymous user. For instance, "Bob Gomez" or "The guy on your front porch."
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Contact methods for anonymous attendees. Currently not linked to Contact methods for users.
  @$pb.TagNumber(2)
  $pb.PbList<$4.ContactMethod> get contactMethods => $_getList(1);

  /// Used to allow anonymous users to RSVP to an event. Generated by the server
  /// when an event attendance is upserted for the first time. Subsequent attendance
  /// upserts, with the same event_instance_id and anonymous_attendee.auth_token,
  /// will update existing anonymous attendance records. Invalid auth tokens used during upserts will always create a new `EventAttendance`.
  @$pb.TagNumber(3)
  $core.String get authToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set authToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthToken() => $_clearField(3);
}

/// Wire-identical to [Author](#author), but with a different name to avoid confusion.
class UserAttendee extends $pb.GeneratedMessage {
  factory UserAttendee({
    $core.String? userId,
    $core.String? username,
    $5.MediaReference? avatar,
    $core.String? realName,
    $core.Iterable<$12.Permission>? permissions,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (avatar != null) result.avatar = avatar;
    if (realName != null) result.realName = realName;
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  UserAttendee._();

  factory UserAttendee.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory UserAttendee.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UserAttendee', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOM<$5.MediaReference>(3, _omitFieldNames ? '' : 'avatar', subBuilder: $5.MediaReference.create)
    ..aOS(4, _omitFieldNames ? '' : 'realName')
    ..pc<$12.Permission>(5, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $12.Permission.valueOf, enumValues: $12.Permission.values, defaultEnumValue: $12.Permission.PERMISSION_UNKNOWN)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserAttendee clone() => UserAttendee()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserAttendee copyWith(void Function(UserAttendee) updates) => super.copyWith((message) => updates(message as UserAttendee)) as UserAttendee;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserAttendee create() => UserAttendee._();
  @$core.override
  UserAttendee createEmptyInstance() => create();
  static $pb.PbList<UserAttendee> createRepeated() => $pb.PbList<UserAttendee>();
  @$core.pragma('dart2js:noInline')
  static UserAttendee getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserAttendee>(create);
  static UserAttendee? _defaultInstance;

  /// The user ID of the attendee.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// The username of the attendee.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  /// The attendee's user avatar.
  @$pb.TagNumber(3)
  $5.MediaReference get avatar => $_getN(2);
  @$pb.TagNumber(3)
  set avatar($5.MediaReference value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatar() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatar() => $_clearField(3);
  @$pb.TagNumber(3)
  $5.MediaReference ensureAvatar() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get realName => $_getSZ(3);
  @$pb.TagNumber(4)
  set realName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRealName() => $_has(3);
  @$pb.TagNumber(4)
  void clearRealName() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$12.Permission> get permissions => $_getList(4);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
