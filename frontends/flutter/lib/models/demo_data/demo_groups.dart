import 'package:jonline/models/jonline_account_operations.dart';
import 'package:jonline/utils/proto_utils.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/visibility_moderation.pb.dart' as vm;
import '../../generated/visibility_moderation.pbenum.dart';
import '../jonline_account.dart';
import '../jonline_clients.dart';

createDemoGroups(
    JonlineAccount account, Function(String) showSnackBar, AppState appState,
    {bool randomizePosts = false}) async {
  final JonlineClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
    return;
  }
  await account.ensureAccessToken(showMessage: showSnackBar);

  await generateDemoGroups(client, account, showSnackBar, appState);
}

Future<Map<DemoGroup, Group>> getExistingDemoGroups(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState) async {
  final existingGroups = await client.getGroups(GetGroupsRequest(),
      options: account.authenticatedCallOptions);
  final Map<DemoGroup, Group> result = {};
  for (final demoGroup in _demoGroups.entries) {
    final name = demoGroup.value.name;
    if (existingGroups.groups.any((g) => g.name == name)) {
      result[demoGroup.key] =
          existingGroups.groups.firstWhere((g) => g.name == name);
    }
  }
  return result;
}

Future<Map<DemoGroup, Group>> generateDemoGroups(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState) async {
  final existingGroups = await client.getGroups(GetGroupsRequest(),
      options: account.authenticatedCallOptions);
  final Map<DemoGroup, Group> result = {};
  int generatedGroups = 0;
  for (final demoGroup in _demoGroups.entries) {
    final name = demoGroup.value.name;
    if (existingGroups.groups.any((g) => g.name == name)) {
      result[demoGroup.key] =
          existingGroups.groups.firstWhere((g) => g.name == name);
      // showSnackBar('Group "$name" already exists, skipping.');
      continue;
    }
    generatedGroups++;
    final group = await client.createGroup(demoGroup.value,
        options: account.authenticatedCallOptions);
    // showSnackBar('Created group "$name".');
    result[demoGroup.key] = group;
  }
  if (generatedGroups > 0) {
    showSnackBar('Created $generatedGroups new groups.');
    await communicationDelay;
  }
  return result;
}

enum DemoGroup {
  coolKidsClub,
  everyoneWelcome,
  music,
  fitness,
  makers,
  yoga,
  engineering,
  math,
  science,
  tech,
  gamers,
  homeImprovement,
  toolSharing,
  cooking,
  restaurants,
  programming
}

final Map<DemoGroup, Group> _demoGroups = Map.unmodifiable({
  DemoGroup.coolKidsClub: Group()
    ..name = "Cool Kids Club 🤫"
    ..description = "Only the coolest ppl get in. Approval required to join."
    ..defaultMembershipModeration = Moderation.PENDING
    ..visibility = Visibility.SERVER_PUBLIC,
  DemoGroup.everyoneWelcome: Group()
    ..name = "Everyone Welcome 🤙"
    ..description = "Feel free to join!",
  DemoGroup.music: Group()
    ..name = "Funktastic 🎶"
    ..description =
        "For music lovers. Post your Spotify playlists, audio tracks, videos and whatever",
  DemoGroup.fitness: Group()
    ..name = "Fitness 🏋️‍♀️"
    ..description =
        "Climbing, biking, running, spikeball, other things involving balls\n\nAlso barbells.\n\nAnd fuck it dance too!",
  DemoGroup.makers: Group()
    ..name = "Makers 🧶"
    ..description =
        "Creators of art, music, furniture, knitting, software... just make stuff!",
  DemoGroup.yoga: Group()
    ..name = "Yoga 🧘‍♂️"
    ..description = "🤸‍♀️🧘‍♀️🧘‍♂️🤸‍♂️🧘‍♀️🧘‍♂️🤸‍♀️",
  DemoGroup.engineering: Group()
    ..name = "Real Engineering 🪄"
    ..description = "Like with real things not just logic 😂😭",
  DemoGroup.math: Group()
    ..name = "Math 🧮"
    ..description =
        "Shit that is literally not real but also the basis of reality",
  DemoGroup.science: Group()
    ..name = "Science 🧪"
    ..description = "Straight from the lab bench",
  DemoGroup.tech: Group()
    ..name = "Tech 📡"
    ..description =
        "General tech 🤓🤖💚\n\nNo billionaire-worship bullshit allowed.",
  DemoGroup.gamers: Group()
    ..name = "Gamers 👾"
    ..description =
        "Honestly just tryna play my Zeldas and Final Fantasies and Marios, is this how my dad feels with his classic blues/funk-infused rock love?",
  DemoGroup.homeImprovement: Group()
    ..name = "Home Improvement 🪚"
    ..description = "An endless and delightful hole",
  DemoGroup.toolSharing: Group()
    ..name = "Tool Sharing 🛠️"
    ..description = "Making Marx proud",
  DemoGroup.cooking: Group()
    ..name = "Cooking 🍳"
    ..description = "😋 on the cheap and local",
  DemoGroup.restaurants: Group()
    ..name = "Restaurants 👨‍🍳"
    ..description = "Tasty food and good vibes",
  DemoGroup.programming: Group()
    ..name = "Programming ⌨️"
    ..description =
        "Math for people who want to make money, plus dealing with other people who want to make money without doing math",
}.map((key, value) => MapEntry(key, value.jonRebuild((e) {
      if (e.defaultMembershipModeration == Moderation.MODERATION_UNKNOWN) {
        e.defaultMembershipModeration = Moderation.UNMODERATED;
      }
      if (e.defaultPostModeration == Moderation.MODERATION_UNKNOWN) {
        e.defaultPostModeration = Moderation.UNMODERATED;
      }
      if (e.defaultEventModeration == Moderation.MODERATION_UNKNOWN) {
        e.defaultEventModeration = Moderation.UNMODERATED;
      }
      if (e.visibility == vm.Visibility.VISIBILITY_UNKNOWN) {
        e.visibility = vm.Visibility.GLOBAL_PUBLIC;
      }
      e.defaultMembershipPermissions.addAll([
        Permission.VIEW_POSTS,
        Permission.CREATE_POSTS,
        Permission.VIEW_EVENTS,
        Permission.CREATE_EVENTS
      ]);
    }))));
