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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authors.pb.dart' as $14;
import 'google/protobuf/timestamp.pb.dart' as $11;

enum EventSyncSource_Configuration {
  icsSubscriptionUrl, 
  notSet
}

/// A user-owned source to sync events from.
class EventSyncSource extends $pb.GeneratedMessage {
  factory EventSyncSource({
    $core.String? id,
    $14.Author? owner,
    $fixnum.Int64? syncIntervalSeconds,
    $11.Timestamp? createdAt,
    $11.Timestamp? updatedAt,
    $11.Timestamp? lastSyncedAt,
    $fixnum.Int64? eventCount,
    $fixnum.Int64? eventInstanceCount,
    $core.String? icsSubscriptionUrl,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (owner != null) {
      $result.owner = owner;
    }
    if (syncIntervalSeconds != null) {
      $result.syncIntervalSeconds = syncIntervalSeconds;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    if (lastSyncedAt != null) {
      $result.lastSyncedAt = lastSyncedAt;
    }
    if (eventCount != null) {
      $result.eventCount = eventCount;
    }
    if (eventInstanceCount != null) {
      $result.eventInstanceCount = eventInstanceCount;
    }
    if (icsSubscriptionUrl != null) {
      $result.icsSubscriptionUrl = icsSubscriptionUrl;
    }
    return $result;
  }
  EventSyncSource._() : super();
  factory EventSyncSource.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EventSyncSource.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, EventSyncSource_Configuration> _EventSyncSource_ConfigurationByTag = {
    9 : EventSyncSource_Configuration.icsSubscriptionUrl,
    0 : EventSyncSource_Configuration.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventSyncSource', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..oo(0, [9])
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$14.Author>(2, _omitFieldNames ? '' : 'owner', subBuilder: $14.Author.create)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'syncIntervalSeconds', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$11.Timestamp>(4, _omitFieldNames ? '' : 'createdAt', subBuilder: $11.Timestamp.create)
    ..aOM<$11.Timestamp>(5, _omitFieldNames ? '' : 'updatedAt', subBuilder: $11.Timestamp.create)
    ..aOM<$11.Timestamp>(6, _omitFieldNames ? '' : 'lastSyncedAt', subBuilder: $11.Timestamp.create)
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'eventCount', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'eventInstanceCount', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(9, _omitFieldNames ? '' : 'icsSubscriptionUrl')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EventSyncSource clone() => EventSyncSource()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EventSyncSource copyWith(void Function(EventSyncSource) updates) => super.copyWith((message) => updates(message as EventSyncSource)) as EventSyncSource;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventSyncSource create() => EventSyncSource._();
  EventSyncSource createEmptyInstance() => create();
  static $pb.PbList<EventSyncSource> createRepeated() => $pb.PbList<EventSyncSource>();
  @$core.pragma('dart2js:noInline')
  static EventSyncSource getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventSyncSource>(create);
  static EventSyncSource? _defaultInstance;

  EventSyncSource_Configuration whichConfiguration() => _EventSyncSource_ConfigurationByTag[$_whichOneof(0)]!;
  void clearConfiguration() => clearField($_whichOneof(0));

  /// Unique ID for the synchronization.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// The user information for the owner of this event sync.
  @$pb.TagNumber(2)
  $14.Author get owner => $_getN(1);
  @$pb.TagNumber(2)
  set owner($14.Author v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwner() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwner() => clearField(2);
  @$pb.TagNumber(2)
  $14.Author ensureOwner() => $_ensure(1);

  /// How frequently the sync should happen in seconds.
  @$pb.TagNumber(3)
  $fixnum.Int64 get syncIntervalSeconds => $_getI64(2);
  @$pb.TagNumber(3)
  set syncIntervalSeconds($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSyncIntervalSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearSyncIntervalSeconds() => clearField(3);

  /// The time the EventSyncSource was created.
  @$pb.TagNumber(4)
  $11.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($11.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => clearField(4);
  @$pb.TagNumber(4)
  $11.Timestamp ensureCreatedAt() => $_ensure(3);

  /// The time the EventSyncSource was last updated.
  @$pb.TagNumber(5)
  $11.Timestamp get updatedAt => $_getN(4);
  @$pb.TagNumber(5)
  set updatedAt($11.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUpdatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearUpdatedAt() => clearField(5);
  @$pb.TagNumber(5)
  $11.Timestamp ensureUpdatedAt() => $_ensure(4);

  /// The time the EventSyncSource was last synced.
  @$pb.TagNumber(6)
  $11.Timestamp get lastSyncedAt => $_getN(5);
  @$pb.TagNumber(6)
  set lastSyncedAt($11.Timestamp v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasLastSyncedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastSyncedAt() => clearField(6);
  @$pb.TagNumber(6)
  $11.Timestamp ensureLastSyncedAt() => $_ensure(5);

  /// The number of events total associated with this EventSyncSource. Recomputed
  /// on each sync.
  @$pb.TagNumber(7)
  $fixnum.Int64 get eventCount => $_getI64(6);
  @$pb.TagNumber(7)
  set eventCount($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasEventCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearEventCount() => clearField(7);

  /// The number of event instances total associated with this EventSyncSource. Recomputed
  /// on each sync.
  @$pb.TagNumber(8)
  $fixnum.Int64 get eventInstanceCount => $_getI64(7);
  @$pb.TagNumber(8)
  set eventInstanceCount($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasEventInstanceCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearEventInstanceCount() => clearField(8);

  /// The iCal subscription URL for the calendar sync.
  @$pb.TagNumber(9)
  $core.String get icsSubscriptionUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set icsSubscriptionUrl($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasIcsSubscriptionUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearIcsSubscriptionUrl() => clearField(9);
}

class GetEventSyncSourcesResponse extends $pb.GeneratedMessage {
  factory GetEventSyncSourcesResponse({
    $core.Iterable<EventSyncSource>? sources,
  }) {
    final $result = create();
    if (sources != null) {
      $result.sources.addAll(sources);
    }
    return $result;
  }
  GetEventSyncSourcesResponse._() : super();
  factory GetEventSyncSourcesResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetEventSyncSourcesResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetEventSyncSourcesResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<EventSyncSource>(1, _omitFieldNames ? '' : 'sources', $pb.PbFieldType.PM, subBuilder: EventSyncSource.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetEventSyncSourcesResponse clone() => GetEventSyncSourcesResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetEventSyncSourcesResponse copyWith(void Function(GetEventSyncSourcesResponse) updates) => super.copyWith((message) => updates(message as GetEventSyncSourcesResponse)) as GetEventSyncSourcesResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEventSyncSourcesResponse create() => GetEventSyncSourcesResponse._();
  GetEventSyncSourcesResponse createEmptyInstance() => create();
  static $pb.PbList<GetEventSyncSourcesResponse> createRepeated() => $pb.PbList<GetEventSyncSourcesResponse>();
  @$core.pragma('dart2js:noInline')
  static GetEventSyncSourcesResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEventSyncSourcesResponse>(create);
  static GetEventSyncSourcesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<EventSyncSource> get sources => $_getList(0);
}

/// Request to delete an EventSyncSource.
class DeleteEventSyncSourceRequest extends $pb.GeneratedMessage {
  factory DeleteEventSyncSourceRequest({
    EventSyncSource? source,
    $core.bool? deleteSyncedEvents,
  }) {
    final $result = create();
    if (source != null) {
      $result.source = source;
    }
    if (deleteSyncedEvents != null) {
      $result.deleteSyncedEvents = deleteSyncedEvents;
    }
    return $result;
  }
  DeleteEventSyncSourceRequest._() : super();
  factory DeleteEventSyncSourceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteEventSyncSourceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteEventSyncSourceRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<EventSyncSource>(1, _omitFieldNames ? '' : 'source', subBuilder: EventSyncSource.create)
    ..aOB(2, _omitFieldNames ? '' : 'deleteSyncedEvents')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteEventSyncSourceRequest clone() => DeleteEventSyncSourceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteEventSyncSourceRequest copyWith(void Function(DeleteEventSyncSourceRequest) updates) => super.copyWith((message) => updates(message as DeleteEventSyncSourceRequest)) as DeleteEventSyncSourceRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteEventSyncSourceRequest create() => DeleteEventSyncSourceRequest._();
  DeleteEventSyncSourceRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteEventSyncSourceRequest> createRepeated() => $pb.PbList<DeleteEventSyncSourceRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteEventSyncSourceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteEventSyncSourceRequest>(create);
  static DeleteEventSyncSourceRequest? _defaultInstance;

  /// The source to be deleted.
  @$pb.TagNumber(1)
  EventSyncSource get source => $_getN(0);
  @$pb.TagNumber(1)
  set source(EventSyncSource v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(1)
  void clearSource() => clearField(1);
  @$pb.TagNumber(1)
  EventSyncSource ensureSource() => $_ensure(0);

  /// Whether to delete synced events.
  @$pb.TagNumber(2)
  $core.bool get deleteSyncedEvents => $_getBF(1);
  @$pb.TagNumber(2)
  set deleteSyncedEvents($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeleteSyncedEvents() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeleteSyncedEvents() => clearField(2);
}

enum SyncDestination_Configuration {
  facebookPage, 
  notSet
}

/// A user-owned destination to sync (cross-post) content out to. Mirrors `EventSyncSource`,
/// but for pushing content out rather than pulling events in. Originally Event-specific
/// (as `EventSyncDestination`), now shared by both `EventInstance`s (see `events.proto`'s
/// `SyncEventInstanceRequest`) and `Post`s (see `posts.proto`'s `SyncPostRequest`).
class SyncDestination extends $pb.GeneratedMessage {
  factory SyncDestination({
    $core.String? id,
    $14.Author? owner,
    $11.Timestamp? createdAt,
    $11.Timestamp? updatedAt,
    $fixnum.Int64? syncedEventInstanceCount,
    $fixnum.Int64? syncedPostCount,
    FacebookPage? facebookPage,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (owner != null) {
      $result.owner = owner;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    if (syncedEventInstanceCount != null) {
      $result.syncedEventInstanceCount = syncedEventInstanceCount;
    }
    if (syncedPostCount != null) {
      $result.syncedPostCount = syncedPostCount;
    }
    if (facebookPage != null) {
      $result.facebookPage = facebookPage;
    }
    return $result;
  }
  SyncDestination._() : super();
  factory SyncDestination.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SyncDestination.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SyncDestination_Configuration> _SyncDestination_ConfigurationByTag = {
    9 : SyncDestination_Configuration.facebookPage,
    0 : SyncDestination_Configuration.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SyncDestination', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..oo(0, [9])
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$14.Author>(2, _omitFieldNames ? '' : 'owner', subBuilder: $14.Author.create)
    ..aOM<$11.Timestamp>(4, _omitFieldNames ? '' : 'createdAt', subBuilder: $11.Timestamp.create)
    ..aOM<$11.Timestamp>(5, _omitFieldNames ? '' : 'updatedAt', subBuilder: $11.Timestamp.create)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'syncedEventInstanceCount', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'syncedPostCount', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<FacebookPage>(9, _omitFieldNames ? '' : 'facebookPage', subBuilder: FacebookPage.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SyncDestination clone() => SyncDestination()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SyncDestination copyWith(void Function(SyncDestination) updates) => super.copyWith((message) => updates(message as SyncDestination)) as SyncDestination;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncDestination create() => SyncDestination._();
  SyncDestination createEmptyInstance() => create();
  static $pb.PbList<SyncDestination> createRepeated() => $pb.PbList<SyncDestination>();
  @$core.pragma('dart2js:noInline')
  static SyncDestination getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncDestination>(create);
  static SyncDestination? _defaultInstance;

  SyncDestination_Configuration whichConfiguration() => _SyncDestination_ConfigurationByTag[$_whichOneof(0)]!;
  void clearConfiguration() => clearField($_whichOneof(0));

  /// Unique ID for the destination.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// The user information for the owner of this destination.
  @$pb.TagNumber(2)
  $14.Author get owner => $_getN(1);
  @$pb.TagNumber(2)
  set owner($14.Author v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwner() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwner() => clearField(2);
  @$pb.TagNumber(2)
  $14.Author ensureOwner() => $_ensure(1);

  /// The time the SyncDestination was created.
  @$pb.TagNumber(4)
  $11.Timestamp get createdAt => $_getN(2);
  @$pb.TagNumber(4)
  set createdAt($11.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(4)
  void clearCreatedAt() => clearField(4);
  @$pb.TagNumber(4)
  $11.Timestamp ensureCreatedAt() => $_ensure(2);

  /// The time the SyncDestination was last updated.
  @$pb.TagNumber(5)
  $11.Timestamp get updatedAt => $_getN(3);
  @$pb.TagNumber(5)
  set updatedAt($11.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUpdatedAt() => $_has(3);
  @$pb.TagNumber(5)
  void clearUpdatedAt() => clearField(5);
  @$pb.TagNumber(5)
  $11.Timestamp ensureUpdatedAt() => $_ensure(3);

  /// The number of EventInstances synced to this destination so far. Computed with a `COUNT` at
  /// request time (unlike `EventSyncSource`'s `event_count`/`event_instance_count`, which are
  /// recomputed-and-stored on each sync) since destinations are pushed to on demand, not synced
  /// in bulk on an interval.
  @$pb.TagNumber(6)
  $fixnum.Int64 get syncedEventInstanceCount => $_getI64(4);
  @$pb.TagNumber(6)
  set syncedEventInstanceCount($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(6)
  $core.bool hasSyncedEventInstanceCount() => $_has(4);
  @$pb.TagNumber(6)
  void clearSyncedEventInstanceCount() => clearField(6);

  /// The number of Posts synced to this destination so far. Computed the same way as
  /// `synced_event_instance_count`, just against Posts instead of EventInstances.
  @$pb.TagNumber(7)
  $fixnum.Int64 get syncedPostCount => $_getI64(5);
  @$pb.TagNumber(7)
  set syncedPostCount($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(7)
  $core.bool hasSyncedPostCount() => $_has(5);
  @$pb.TagNumber(7)
  void clearSyncedPostCount() => clearField(7);

  /// A connected Facebook Page to post EventInstances/Posts to.
  @$pb.TagNumber(9)
  FacebookPage get facebookPage => $_getN(6);
  @$pb.TagNumber(9)
  set facebookPage(FacebookPage v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasFacebookPage() => $_has(6);
  @$pb.TagNumber(9)
  void clearFacebookPage() => clearField(9);
  @$pb.TagNumber(9)
  FacebookPage ensureFacebookPage() => $_ensure(6);
}

class GetSyncDestinationsResponse extends $pb.GeneratedMessage {
  factory GetSyncDestinationsResponse({
    $core.Iterable<SyncDestination>? destinations,
  }) {
    final $result = create();
    if (destinations != null) {
      $result.destinations.addAll(destinations);
    }
    return $result;
  }
  GetSyncDestinationsResponse._() : super();
  factory GetSyncDestinationsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetSyncDestinationsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetSyncDestinationsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<SyncDestination>(1, _omitFieldNames ? '' : 'destinations', $pb.PbFieldType.PM, subBuilder: SyncDestination.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetSyncDestinationsResponse clone() => GetSyncDestinationsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetSyncDestinationsResponse copyWith(void Function(GetSyncDestinationsResponse) updates) => super.copyWith((message) => updates(message as GetSyncDestinationsResponse)) as GetSyncDestinationsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSyncDestinationsResponse create() => GetSyncDestinationsResponse._();
  GetSyncDestinationsResponse createEmptyInstance() => create();
  static $pb.PbList<GetSyncDestinationsResponse> createRepeated() => $pb.PbList<GetSyncDestinationsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetSyncDestinationsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetSyncDestinationsResponse>(create);
  static GetSyncDestinationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SyncDestination> get destinations => $_getList(0);
}

/// Request to delete a SyncDestination.
class DeleteSyncDestinationRequest extends $pb.GeneratedMessage {
  factory DeleteSyncDestinationRequest({
    SyncDestination? destination,
    $core.bool? deleteSyncedPosts,
  }) {
    final $result = create();
    if (destination != null) {
      $result.destination = destination;
    }
    if (deleteSyncedPosts != null) {
      $result.deleteSyncedPosts = deleteSyncedPosts;
    }
    return $result;
  }
  DeleteSyncDestinationRequest._() : super();
  factory DeleteSyncDestinationRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteSyncDestinationRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSyncDestinationRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<SyncDestination>(1, _omitFieldNames ? '' : 'destination', subBuilder: SyncDestination.create)
    ..aOB(2, _omitFieldNames ? '' : 'deleteSyncedPosts')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteSyncDestinationRequest clone() => DeleteSyncDestinationRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteSyncDestinationRequest copyWith(void Function(DeleteSyncDestinationRequest) updates) => super.copyWith((message) => updates(message as DeleteSyncDestinationRequest)) as DeleteSyncDestinationRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSyncDestinationRequest create() => DeleteSyncDestinationRequest._();
  DeleteSyncDestinationRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteSyncDestinationRequest> createRepeated() => $pb.PbList<DeleteSyncDestinationRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteSyncDestinationRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteSyncDestinationRequest>(create);
  static DeleteSyncDestinationRequest? _defaultInstance;

  /// The destination to be deleted.
  @$pb.TagNumber(1)
  SyncDestination get destination => $_getN(0);
  @$pb.TagNumber(1)
  set destination(SyncDestination v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDestination() => $_has(0);
  @$pb.TagNumber(1)
  void clearDestination() => clearField(1);
  @$pb.TagNumber(1)
  SyncDestination ensureDestination() => $_ensure(0);

  /// Whether to also delete posts already made on the destination (e.g. the Facebook Page posts).
  @$pb.TagNumber(2)
  $core.bool get deleteSyncedPosts => $_getBF(1);
  @$pb.TagNumber(2)
  set deleteSyncedPosts($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeleteSyncedPosts() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeleteSyncedPosts() => clearField(2);
}

/// A Facebook Page connected as a `SyncDestination`.
class FacebookPage extends $pb.GeneratedMessage {
  factory FacebookPage({
    $core.String? pageId,
    $core.String? pageName,
    $core.String? shortLivedUserAccessToken,
  }) {
    final $result = create();
    if (pageId != null) {
      $result.pageId = pageId;
    }
    if (pageName != null) {
      $result.pageName = pageName;
    }
    if (shortLivedUserAccessToken != null) {
      $result.shortLivedUserAccessToken = shortLivedUserAccessToken;
    }
    return $result;
  }
  FacebookPage._() : super();
  factory FacebookPage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FacebookPage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FacebookPage', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'pageId')
    ..aOS(2, _omitFieldNames ? '' : 'pageName')
    ..aOS(3, _omitFieldNames ? '' : 'shortLivedUserAccessToken')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FacebookPage clone() => FacebookPage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FacebookPage copyWith(void Function(FacebookPage) updates) => super.copyWith((message) => updates(message as FacebookPage)) as FacebookPage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FacebookPage create() => FacebookPage._();
  FacebookPage createEmptyInstance() => create();
  static $pb.PbList<FacebookPage> createRepeated() => $pb.PbList<FacebookPage>();
  @$core.pragma('dart2js:noInline')
  static FacebookPage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FacebookPage>(create);
  static FacebookPage? _defaultInstance;

  /// The Facebook Page's ID.
  @$pb.TagNumber(1)
  $core.String get pageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pageId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageId() => clearField(1);

  /// The Facebook Page's name, populated by the server when the connection is made.
  @$pb.TagNumber(2)
  $core.String get pageName => $_getSZ(1);
  @$pb.TagNumber(2)
  set pageName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPageName() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageName() => clearField(2);

  /// Only used (and required) on `CreateSyncDestination`: a short-lived user access token
  /// from client-side Facebook Login, exchanged server-side for a long-lived Page access token.
  /// Never populated in responses.
  @$pb.TagNumber(3)
  $core.String get shortLivedUserAccessToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set shortLivedUserAccessToken($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasShortLivedUserAccessToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearShortLivedUserAccessToken() => clearField(3);
}

/// The status of a single piece of content's (an `EventInstance` or `Post`) sync (cross-post) to
/// one `SyncDestination`. Shared/generic so both `EventInstance.sync_destinations` and
/// `Post.sync_destinations` can reuse it.
class SyncDestinationStatus extends $pb.GeneratedMessage {
  factory SyncDestinationStatus({
    $core.String? syncDestinationId,
    $core.String? destinationInstanceId,
    $core.String? destinationUrl,
    $11.Timestamp? syncedAt,
  }) {
    final $result = create();
    if (syncDestinationId != null) {
      $result.syncDestinationId = syncDestinationId;
    }
    if (destinationInstanceId != null) {
      $result.destinationInstanceId = destinationInstanceId;
    }
    if (destinationUrl != null) {
      $result.destinationUrl = destinationUrl;
    }
    if (syncedAt != null) {
      $result.syncedAt = syncedAt;
    }
    return $result;
  }
  SyncDestinationStatus._() : super();
  factory SyncDestinationStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SyncDestinationStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SyncDestinationStatus', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'syncDestinationId')
    ..aOS(2, _omitFieldNames ? '' : 'destinationInstanceId')
    ..aOS(3, _omitFieldNames ? '' : 'destinationUrl')
    ..aOM<$11.Timestamp>(4, _omitFieldNames ? '' : 'syncedAt', subBuilder: $11.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SyncDestinationStatus clone() => SyncDestinationStatus()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SyncDestinationStatus copyWith(void Function(SyncDestinationStatus) updates) => super.copyWith((message) => updates(message as SyncDestinationStatus)) as SyncDestinationStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncDestinationStatus create() => SyncDestinationStatus._();
  SyncDestinationStatus createEmptyInstance() => create();
  static $pb.PbList<SyncDestinationStatus> createRepeated() => $pb.PbList<SyncDestinationStatus>();
  @$core.pragma('dart2js:noInline')
  static SyncDestinationStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncDestinationStatus>(create);
  static SyncDestinationStatus? _defaultInstance;

  /// The SyncDestination this status is for.
  @$pb.TagNumber(1)
  $core.String get syncDestinationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set syncDestinationId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSyncDestinationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSyncDestinationId() => clearField(1);

  /// The ID of the resulting post on the destination (e.g. a Facebook Post ID).
  @$pb.TagNumber(2)
  $core.String get destinationInstanceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set destinationInstanceId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDestinationInstanceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestinationInstanceId() => clearField(2);

  /// A link to the resulting post on the destination, if available.
  @$pb.TagNumber(3)
  $core.String get destinationUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set destinationUrl($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDestinationUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearDestinationUrl() => clearField(3);

  /// The time this content was last successfully synced to the destination.
  @$pb.TagNumber(4)
  $11.Timestamp get syncedAt => $_getN(3);
  @$pb.TagNumber(4)
  set syncedAt($11.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSyncedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearSyncedAt() => clearField(4);
  @$pb.TagNumber(4)
  $11.Timestamp ensureSyncedAt() => $_ensure(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
