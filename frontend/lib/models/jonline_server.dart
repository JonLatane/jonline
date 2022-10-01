import 'dart:collection';
import 'dart:convert';

import 'package:jonline/my_platform.dart';
import 'package:uuid/uuid.dart';

import '../generated/admin.pb.dart';
import 'jonline_account.dart';
import 'storage.dart';

const uuid = Uuid();

class JonlineServer {
  static JonlineServer _selectedServer = JonlineServer("jonline.io");
  static JonlineServer get selectedServer {
    if (JonlineAccount.selectedAccount != null) {
      return JonlineServer(JonlineAccount.selectedAccount!.server);
    }
    return _selectedServer;
  }

  static set selectedServer(JonlineServer server) {
    _selectedServer = server;
    appStorage.setString('selected_server', server.server);
  }

  final String server;
  String? serviceVersion;
  String? refreshToken;
  bool? supportsSecure;
  bool? supportsInsecure;
  ServerConfiguration? configuration;

  JonlineServer(this.server);

  /// Used by [servers] to load data.
  JonlineServer._fromJson(Map<String, dynamic> json)
      : server = json['server'],
        serviceVersion = json['serviceVersion'] ?? '',
        refreshToken = json['refreshToken'] ?? '',
        supportsSecure = json['supportsSecure'],
        supportsInsecure = json['supportsInsecure'],
        configuration = json['configuration'] != null
            ? ServerConfiguration.fromJson(json['configuration'].toString())
            : null;

  Map<String, dynamic> toJson() => {
        'server': server,
        'serviceVersion': serviceVersion,
        'refreshToken': refreshToken,
        'supportsSecure': supportsSecure,
        'supportsInsecure': supportsInsecure,
        'configuration': configuration == null
            ? null
            : jsonEncode(configuration?.writeToJson()),
      };

  Future<void> save() async {
    List<JonlineServer> jsonArray = await servers;
    final index = jsonArray.indexWhere((element) => element.server == server);
    jsonArray[index] = this;
    await updateServerList(jsonArray);
  }

  Future<void> saveNew({bool atBeginning = false}) async {
    List<JonlineServer> jsonArray = await servers;
    jsonArray.insert(atBeginning ? 0 : jsonArray.length, this);
    await updateServerList(jsonArray);
  }

  Future<void> delete() async {
    List<JonlineServer> jsonArray = await servers;
    jsonArray.removeWhere((e) => e.server == server);
    await updateServerList(jsonArray);
  }

  static Future<bool?> updateServerList(List<JonlineServer> servers) async {
    // if (!servers.any((a) => a.server == selectedServer?.server)) {
    //   appStorage.remove('selected_server');
    //   selectedServer = null;
    // }
    return appStorage.setStringList(
        'jonline_servers', servers.map((e) => jsonEncode(e)).toList());
  }

  static Future<List<JonlineServer>> get servers async {
    List<String> jsonArrayString =
        appStorage.getStringList('jonline_servers') ?? [];
    final serversJson = jsonArrayString
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    final servers = serversJson.map((e) => JonlineServer._fromJson(e)).toList();
    if (servers.isEmpty && !MyPlatform.isWeb) {
      servers.add(JonlineServer("jonline.io"));
    }

    selectedServer = servers.firstWhere(
        (a) => a.server == selectedServer.server,
        orElse: () => selectedServer);

    final accounts = await JonlineAccount.accounts;
    for (final account in accounts) {
      if (!servers.any((a) => a.server == account.server)) {
        servers.add(JonlineServer(account.server));
      }
    }

    return LinkedHashSet.of(servers).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JonlineServer &&
          runtimeType == other.runtimeType &&
          server == other.server;

  @override
  int get hashCode => server.hashCode;
}
