import 'package:rellm/generated/rellm.pbgrpc.dart';

import '../app_state.dart';
import '../generated/groups.pb.dart';
import '../generated/posts.pb.dart';
import '../generated/users.pb.dart';
import 'rellm_account.dart';
import 'rellm_account_operations.dart';
import 'rellm_clients.dart';
import 'server_errors.dart';

/// Operations based on [RellmAccount.selectedAccount] and
/// [RellmAccount.selectedServer] that are useful whether or not
/// the user is logged in.
extension RellmOperations on RellmAccount {
  static Future<GetMembersResponse?> getMembers(
      {GetMembersRequest? request, Function(String)? showMessage}) async {
    return performOperation(
        (client) => client.getMembers(request ?? GetMembersRequest(),
            options: RellmAccount.selectedAccount?.authenticatedCallOptions),
        showMessage: showMessage,
        entityType: "members");
  }

  static Future<GetUsersResponse?> getUsers(
      {GetUsersRequest? request, Function(String)? showMessage}) async {
    return performOperation(
        (client) => client.getUsers(request ?? GetUsersRequest(),
            options: RellmAccount.selectedAccount?.authenticatedCallOptions),
        showMessage: showMessage,
        entityType: "users");
  }

  static Future<GetGroupsResponse?> getGroups({
    GetGroupsRequest? request,
    Function(String)? showMessage,
  }) async {
    return performOperation(
        (client) => client.getGroups(request ?? GetGroupsRequest(),
            options: RellmAccount.selectedAccount?.authenticatedCallOptions),
        showMessage: showMessage,
        entityType: "groups");
  }

  static Future<GetPostsResponse?> getPosts(
      {GetPostsRequest? request,
      Function(String)? showMessage,
      bool forReplies = false}) async {
    return performOperation(
        (client) => client.getPosts(request ?? GetPostsRequest(),
            options: RellmAccount.selectedAccount?.authenticatedCallOptions),
        showMessage: showMessage,
        entityType: forReplies ? "replies" : "posts");
  }

  static Future<GetGroupPostsResponse?> getGroupPosts(
      GetGroupPostsRequest request,
      {Function(String)? showMessage}) async {
    return performOperation(
        (client) => client.getGroupPosts(request,
            options: RellmAccount.selectedAccount?.authenticatedCallOptions),
        showMessage: showMessage,
        entityType: "group posts");
  }

  static final Map<String, DateTime> _lastErrors = {};
  static Future<Response?> performOperation<Response>(
      Future<Response?> Function(RellmClient) operation,
      {Function(String)? showMessage,
      String? entityType}) async {
    await RellmAccount.selectedAccount
        ?.ensureAccessToken(showMessage: showMessage);
    final client = await RellmClients.getSelectedOrDefaultClient(
        showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return null;
    }
    // await communicationDelay;
    // showMessage?.call("Loading $entityType...");
    final Response? response;
    try {
      response = await operation(client);
    } catch (e) {
      if (_lastErrors[entityType ?? 'data'] == null ||
          DateTime.now()
                  .difference(_lastErrors[entityType ?? 'data']!)
                  .inSeconds >
              5) {
        showMessage?.call('Error loading ${entityType ?? 'data'}.');
        if (showMessage != null) await communicationDelay;
        _lastErrors[entityType ?? 'data'] = DateTime.now();
        showMessage?.call(formatServerError(e));
      }
      return null;
    }
    return response;
  }
}
