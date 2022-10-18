import 'dart:math';

import 'package:jonline/utils/proto_utils.dart';

import '../app_state.dart';
import '../generated/groups.pb.dart';
import '../generated/visibility_moderation.pb.dart' as vm;
import '../generated/jonline.pbgrpc.dart';
import '../generated/permissions.pbenum.dart';
import '../generated/posts.pb.dart';
import '../generated/users.pb.dart';
import '../generated/visibility_moderation.pbenum.dart';
import 'jonline_account.dart';
import 'jonline_account_operations.dart';
import 'jonline_clients.dart';

postDemoData(
    JonlineAccount account, Function(String) showSnackBar, AppState appState,
    {bool randomize = false}) async {
  final JonlineClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
    return;
  }
  // showSnackBar("Updating refresh token...");
  await account.ensureRefreshToken(showMessage: showSnackBar);

  final demoGroups =
      await generateDemoGroups(client, account, showSnackBar, appState);
  // showSnackBar("Relevant Groups exist or have been generated.");

  final List<Post> posts = [];
  var topLevelPosts = List.of(_demoData);
  if (randomize) {
    topLevelPosts.shuffle();
  }
  for (final demoPost in topLevelPosts) {
    final groups = demoPost.groups;
    final basePost = demoPost.post;

    showSnackBar(
        'Posting "${basePost.title}" across ${groups.length} groups...');
    try {
      final post = await client.createPost(basePost,
          options: account.authenticatedCallOptions);
      posts.add(post);
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
    await communicationDelay;
  }
  showSnackBar(
      "Posted demo topics successfully! 🎉 Generating users, relationships, and conversations...");
  // JonlineAccount? sideAccount;
  List<JonlineAccount> sideAccounts = await generateSideAccounts(
      client, account, demoGroups, showSnackBar, appState, 7);
  List<JonlineAccount> replyAccounts = [
    account,
    ...sideAccounts,
    ...sideAccounts
  ];
  int replyCount = 0;
  var lastMessageTime = DateTime.now();
  final totalReplies = 1 + Random().nextInt(posts.length * 200);
  final targets = posts;
  // showSnackBar('Replying to "${post.title}"...');
  for (int i = 0; i < totalReplies; i++) {
    final targetAccount = replyAccounts[_random.nextInt(replyAccounts.length)];
    final reply = _demoReplies[_random.nextInt(_demoReplies.length)];
    final target = targets[_random.nextInt(targets.length)];
    try {
      final replyPost = await client.createPost(
          CreatePostRequest(
            replyToPostId: target.id,
            content: reply,
          ),
          options: targetAccount.authenticatedCallOptions);
      targets.add(replyPost);
      replyCount += 1;
      if (DateTime.now().difference(lastMessageTime) >
          const Duration(seconds: 5)) {
        showSnackBar("Posted $replyCount replies.");
        lastMessageTime = DateTime.now();
      }
    } catch (e) {
      showSnackBar("Error posting demo data: $e");
      return;
    }
  }
  showSnackBar("Posted all demo data, with $replyCount replies 🎉🎉🎉🎉🎉 ");
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
  }
  return result;
}

