// import '../app_state.dart';
import '../generated/authentication.pb.dart';
import '../generated/google/protobuf/empty.pb.dart';
// import '../generated/posts.pb.dart';
import '../generated/users.pb.dart';
import 'jonline_account.dart';
import 'jonline_clients.dart';
import 'server_errors.dart';

extension JonlineAccountOperations on JonlineAccount {
  Future<User?> getUser({Function(String)? showMessage}) async {
    if (!await ensureAccessToken()) return null;

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

  Future<User?> updateUserData({Function(String)? showMessage}) async {
    final User? user = await getUser(showMessage: showMessage);
    if (user == null) return null;

    this.user = user;
    await save();
    return user;
  }

  Future<bool> ensureAccessToken({Function(String)? showMessage}) async {
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    if (accessTokenExpiresAt - now < 60) {
      return await _updateAccessToken(showMessage: showMessage);
    }
    return true;
  }

  Future<bool> _updateAccessToken({Function(String)? showMessage}) async {
    ExpirableToken? newAccessToken;
    try {
      final client = await getClient(showMessage: showMessage);
      final response = await client?.accessToken(
          AccessTokenRequest()..refreshToken = authorizationToken);
      newAccessToken = response?.accessToken;
    } catch (e) {
      showMessage?.call(formatServerError(e));
      return false;
    }
    if (newAccessToken == null || newAccessToken.token.isEmpty) {
      showMessage?.call('No access token received.');
      return false;
    }
    accessToken = newAccessToken.token;
    accessTokenExpiresAt = newAccessToken.expiresAt.seconds.toInt();
    await save();
    return true;
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
