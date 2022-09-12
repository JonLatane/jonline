import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/generated/google/protobuf/empty.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/generated/users.pb.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class JonlineAccount {
  static Future<JonlineClient?> getSelectedOrDefaultClient(
      {Function(String)? showMessage}) async {
    if (selectedAccount == null) {
      return createAndTestClient(defaultServer, showMessage: showMessage);
    }
    return getSelectedClient(showMessage: showMessage);
  }

  static Future<JonlineClient?> getSelectedClient(
      {Function(String)? showMessage}) async {
    if (selectedAccount == null) return null;
    return await selectedAccount!.getClient(showMessage: showMessage);
  }

  static JonlineAccount? get selectedAccount => _selectedAccount;
  static set selectedAccount(JonlineAccount? account) {
    _selectedAccount = account;
    getStorage().then((storage) {
      if (account != null) {
        storage.setString('selected_account', account.id);
      } else {
        storage.remove('selected_account');
      }
    });
  }

  static String get selectedServer =>
      selectedAccount?.server ?? _selectedServer;

  static JonlineAccount? _selectedAccount;
  static const String _selectedServer = defaultServer;
  static final Map<String, JonlineClient> _clients = {};
  static SharedPreferences? _storage;
  static Future<SharedPreferences> getStorage() async {
    if (_storage == null) {
      print("setting up storage");
      _storage = await SharedPreferences.getInstance();
      if (_storage!.containsKey('selected_account')) {
        selectedAccount = (await accounts)
            // ignore: unnecessary_cast
            .map((e) => e as JonlineAccount?)
            .firstWhere((a) => a?.id == _storage!.getString('selected_account'),
                orElse: () => null);
      }
    }
    return _storage!;
  }

  final String id;
  final String server;
  final String authorizationToken;
  String userId;
  String refreshToken;
  String username;
  bool allowInsecure;
  CallOptions get authenticatedCallOptions =>
      CallOptions(metadata: {'authorization': refreshToken});

  JonlineAccount(
      this.server, this.authorizationToken, this.refreshToken, this.username,
      {this.allowInsecure = false})
      : id = uuid.v4(),
        userId = "";

  JonlineAccount.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'] ?? '',
        userId = json['userId'] ?? '',
        server = json['server'],
        authorizationToken = json['authorizationToken'],
        refreshToken = json['refreshToken'],
        allowInsecure = json['allowInsecure'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'userId': userId,
        'server': server,
        'authorizationToken': authorizationToken,
        'refreshToken': refreshToken,
        'allowInsecure': allowInsecure,
      };

  Future<void> updateUserData({Function(String)? showMessage}) async {
    User? user;
    try {
      user = await (await getClient())
          ?.getCurrentUser(Empty(), options: authenticatedCallOptions);
    } catch (e) {
      showMessage?.call(formatServerError(e));
      return;
    }
    if (user == null) {
      showMessage?.call('No user data received.');
      return;
    }
    username = user.username;
    userId = user.id;
    await save();
  }

  Future<void> updateRefreshToken({Function(String)? showMessage}) async {
    ExpirableToken? newRefreshToken;
    try {
      newRefreshToken = await (await getClient())
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

  Future<void> save() async {
    List<JonlineAccount> jsonArray = await accounts;
    final index = jsonArray.indexWhere((element) => element.id == id);
    jsonArray[index] = this;
    await updateAccountList(jsonArray);
  }

  Future<void> saveNew() async {
    List<JonlineAccount> jsonArray = await accounts;
    jsonArray.insert(0, this);
    await updateAccountList(jsonArray);
  }

  Future<void> delete() async {
    List<JonlineAccount> jsonArray = await accounts;
    jsonArray.removeWhere((e) => e.id == id);
    await updateAccountList(jsonArray);
  }

  Future<JonlineClient?> getClient(
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    if (_clients.containsKey(id)) {
      return _clients[id];
    } else {
      try {
        _clients[id] = (await _createClient(
            showMessage: showMessage, allowInsecure: allowInsecure))!;
        return _clients[id];
      } catch (e) {
        showMessage?.call(formatServerError(e));
        return null;
      }
    }
  }

  Future<JonlineClient?> _createClient(
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    return await createAndTestClient(server,
        showMessage: showMessage, allowInsecure: allowInsecure);
  }

  static Future<bool?> updateAccountList(List<JonlineAccount> accounts) async {
    if (!accounts.any((a) => a.id == selectedAccount?.id)) {
      (await getStorage()).remove('selected_account');
      selectedAccount = null;
    }
    return (await getStorage()).setStringList(
        'jonline_accounts', accounts.map((e) => jsonEncode(e)).toList());
  }

  static Future<List<JonlineAccount>> get accounts async {
    final storage = await getStorage();
    List<String> jsonArrayString =
        storage.getStringList('jonline_accounts') ?? [];
    final accountsJson = jsonArrayString
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    // List<Map<String, dynamic>> jsonArray = await accountsJson;
    final accounts =
        accountsJson.map((e) => JonlineAccount.fromJson(e)).toList();

    if (selectedAccount != null) {
      selectedAccount = accounts.firstWhere((a) => a.id == selectedAccount?.id,
          orElse: () => selectedAccount!);
    }
    return accounts;
  }

  static JonlineClient createClient(
      String server, ChannelCredentials credentials) {
    final channel = ClientChannel(
      "jonline.$server",
      port: 27707,
      options: ChannelOptions(credentials: credentials),
    );
    return JonlineClient(channel);
  }

  static Future<JonlineClient?> createAndTestClient(String server,
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    JonlineClient? client;
    String? serviceVersion;
    try {
      client = createClient(server, const ChannelCredentials.secure());
      serviceVersion = (await client.getServiceVersion(Empty())).version;
    } catch (e) {
      showMessage?.call("Failed to connect to \"$server\" securely!");
    }

    if (allowInsecure && serviceVersion == null) {
      try {
        showMessage?.call("Trying to connect to \"$server\" insecurely...");
        client = createClient(server, const ChannelCredentials.insecure());
        serviceVersion = (await client.getServiceVersion(Empty())).version;
        showMessage?.call("Connected to \"$server\" insecurely 🤨");
      } catch (e) {
        showMessage?.call("Failed to connect to \"$server\" insecurely!");
        return null;
      }
    }
    if (client != null) {
      showMessage
          ?.call("Connected to $server running Jonline $serviceVersion!");
    }
    return client;
  }

  static Future<JonlineAccount?> loginToAccount(String server, String username,
      String password, BuildContext context, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client = await createAndTestClient(server,
        showMessage: showMessage, allowInsecure: allowInsecure);
    if (client == null) return null;
    await Future.delayed(const Duration(seconds: 1));
    showMessage("Connected to $server! Logging in...");

    AuthTokenResponse authResponse;
    try {
      authResponse = await client
          .login(LoginRequest(username: username, password: password));
    } catch (e) {
      await communicationDelay;
      showMessage("Failed to login to $server as \"$username\"!");
      final formattedError = formatServerError(e);
      showMessage(formattedError);
      return null;
    }
    await communicationDelay;
    showMessage("Logged in to $server as $username!");

    final account = JonlineAccount(server, authResponse.authToken.token,
        authResponse.refreshToken.token, username,
        allowInsecure: allowInsecure);
    await account.saveNew();
    selectedAccount = account;
    return account;
  }

  static Future<JonlineAccount?> createAccount(String server, String username,
      String password, BuildContext context, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client = await createAndTestClient(server,
        showMessage: showMessage, allowInsecure: allowInsecure);
    if (client == null) return null;
    await Future.delayed(const Duration(seconds: 1));
    showMessage("Connected to $server! Creating account...");
    AuthTokenResponse authResponse;
    try {
      authResponse = await client.createAccount(
          CreateAccountRequest(username: username, password: password));
    } catch (e) {
      await communicationDelay;
      showMessage("Failed to create account $username on $server!");
      final formattedError = formatServerError(e);
      showMessage(formattedError);
      return null;
    }
    await communicationDelay;
    showMessage("Created account $username on $server!");

    final account = JonlineAccount(server, authResponse.authToken.token,
        authResponse.refreshToken.token, username,
        allowInsecure: allowInsecure);
    await account.saveNew();
    selectedAccount = account;
    return account;
  }
}
