import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../app_state.dart';
import 'storage.dart';

const uuid = Uuid();

class JonlineAccount {
  static JonlineAccount? get selectedAccount => _selectedAccount;
  static set selectedAccount(JonlineAccount? account) {
    _selectedAccount = account;
    if (account != null) {
      appStorage.setString('selected_account', account.id);
    } else {
      appStorage.remove('selected_account');
    }
  }

  static String get selectedServer =>
      selectedAccount?.server ?? _selectedServer;

  static JonlineAccount? _selectedAccount;
  static const String _selectedServer = defaultServer;

  final String id;
  final String server;
  final String authorizationToken;
  String serviceVersion;
  String userId;
  String refreshToken;
  String username;
  bool allowInsecure;

  JonlineAccount(
      this.server, this.authorizationToken, this.refreshToken, this.username,
      {this.allowInsecure = false})
      : id = uuid.v4(),
        userId = "",
        serviceVersion = "";

  JonlineAccount.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'] ?? '',
        userId = json['userId'] ?? '',
        server = json['server'],
        authorizationToken = json['authorizationToken'],
        refreshToken = json['refreshToken'],
        allowInsecure = json['allowInsecure'],
        serviceVersion = json['serviceVersion'] ?? "";

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'userId': userId,
        'server': server,
        'authorizationToken': authorizationToken,
        'refreshToken': refreshToken,
        'allowInsecure': allowInsecure,
        'serviceVersion': serviceVersion,
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
        accountsJson.map((e) => JonlineAccount.fromJson(e)).toList();

    if (selectedAccount != null) {
      selectedAccount = accounts.firstWhere((a) => a.id == selectedAccount?.id,
          orElse: () => selectedAccount!);
    }
    return accounts;
  }
}
