import 'package:flutter/material.dart';

import '../app_state.dart';
import '../generated/authentication.pb.dart';
import '../generated/jonline.pbgrpc.dart';
import 'jonline_account.dart';
import 'jonline_clients.dart';
import 'server_errors.dart';

extension JonlineAccountFactories on JonlineAccount {
  static Future<JonlineAccount?> loginToAccount(String server, String username,
      String password, BuildContext context, Function(String) showMessage,
      {bool allowInsecure = false}) async {
    JonlineClient? client = await JonlineClients.createAndTestClient(server,
        showMessage: showMessage, allowInsecure: allowInsecure);
    if (client == null) return null;
    await communicationDelay;

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
    await communicationDelay;
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
