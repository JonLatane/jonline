import 'package:flutter/foundation.dart';

import 'storage.dart';

class Settings {
  static bool _powerUserMode = false;
  static bool get powerUserMode => _powerUserMode;
  static set powerUserMode(bool v) {
    {
      _powerUserMode = v;
      if (!v) {
        developerMode = false;
      }
      Future.microtask(
          () async => (await getStorage()).setBool("power_user_mode", v));
    }
  }

  static bool _developerMode = false;
  static bool get developerMode => _developerMode;
  static set developerMode(bool v) {
    {
      _developerMode = v;
      if (v) {
        powerUserMode = true;
      }
      Future.microtask(
          () async => (await getStorage()).setBool("developer_mode", v));
    }
  }

  static bool _preferServerPreviews = false;
  static bool get preferServerPreviews => _preferServerPreviews;
  static set preferServerPreviews(bool v) {
    {
      _preferServerPreviews = v;
      Future.microtask(() async =>
          (await getStorage()).setBool("prefer_server_previews", v));
    }
  }

  static initialize(VoidCallback onComplete) async {
    _powerUserMode = (await getStorage()).getBool("power_user_mode") ?? false;
    _developerMode = (await getStorage()).getBool("developer_mode") ?? false;
    _preferServerPreviews =
        (await getStorage()).getBool("prefer_server_previews") ?? false;
  }
}
