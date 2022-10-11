import 'dart:convert';

import 'package:jonline/models/jonline_server.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../generated/authentication.pb.dart';
import '../generated/jonline.pbgrpc.dart';
import '../generated/permissions.pbenum.dart';
import '../generated/users.pb.dart';
import 'jonline_clients.dart';
import 'server_errors.dart';
import 'storage.dart';

const uuid = Uuid();

/// Local storage for the user's account on a given Jonline instance.
/// Constructors are private; factory methods [loginToAccount] and [createAccount]
/// should be used instead.
class JonlineAccount {
  static JonlineAccount? _selectedAccount;
  static JonlineAccount? get selectedAccount => _selectedAccount;
  static set selectedAccount(JonlineAccount? account) {
    _selectedAccount = account;
    if (account != null) {
      appStorage.setString('selected_account', account.id);
    } else {
      appStorage.remove('selected_account');
    }
  }

  // static String get selectedServer =>
  //     selectedAccount?.server ?? _selectedServer;

  // static const String _selectedServer = defaultServer;

  static Future<JonlineAccount?> loginToAccount(String server, String username,
      String password, Function(String) showMessage,
      {bool allowInsecure = false, bool selectAccount = true}) async {
    return _authAccount(
        (client) =>
            client.login(LoginRequest(username: username, password: password)),
        ['Logging in', 'login', 'Logged in'],
        server,
        username,
        password,
        showMessage,
        allowInsecure: allowInsecure,
        selectAccount: selectAccount);
    // JonlineClient? client = await JonlineClients.createAndTestClient(server,
    //     showMessage: showMessage, allowInsecure: allowInsecure);
    // if (client == null) return null;
    // await communicationDelay;

    // AuthTokenResponse authResponse;
    // try {
    //   authResponse = await client
    //       .login(LoginRequest(username: username, password: password));
    // } catch (e) {
    //   await communicationDelay;
    //   showMessage("Failed to login to $server as \"$username\"!");
    //   final formattedError = formatServerError(e);
    //   showMessage(formattedError);
    //   return null;
    // }
    // await communicationDelay;
    // showMessage("Logged in to $server as $username!");

    // final account = JonlineAccount._fromAuth(server,
    //     authResponse.authToken.token, authResponse.refreshToken.token, username,
    //     allowInsecure: allowInsecure);
    // await account.saveNew(atBeginning: selectAccount);
    // if (selectAccount) {
    //   JonlineAccount.selectedAccount = account;
    //   JonlineServer.selectedServer =
    //       (await JonlineServer.servers).firstWhere((s) => s.server == server);
    //   await JonlineServer.selectedServer.updateConfiguration();
    //   await JonlineServer.selectedServer.save();
    // }
    // return account;
  }

  static Future<JonlineAccount?> createAccount(String server, String username,
      String password, Function(String) showMessage,
      {bool allowInsecure = false, bool selectAccount = true}) async {
    return _authAccount(
        (client) => client.createAccount(
            CreateAccountRequest(username: username, password: password)),
        ['Creating account', 'create account', 'Created account'],
        server,
        username,
        password,
        showMessage,
        allowInsecure: allowInsecure,
        selectAccount: selectAccount);
  }

  static Future<JonlineAccount?> _authAccount(
      Future<AuthTokenResponse> Function(JonlineClient) authenticator,
      List<String> verbs,
      String server,
      String username,
      String password,
      Function(String) showMessage,
      {bool allowInsecure = false,
      bool selectAccount = true}) async {
    JonlineClient? client = await JonlineClients.createAndTestClient(server,
        showMessage: showMessage, allowInsecure: allowInsecure);
    if (client == null) return null;
    if (selectAccount) {
      await communicationDelay;
    }
    // showMessage("Connected to $server! ${verbs[0]}...");
    AuthTokenResponse authResponse;
    try {
      authResponse = await authenticator(client);
    } catch (e) {
      if (selectAccount) {
        await communicationDelay;
      }
      showMessage("Failed to ${verbs[1]} $username on $server!");
      final formattedError = formatServerError(e);
      showMessage(formattedError);
      return null;
    }
    await communicationDelay;
    showMessage("${verbs[2]} $username on $server!");

    final account = JonlineAccount._fromAuth(
        server, authResponse.authToken.token, authResponse.refreshToken.token,
        allowInsecure: allowInsecure);
    await account.saveNew(atBeginning: selectAccount);
    if (selectAccount) {
      JonlineAccount.selectedAccount = account;
      JonlineServer.selectedServer =
          (await JonlineServer.servers).firstWhere((s) => s.server == server);
      await JonlineServer.selectedServer.updateConfiguration();
      await JonlineServer.selectedServer.save();
    }
    return account;
  }

