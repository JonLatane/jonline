import '../app_state.dart';
import '../generated/posts.pb.dart';
import 'jonline_account.dart';
import 'jonline_clients.dart';
import 'server_errors.dart';

/// Operations based on [JonlineAccount.selectedAccount] and
/// [JonlineAccount.selectedServer] that are useful whether or not
/// the user is logged in.
extension JonlineOperations on JonlineAccount {
  static Future<Posts?> getPosts(
      {GetPostsRequest? request,
      Function(String)? showMessage,
      bool forReplies = false}) async {
    final client = await JonlineClients.getSelectedOrDefaultClient(
        showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return null;
    }
    await communicationDelay;
    // showMessage?.call("Loading posts...");
    final Posts posts;
    try {
      posts = await client.getPosts(request ?? GetPostsRequest(),
          options: JonlineAccount.selectedAccount?.authenticatedCallOptions);
    } catch (e) {
      showMessage?.call('Error loading ${forReplies ? "replies" : "posts"}.');
      if (showMessage != null) await communicationDelay;
      showMessage?.call(formatServerError(e));
      return null;
    }
    return posts;
  }
}
