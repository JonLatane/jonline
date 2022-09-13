import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/models/jonline_clients.dart';
import 'package:jonline/models/server_errors.dart';

extension JonlineAccountFactories on JonlineAccount {
  static Future<JonlineAccount?> loginToAccount(String server, String username,
      String password, BuildContext context, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client = await JonlineClients.createAndTestClient(server,
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
    JonlineAccount.selectedAccount = account;
    return account;
  }

  static Future<JonlineAccount?> createAccount(String server, String username,
      String password, BuildContext context, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client = await JonlineClients.createAndTestClient(server,
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
    JonlineAccount.selectedAccount = account;
    return account;
  }
}
