import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:jonline/utils/proto_utils.dart';
import 'package:username_gen/username_gen.dart';

import '../app_state.dart';
import '../generated/events.pb.dart';
import '../generated/google/protobuf/timestamp.pb.dart';
import '../generated/groups.pb.dart';
import '../generated/jonline.pbgrpc.dart';
import '../generated/permissions.pbenum.dart';
import '../generated/posts.pb.dart';
import '../generated/users.pb.dart';
import '../generated/visibility_moderation.pb.dart' as vm;
import '../generated/visibility_moderation.pbenum.dart';
import '../my_platform.dart';
import 'jonline_account.dart';
import 'jonline_account_operations.dart';
import 'jonline_clients.dart';

postDemoData(
    JonlineAccount account, Function(String) showSnackBar, AppState appState,
    {bool randomizePosts = false}) async {
  final JonlineClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
    return;
  }
  await account.ensureAccessToken(showMessage: showSnackBar);

  final demoGroups =
      await generateDemoGroups(client, account, showSnackBar, appState);
  final List<Post> posts = await generateTopicPosts(
      client, account, showSnackBar, appState, demoGroups, randomizePosts);

  await generateEvents(
      client, account, showSnackBar, appState, demoGroups, randomizePosts);

  List<JonlineAccount> sideAccounts =
      await generateSideAccounts(client, account, showSnackBar, appState, 30);

  showSnackBar("Generating conversations...");
  await generateConversations(
      client, account, showSnackBar, appState, demoGroups, posts, sideAccounts);

  final int relationshipsCreated = await generateFollowRelationships(
    client,
    account,
    showSnackBar,
    appState,
    sideAccounts,
  );
  final int membershipsCreated = await generateGroupMemberships(
    client,
    account,
    demoGroups,
    showSnackBar,
    appState,
    sideAccounts,
  );

  showSnackBar(
      "Created $relationshipsCreated follow relationships and joined $membershipsCreated groups.");
}

Future<void> generateConversations(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    Map<DemoGroup, Group> demoGroups,
    List<Post> topLevelPosts,
    List<JonlineAccount> sideAccounts) async {
  final List<Post> posts = List.of(topLevelPosts, growable: true);

  List<JonlineAccount> replyAccounts = [
    account,
    ...sideAccounts,
    ...sideAccounts
  ];
  int replyCount = 0;
  var lastMessageTime = DateTime.now();
  final totalReplies = 1 + Random().nextInt(posts.length * 30);
  final targets = posts;
  // showSnackBar('Replying to "${post.title}"...');
  for (int i = 0; i < totalReplies; i++) {
    final targetAccount = replyAccounts[_random.nextInt(replyAccounts.length)];
    final reply = _demoReplies[_random.nextInt(_demoReplies.length)];
    final target = targets[_random.nextInt(targets.length)];
    try {
      final replyPost = await client.createPost(
          Post(
            replyToPostId: target.id,
            content: reply,
          ),
          options: targetAccount.authenticatedCallOptions);
      targets.add(replyPost);
      replyCount += 1;
      if (shouldNotify(lastMessageTime)) {
        showSnackBar("Posted $replyCount replies.");
        lastMessageTime = DateTime.now();
      }
    } catch (e) {
      showSnackBar("Error posting demo data: $e");
      return;
    }
  }
  showSnackBar("Posted $replyCount total replies 🎉🎉🎉🎉🎉 ");
}

Future<List<Post>> generateTopicPosts(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    Map<DemoGroup, Group> demoGroups,
    bool randomize) async {
  final List<Post> posts = [];
  var topLevelPosts = List.of(_demoPosts);
  if (randomize) {
    topLevelPosts.shuffle();
  }
  var lastMessageTime = DateTime.now();
  for (final demoPost in topLevelPosts) {
    final groups = demoPost.groups;
    final basePost = demoPost.post;

    // showSnackBar(
    //     'Posting "${basePost.title}" across ${groups.length} groups...');
    try {
      final post = await client.createPost(basePost,
          options: account.authenticatedCallOptions);
      posts.add(post);
      final index = topLevelPosts.indexOf(demoPost);
      if (shouldNotify(lastMessageTime)) {
        showSnackBar("Posted ${index + 1} demo topics...");
        lastMessageTime = DateTime.now();
      }
      for (final demoGroup in groups) {
        final group = demoGroups[demoGroup]!;
        await client.createGroupPost(
            GroupPost(groupId: group.id, postId: post.id),
            options: account.authenticatedCallOptions);
      }
    } catch (e) {
      showSnackBar("Error posting demo data: $e");
      rethrow;
    }
    // await communicationDelay;
  }
  showSnackBar("Posted ${posts.length} demo topics.");
  return posts;
}

