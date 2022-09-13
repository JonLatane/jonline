import 'package:grpc/grpc.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/google/protobuf/empty.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/models/server_errors.dart';

extension JonlineClients on JonlineAccount {
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

  static Future<JonlineClient?> getSelectedOrDefaultClient(
      {Function(String)? showMessage}) async {
    if (JonlineAccount.selectedAccount == null) {
      return getDefaultClient(showMessage: showMessage);
    }
    return getSelectedClient(showMessage: showMessage);
  }

  static Future<JonlineClient?> getDefaultClient(
      {Function(String)? showMessage}) async {
    return createAndTestClient(JonlineAccount.selectedServer,
        showMessage: showMessage);
  }

  static Future<JonlineClient?> getSelectedClient(
      {Function(String)? showMessage}) async {
    if (JonlineAccount.selectedAccount == null) return null;
    return await JonlineAccount.selectedAccount!
        .getClient(showMessage: showMessage);
  }

  CallOptions get authenticatedCallOptions =>
      CallOptions(metadata: {'authorization': refreshToken});

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
}

final Map<String, JonlineClient> _clients = {};
