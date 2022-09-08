import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/generated/google/protobuf/empty.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class JonlineAccount {
  static SharedPreferences? _storage;
  static Future<SharedPreferences> getStorage() async {
    if (_storage == null) {
      print("setting up storage");
      _storage = await SharedPreferences.getInstance();
    }
    return _storage!;
  }

  final String id;
  final String server;
  final String authorizationToken;
  String refreshToken;
  String username;
  bool allowInsecure;

  JonlineAccount(
      this.server, this.authorizationToken, this.refreshToken, this.username,
      {this.allowInsecure = false})
      : id = uuid.v4();

  JonlineAccount.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'] ?? 'unknown',
        server = json['server'],
        authorizationToken = json['authorizationToken'],
        refreshToken = json['refreshToken'],
        allowInsecure = json['allowInsecure'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'server': server,
        'authorizationToken': authorizationToken,
        'refreshToken': refreshToken,
        'allowInsecure': allowInsecure,
      };
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
    return await createAndTestClient(server, showMessage ?? (m) => print(m),
        allowInsecure: allowInsecure);
  }

  static Future<bool?> updateAccountList(List<JonlineAccount> accounts) async {
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
    return accountsJson.map((e) => JonlineAccount.fromJson(e)).toList();
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

  static Future<JonlineClient?> createAndTestClient(
      String server, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client;
    String? serviceVersion;
    try {
      client = createClient(server, const ChannelCredentials.secure());
      serviceVersion = (await client.getServiceVersion(Empty())).version;
    } catch (e) {
      showMessage("Failed to connect to \"$server\" securely!");
    }

    if (allowInsecure && serviceVersion == null) {
      try {
        showMessage("Trying to connect to \"$server\" insecurely...");
        client = createClient(server, const ChannelCredentials.insecure());
        serviceVersion = (await client.getServiceVersion(Empty())).version;
        showMessage("Connected to \"$server\" insecurely 🤨");
      } catch (e) {
        showMessage("Failed to connect to \"$server\" insecurely!");
        return null;
      }
    }
    if (client != null) {
      showMessage("Connected to $server running Jonline $serviceVersion!");
    }
    return client;
  }

  static Future<JonlineAccount?> loginToAccount(String server, String username,
      String password, BuildContext context, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client = await createAndTestClient(server, showMessage,
        allowInsecure: allowInsecure);
    if (client == null) return null;
    await Future.delayed(const Duration(seconds: 1));
    showMessage("Connected to $server! Logging in...");

    AuthTokenResponse authResponse;
    try {
      authResponse = await client
          .login(LoginRequest(username: username, password: password));
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      showMessage("Failed to login to $server as \"$username\"!");
      final formattedError = formatServerError(e);
      showMessage(formattedError);
      return null;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    showMessage("Logged in to $server as $username!");

    final account = JonlineAccount(server, authResponse.authToken.token,
        authResponse.refreshToken.token, username,
        allowInsecure: allowInsecure);
    await account.saveNew();
    return account;
  }

  static Future<JonlineAccount?> createAccount(String server, String username,
      String password, BuildContext context, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client = await createAndTestClient(server, showMessage,
        allowInsecure: allowInsecure);
    if (client == null) return null;
    await Future.delayed(const Duration(seconds: 1));
    showMessage("Connected to $server! Creating account...");
    AuthTokenResponse authResponse;
    try {
      authResponse = await client.createAccount(
          CreateAccountRequest(username: username, password: password));
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      showMessage("Failed to create account $username on $server!");
      final formattedError = formatServerError(e);
      showMessage(formattedError);
      return null;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    showMessage("Created account $username on $server!");

    final account = JonlineAccount(server, authResponse.authToken.token,
        authResponse.refreshToken.token, username,
        allowInsecure: allowInsecure);
    await account.saveNew();
    return account;
  }
}
