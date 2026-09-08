import 'dart:math';

import 'package:rellm/generated/events.pb.dart';
import 'package:rellm/models/rellm_account_operations.dart';

import '../../app_state.dart';
import '../../generated/rellm.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../rellm_account.dart';
import '../rellm_clients.dart';
import 'demo_accounts.dart';

createDemoConversations(
    RellmAccount account, Function(String) showSnackBar, AppState appState,
    {bool randomizePosts = false}) async {
  final RellmClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
    return;
  }
  await account.ensureAccessToken(showMessage: showSnackBar);
  final posts = (await client.getPosts(GetPostsRequest()
        ..listingType = PostListingType.ALL_ACCESSIBLE_POSTS))
      .posts;
  final events = (await client.getEvents(GetEventsRequest()
        ..listingType = EventListingType.ALL_ACCESSIBLE_EVENTS))
      .events;
  List<RellmAccount> sideAccounts =
      await generateSideAccounts(client, account, showSnackBar, appState, 30);

  await generateConversations(client, account, showSnackBar, appState,
      posts + events.map((e) => e.post).toList(), sideAccounts);
}

Future<void> generateConversations(
    RellmClient client,
    RellmAccount account,
    Function(String) showSnackBar,
    AppState appState,
    List<Post> topLevelPosts,
    List<RellmAccount> sideAccounts) async {
  final List<Post> posts = List.of(topLevelPosts, growable: true);

  List<RellmAccount> replyAccounts = [
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
          Post()
            ..replyToPostId = target.id
            ..content = reply,
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
  "Green. Mmh wondering if this comment will hit the generator as well...",
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

final _random = Random();

shouldNotify(DateTime lastMessageTime) =>
    DateTime.now().difference(lastMessageTime) > const Duration(seconds: 5);
