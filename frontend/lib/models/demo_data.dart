import '../app_state.dart';
import '../generated/jonline.pbgrpc.dart';
import '../generated/posts.pb.dart';
import 'jonline_account.dart';
import 'jonline_account_operations.dart';
import 'jonline_clients.dart';

postDemoData(JonlineAccount account, Function(String) showSnackBar) async {
  final JonlineClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
  }
  showSnackBar("Updating refresh token...");
  await account.updateRefreshToken(showMessage: showSnackBar);

  showSnackBar("Posting demo data 1...");
  try {
    await client!.createPost(
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
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;

  showSnackBar("Posting demo data 2...");
  try {
    await client.createPost(
        CreatePostRequest(
            title: "BeatScratch Legacy (formerly Topologica) on the Play Store",
            link:
                "https://play.google.com/store/apps/details?id=com.jonlatane.beatpad.free&hl=en_US&gl=US",
            content: "Not maintained, but still available on the Play Store."),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;
  showSnackBar("Posting demo data 3...");
  try {
    await client.createPost(
        CreatePostRequest(
            title: "Yay socialism!",
            link: "https://www.dsanc.org",
            content: "I should go to more meetings but eh I pay my dues."),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;
  showSnackBar("Posting demo data 4...");
  try {
    await client.createPost(
        CreatePostRequest(
            title: "BeatScratch on the App Store",
            link: "https://apps.apple.com/us/app/beatscratch/id1509788448",
            content: "The freshest, slickest way to scratch your beat!"),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;
  showSnackBar("Posting demo data 5...");
  try {
    await client.createPost(
        CreatePostRequest(
            title: "These burgers look soooo good 😋",
            link: "https://www.eatqueenburger.com"),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;
  await communicationDelay;
  showSnackBar("Posting demo data 6...");
  try {
    await client.createPost(
        CreatePostRequest(
            title: "BeatScratch on the Play Store",
            link:
                "https://play.google.com/store/apps/details?id=io.beatscratch.beatscratch_flutter_redux&hl=en_US&gl=US",
            content:
                "Android version of BeatScratch! FluidSynth doesn't quite keep up with AudioKit but still among the best you can get on Android."),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;
  showSnackBar("Posting demo data 7...");
  try {
    await client.createPost(
        CreatePostRequest(
            title: "These are cool! I want one",
            link: "https://www.fuell.us/products/fuell-fllow-e-motorcycle"),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;

  showSnackBar("Posting demo data 8...");
  try {
    await client.createPost(
        CreatePostRequest(
            title:
                "My Insta 📸 See my animals, music, mediocre climbing and gymbro-ing, other apps and more weirdness.",
            link: "https://instagram.com/jon_luvs_ya"),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;
  showSnackBar("Posted demo data successfully!");
}
