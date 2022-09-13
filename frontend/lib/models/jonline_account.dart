import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/generated/google/protobuf/empty.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/generated/users.pb.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:jonline/models/storage.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class JonlineAccount {
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

  final String id;
  final String server;
  final String authorizationToken;
  String userId;
  String refreshToken;
  String username;
  bool allowInsecure;

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
}
