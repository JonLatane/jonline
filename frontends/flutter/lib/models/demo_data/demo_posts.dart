import 'dart:math';

import 'package:jonline/models/jonline_account_operations.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../jonline_account.dart';
import '../jonline_clients.dart';
import 'demo_groups.dart';

createDemoPosts(
    JonlineAccount account, Function(String) showSnackBar, AppState appState,
    {bool randomOrder = false}) async {
  final JonlineClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
    return;
  }
  await account.ensureAccessToken(showMessage: showSnackBar);

  final groups =
      await getExistingDemoGroups(client, account, showSnackBar, appState);
  await generateTopicPosts(client, account, showSnackBar, appState, groups,
      randomOrder: randomOrder);
}

Future<List<Post>> generateTopicPosts(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    Map<DemoGroup, Group> demoGroups,
    {bool randomOrder = false}) async {
  final List<Post> posts = [];
  var topLevelPosts = List.of(_demoPosts);
  if (randomOrder) {
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
        final group = demoGroups[demoGroup];
        if (group != null) {
          await client.createGroupPost(
              GroupPost()
                ..groupId = group.id
                ..postId = post.id,
              options: account.authenticatedCallOptions);
        }
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

class DemoPost {
  final List<DemoGroup> groups;
  Post post;

  DemoPost(this.groups, this.post);
}

final List<DemoPost> _demoPosts = [
  DemoPost(
      [DemoGroup.yoga, DemoGroup.fitness, DemoGroup.coolKidsClub],
      Post()
        ..title = "Magical fountain of kinesthetic knowledge"
        ..link = "https://www.triangleintegratedyoga.com"),
  DemoPost(
      [DemoGroup.yoga, DemoGroup.fitness, DemoGroup.coolKidsClub],
      Post()
        ..title = "Homegirl know how to make you work n have fun"
        ..link = "https://www.laurenaliviayoga.com"),
  DemoPost(
      [DemoGroup.gamers],
      Post()
        ..title = "Gonna play this with my lil second cousin"
        ..link = "https://frontiers.sonicthehedgehog.com"),
  DemoPost(
      [DemoGroup.fitness],
      Post()
        ..title = "Not having fear is aid"
        ..link = "https://www.youtube.com/watch?v=7XhsuT0xctI"
        ..content = "Nah but fr Alexa Handhold is one of the GOAT"),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      Post()
        ..title = "ChordCalc, my first indie app, on the Play Store"
        ..link =
            "https://play.google.com/store/apps/details?id=com.jonlatane.composer&hl=en_US&gl=US"
        ..content =
            "Not maintained, but still available on the Play Store. For the time (around 2011) I wrote a pretty novel algorithm for naming chords that I've reused in BeatScratch."),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      Post()
        ..title = "ChordCalc on GitHub"
        ..link = "https://github.com/falrm/ChordCalcComposer"
        ..content = "Use or improve my algorithms 💚"),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.tech, DemoGroup.programming],
      Post()
        ..title =
            "Topologica was my second app; here's an article about how it works!"
        ..link =
            "https://medium.com/fully-automated-luxury-robot-music/topologica-jazz-orbifolds-and-your-event-sourced-flux-driven-dream-code-f8e24443a941"
        ..content =
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

