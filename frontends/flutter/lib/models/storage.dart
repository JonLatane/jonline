import 'package:rellm/models/rellm_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rellm_account.dart';

SharedPreferences? _storage;
SharedPreferences get appStorage => _storage!;
Future<SharedPreferences> initStorage() async {
  if (_storage == null) {
    _storage = await SharedPreferences.getInstance();
    if (_storage!.containsKey('selected_server')) {
      final servers = await RellmServer.servers;
      final server = servers.firstWhere(
          (s) => s.server == _storage!.getString('selected_server'),
          orElse: () => RellmServer.selectedServer);
      RellmServer.selectedServer = server;
    }
    if (_storage!.containsKey('selected_account')) {
      RellmAccount.selectedAccount = (await RellmAccount.accounts)
          // ignore: unnecessary_cast
          .map((e) => e as RellmAccount?)
          .firstWhere((a) => a?.id == _storage!.getString('selected_account'),
              orElse: () => null);
    }
  }
  return _storage!;
}
