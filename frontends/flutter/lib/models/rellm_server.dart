import 'dart:collection';
import 'dart:convert';

import 'package:rellm/my_platform.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../generated/server_configuration.pb.dart';
import '../generated/google/protobuf/empty.pb.dart';
import 'rellm_account.dart';
import 'rellm_clients.dart';
import 'server_errors.dart';
import 'storage.dart';

const uuid = Uuid();

class RellmServer {
  static final log = Logger('RellmServer');
  static RellmServer _selectedServer = RellmServer("jonline.io");
  static RellmServer get selectedServer {
    return _selectedServer;
  }

  static set selectedServer(RellmServer server) {
    _selectedServer = server;
    appStorage.setString('selected_server', server.server);
  }

  final String server;
  String? serviceVersion;
  bool? supportsSecure;
  bool? supportsInsecure;
  ServerConfiguration? configuration;

  RellmServer(this.server);

  /// Used by [servers] to load data.
  RellmServer._fromJson(Map<String, dynamic> json)
      : server = json['server'],
        serviceVersion = json['serviceVersion'] ?? '',
        supportsSecure = json['supportsSecure'],
        supportsInsecure = json['supportsInsecure'],
        configuration = json['configuration'] != null
            ? ServerConfiguration.fromJson(jsonEncode(json['configuration']))
            : null;

  Map<String, dynamic> toJson() => {
        'server': server,
        'serviceVersion': serviceVersion,
        'supportsSecure': supportsSecure,
        'supportsInsecure': supportsInsecure,
        'configuration': configuration == null
            ? null
            : jsonDecode(configuration!.writeToJson()),
      };

  Future<void> save() async {
    List<RellmServer> jsonArray = await servers;
    final index = jsonArray.indexWhere((element) => element.server == server);
    jsonArray[index] = this;
    if (_selectedServer == this) {
      _selectedServer = this;
    }
    await updateServerList(jsonArray);
  }

  Future<void> saveNew({bool atBeginning = false}) async {
    List<RellmServer> jsonArray = await servers;
    jsonArray.insert(atBeginning ? 0 : jsonArray.length, this);
    await updateServerList(jsonArray);
  }

  Future<void> delete() async {
    List<RellmServer> jsonArray = await servers;
    jsonArray.removeWhere((e) => e.server == server);
    await updateServerList(jsonArray);
  }

  static Future<bool?> updateServerList(List<RellmServer> servers) async {
    return appStorage.setStringList(
        'rellm_servers', servers.map((e) => jsonEncode(e)).toList());
  }

  static Future<List<RellmServer>> get servers async {
    List<String> jsonArrayString =
        appStorage.getStringList('rellm_servers') ?? [];
    final serversJson = jsonArrayString
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    final servers = serversJson
        .map((e) {
          try {
            return RellmServer._fromJson(e);
          } catch (e) {
            log.warning("Failed to load server from json: $e");
            return null;
          }
        })
        .where((e) => e != null)
        .map((e) => e!)
        .toList();
    if (servers.isEmpty && !MyPlatform.isWeb) {
      servers.add(RellmServer("jonline.io"));
    }

    final accounts = await RellmAccount.accounts;
    for (final account in accounts) {
      if (!servers.any((a) => a.server == account.server)) {
        servers.add(RellmServer(account.server));
      }
    }

    return LinkedHashSet.of(servers).toList();
  }

  Future<ServerConfiguration?> updateConfiguration(
      {Function(String)? showMessage}) async {
    final client = await RellmClients.getServerClient(this,
        showMessage: (m) => log.info(m),
        allowInsecure: RellmClients.isInsecureAllowed(server));
    if (client == null) return null;

    configuration = (await client.getServerConfiguration(Empty()));
    await save();
    return configuration;
  }

  Future<void> updateServiceVersion({Function(String)? showMessage}) async {
    showMessage ??= (m) => log.info(m);
    final client = await RellmClients.getServerClient(this,
        showMessage: showMessage, allowInsecure: true);
    if (client == null) return;
    String? serviceVersion;
    try {
      serviceVersion = (await client.getServiceVersion(Empty())).version;
    } catch (e) {
      showMessage.call(formatServerError(e));
      return;
    }
    this.serviceVersion = serviceVersion;
    await save();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RellmServer &&
          runtimeType == other.runtimeType &&
          server == other.server;

  @override
  int get hashCode => server.hashCode;
}