I plan to re-implement the Orbifold in BeatScratch, at which point this app will be deprecated.'''),
  DemoPost(
      [DemoGroup.music, DemoGroup.math],
      Post()
        ..title = "BeatScratch Legacy (formerly Topologica) on the Play Store"
        ..link =
            "https://play.google.com/store/apps/details?id=com.jonlatane.beatpad.free&hl=en_US&gl=US"
        ..content = "Not maintained, but still available on the Play Store."),
  DemoPost(
      [DemoGroup.music, DemoGroup.math, DemoGroup.programming],
      Post()
        ..title = "BeatScratch Legacy (formerly Topologica) on GitHub"
        ..link = "https://github.com/falrm/BeatPad"
        ..content =
            "Again, not maintained, but still available on the Play Store. Anko (which the UI's built with) is also not maintained 🥲"),
  DemoPost(
      [
        DemoGroup.everyoneWelcome,
        DemoGroup.makers,
        DemoGroup.toolSharing,
        DemoGroup.coolKidsClub
      ],
      Post()
        ..title = "Yay socialism!"
        ..link = "https://www.dsanc.org"
        ..content = "I should go to more meetings but eh I pay my dues."),
  DemoPost(
      [DemoGroup.restaurants, DemoGroup.coolKidsClub],
      Post()
        ..title = "These burgers look soooo good 😋"
        ..link = "https://www.eatqueenburger.com"),
  DemoPost(
      [DemoGroup.music],
      Post()
        ..title = "BeatScratch on the App Store"
        ..link = "https://apps.apple.com/us/app/beatscratch/id1509788448"
        ..content = "The freshest, slickest way to scratch your beat!"),
  DemoPost(
      [DemoGroup.music],
      Post()
        ..title = "BeatScratch on the Play Store"
        ..link =
            "https://play.google.com/store/apps/details?id=io.beatscratch.beatscratch_flutter_redux&hl=en_US&gl=US"
        ..content =
            "Android version of BeatScratch! FluidSynth doesn't quite keep up with AudioKit but still among the best you can get on Android."),
  DemoPost(
      [DemoGroup.everyoneWelcome],
      Post()
        ..title = "My reddit account, or at least the one I'd post here 🙃"
        ..link = "https://www.reddit.com/user/pseudocomposer"
        ..embedLink = true),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.tech],
      Post()
        ..title = "These are cool! I want one"
        ..link = "https://www.fuell.us/products/fuell-fllow-e-motorcycle"),
  DemoPost(
      [
        DemoGroup.everyoneWelcome,
        DemoGroup.fitness,
        DemoGroup.music,
        DemoGroup.coolKidsClub
      ],
      Post()
        ..title =
            "My Insta 📸 See my animals, music, mediocre climbing and gymbro-ing, other apps and more weirdness."
        ..link = "https://instagram.com/jons_meaningless_life"),
  DemoPost(
      [DemoGroup.everyoneWelcome],
      Post()
        ..title =
            "My LinkedIn, if you wanna see things people have paid me to do"
        ..link = "https://www.linkedin.com/in/jonlatane/"),
  DemoPost(
      [DemoGroup.music],
      Post()
        ..title = "Jack Stratton rockin a Harpejji"
        ..link = "https://www.instagram.com/reel/CsY_NinvWDW/"
        ..embedLink = true),
  DemoPost(
    [DemoGroup.everyoneWelcome, DemoGroup.tech, DemoGroup.programming],
    Post()
      ..title =
          "Jonline images are on DockerHub so you can try/deploy it easily without touching anything Rust/React/Flutter"
      ..link = "https://hub.docker.com/r/jonlatane/jonline",
  ),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.programming],
      Post()
        ..title = "Jonline on GitHub"
        ..link = "https://github.com/jonlatane/jonline"
        ..content =
            "Jonline is released under the AGPLv3. Please contribute! The intent is to create a safe, trustworthy, provably open social media reference platform, using mostly boring but established tech."),
  DemoPost(
      [DemoGroup.everyoneWelcome, DemoGroup.tech],
      Post()
        ..title = "What is Jonline?"
        ..content = '''Corporate social media sucks. 
Jonline is a new approach to social media that hopes to keep user data hyper-local - 
owned by ourselves or others in our physical communities, rather than any single 
corporation or data source. At its core is a 
[well-documented, performant open-source protocol](https://github.com/JonLatane/jonline/blob/main/docs/protocol.md). 
A Jonline *instance* or community (like the one you're reading this post on - probably 
[jonline.io](https://jonline.io)) 
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
even [the code that was used to generate *this post you're reading right now and the "bot"-generated demo comments on it*](https://github.com/JonLatane/jonline/blob/main/frontends/flutter/lib/models/demo_data/demo_posts.dart) 🤯🙃

If you're familiar with OpenSocial and Mastodon, Jonline is something like them. Notably, Jonline does *not*
support reactions to posts as they do (and is deliberately not architected in a "big data" way so as to support this).
On similar hardware, Jonline has a faster web UI than either thanks to Tamagui and NextJS, and a faster BE thanks to Rust.
[Jonline's Docker images are currently 115MB](https://hub.docker.com/r/jonlatane/jonline/tags),
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
'''),
];

final _random = Random();
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));

shouldNotify(DateTime lastMessageTime) =>
    DateTime.now().difference(lastMessageTime) > const Duration(seconds: 5);
