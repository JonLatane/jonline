import 'package:flutter/foundation.dart';
import 'package:jonline/my_platform.dart';

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
      Future.microtask(() async => appStorage.setBool("power_user_mode", v));
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
      Future.microtask(() async => appStorage.setBool("developer_mode", v));
    }
  }

  static bool _preferServerPreviews = MyPlatform.isWeb;
  static bool get preferServerPreviews => _preferServerPreviews;
  static set preferServerPreviews(bool v) {
    {
      _preferServerPreviews = v;
      Future.microtask(
          () async => appStorage.setBool("prefer_server_previews", v));
    }
  }

  static ValueNotifier<bool> showSettingsTabListener = ValueNotifier(false);
  static bool get showSettingsTab => showSettingsTabListener.value;
  static set showSettingsTab(bool v) {
    {
      showSettingsTabListener.value = v;
      Future.microtask(() async => appStorage.setBool("show_settings_tab", v));
    }
  }

  static initialize(VoidCallback onComplete) async {
    _powerUserMode = appStorage.getBool("power_user_mode") ?? false;
    _developerMode = appStorage.getBool("developer_mode") ?? false;
    _preferServerPreviews =
        appStorage.getBool("prefer_server_previews") ?? false;
    showSettingsTabListener.value =
        appStorage.getBool("show_settings_tab") ?? false;
  }
}
