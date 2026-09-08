import '../../app_state.dart';
import '../../generated/rellm.pbgrpc.dart';
import '../../generated/posts.pb.dart';
import '../rellm_account.dart';
import '../rellm_account_operations.dart';
import '../rellm_clients.dart';
import 'demo_accounts.dart';
import 'demo_conversations.dart';
import 'demo_events.dart';
import 'demo_groups.dart';
import 'demo_posts.dart';

createDemoData(RellmAccount account, Function(String) showSnackBar,
    AppState appState) async {
  final RellmClient? client =
      await (account.getClient(showMessage: showSnackBar));
  if (client == null) {
    showSnackBar("Account not ready.");
    return;
  }
  await account.ensureAccessToken(showMessage: showSnackBar);

  final demoGroups =
      await generateDemoGroups(client, account, showSnackBar, appState);
  final List<Post> posts = await generateTopicPosts(
      client, account, showSnackBar, appState, demoGroups);

  final events = await generateEvents(
    client,
    account,
    showSnackBar,
    appState,
    demoGroups,
  );

  List<RellmAccount> sideAccounts =
      await generateSideAccounts(client, account, showSnackBar, appState, 30);

  showSnackBar("Generating conversations...");
  await generateConversations(client, account, showSnackBar, appState,
      posts + events.map((e) => e.post).toList(), sideAccounts);

  await createFollowsAndGroupMemberships(
      account, showSnackBar, appState, sideAccounts);
}