Future<List<JonlineAccount>> generateSideAccounts(
    JonlineClient client,
    JonlineAccount account,
    Map<DemoGroup, Group> demoGroups,
    Function(String) showSnackBar,
    AppState appState,
    int count) async {
  List<JonlineAccount> sideAccounts = [];
  String prefix = "";
  String fakeAccountName = generateRandomName();

  while (sideAccounts.length < count && prefix.length < 200) {
    try {
      final JonlineAccount? sideAccount = await JonlineAccount.createAccount(
          account.server, "$prefix$fakeAccountName", getRandomString(15), (m) {
        if (!m.contains("insecurely") &&
            !m.contains("already exists") &&
            !m.contains("Failed to create account")) {
          showSnackBar(m);
        }
      }, allowInsecure: account.allowInsecure, selectAccount: false);
      // final JonlineClient? sideClient =
      //     await (sideAccount?.getClient(showMessage: showSnackBar));
      if (sideAccount != null) {
        final User? user = await sideAccount.updateUserData();
        if (user != null) {
          user.permissions.add(Permission.RUN_BOTS);
          await client.updateUser(user,
              options: account.authenticatedCallOptions);
          await sideAccount.updateUserData();
        }
        // showSnackBar("Created side account ${sideAccount.username}.");
        appState.updateAccountList();
        sideAccounts.add(sideAccount);
        prefix = "";
        fakeAccountName = generateRandomName();
      } else {
        prefix = "not-$prefix";
      }
    } catch (e) {
      prefix = "not-$prefix";
    }
  }

  //Generate follow relationships between side accounts and originating account
  int relationshipsCreated = 0;

  final originalAccountDupes = sideAccounts.length * 2;
  final targetAccounts = [
    ...List.filled(originalAccountDupes, account),
    ...sideAccounts
  ];
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
      }
    } catch (e) {
      showSnackBar("Error following side account: $e");
    }
  }

  //Generate follow relationships between side accounts and originating account
  int membershipsCreated = 0;

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
      }
    } catch (e) {
      showSnackBar("Error following side account: $e");
    }
  }
  showSnackBar(
      "Created $relationshipsCreated follow relationships and joined $membershipsCreated groups.");
  return sideAccounts;
}

String generateRandomName() =>
    _demoNameComponents.map((fix) => fix[_random.nextInt(fix.length)]).join('');

final List<List<String>> _demoNameComponents = [
  [
    'kim',
    'bob',
    'tim',
    'jess',
    'kim',
    'mar',
    'jen',
    'jeff',
    'anton',
    'chris',
    'mor',
    'shay',
    'trey',
    'josh',
    'joe',
    'jim',
    'jimmy',
    'shan',
    'han',
    'mike',
    'hil'
  ],
  [
    'berly',
    'othy',
    'athon',
    'bothy',
    'ine',
    'an',
    'frey',
    'nifer',
    'berly',
    'bo',
    'ary'
  ]
];

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

final Map<DemoGroup, Group> _demoGroups = Map.unmodifiable({
  DemoGroup.coolKidsClub: Group(
      name: "Cool Kids Club",
      description: "Only the coolest ppl get in. Approval required to join.",
      defaultMembershipModeration: Moderation.PENDING),
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
      description: "Like with real things not software 😂😭"),
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
  CreatePostRequest post;

  DemoPost(this.groups, this.post);
}

