///
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'posts.pb.dart' as $7;

import 'events.pbenum.dart';

export 'events.pbenum.dart';

class GetEventsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetEventsRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'eventId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'authorUserId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'eventInstanceId')
    ..aOM<TimeFilter>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timeFilter', subBuilder: TimeFilter.create)
    ..e<EventListingType>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: EventListingType.PUBLIC_EVENTS, valueOf: EventListingType.valueOf, enumValues: EventListingType.values)
    ..hasRequiredFields = false
  ;

  GetEventsRequest._() : super();
  factory GetEventsRequest({
    $core.String? eventId,
    $core.String? authorUserId,
    $core.String? groupId,
    $core.String? eventInstanceId,
    TimeFilter? timeFilter,
    EventListingType? listingType,
  }) {
    final _result = create();
    if (eventId != null) {
      _result.eventId = eventId;
    }
    if (authorUserId != null) {
      _result.authorUserId = authorUserId;
    }
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (eventInstanceId != null) {
      _result.eventInstanceId = eventInstanceId;
    }
    if (timeFilter != null) {
      _result.timeFilter = timeFilter;
    }
    if (listingType != null) {
      _result.listingType = listingType;
    }
    return _result;
  }
  factory GetEventsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetEventsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetEventsRequest clone() => GetEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetEventsRequest copyWith(void Function(GetEventsRequest) updates) => super.copyWith((message) => updates(message as GetEventsRequest)) as GetEventsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetEventsRequest create() => GetEventsRequest._();
  GetEventsRequest createEmptyInstance() => create();
  static $pb.PbList<GetEventsRequest> createRepeated() => $pb.PbList<GetEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetEventsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEventsRequest>(create);
  static GetEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get eventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get authorUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorUserId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAuthorUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorUserId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get groupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get eventInstanceId => $_getSZ(3);
  @$pb.TagNumber(4)
  set eventInstanceId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEventInstanceId() => $_has(3);
  @$pb.TagNumber(4)
  void clearEventInstanceId() => clearField(4);

  @$pb.TagNumber(5)
  TimeFilter get timeFilter => $_getN(4);
  @$pb.TagNumber(5)
  set timeFilter(TimeFilter v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasTimeFilter() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimeFilter() => clearField(5);
  @$pb.TagNumber(5)
  TimeFilter ensureTimeFilter() => $_ensure(4);

  @$pb.TagNumber(10)
  EventListingType get listingType => $_getN(5);
  @$pb.TagNumber(10)
  set listingType(EventListingType v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasListingType() => $_has(5);
  @$pb.TagNumber(10)
  void clearListingType() => clearField(10);
}

class TimeFilter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TimeFilter', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<$9.Timestamp>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startsAfter', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'endsAfter', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startsBefore', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'endsBefore', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  TimeFilter._() : super();
  factory TimeFilter({
    $9.Timestamp? startsAfter,
    $9.Timestamp? endsAfter,
    $9.Timestamp? startsBefore,
    $9.Timestamp? endsBefore,
  }) {
    final _result = create();
    if (startsAfter != null) {
      _result.startsAfter = startsAfter;
    }
    if (endsAfter != null) {
      _result.endsAfter = endsAfter;
    }
    if (startsBefore != null) {
      _result.startsBefore = startsBefore;
    }
    if (endsBefore != null) {
      _result.endsBefore = endsBefore;
    }
    return _result;
  }
  factory TimeFilter.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TimeFilter.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TimeFilter clone() => TimeFilter()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TimeFilter copyWith(void Function(TimeFilter) updates) => super.copyWith((message) => updates(message as TimeFilter)) as TimeFilter; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TimeFilter create() => TimeFilter._();
  TimeFilter createEmptyInstance() => create();
  static $pb.PbList<TimeFilter> createRepeated() => $pb.PbList<TimeFilter>();
  @$core.pragma('dart2js:noInline')
  static TimeFilter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TimeFilter>(create);
  static TimeFilter? _defaultInstance;

  @$pb.TagNumber(1)
  $9.Timestamp get startsAfter => $_getN(0);
  @$pb.TagNumber(1)
  set startsAfter($9.Timestamp v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStartsAfter() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartsAfter() => clearField(1);
  @$pb.TagNumber(1)
  $9.Timestamp ensureStartsAfter() => $_ensure(0);

  @$pb.TagNumber(2)
  $9.Timestamp get endsAfter => $_getN(1);
  @$pb.TagNumber(2)
  set endsAfter($9.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasEndsAfter() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndsAfter() => clearField(2);
  @$pb.TagNumber(2)
  $9.Timestamp ensureEndsAfter() => $_ensure(1);

  @$pb.TagNumber(3)
  $9.Timestamp get startsBefore => $_getN(2);
  @$pb.TagNumber(3)
  set startsBefore($9.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasStartsBefore() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartsBefore() => clearField(3);
  @$pb.TagNumber(3)
  $9.Timestamp ensureStartsBefore() => $_ensure(2);

  @$pb.TagNumber(4)
  $9.Timestamp get endsBefore => $_getN(3);
  @$pb.TagNumber(4)
  set endsBefore($9.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasEndsBefore() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndsBefore() => clearField(4);
  @$pb.TagNumber(4)
  $9.Timestamp ensureEndsBefore() => $_ensure(3);
}

class GetEventsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetEventsResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Event>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'events', $pb.PbFieldType.PM, subBuilder: Event.create)
    ..hasRequiredFields = false
  ;

  GetEventsResponse._() : super();
  factory GetEventsResponse({
    $core.Iterable<Event>? events,
  }) {
    final _result = create();
    if (events != null) {
      _result.events.addAll(events);
    }
    return _result;
  }
  factory GetEventsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetEventsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetEventsResponse clone() => GetEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetEventsResponse copyWith(void Function(GetEventsResponse) updates) => super.copyWith((message) => updates(message as GetEventsResponse)) as GetEventsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetEventsResponse create() => GetEventsResponse._();
  GetEventsResponse createEmptyInstance() => create();
  static $pb.PbList<GetEventsResponse> createRepeated() => $pb.PbList<GetEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetEventsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEventsResponse>(create);
  static GetEventsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Event> get events => $_getList(0);
}

class Event extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Event', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOM<$7.Post>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'post', subBuilder: $7.Post.create)
    ..aOM<EventInfo>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'info', subBuilder: EventInfo.create)
    ..pc<EventInstance>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'instances', $pb.PbFieldType.PM, subBuilder: EventInstance.create)
    ..hasRequiredFields = false
  ;

  Event._() : super();
  factory Event({
    $core.String? id,
    $7.Post? post,
    EventInfo? info,
    $core.Iterable<EventInstance>? instances,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (post != null) {
      _result.post = post;
    }
    if (info != null) {
      _result.info = info;
    }
    if (instances != null) {
      _result.instances.addAll(instances);
    }
    return _result;
  }
  factory Event.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Event.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Event clone() => Event()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Event copyWith(void Function(Event) updates) => super.copyWith((message) => updates(message as Event)) as Event; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Event create() => Event._();
  Event createEmptyInstance() => create();
  static $pb.PbList<Event> createRepeated() => $pb.PbList<Event>();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Event>(create);
  static Event? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $7.Post get post => $_getN(1);
  @$pb.TagNumber(2)
  set post($7.Post v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasPost() => $_has(1);
  @$pb.TagNumber(2)
  void clearPost() => clearField(2);
  @$pb.TagNumber(2)
  $7.Post ensurePost() => $_ensure(1);

  @$pb.TagNumber(3)
  EventInfo get info => $_getN(2);
  @$pb.TagNumber(3)
  set info(EventInfo v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearInfo() => clearField(3);
  @$pb.TagNumber(3)
  EventInfo ensureInfo() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<EventInstance> get instances => $_getList(3);
}

class EventInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EventInfo', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  EventInfo._() : super();
  factory EventInfo() => create();
  factory EventInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EventInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EventInfo clone() => EventInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EventInfo copyWith(void Function(EventInfo) updates) => super.copyWith((message) => updates(message as EventInfo)) as EventInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EventInfo create() => EventInfo._();
  EventInfo createEmptyInstance() => create();
  static $pb.PbList<EventInfo> createRepeated() => $pb.PbList<EventInfo>();
  @$core.pragma('dart2js:noInline')
  static EventInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventInfo>(create);
  static EventInfo? _defaultInstance;
}

class EventInstance extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EventInstance', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'eventId')
    ..aOM<$7.Post>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'post', subBuilder: $7.Post.create)
    ..aOM<EventInstanceInfo>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'info', subBuilder: EventInstanceInfo.create)
    ..aOM<$9.Timestamp>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startsAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'endsAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  EventInstance._() : super();
  factory EventInstance({
    $core.String? id,
    $core.String? eventId,
    $7.Post? post,
    EventInstanceInfo? info,
    $9.Timestamp? startsAt,
    $9.Timestamp? endsAt,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (eventId != null) {
      _result.eventId = eventId;
    }
    if (post != null) {
      _result.post = post;
    }
    if (info != null) {
      _result.info = info;
    }
    if (startsAt != null) {
      _result.startsAt = startsAt;
    }
    if (endsAt != null) {
      _result.endsAt = endsAt;
    }
    return _result;
  }
  factory EventInstance.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EventInstance.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EventInstance clone() => EventInstance()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EventInstance copyWith(void Function(EventInstance) updates) => super.copyWith((message) => updates(message as EventInstance)) as EventInstance; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EventInstance create() => EventInstance._();
  EventInstance createEmptyInstance() => create();
  static $pb.PbList<EventInstance> createRepeated() => $pb.PbList<EventInstance>();
  @$core.pragma('dart2js:noInline')
  static EventInstance getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventInstance>(create);
  static EventInstance? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get eventId => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEventId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventId() => clearField(2);

  @$pb.TagNumber(3)
  $7.Post get post => $_getN(2);
  @$pb.TagNumber(3)
  set post($7.Post v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasPost() => $_has(2);
  @$pb.TagNumber(3)
  void clearPost() => clearField(3);
  @$pb.TagNumber(3)
  $7.Post ensurePost() => $_ensure(2);

  @$pb.TagNumber(4)
  EventInstanceInfo get info => $_getN(3);
  @$pb.TagNumber(4)
  set info(EventInstanceInfo v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearInfo() => clearField(4);
  @$pb.TagNumber(4)
  EventInstanceInfo ensureInfo() => $_ensure(3);

  @$pb.TagNumber(5)
  $9.Timestamp get startsAt => $_getN(4);
  @$pb.TagNumber(5)
  set startsAt($9.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasStartsAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearStartsAt() => clearField(5);
  @$pb.TagNumber(5)
  $9.Timestamp ensureStartsAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $9.Timestamp get endsAt => $_getN(5);
  @$pb.TagNumber(6)
  set endsAt($9.Timestamp v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasEndsAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndsAt() => clearField(6);
  @$pb.TagNumber(6)
  $9.Timestamp ensureEndsAt() => $_ensure(5);
}

class EventInstanceInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EventInstanceInfo', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  EventInstanceInfo._() : super();
  factory EventInstanceInfo() => create();
  factory EventInstanceInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EventInstanceInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EventInstanceInfo clone() => EventInstanceInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EventInstanceInfo copyWith(void Function(EventInstanceInfo) updates) => super.copyWith((message) => updates(message as EventInstanceInfo)) as EventInstanceInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EventInstanceInfo create() => EventInstanceInfo._();
  EventInstanceInfo createEmptyInstance() => create();
  static $pb.PbList<EventInstanceInfo> createRepeated() => $pb.PbList<EventInstanceInfo>();
  @$core.pragma('dart2js:noInline')
  static EventInstanceInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventInstanceInfo>(create);
  static EventInstanceInfo? _defaultInstance;
}