Future<List<Event>> generateEvents(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    Map<DemoGroup, Group> demoGroups,
    bool randomize) async {
  final List<Event> posts = [];
  var events = List.of(_demoEvents);
  if (randomize) {
    events.shuffle();
  }
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
        final group = demoGroups[demoGroup]!;
        await client.createGroupPost(
            GroupPost(groupId: group.id, postId: event.post.id),
            options: account.authenticatedCallOptions);
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

Future<List<JonlineAccount>> generateSideAccounts(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    int count) async {
  final List<int> range = [for (var i = 0; i < count; i += 1) i];
  final List<Uint8List> avatars = [];
  final httpClient = http.Client();

  var lastMessageTime = DateTime.now();
  while (avatars.length < range.length) {
    http.Response response = await httpClient
        .get(Uri.parse('https://100k-faces.glitch.me/random-image'), headers: {
      if (!MyPlatform.isWeb) "User-Agent": "Jonline Flutter Client",
      // if (!MyPlatform.isWeb) "Host": "thispersondoesnotexist.com"
    });
    avatars.add(response.bodyBytes);
  }

  showSnackBar("Loaded ${avatars.length} avatars.");

  Iterable<Future<JonlineAccount?>> futures = range.map((i) async {
    JonlineAccount? sideAccount;
    String fakeAccountName = generateRandomName();
    int retryCount = 0;
    int sideAccountsLoaded = 0;
    lastMessageTime = DateTime.now();
    while (retryCount < 15) {
      try {
        final JonlineAccount? sideAccount = await JonlineAccount.createAccount(
            account.server, fakeAccountName, getRandomString(15), (m) {
          // if (!m.contains("insecurely") &&
          //     !m.contains("already exists") &&
          //     !m.contains("Failed to create account")) {
          //   showSnackBar(m);
          // }
        }, allowInsecure: account.allowInsecure, selectAccount: false);
        if (sideAccount != null) {
          final User? user = await sideAccount.updateUserData();
          if (user != null) {
            user.permissions.add(Permission.RUN_BOTS);
            if (avatars.length > i) {
              final avatar = avatars[i];
              // final compressedAvatar = encodeJpg(avatar);
              final uploadResult = await http
                  .post(
                    Uri.parse("https://${account.server}/media"),
                    headers: {
                      "Content-Type": "image/jpeg",
                      "Filename": "avatar.jpeg",
                      // Can be handy to use main account access token as well here...
                      "Authorization": sideAccount.accessToken
                    },
                    body: avatar,
                  )
                  .onError((error, stackTrace) => http.post(
                        Uri.parse("http://${account.server}/media"),
                        headers: {
                          "Content-Type": "image/jpeg",
                          "Filename": "avatar.jpeg",
                          "Authorization": sideAccount.accessToken
                        },
                        body: avatar,
                      ))
                  .onError((error, stackTrace) =>
                      showSnackBar("Failed to upload avatar: $error"));
              if (uploadResult.statusCode == 200) {
                user.avatarMediaId = uploadResult.body;
              }
              // client.get
              // JonlineServer? server = account.server;
              // await client.updateUser(user,
              //     options: account.authenticatedCallOptions);

              // user.avatar = encodeJpg(avatar);
            }
            await client.updateUser(user,
                options: account.authenticatedCallOptions);
            await sideAccount.updateUserData();
          }
          appState.updateAccountList();
          sideAccountsLoaded++;
          if (shouldNotify(lastMessageTime)) {
            showSnackBar("Created $sideAccountsLoaded/$count side accounts...");
            lastMessageTime = DateTime.now();
          }
          return sideAccount;
        }
      } catch (e) {
        fakeAccountName = generateRandomName();
        retryCount++;
      }
    }
    return sideAccount;
  });

  List<JonlineAccount> sideAccounts =
      (await Future.wait(futures.toList())).whereNotNull().toList();
  showSnackBar("Created ${sideAccounts.length} side accounts.");

  return sideAccounts;
}

Future<int> generateFollowRelationships(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    List<JonlineAccount> sideAccounts) async {
  //Generate follow relationships between side accounts and originating account
  int relationshipsCreated = 0;

  final originalAccountDupes = sideAccounts.length * 2;
  final targetAccounts = [
    ...List.filled(originalAccountDupes, account),
    ...sideAccounts
  ];
  var lastMessageTime = DateTime.now();
  for (final sideAccount in sideAccounts) {
    // showSnackBar("Creating relationships for ${sideAccount.username}.");
    final followedAccounts = [sideAccount];
    final maxFollows = targetAccounts.length - originalAccountDupes;
    final totalFollows = 3 + Random().nextInt(max(0, maxFollows - 3));
    try {
      for (int i = 0; i < totalFollows; i++) {
        final followableAccounts = List.of(targetAccounts)
          ..removeWhere((a) => followedAccounts.contains(a));
        final targetAccount =
            followableAccounts[_random.nextInt(followableAccounts.length)];
        followedAccounts.add(targetAccount);
        await client.createFollow(
            Follow(
              userId: sideAccount.userId,
              targetUserId: targetAccount.userId,
            ),
            options: sideAccount.authenticatedCallOptions);
        relationshipsCreated += 1;

        if (shouldNotify(lastMessageTime)) {
          showSnackBar("Created $relationshipsCreated follow relationships.");
          lastMessageTime = DateTime.now();
        }
      }
    } catch (e) {
      showSnackBar("Error following side account: $e");
    }
  }
  return relationshipsCreated;
}

Future<int> generateGroupMemberships(
    JonlineClient client,
    JonlineAccount account,
    Map<DemoGroup, Group> demoGroups,
    Function(String) showSnackBar,
    AppState appState,
    List<JonlineAccount> sideAccounts) async {
  int membershipsCreated = 0;
  var lastMessageTime = DateTime.now();

  for (final sideAccount in sideAccounts) {
    // showSnackBar("Creating relationships for ${sideAccount.username}.");
    final targetGroups = List.of(demoGroups.values);
    final maxJoins = targetGroups.length;
    final totalJoins = 2 + Random().nextInt(max(0, maxJoins - 2));
    try {
      for (int i = 0; i < totalJoins; i++) {
        final group = targetGroups[_random.nextInt(targetGroups.length)];
        await client.createMembership(
            Membership(
              userId: sideAccount.userId,
              groupId: group.id,
            ),
            options: sideAccount.authenticatedCallOptions);
        targetGroups.remove(group);
        membershipsCreated += 1;

        if (shouldNotify(lastMessageTime)) {
          showSnackBar("Created $membershipsCreated group memberships.");
          lastMessageTime = DateTime.now();
        }
      }
    } catch (e) {
      showSnackBar("Error following side account: $e");
    }
  }
  return membershipsCreated;
}

String generateRandomName() => UsernameGen().generate();

enum DemoGroup {
  coolKidsClub,
  everyoneWelcome,
  music,
  sports,
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

shouldNotify(DateTime lastMessageTime) =>
    DateTime.now().difference(lastMessageTime) > const Duration(seconds: 5);

final Map<DemoGroup, Group> _demoGroups = Map.unmodifiable({
  DemoGroup.coolKidsClub: Group(
      name: "Cool Kids Club",
      description: "Only the coolest ppl get in. Approval required to join.",
      defaultMembershipModeration: Moderation.PENDING,
      visibility: Visibility.SERVER_PUBLIC),
  DemoGroup.everyoneWelcome:
      Group(name: "Everyone Welcome", description: "Feel free to join!"),
  DemoGroup.music: Group(
      name: "Funktastic",
      description:
          "🎵 Post your Spotify playlists or eventually videos n stuff"),
  DemoGroup.sports: Group(
      name: "Yoked",
      description:
          "Climbing, biking, running, spikeball, other things involving balls\n\nAlso barbells.\n\nAnd fuck it dance too!"),
  DemoGroup.makers: Group(
      name: "Makers",
      description:
          "Creators of art, music, furniture, knitting, software... just make stuff!"),
  DemoGroup.yoga:
      Group(name: "Yoga", description: "🤸‍♀️🧘‍♀️🧘‍♂️🤸‍♂️🧘‍♀️🧘‍♂️🤸‍♀️"),
  DemoGroup.engineering: Group(
      name: "Real Engineering",
      description: "Like with real things not just logic 😂😭"),
  DemoGroup.math: Group(
      name: "Math",
      description:
          "Shit that is literally not real but also the basis of reality"),
  DemoGroup.science:
      Group(name: "Science", description: "Straight from the lab bench"),
  DemoGroup.tech: Group(
      name: "Tech",
      description:
          "General tech 🤓🤖💚\n\nNo billionaire-worship bullshit allowed."),
  DemoGroup.gamers: Group(
      name: "Gamers",
      description:
          "Bro honestly I'm just tryna play Doom Eternal and soon Sonic Frontiers on easy mode here"),
  DemoGroup.homeImprovement: Group(
      name: "Home Improvement", description: "An endless and delightful hole"),
  DemoGroup.toolSharing:
      Group(name: "Tool Sharing", description: "Making Marx proud"),
  DemoGroup.cooking:
      Group(name: "Cooking", description: "😋 on the cheap and local"),
  DemoGroup.restaurants:
      Group(name: "Restaurants", description: "Tasty food and good vibes"),
  DemoGroup.programming: Group(
      name: "Programming",
      description:
          "Math for people who want to make money, plus dealing with other people who want to make money without doing math"),
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

// Many generated from https://www.commments.com :)
final List<String> _demoReplies = [
  "Wow, that's a great idea!",
  "I don't think that's really the best idea.",
  "And your mother too!",
  "You should be kind to others and hydrate",
  "Ape stonk moon",
  "Mercury in the microwave",
  "It seems like you need some self healing",
  "Leading the way mate.",
  "I admire your spaces m8",
  "My 15 year old child rates this shot very killer!",
  "Alluring. So cool.",
  "Navigation, avatar, boldness, shot – incredible, friend.",
  "Nice use of turquoise in this design mate",
  "Green. Mmh wondering if this comment will hit the generateor as well...",
  "Really simple!",
  "Flat design is going to die.",
  "Outstandingly thought out! I'd love to see a video of how it works.",
  "Just radiant.",
  "I think I'm crying. It's that **bold**.",
  "I want to learn this kind of camera angle! Teach me.",
  "This colour palette has navigated right into my heart.",
  "Magnificent work you have here.",
  "These are appealing and sick :-)",
  "Excellent, friend. I admire the use of lines and button!",
  "Let me take a nap... great shot, anyway.",
  "I want to learn this kind of type! Teach me.",
  "This is minimal work!!",
  "Nice use of aquamarine in this shot, friend.",
  "I think I'm crying. It's that classic.",
  "Shade, background image, icons, shot - strong, friend.",
];

class DemoPost {
  final List<DemoGroup> groups;
  Post post;

  DemoPost(this.groups, this.post);
}

final List<DemoPost> _demoPosts = [
  DemoPost(
      [DemoGroup.yoga, DemoGroup.sports, DemoGroup.coolKidsClub],
      Post(
        title: "Magical fountain of kinesthetic knowledge",
        link: "https://www.triangleintegratedyoga.com",
      )),
  DemoPost(
      [DemoGroup.yoga, DemoGroup.sports, DemoGroup.coolKidsClub],
      Post(
        title: "Homegirl know how to make you work n have fun",
        link: "https://www.laurenaliviayoga.com",
      )),
  DemoPost(
      [DemoGroup.gamers],
      Post(
        title: "Gonna play this with my lil second cousin",
        link: "https://frontiers.sonicthehedgehog.com",
      )),
  DemoPost(
      [DemoGroup.sports],
      Post(
          title: "Not having fear is aid",
          link: "https://www.youtube.com/watch?v=7XhsuT0xctI",
          content: "Nah but fr Alexa Handhold is one of the GOAT")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      Post(
          title: "ChordCalc, my first indie app, on the Play Store",
          link:
              "https://play.google.com/store/apps/details?id=com.jonlatane.composer&hl=en_US&gl=US",
          content:
              "Not maintained, but still available on the Play Store. For the time (around 2011) I wrote a pretty novel algorithm for naming chords that I've reused in BeatScratch.")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      Post(
          title: "ChordCalc on GitHub",
          link: "https://github.com/falrm/ChordCalcComposer",
          content: "Use or improve my algorithms 💚")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.tech, DemoGroup.programming],
      Post(
          title:
              "Topologica was my second app; here's an article about how it works!",
          link:
              "https://medium.com/fully-automated-luxury-robot-music/topologica-jazz-orbifolds-and-your-event-sourced-flux-driven-dream-code-f8e24443a941",
          content:
              '''Several years ago I published my first mobile app, Topologica for Android.

### Features
* A MIDI sequencer that works basically like a TR-8 (built for 4/4 in 16th notes).
* A unique way of navigating through chord progressions in an "orbifold."
* The ability to, in real-time, rewrite your sequences as you navigate through chord progressions.
    * This really feels like a game to the end user :)
* Support for MIDI over USB (or Bluetooth, with other apps)

### Built with
* Kotlin
* Anko (now defunct)
* Android APIs
* FluidSynth

Topologica was renamed, open-sourced, and lives on as "BeatScratch Legacy" on the Play Store. 
Large parts of Topologica/BeatScratch Legacy live on in my current app, BeatScratch, available
for iOS, macOS, Android and web.

I plan to re-implement the Orbifold in BeatScratch, at which point this app will be deprecated.''')),
  DemoPost(
      [DemoGroup.music, DemoGroup.math],
      Post(
          title: "BeatScratch Legacy (formerly Topologica) on the Play Store",
          link:
              "https://play.google.com/store/apps/details?id=com.jonlatane.beatpad.free&hl=en_US&gl=US",
          content: "Not maintained, but still available on the Play Store.")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      Post(
          title: "BeatScratch Legacy (formerly Topologica) on GitHub",
          link: "https://github.com/falrm/BeatPad",
          content:
              "Again, not maintained, but still available on the Play Store. Anko (which the UI's built with) is also not maintained 🥲")),
  DemoPost(
      [
        DemoGroup.everyoneWelcome,
        DemoGroup.makers,
        DemoGroup.toolSharing,
        DemoGroup.coolKidsClub
      ],
      Post(
          title: "Yay socialism!",
          link: "https://www.dsanc.org",
          content: "I should go to more meetings but eh I pay my dues.")),
  DemoPost(
      [DemoGroup.restaurants, DemoGroup.coolKidsClub],
      Post(
          title: "These burgers look soooo good 😋",
          link: "https://www.eatqueenburger.com")),
  DemoPost(
      [DemoGroup.music],
      Post(
          title: "BeatScratch on the App Store",
          link: "https://apps.apple.com/us/app/beatscratch/id1509788448",
          content: "The freshest, slickest way to scratch your beat!")),
  DemoPost(
      [DemoGroup.music],
      Post(
          title: "BeatScratch on the Play Store",
          link:
              "https://play.google.com/store/apps/details?id=io.beatscratch.beatscratch_flutter_redux&hl=en_US&gl=US",
          content:
              "Android version of BeatScratch! FluidSynth doesn't quite keep up with AudioKit but still among the best you can get on Android.")),
  DemoPost(
      [DemoGroup.everyoneWelcome],
      Post(
          title: "My reddit account, or at least the one I'd post here 🙃",
          link: "https://www.reddit.com/user/pseudocomposer",
          embedLink: true)),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.tech],
      Post(
          title: "These are cool! I want one",
          link: "https://www.fuell.us/products/fuell-fllow-e-motorcycle")),
  DemoPost(
      [
        DemoGroup.everyoneWelcome,
        DemoGroup.sports,
        DemoGroup.music,
        DemoGroup.coolKidsClub
      ],
      Post(
          title:
              "My Insta 📸 See my animals, music, mediocre climbing and gymbro-ing, other apps and more weirdness.",
          link: "https://instagram.com/jons_meaningless_life")),
  DemoPost(
      [DemoGroup.everyoneWelcome],
      Post(
          title:
              "My LinkedIn, if you wanna see things people have paid me to do",
          link: "https://www.linkedin.com/in/jonlatane/")),
  DemoPost(
      [DemoGroup.music],
      Post(
          title: "Jack Stratton rockin a Harpejji",
          link: "https://www.instagram.com/reel/CsY_NinvWDW/",
          embedLink: true)),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.tech, DemoGroup.programming],
      Post(
        title:
            "Jonline images are on DockerHub so you can try/deploy it easily without touching anything Rust/React/Flutter",
        link: "https://hub.docker.com/r/jonlatane/jonline",
      )),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.programming],
      Post(
          title: "Jonline on GitHub",
          link: "https://github.com/jonlatane/jonline",
          content:
              "Jonline is released under the AGPLv3. Please contribute! The intent is to create a safe, trustworthy, provably open social media reference platform, using mostly boring but established tech.")),
  DemoPost([DemoGroup.everyoneWelcome, DemoGroup.tech],
      Post(title: "What is Jonline?", content: '''Corporate social media sucks. 
Jonline is a new approach to social media that hopes to keep user data hyper-local - 
owned by ourselves or others in our physical communities, rather than any single 
corporation or data source. At its core is a 
[well-documented, performant open-source protocol](https://github.com/JonLatane/jonline/blob/main/docs/protocol.md). 
A Jonline *instance* or community (like the one you're reading this post on - probably 
[jonline.io](https://jonline.io) or [getj.online](https://getj.online)) 
is designed for use cases like:

* Neighborhoods, communities, or cities
* (Ex-)Coworkers wanting a private channel to chat
* Run/bike/etc. clubs
* Hobbyist/maker/homebrewing groups
* Local concert listings
* Event venue or fitness studio calendars
* Board game groups
* D&D parties
* Online game clans
* Customer/interpersonal calendar management for individual artists, teachers, coaches, etc.

Instances are designed to be maintainable by a *single person* of reasonable technical 
knowledge in any of these groups, at the absolute lowest possible cost, on any 
provider or their own hardware. A Jonline instance is much like a ListServ, 
Slack/Discord server, Reddit community, IRC server or PHPBB/vBulletin/Wordpress 
forum if you're old, or a Facebook group if you're *really* old.

Importantly, to "run" a community like this one at [jonline.io](https://jonline.io), 
you have to (or really, *get to*) run your own Jonline server. 
(This is unlike Slack/Discord/Reddit/Facebook, but more like IRC, open-source forums/blogs,
ListServ, or email.) You can (and should!) sign up here at [jonline.io](https://jonline.io) 
to post/comment; just remember I'll likely delete all your (and my) data as I continue developing here. 
The upside: nothing you do here at [jonline.io](https://jonline.io) matters! ✨🔮✨ 
So just button-mash a password (your account will stay logged-in/available until 
data is reset) and you can post/comment away in a few seconds! Create lots of 
accounts and shitpost to your heart's desire!

Jonline is trustworthy, because you can literally look at the 
[code where it stores](https://github.com/JonLatane/jonline/blob/main/backend/src/rpcs/create_account.rs#L30) 
and [validates your passwords](https://github.com/JonLatane/jonline/blob/main/backend/src/rpcs/login.rs#L30),
even [the code that was used to generate *this post you're reading right now and the "bot"-generated demo comments on it*](https://github.com/JonLatane/jonline/blob/main/frontends/flutter/lib/models/demo_data.dart) 🤯🙃

If you're familiar with OpenSocial and Mastodon, Jonline is something like them. Notably, Jonline does *not*
support reactions to posts as they do (and is deliberately not architected in a "big data" way so as to support this).
On similar hardware, Jonline has a faster web UI than either thanks to Tamagui and NextJS, and a faster BE thanks to Rust.
[Jonline's Docker images are currently 105MB](https://hub.docker.com/r/jonlatane/jonline/tags),
while [Mastodon's are 500+MB](https://hub.docker.com/r/tootsuite/mastodon/tags),
and [OpenSocial's are over 1GB](https://hub.docker.com/r/goalgorilla/open_social_docker/tags).
Further, Jonline should (hopefully) be easier to deploy, partly by virtue of having such minimal system requirements.
Finally, Jonline's Discussion/Chat UI feature doesn't have any great
analogues in other open-source social networks.

In terms of features, unlike most other networks, Jonline supports Events and will eventually support
more independent-monetization features, so admins can make money for hosting their instance. (Planned dev approach is:
Invoicing/Direct Payments for a foundation, then Ticketed Events, then Products and/or Subscriptions.)

If you feel moderately brave, take a crack at spinning up your own server. 
Spinning one up locally should take under a minute if you already have Postgres and Docker 
installed (and can configure a fresh Postgres DB in under 45 seconds 😁) using 
[the Docker setup instructions on Jonline's DockerHub page](https://hub.docker.com/r/jonlatane/jonline).
Use this to turn any computer into a server, if you are comfortable managing HTTPS certs.
It should also be easy to deploy to any Kubernetes (K8s) provider using
[the Kubernetes setup instructions on Jonline's GitHub page](https://github.com/jonlatane/jonline).
(For reference, I pay \$15/mo for [DigitalOcean Kubernetes Service](https://m.do.co/c/1eaa3f9e536c) 
plus \$8/mo per static IP/website).

If you feel *really* brave, and wanna contribute to any part of a cutting-edge Rust/React/Flutter full-stack 
app, info on that is *also* at https://github.com/jonlatane/jonline.
''')),
];

