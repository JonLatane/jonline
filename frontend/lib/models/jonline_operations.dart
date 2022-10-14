import '../app_state.dart';
import '../generated/groups.pb.dart';
import '../generated/posts.pb.dart';
import '../generated/users.pb.dart';
import 'jonline_account.dart';
import 'jonline_account_operations.dart';
import 'jonline_clients.dart';
import 'server_errors.dart';

/// Operations based on [JonlineAccount.selectedAccount] and
/// [JonlineAccount.selectedServer] that are useful whether or not
/// the user is logged in.
extension JonlineOperations on JonlineAccount {
  static Future<GetMembersResponse?> getMembers(
      {GetMembersRequest? request, Function(String)? showMessage}) async {
    await JonlineAccount.selectedAccount
        ?.ensureRefreshToken(showMessage: showMessage);
    final client = await JonlineClients.getSelectedOrDefaultClient(
        showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return null;
    }
    await communicationDelay;
    // showMessage?.call("Loading posts...");
    final GetMembersResponse response;
    try {
      response = await client.getMembers(request ?? GetMembersRequest(),
          options: JonlineAccount.selectedAccount?.authenticatedCallOptions);
    } catch (e) {
      showMessage?.call('Error loading members.');
      if (showMessage != null) await communicationDelay;
      showMessage?.call(formatServerError(e));
      return null;
    }
    return response;
  }

  static Future<GetUsersResponse?> getUsers(
      {GetUsersRequest? request, Function(String)? showMessage}) async {
    await JonlineAccount.selectedAccount
        ?.ensureRefreshToken(showMessage: showMessage);
    final client = await JonlineClients.getSelectedOrDefaultClient(
        showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return null;
    }
    await communicationDelay;
    // showMessage?.call("Loading posts...");
    final GetUsersResponse response;
    try {
      response = await client.getUsers(request ?? GetUsersRequest(),
          options: JonlineAccount.selectedAccount?.authenticatedCallOptions);
    } catch (e) {
      showMessage?.call('Error loading users');
      if (showMessage != null) await communicationDelay;
      showMessage?.call(formatServerError(e));
      return null;
    }
    return response;
  }

  static Future<GetGroupsResponse?> getGroups(
      {GetGroupsRequest? request,
      Function(String)? showMessage,
      bool forReplies = false}) async {
    await JonlineAccount.selectedAccount
        ?.ensureRefreshToken(showMessage: showMessage);
    final client = await JonlineClients.getSelectedOrDefaultClient(
        showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return null;
    }
    await communicationDelay;
    // showMessage?.call("Loading posts...");
    final GetGroupsResponse response;
    try {
      response = await client.getGroups(request ?? GetGroupsRequest(),
          options: JonlineAccount.selectedAccount?.authenticatedCallOptions);
    } catch (e) {
      showMessage?.call('Error loading ${forReplies ? "replies" : "posts"}.');
      if (showMessage != null) await communicationDelay;
      showMessage?.call(formatServerError(e));
      return null;
    }
    return response;
  }

  static Future<Posts?> getPosts(
      {GetPostsRequest? request,
      Function(String)? showMessage,
      bool forReplies = false}) async {
    await JonlineAccount.selectedAccount
        ?.ensureRefreshToken(showMessage: showMessage);
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
