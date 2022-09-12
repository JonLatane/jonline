import 'package:jonline/app_state.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/generated/posts.pb.dart';
import 'package:jonline/models/jonline_account.dart';

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
            title: "This is a post with a title - no link or content"),
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
            title: "This is a post with a title and link only",
            link: "https://instagram.com/jon_luvs_ya"),
        options: account.authenticatedCallOptions);
  } catch (e) {
    showSnackBar("Error posting demo data: $e");
    return;
  }
  await communicationDelay;
  showSnackBar("Posted demo data successfully!");
}