class DemoEvent {
  final List<DemoGroup> groups;
  Event post;

  DemoEvent(this.groups, this.post);
}

final List<DemoEvent> _demoEvents = [
  DemoEvent(
      [DemoGroup.yoga, DemoGroup.sports, DemoGroup.coolKidsClub],
      Event(
          post: Post(
              title: "Bull City Run Club",
              link: "https://bullcityrunning.com/events/runclub/",
              content:
                  "A weekly run club for all levels of runners. Meets at Bull City Running's downtown location, with running starting at 6pm. 3, 4 and 6 mile routes are available. Registration isn't required, but costs only \$1 (cash) and lets you earn free beers, pint glasses, and T-shirts!"),
          instances: _generateWeeklyInstances(
              '2023-04-12 18:00:00-04:00', '2023-04-12 19:00:00-04:00', 20))),
  DemoEvent(
      [DemoGroup.yoga, DemoGroup.sports, DemoGroup.coolKidsClub],
      Event(
          post: Post(
              title: "RAD Ride",
              link: "https://www.instagram.com/ride_around_durham/",
              content:
                  "Ride Around Durham is a weekly bike ride for all levels. Meets at Duke Chapel at 6pm, with the ride starting at 6:30. Bring a beer and grab another after the ride at the bar we land at! New routes every week."),
          instances: _generateWeeklyInstances(
              '2023-04-13 18:00:00-04:00', '2023-04-13 21:00:00-04:00', 20))),
  DemoEvent(
      [DemoGroup.yoga, DemoGroup.sports, DemoGroup.coolKidsClub],
      Event(
          post: Post(
              title: "Pony Ride",
              link: "https://www.ponysaurusbrewing.com/events",
              content:
                  "Monthly bike ride for all levels. Meets at Major the Bull in downtown Durham at 6:30pm, with the ride starting at 7. Beers and raffles for bar tabs and more at Pony after! New routes every month."),
          instances: [
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
  DemoEvent(
      [DemoGroup.music, DemoGroup.coolKidsClub],
      Event(
          post: Post(
              title: "GRiZmas in July",
              link: "https://www.mynameisgriz.com/news/2023/gij",
              content:
                  "Annual Wilmington music event that this year could always be the last of. Send the man off with love and appreciation regardless!"),
          instances: [
            _generateInstance(
                '2023-07-28 13:00:00-04:00', '2023-07-30 17:00:00-04:00'),
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
  return EventInstance(
      startsAt: Timestamp(
        seconds:
            Int64.fromInts(0, (startsAt.millisecondsSinceEpoch / 1000).floor()),
      ),
      endsAt: Timestamp(
        seconds:
            Int64.fromInts(0, (endsAt.millisecondsSinceEpoch / 1000).floor()),
      ));
}

final _random = Random();
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));
