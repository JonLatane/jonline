import 'package:jonline/models/jonline_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'jonline_account.dart';

SharedPreferences? _storage;
SharedPreferences get appStorage => _storage!;
Future<SharedPreferences> initStorage() async {
  if (_storage == null) {
    _storage = await SharedPreferences.getInstance();
    if (_storage!.containsKey('selected_server')) {
      final servers = await JonlineServer.servers;
      final server = servers.firstWhere(
          (s) => s.server == _storage!.getString('selected_server'),
          orElse: () => JonlineServer.selectedServer);
      JonlineServer.selectedServer = server;
    }
    if (_storage!.containsKey('selected_account')) {
      JonlineAccount.selectedAccount = (await JonlineAccount.accounts)
          // ignore: unnecessary_cast
          .map((e) => e as JonlineAccount?)
          .firstWhere((a) => a?.id == _storage!.getString('selected_account'),
              orElse: () => null);
    }
  }
  return _storage!;
}
