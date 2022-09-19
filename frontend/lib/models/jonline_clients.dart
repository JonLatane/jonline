import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';

import '../app_state.dart';
import '../generated/google/protobuf/empty.pb.dart';
import '../generated/jonline.pbgrpc.dart';
import 'jonline_account.dart';
import 'jonline_channels_native.dart'
    if (dart.library.html) 'jonline_channels_web.dart';
import 'server_errors.dart';

extension JonlineClients on JonlineAccount {
  static JonlineClient createClient(
      String server, ChannelCredentials credentials) {
    final ClientChannelBase channel = createJonlineChannel(server, credentials);
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
      client = null;
    }

    if (allowInsecure && serviceVersion == null) {
      await communicationDelay;
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

  static Future<JonlineClient?> getSelectedOrDefaultClient(
      {Function(String)? showMessage}) async {
    if (JonlineAccount.selectedAccount == null) {
      return getDefaultClient(showMessage: showMessage);
    }
    return getSelectedClient(showMessage: showMessage);
  }

  static Future<JonlineClient?> getSelectedClient(
      {Function(String)? showMessage}) async {
    if (JonlineAccount.selectedAccount == null) return null;
    return await JonlineAccount.selectedAccount
        ?.getClient(showMessage: showMessage);
  }

  static Future<JonlineClient?> getDefaultClient(
      {Function(String)? showMessage}) async {
    final server = JonlineAccount.selectedServer;
    final clients = _secureClients;
    if (clients.containsKey(server)) {
      return clients[server];
    } else {
      try {
        clients[server] = (await createAndTestClient(server,
            showMessage: showMessage, allowInsecure: false))!;
        return clients[server];
      } catch (e) {
        showMessage?.call(formatServerError(e));
        return null;
      }
    }
  }

  // Gets a JonlineClient for the server for this account.
  Future<JonlineClient?> getClient({Function(String)? showMessage}) async {
    final clients = allowInsecure ? _insecureClients : _secureClients;
    if (clients.containsKey(server)) {
      return clients[server];
    } else {
      try {
        clients[server] = (await createAndTestClient(server,
            showMessage: showMessage, allowInsecure: allowInsecure))!;
        return clients[server];
      } catch (e) {
        showMessage?.call(formatServerError(e));
        return null;
      }
    }
  }

  // Gets authenticated call headers for this account.
  CallOptions get authenticatedCallOptions =>
      CallOptions(metadata: {'authorization': refreshToken});
}

final Map<String, JonlineClient> _secureClients = {};
final Map<String, JonlineClient> _insecureClients = {};