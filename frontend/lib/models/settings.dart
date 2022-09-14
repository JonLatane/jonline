import 'package:flutter/foundation.dart';

import 'storage.dart';

class Settings {
  static bool _developerMode = false;
  static bool get developerMode => _developerMode;
  static set developerMode(bool v) {
    {
      _developerMode = v;
      Future.microtask(
          () async => (await getStorage()).setBool("developer_mode", v));
    }
  }

  static initialize(VoidCallback onComplete) async {
    _developerMode = (await getStorage()).getBool("developer_mode") ?? false;
  }
}
