import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:logging/logging.dart';

import '../app_state.dart';
import '../generated/google/protobuf/empty.pb.dart';
import '../generated/rellm.pbgrpc.dart';
import 'rellm_account.dart';
import 'rellm_channels_native.dart'
    if (dart.library.html) 'rellm_channels_web.dart';
import 'rellm_server.dart';
import 'server_errors.dart';
import 'package:http/http.dart' as http;

/// Tracks RellmClient instances for each Rellm server, and provides
/// extension methods for RellmAccount to fetch the appropriate client.
extension RellmClients on RellmAccount {
  static final log = Logger('RellmClients');

  static Future<RellmClient> _createClient(
      String server, bool secure, int port) async {
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
    final ClientChannelBase channel =
        createRellmChannel(host, credentials, port);
    return RellmClient(channel);
  }

  static Future<RellmClient?> createAndTestClient(String server,
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    RellmClient? client;
    // String? serviceVersion;

    // We can't actually gracefully handle browser SSL errors, so must
    // use this "if" block instead.
    log.warning("createAndTestClient", server);
    if (server != "localhost") {
      for (final port in [443, 27707]) {
        try {
          final maybeClient = await _createClient(server, true, port);
          (await maybeClient.getServiceVersion(Empty())).version;
          client = maybeClient;
        } catch (e) {}
      }
      if (client == null && !allowInsecure) {
        showMessage?.call("Failed to connect to \"$server\" securely!");
      }
    }

    if (allowInsecure && client == null) {
      await communicationDelay;
      for (final port in [27707, 443]) {
        try {
          // showMessage?.call("Trying to connect to \"$server\" insecurely...");
          final maybeClient = await _createClient(server, false, port);
          (await maybeClient.getServiceVersion(Empty())).version;
          client = maybeClient;
        } catch (e) {}
      }
      if (client == null) {
        showMessage?.call("Failed to connect to \"$server\" insecurely!");
      } else {
        showMessage?.call("Connected to \"$server\" insecurely 🤨");
      }
    }
    return client;
  }

  static Future<RellmClient?> getSelectedOrDefaultClient(
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    if (RellmAccount.selectedAccount == null) {
      return getSelectedServerClient(
          showMessage: showMessage, allowInsecure: allowInsecure);
    }
    return getSelectedAccountClient(showMessage: showMessage);
  }

  static Future<RellmClient?> getServerClient(RellmServer server,
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

  static Future<RellmClient?> getSelectedAccountClient(
      {Function(String)? showMessage}) async {
    if (RellmAccount.selectedAccount == null) return null;
    return await RellmAccount.selectedAccount
        ?.getClient(showMessage: showMessage);
  }

  static bool isInsecureAllowed(String server) {
    return ["localhost", "armothy", "armothy.local"]
        .contains(server.toLowerCase());
  }

  static Future<RellmClient?> getSelectedServerClient(
      {Function(String)? showMessage, bool allowInsecure = false}) async {
    // Workaround for anonymous browsing on localhost
    log.info("getSelectedServerClient", RellmServer.selectedServer.server);
    final server = RellmServer.selectedServer.server;
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

  // Gets a RellmClient for the server for this account.
  Future<RellmClient?> getClient({Function(String)? showMessage}) async {
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

final Map<String, RellmClient> _secureClients = {};
final Map<String, RellmClient> _insecureClients = {};