final List<DemoPost> _demoData = [
  DemoPost(
      [DemoGroup.yoga, DemoGroup.sports],
      CreatePostRequest(
        title: "Magical fountain of kinesthetic knowledge",
        link: "https://www.triangleintegratedyoga.com",
      )),
  DemoPost(
      [DemoGroup.yoga, DemoGroup.sports],
      CreatePostRequest(
        title: "Homegirl know how to make you work n have fun",
        link: "https://www.laurenaliviayoga.com",
      )),
  DemoPost(
      [DemoGroup.gamers],
      CreatePostRequest(
        title: "Gonna play this with my lil second cousin",
        link: "https://frontiers.sonicthehedgehog.com",
      )),
  DemoPost(
      [DemoGroup.sports],
      CreatePostRequest(
          title: "Not having fear is aid",
          link: "https://www.disneyplus.com/movies/free-solo/3ibzvuU6iPlE",
          content: "Nah but fr Alexa Handhold is one of the GOAT")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      CreatePostRequest(
          title: "ChordCalc, my first indie app, on the Play Store",
          link:
              "https://play.google.com/store/apps/details?id=com.jonlatane.composer&hl=en_US&gl=US",
          content:
              "Not maintained, but still available on the Play Store. For the time (around 2011) I wrote a pretty novel algorithm for naming chords that I've reused in BeatScratch.")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      CreatePostRequest(
          title: "ChordCalc on GitHub",
          link: "https://github.com/falrm/ChordCalcComposer",
          content: "Use or improve my algorithms 💚")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.tech, DemoGroup.programming],
      CreatePostRequest(
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

I plan to re-implement the Orbifold in BeatScratch, at which point this app will be deprecated.
string''')),
  DemoPost(
      [DemoGroup.music, DemoGroup.math],
      CreatePostRequest(
          title: "BeatScratch Legacy (formerly Topologica) on the Play Store",
          link:
              "https://play.google.com/store/apps/details?id=com.jonlatane.beatpad.free&hl=en_US&gl=US",
          content: "Not maintained, but still available on the Play Store.")),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      CreatePostRequest(
          title: "BeatScratch Legacy (formerly Topologica) on GitHub",
          link: "https://github.com/falrm/BeatPad",
          content:
              "Again, not maintained, but still available on the Play Store. Anko (which the UI's built with) is also not maintained 🥲")),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.makers, DemoGroup.toolSharing],
      CreatePostRequest(
          title: "Yay socialism!",
          link: "https://www.dsanc.org",
          content: "I should go to more meetings but eh I pay my dues.")),
  DemoPost(
      [DemoGroup.restaurants],
      CreatePostRequest(
          title: "These burgers look soooo good 😋",
          link: "https://www.eatqueenburger.com")),
  DemoPost(
      [DemoGroup.music],
      CreatePostRequest(
          title: "BeatScratch on the App Store",
          link: "https://apps.apple.com/us/app/beatscratch/id1509788448",
          content: "The freshest, slickest way to scratch your beat!")),
  DemoPost(
      [DemoGroup.music],
      CreatePostRequest(
          title: "BeatScratch on the Play Store",
          link:
              "https://play.google.com/store/apps/details?id=io.beatscratch.beatscratch_flutter_redux&hl=en_US&gl=US",
          content:
              "Android version of BeatScratch! FluidSynth doesn't quite keep up with AudioKit but still among the best you can get on Android.")),
  DemoPost(
      [DemoGroup.everyoneWelcome],
      CreatePostRequest(
          title: "My reddit account, or at least the one I'd post here 🙃",
          link: "https://www.reddit.com/user/pseudocomposer")),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.tech],
      CreatePostRequest(
          title: "These are cool! I want one",
          link: "https://www.fuell.us/products/fuell-fllow-e-motorcycle")),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.sports, DemoGroup.music],
      CreatePostRequest(
          title:
              "My Insta 📸 See my animals, music, mediocre climbing and gymbro-ing, other apps and more weirdness.",
          link: "https://instagram.com/jon_luvs_ya")),
  DemoPost(
      [DemoGroup.everyoneWelcome],
      CreatePostRequest(
        title: "My LinkedIn, if you wanna see things people have paid me to do",
        link: "https://www.linkedin.com/in/jonlatane/",
      )),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.tech, DemoGroup.programming],
      CreatePostRequest(
        title:
            "Jonline images are on DockerHub so you can try/deploy it easily without touching anything Rust/Flutter",
        link: "https://hub.docker.com/r/jonlatane/jonline",
      )),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.programming],
      CreatePostRequest(
          title: "Jonline on GitHub",
          link: "https://github.com/jonlatane/jonline",
          content:
              "Jonline is released under the GPLv3. Please contribute! The intent is to create a safe, trustworthy, provably open social media reference platform, using mostly boring but established tech.")),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.tech],
      CreatePostRequest(
          title: "What is Jonline??",
          content: '''Large-scale capitalist social media sucks for most of us. 
Jonline takes a minimalist approach to social media, both in terms of user count 
(per "instance" at least) and features. 
A Jonline *instance* or community (like the one you're reading this post on - probably 
[jonline.io](https://jonline.io) or [getj.online](https://getj.online)) 
is designed for groups like:

* Neighborhoods, communities, or cities
* (Ex-)Coworkers wanting a private channel to chat
* Run/bike/etc. clubs
* Hobbyist/maker groups
* Local concert listings
* Event venue calendars
* Board game groups
* D&D parties
* App user groups
* Online game clans

Instances are designed to be maintainable by a *single person* in any of these groups,
at a cost of no more than \$15/mo, on any provider you choose or your own hardware. 
Jonline keeps things simple: there are only Users/People (with follows/friendships),
Groups (with memberships), Posts (with replies), and Events (TODO, but also with replies),
along with visibility features like most other social media apps, and easy-to-use 
admin and moderation tools. A Jonline  instance is much like a ListServ, 
Slack/Discord server, Reddit community, IRC server or PHPBB/vBulletin/Wordpress 
forum if you're old, or a Facebook group if you're *really* old.

(If you want to pay me to host an instance and/or develop features for your needs, 
get in touch! I work a real job making much more boring but profitable things than
Jonline, but would love to get paid to do this kind of stuff for myself. There 
will probably be a waitlist until I have at least 5-10 interested parties and have 
developed the features everyone needs, though. And I will expect things like domain 
ownership and moderating your instance to stay on your end, with me just providing 
hosting.)

Jonline is trustworthy, because you can literally look at the 
[code where it stores](https://github.com/JonLatane/jonline/blob/main/backend/src/rpcs/create_account.rs#L30) 
and [validates your passwords](https://github.com/JonLatane/jonline/blob/main/backend/src/rpcs/login.rs#L30),
even [the code that was used to generate *this post you're reading right now and the "bot"-generated demo comments on it*](https://github.com/JonLatane/jonline/blob/main/frontend/lib/models/demo_data.dart) 🤯🙃

Importantly, to "run" a community like this one at [jonline.io](https://jonline.io), 
you have to (or really, *get to*) run your own Jonline server. 
(This is unlike Slack/Discord/Reddit/Facebook, but more like IRC, open-source forums/blogs,
ListServ, or email.) You can (and should!) sign up here at [jonline.io](https://jonline.io) 
to post/comment; just remember I'll likely delete all your (and my) data as I continue developing here. 
The upside: nothing you do here at [jonline.io](https://jonline.io) matters! ✨🔮✨ 
So just button-mash a password (your account will stay logged-in/available until 
data is reset) and you can post/comment away in a few seconds! Create lots of 
accounts and shitpost to your heart's desire! Comment about how easy/hard my 
account-switching UI makes it to shitpost! Give me a reason to implement 
moderation tools! 🙃 (But like, don't be a real asshole pls)

If you feel moderately brave, take a crack at spinning up your own server. 
Part of the design is that running your own server, or one for your local 
community, should be easy, cheap, and portable to any Kubernetes (K8s) provider 
(I pay \$15/mo for [DigitalOcean Kubernetes Service](https://m.do.co/c/1eaa3f9e536c)). 
Instructions for quick K8s setup are at https://github.com/jonlatane/jonline, or if you're more a
DIY Docker person, images are at https://hub.docker.com/r/jonlatane/jonline.

If you feel *really* brave, and wanna contribute to a Flutter/Rust full-stack
app, info on that stuff is *also* at https://github.com/jonlatane/jonline.
The tl;dr: [Jonline BE](https://hub.docker.com/r/jonlatane/jonline) is a monolithic Rust server that runs 
[a gRPC server via Tonic on port 27707](https://github.com/JonLatane/jonline/blob/0e51d0350c01496fcb6ad1c94efb21ce426ff857/backend/src/main.rs#L45)
along with web servers via Rocket on ports 
[443 (if TLS is enabled)](https://github.com/JonLatane/jonline/blob/0e51d0350c01496fcb6ad1c94efb21ce426ff857/backend/src/main.rs#L78), 
[80](https://github.com/JonLatane/jonline/blob/0e51d0350c01496fcb6ad1c94efb21ce426ff857/backend/src/main.rs#L68) and 
[8000](https://github.com/JonLatane/jonline/blob/0e51d0350c01496fcb6ad1c94efb21ce426ff857/backend/src/main.rs#L58). 
Jonline FE is a Flutter app that uses the gRPC server; versions can be built for 
iOS, Android, macOS, Windows, Linux, or any other platform Flutter supports. 
Jonline FE's Flutter Web build is also copied to the Jonline BE docker image, 
and served by Rocket on the ports listed. So the [single `jonline` Docker image](https://hub.docker.com/r/jonlatane/jonline) 
is a full-stack app that can be run wherever!
''')),
];

final _random = Random();
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));
