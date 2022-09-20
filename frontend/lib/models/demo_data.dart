import '../app_state.dart';
import '../generated/jonline.pbgrpc.dart';
import '../generated/posts.pb.dart';
import 'jonline_account.dart';
import 'jonline_account_operations.dart';
import 'jonline_clients.dart';
import 'package:protobuf/protobuf.dart';

postDemoData(JonlineAccount account, Function(String) showSnackBar) async {
  final JonlineClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
  }
  showSnackBar("Updating refresh token...");
  await account.updateRefreshToken(showMessage: showSnackBar);

  for (final data in _demoData) {
    showSnackBar('Posting "${data.title}"...');
    try {
      await client!.createPost(data, options: account.authenticatedCallOptions);
    } catch (e) {
      showSnackBar("Error posting demo data: $e");
      return;
    }
    await communicationDelay;
  }
  showSnackBar("Posted demo data successfully! 🎉");
}

final List<CreatePostRequest> _demoData = [
  CreatePostRequest(
      title:
          "Topologica was my first app; here's an article about how it works!",
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
string'''),
  CreatePostRequest(
      title: "BeatScratch Legacy (formerly Topologica) on the Play Store",
      link:
          "https://play.google.com/store/apps/details?id=com.jonlatane.beatpad.free&hl=en_US&gl=US",
      content: "Not maintained, but still available on the Play Store."),
  CreatePostRequest(
      title: "Yay socialism!",
      link: "https://www.dsanc.org",
      content: "I should go to more meetings but eh I pay my dues."),
  CreatePostRequest(
      title: "These burgers look soooo good 😋",
      link: "https://www.eatqueenburger.com"),
  CreatePostRequest(
      title: "BeatScratch on the App Store",
      link: "https://apps.apple.com/us/app/beatscratch/id1509788448",
      content: "The freshest, slickest way to scratch your beat!"),
  CreatePostRequest(
      title: "BeatScratch on the Play Store",
      link:
          "https://play.google.com/store/apps/details?id=io.beatscratch.beatscratch_flutter_redux&hl=en_US&gl=US",
      content:
          "Android version of BeatScratch! FluidSynth doesn't quite keep up with AudioKit but still among the best you can get on Android."),
  CreatePostRequest(
      title: "My reddit account, or at least the one I'd post here 🙃",
      link: "https://www.reddit.com/user/pseudocomposer"),
  CreatePostRequest(
      title: "These are cool! I want one",
      link: "https://www.fuell.us/products/fuell-fllow-e-motorcycle"),
  CreatePostRequest(
      title:
          "My Insta 📸 See my animals, music, mediocre climbing and gymbro-ing, other apps and more weirdness.",
      link: "https://instagram.com/jon_luvs_ya"),
  CreatePostRequest(
    title: "My LinkedIn, if you wanna see things people have paid me to do",
    link: "https://www.linkedin.com/in/jonlatane/",
  ),
  CreatePostRequest(
    title: "Jonline images are on DockerHub so you can try/deploy it easily",
    link: "https://hub.docker.com/r/jonlatane/jonline",
  ),
  CreatePostRequest(
      title: "Jonline on GitHub",
      link: "https://github.com/jonlatane/jonline",
      content:
          "Jonline is released under the GPLv3. Please contribute! The intent is to create a safe, trustworthy, provably open social media reference platform, using mostly boring but established tech."),
  CreatePostRequest(
      title: "What is Jonline??",
      content: '''The social media that capitalism has given us sucks.

Jonline takes large-scale social media and downsizes it. It's just Posts and Events,
and a single server is meant for a community smaller than 100M users - typically, though,
a handful or a few dozen people. A Jonline instance is much like a ListServ, 
Slack/Discord server, Reddit community, IRC server if 
you're old, or a Facebook group if you're *really* old. It keeps things *very*
simple: just Posts and Events, with replies/comment threads on both. And it's
trustworthy as fuck, because you can literally look at the 
[code where we store](https://github.com/JonLatane/jonline/blob/main/backend/src/rpcs/create_account.rs#L24) 
and [validate your passwords](https://github.com/JonLatane/jonline/blob/main/backend/src/rpcs/login.rs#L30).

Importantly, to "run" a community like this one at [jonline.io](https://jonline.io), 
*you have to run your own Jonline server*. (This is unlike Slack/Discord/Reddit/Facebook,
but more like IRC, ListServ, or email.) You can (and should!) sign up here at 
[jonline.io](https://jonline.io) to post/comment; just remember I'll likely 
delete all your (and my) data as I continue developing here. 
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
'''),
];