  final String id;
  final String server;
  final String authorizationToken;
  String serviceVersion;
  String refreshToken;
  int refreshTokenExpiresAt;
  bool allowInsecure;
  User? user;
  String get userId => user?.id ?? '';
  String get username => user?.username ?? '';
  List<Permission> get permissions => user?.permissions ?? [];

  /// Used by [loginToAccount] and [createAccount] when creating a new account.
  JonlineAccount._fromAuth(
      this.server, this.authorizationToken, this.refreshToken,
      {this.allowInsecure = false})
      : id = uuid.v4(),
        // userId = "",
        serviceVersion = "",
        refreshTokenExpiresAt = 0; //permissions = [];

  /// Used by [accounts] to load data.
  JonlineAccount._fromJson(Map<String, dynamic> json)
      : id = json['id'],
        // username = json['username'] ?? '',
        // userId = json['userId'] ?? '',
        server = json['server'],
        authorizationToken = json['authorizationToken'],
        refreshToken = json['refreshToken'],
        allowInsecure = json['allowInsecure'],
        serviceVersion = json['serviceVersion'] ?? "",
        refreshTokenExpiresAt = json['refreshTokenExpiresAt'] ?? 0,
        // permissions = json['permissions'] == null
        //     ? []
        //     : (json['permissions'] as List<dynamic>)
        //         .map((e) => Permission.values.firstWhere((p) => p.name == e,
        //             orElse: () => Permission.PERMISSION_UNKNOWN))
        //         .where((e) => e != Permission.PERMISSION_UNKNOWN)
        //         .toList(),
        user = json['user'] == null
            ? null
            : User.fromJson(jsonEncode(json['user']));

  Map<String, dynamic> toJson() => {
        'id': id,
        // 'username': username,
        // 'userId': userId,
        'server': server,
        'authorizationToken': authorizationToken,
        'refreshToken': refreshToken,
        'refreshTokenExpiresAt': refreshTokenExpiresAt,
        'allowInsecure': allowInsecure,
        'serviceVersion': serviceVersion,
        // 'permissions': permissions.map((e) => e.name).toList(),
        'user': user == null ? null : jsonDecode(user!.writeToJson()),
      };

  Future<void> save() async {
    List<JonlineAccount> jsonArray = await accounts;
    final index = jsonArray.indexWhere((element) => element.id == id);
    jsonArray[index] = this;
    await updateAccountList(jsonArray);
  }

  Future<void> saveNew({bool atBeginning = true}) async {
    List<JonlineAccount> jsonArray = await accounts;
    jsonArray.insert(atBeginning ? 0 : jsonArray.length, this);
    await updateAccountList(jsonArray);
  }

  Future<void> delete() async {
    List<JonlineAccount> jsonArray = await accounts;
    jsonArray.removeWhere((e) => e.id == id);
    await updateAccountList(jsonArray);
  }

  static Future<bool?> updateAccountList(List<JonlineAccount> accounts) async {
    if (!accounts.any((a) => a.id == selectedAccount?.id)) {
      appStorage.remove('selected_account');
      selectedAccount = null;
    }
    return appStorage.setStringList(
        'jonline_accounts', accounts.map((e) => jsonEncode(e)).toList());
  }

  static Future<List<JonlineAccount>> get accounts async {
    List<String> jsonArrayString =
        appStorage.getStringList('jonline_accounts') ?? [];
    final accountsJson = jsonArrayString
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    // List<Map<String, dynamic>> jsonArray = await accountsJson;
    final accounts =
        accountsJson.map((e) => JonlineAccount._fromJson(e)).toList();

    if (selectedAccount != null) {
      selectedAccount = accounts.firstWhere((a) => a.id == selectedAccount?.id,
          orElse: () => selectedAccount!);
    }
    return accounts;
  }
}
