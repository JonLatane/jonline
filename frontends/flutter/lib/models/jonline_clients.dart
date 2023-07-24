import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:logging/logging.dart';

import '../app_state.dart';
import '../generated/google/protobuf/empty.pb.dart';
import '../generated/jonline.pbgrpc.dart';
import 'jonline_account.dart';
import 'jonline_channels_native.dart'
    if (dart.library.html) 'jonline_channels_web.dart';
import 'jonline_server.dart';
import 'server_errors.dart';
import 'package:http/http.dart' as http;

/// Tracks JonlineClient instances for each Jonline server, and provides
/// extension methods for JonlineAccount to fetch the appropriate client.
extension JonlineClients on JonlineAccount {
  static final log = Logger('JonlineClients');

  static Future<JonlineClient> _createClient(String server, bool secure) async {
    var host = server;
    log.warning("_createClient $server $secure", Exception("hi"));
    try {
      host = (await http.get(
              Uri.parse("${secure ? "https" : "http"}://$server/backend_host")))
          .body
          .trim();
      final validDomain = RegExp(
          r"^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$");
      if (!validDomain.hasMatch(host)) {
        throw Exception("Invalid backend host format: $host");
      }
    } catch (e) {
      log.warning("Failed to get backend host for $server", e);
    }

    log.info("Creating client against host $host");
    final ChannelCredentials credentials = secure
        ? const ChannelCredentials.secure()
        : const ChannelCredentials.insecure();
    final ClientChannelBase channel = createJonlineChannel(host, credentials);
    return JonlineClient(channel);
  }

  static Future<JonlineClient?> createAndTestClient(String server,
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    JonlineClient? client;
    String? serviceVersion;

    // We can't actually gracefully handle browser SSL errors, so must
    // use this "if" block instead.
    log.warning("createAndTestClient", server);
    if (server != "localhost") {
      try {
        client = await _createClient(server, true);
        serviceVersion = (await client.getServiceVersion(Empty())).version;
      } catch (e) {
        if (!allowInsecure) {
          showMessage?.call("Failed to connect to \"$server\" securely!");
        }
        client = null;
      }
    }

    if (allowInsecure && serviceVersion == null) {
      await communicationDelay;
      try {
        // showMessage?.call("Trying to connect to \"$server\" insecurely...");
        client = await _createClient(server, false);
        serviceVersion = (await client.getServiceVersion(Empty())).version;
        showMessage?.call("Connected to \"$server\" insecurely 🤨");
      } catch (e) {
        showMessage?.call("Failed to connect to \"$server\" insecurely!");
        return null;
      }
    }
    // if (client != null) {
    //   showMessage
    //       ?.call("Connected to $server running Jonline $serviceVersion!");
    // }
    return client;
  }

  static Future<JonlineClient?> getSelectedOrDefaultClient(
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    if (JonlineAccount.selectedAccount == null) {
      return getSelectedServerClient(
          showMessage: showMessage, allowInsecure: allowInsecure);
    }
    return getSelectedAccountClient(showMessage: showMessage);
  }

  static Future<JonlineClient?> getServerClient(JonlineServer server,
      {bool allowInsecure = false, Function(String)? showMessage}) async {
    final clients = allowInsecure ? _insecureClients : _secureClients;
    if (clients.containsKey(server)) {
      return clients[server];
    } else {
      try {
        clients[server.server] = (await createAndTestClient(server.server,
            showMessage: showMessage, allowInsecure: allowInsecure))!;
        return clients[server.server];
      } catch (e) {
        showMessage?.call(formatServerError(e));
        return null;
      }
    }
  }

  static Future<JonlineClient?> getSelectedAccountClient(
      {Function(String)? showMessage}) async {
    if (JonlineAccount.selectedAccount == null) return null;
    return await JonlineAccount.selectedAccount
        ?.getClient(showMessage: showMessage);
  }

  static bool isInsecureAllowed(String server) {
    return ["localhost", "armothy", "armothy.local"]
        .contains(server.toLowerCase());
  }

  static Future<JonlineClient?> getSelectedServerClient(
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    // Workaround for anonymous browsing on localhost
    log.info("getSelectedServerClient", JonlineServer.selectedServer.server);
    final server = JonlineServer.selectedServer.server;
    final reallyAllowInsecure = allowInsecure || isInsecureAllowed(server);
    final clients = Map.of(_secureClients)
      ..addAll(reallyAllowInsecure ? _insecureClients : {});
    if (clients.containsKey(server)) {
      return clients[server];
    } else {
      try {
        clients[server] = (await createAndTestClient(server,
            showMessage: showMessage, allowInsecure: reallyAllowInsecure))!;
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
      CallOptions(metadata: {'authorization': accessToken});
}

final Map<String, JonlineClient> _secureClients = {};
final Map<String, JonlineClient> _insecureClients = {};
