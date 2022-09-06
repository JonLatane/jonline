import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/generated/google/protobuf/empty.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';

class JonlineAccount {
  final String server;
  final String authorizationToken;

  JonlineAccount(this.server, this.authorizationToken);

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
      String server, Function(String) showMessage) async {
    JonlineClient? client;
    String? serviceVersion;
    try {
      client = createClient(server, const ChannelCredentials.secure());
      serviceVersion = (await client.getServiceVersion(Empty())).version;
    } catch (e) {
      showMessage("Failed to connect to $server securely!");
    }

    if (serviceVersion == null) {
      try {
        showMessage("Trying to connect to $server insecurely...");
        client = createClient(server, const ChannelCredentials.insecure());
        serviceVersion = (await client.getServiceVersion(Empty())).version;
        showMessage("Connected to $server insecurely 🤨");
      } catch (e) {
        showMessage("Failed to connect to $server insecurely!");
        return null;
      }
    }
    showMessage("Connected to $server running Jonline $serviceVersion!");
    return client;
  }

  static Future<JonlineAccount?> loginToAccount(
      String server,
      String username,
      String password,
      BuildContext context,
      Function(String) showMessage) async {
    JonlineClient? client = await createAndTestClient(server, showMessage);
    if (client == null) return null;
    showMessage("Connected to $server! Logging in...");

    try {
      AuthTokenResponse authResponse = await client
          .login(LoginRequest(username: username, password: password));
    } catch (e) {
      showMessage("Failed to login to $server as $username!");
      if (e is GrpcError) {
        showMessage("Error code: ${e.code}");
        showMessage("Error message: ${e.message}");
      }
      return null;
    }
    showMessage("Logged in to $server as $username!");

    return null;
  }

  static Future<JonlineAccount?> createAccount(
      String server,
      String username,
      String password,
      BuildContext context,
      Function(String) showMessage) async {
    JonlineClient? client = await createAndTestClient(server, showMessage);
    if (client == null) return null;
    showMessage("Connected to $server! Logging in...");

    try {
      AuthTokenResponse authResponse = await client.createAccount(
          CreateAccountRequest(username: username, password: password));
    } catch (e) {
      showMessage("Failed to create account $username on $server!");
      if (e is GrpcError) {
        showMessage("Error code: ${e.code}");
        showMessage("Error message: ${e.message}");
      }
      return null;
    }
    showMessage("Created account $username on $server!");

    return null;
  }
}
