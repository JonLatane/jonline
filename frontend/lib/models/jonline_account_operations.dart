import 'package:jonline/app_state.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/generated/google/protobuf/empty.pb.dart';
import 'package:jonline/generated/users.pb.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/models/server_errors.dart';

import '../generated/posts.pb.dart';

extension JonlineAccountOperations on JonlineAccount {
  static Future<Posts?> getSelectedPosts(
      {GetPostsRequest? request,
      Function(String)? showMessage,
      bool forReplies = false}) async {
    final client = await JonlineClients.getSelectedOrDefaultClient(
        showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return null;
    }
    // showMessage?.call("Loading posts...");
    final Posts posts;
    try {
      posts = await client.getPosts(GetPostsRequest(),
          options: JonlineAccount.selectedAccount?.authenticatedCallOptions);
    } catch (e) {
      showMessage?.call('Error loading ${forReplies ? "replies" : "posts"}.');
      if (showMessage != null) await communicationDelay;
      showMessage?.call(formatServerError(e));
      return null;
    }
    return posts;
  }

  Future<Posts?> getPosts(
      {GetPostsRequest? request, Function(String)? showMessage}) async {
    final client = await getClient(showMessage: showMessage);
    if (client == null) {
      showMessage?.call("Error: No client");
      return null;
    }
    showMessage?.call("Loading posts...");
    final Posts posts;
    try {
      posts = await client.getPosts(request ?? GetPostsRequest(),
          options: authenticatedCallOptions);
    } catch (e) {
      showMessage?.call("Error loading posts.");
      if (showMessage != null) await communicationDelay;
      showMessage?.call(formatServerError(e));
      return null;
    }
    return posts;
  }

  Future<User?> getUser({Function(String)? showMessage}) async {
    final User? user;
    try {
      user = await (await getClient(showMessage: showMessage))
          ?.getCurrentUser(Empty(), options: authenticatedCallOptions);
    } catch (e) {
      showMessage?.call(formatServerError(e));
      return null;
    }
    if (user == null) {
      showMessage?.call('No user data received.');
    }
    return user;
  }

  Future<void> updateUserData({Function(String)? showMessage}) async {
    final User? user = await getUser(showMessage: showMessage);
    if (user == null) return;

    username = user.username;
    userId = user.id;
    await save();
  }

  Future<void> updateRefreshToken({Function(String)? showMessage}) async {
    ExpirableToken? newRefreshToken;
    try {
      newRefreshToken = await (await getClient(showMessage: showMessage))
          ?.refreshToken(RefreshTokenRequest(authToken: authorizationToken));
    } catch (e) {
      showMessage?.call(formatServerError(e));
      return;
    }
    if (newRefreshToken == null) {
      showMessage?.call('No refresh token received.');
      return;
    }
    refreshToken = newRefreshToken.token;
    await save();
  }
}
