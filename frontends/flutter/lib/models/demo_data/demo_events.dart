import 'package:fixnum/fixnum.dart';
import 'package:jonline/models/jonline_account_operations.dart';

import '../../app_state.dart';
import '../../generated/events.pb.dart';
import '../../generated/google/protobuf/timestamp.pb.dart';
import '../../generated/groups.pb.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../jonline_account.dart';
import '../jonline_clients.dart';
import 'demo_groups.dart';

createDemoEvents(
    JonlineAccount account, Function(String) showSnackBar, AppState appState,
    {List<DemoEvent>? eventSetOverride}) async {
  final JonlineClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
    return;
  }
  await account.ensureAccessToken(showMessage: showSnackBar);

  final groups =
      await getExistingDemoGroups(client, account, showSnackBar, appState);
  await generateEvents(client, account, showSnackBar, appState, groups,
      eventSetOverride: eventSetOverride);
}

Future<List<Event>> generateEvents(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    Map<DemoGroup, Group> demoGroups,
    {List<DemoEvent>? eventSetOverride}) async {
  final List<Event> posts = [];
  var events = List.of(eventSetOverride ?? demoEvents);
  var lastMessageTime = DateTime.now();
  for (final demoPost in events) {
    final groups = demoPost.groups;
    final basePost = demoPost.post;

    // showSnackBar(
    //     'Posting "${basePost.title}" across ${groups.length} groups...');
    try {
      final event = await client.createEvent(basePost,
          options: account.authenticatedCallOptions);
      posts.add(event);
      final index = events.indexOf(demoPost);
      if (shouldNotify(lastMessageTime)) {
        showSnackBar("Posted ${index + 1} demo events...");
        lastMessageTime = DateTime.now();
      }
      for (final demoGroup in groups) {
        final group = demoGroups[demoGroup];
        if (group != null) {
          await client.createGroupPost(
              GroupPost()
                ..groupId = group.id
                ..postId = event.post.id,
              options: account.authenticatedCallOptions);
        }
      }
    } catch (e) {
      showSnackBar("Error posting demo data: $e");
      rethrow;
    }
    // await communicationDelay;
  }
  showSnackBar("Posted ${posts.length} demo events.");
  return posts;
}

class DemoEvent {
  final List<DemoGroup> groups;
  Event post;

  DemoEvent(this.groups, this.post);
}

final List<DemoEvent> demoEvents = [
  ...durhamDemoEvents,
  DemoEvent(
      [DemoGroup.music, DemoGroup.coolKidsClub],
      Event()
        ..post = (Post()
          ..title = "GRiZmas in July"
          ..link = "https://www.mynameisgriz.com/news/2023/gij"
          ..content =
              "Annual Wilmington music event that this year could always be the last of. Send the man off with love and appreciation regardless!")
        ..instances.addAll([
          _generateInstance(
              '2023-07-28 13:00:00-04:00', '2023-07-30 17:00:00-04:00'),
        ])),
];

final List<DemoEvent> durhamDemoEvents = [
  DemoEvent(
      [DemoGroup.yoga, DemoGroup.fitness, DemoGroup.coolKidsClub],
      Event()
        ..post = (Post()
          ..title = "Bull City Run Club"
          ..link = "https://bullcityrunning.com/events/runclub/"
          ..content =
              "A weekly run club for all levels of runners. Meets at Bull City Running's downtown location, with running starting at 6pm. 3, 4 and 6 mile routes are available. Registration isn't required, but costs only \$1 (cash) and lets you earn free beers, pint glasses, and T-shirts!")
        ..instances.addAll(_generateWeeklyInstances(
            '2023-04-12 18:00:00-04:00', '2023-04-12 19:00:00-04:00', 20))),
  DemoEvent(
      [DemoGroup.yoga, DemoGroup.fitness, DemoGroup.coolKidsClub],
      Event()
        ..post = (Post()
          ..title = "RAD Ride"
          ..link = "https://www.instagram.com/ride_around_durham/"
          ..content =
              "Ride Around Durham is a weekly bike ride for all levels. Meets at Duke Chapel at 6pm, with the ride starting at 6:30. Bring a beer and grab another after the ride at the bar we land at! New routes every week.")
        ..instances.addAll(_generateWeeklyInstances(
            '2023-04-13 18:00:00-04:00', '2023-04-13 21:00:00-04:00', 20))),
  DemoEvent(
      [DemoGroup.yoga, DemoGroup.fitness, DemoGroup.coolKidsClub],
      Event()
        ..post = (Post()
          ..title = "Pony Ride"
          ..link = "https://www.ponysaurusbrewing.com/events"
          ..content =
              "Monthly bike ride for all levels. Meets at Major the Bull in downtown Durham at 6:30pm, with the ride starting at 7. Beers and raffles for bar tabs and more at Pony after! New routes every month.")
        ..instances.addAll([
          _generateInstance(
              '2023-06-13 18:30:00-04:00', '2023-06-13 20:00:00-04:00'),
          _generateInstance(
              '2023-07-11 18:30:00-04:00', '2023-07-11 20:00:00-04:00'),
          _generateInstance(
              '2023-08-08 18:30:00-04:00', '2023-08-08 20:00:00-04:00'),
          _generateInstance(
              '2023-09-12 18:30:00-04:00', '2023-09-12 20:00:00-04:00'),
          _generateInstance(
              '2023-10-17 18:30:00-04:00', '2023-10-17 20:00:00-04:00'),
        ])),
];

List<EventInstance> _generateWeeklyInstances(
    String startsAtStr, String endsAtStr, int recurringWeeks) {
  final List<EventInstance> instances = [];
  DateTime startsAt = DateTime.parse(startsAtStr);
  DateTime endsAt = DateTime.parse(endsAtStr);
  // LOL this doesn't even handle DST but copilot generated it and it's good enough for a demo for now...
  for (int i = 0; i < recurringWeeks; i++) {
    instances.add(_generateInstance(
        startsAt.add(Duration(days: i * 7)).toIso8601String(),
        endsAt.add(Duration(days: i * 7)).toIso8601String()));
  }
  return instances;
}

EventInstance _generateInstance(String startsAtStr, String endsAtStr) {
  DateTime startsAt = DateTime.parse(startsAtStr);
  DateTime endsAt = DateTime.parse(endsAtStr);
  return EventInstance()
    ..startsAt = (Timestamp()
      ..seconds =
          Int64.fromInts(0, (startsAt.millisecondsSinceEpoch / 1000).floor()))
    ..endsAt = (Timestamp()
      ..seconds =
          Int64.fromInts(0, (endsAt.millisecondsSinceEpoch / 1000).floor()));
}

shouldNotify(DateTime lastMessageTime) =>
    DateTime.now().difference(lastMessageTime) > const Duration(seconds: 5);
