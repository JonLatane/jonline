// import '../app_state.dart';
import '../generated/authentication.pb.dart';
import '../generated/google/protobuf/empty.pb.dart';
// import '../generated/posts.pb.dart';
import '../generated/users.pb.dart';
import 'jonline_account.dart';
import 'jonline_clients.dart';
import 'server_errors.dart';

extension JonlineAccountOperations on JonlineAccount {
  // Future<Posts?> getPosts(
  //     {GetPostsRequest? request, Function(String)? showMessage}) async {
  //   final client = await getClient(showMessage: showMessage);
  //   if (client == null) {
  //     showMessage?.call("Error: No client");
  //     return null;
  //   }
  //   showMessage?.call("Loading posts...");
  //   final Posts posts;
  //   try {
  //     posts = await client.getPosts(request ?? GetPostsRequest(),
  //         options: authenticatedCallOptions);
  //   } catch (e) {
  //     showMessage?.call("Error loading posts.");
  //     if (showMessage != null) await communicationDelay;
  //     showMessage?.call(formatServerError(e));
  //     return null;
  //   }
  //   return posts;
  // }

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
      // showMessage?.call('No user data received.');
    }
    return user;
  }

  Future<void> updateUserData({Function(String)? showMessage}) async {
    final User? user = await getUser(showMessage: showMessage);
    if (user == null) return;

    username = user.username;
    userId = user.id;
    permissions = user.permissions;
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

  Future<void> updateServiceVersion({Function(String)? showMessage}) async {
    String? serviceVersion;
    try {
      serviceVersion = (await (await getClient(showMessage: showMessage))
              ?.getServiceVersion(Empty()))
          ?.version;
    } catch (e) {
      showMessage?.call(formatServerError(e));
      return;
    }
    if (serviceVersion == null) {
      showMessage?.call('No service version received.');
      return;
    }
    this.serviceVersion = serviceVersion;
    await save();
  }
}
