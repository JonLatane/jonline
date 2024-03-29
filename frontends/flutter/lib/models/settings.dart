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
      if (!v && forceServerPreviews) {
        forceServerPreviews = false;
      }
      Future.microtask(
          () async => appStorage.setBool("prefer_server_previews", v));
    }
  }

  static bool _forceServerPreviews = MyPlatform.isWeb;
  static bool get forceServerPreviews => _forceServerPreviews;
  static set forceServerPreviews(bool v) {
    {
      _forceServerPreviews = v;
      if (v && !preferServerPreviews) {
        preferServerPreviews = true;
      }
      Future.microtask(
          () async => appStorage.setBool("force_server_previews", v));
    }
  }

  static int _replyLayersToLoad = 1;
  static int get replyLayersToLoad => _replyLayersToLoad;
  static set replyLayersToLoad(int v) {
    {
      _replyLayersToLoad = v;
      Future.microtask(
          () async => appStorage.setInt("reply_layers_to_load", v));
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

  static ValueNotifier<bool> showPeopleTabListener = ValueNotifier(true);
  static bool get showPeopleTab => showPeopleTabListener.value;
  static set showPeopleTab(bool v) {
    {
      showPeopleTabListener.value = v;
      Future.microtask(() async => appStorage.setBool("show_people_tab", v));
    }
  }

  static ValueNotifier<bool> showGroupsTabListener = ValueNotifier(true);
  static bool get showGroupsTab => showGroupsTabListener.value;
  static set showGroupsTab(bool v) {
    {
      showGroupsTabListener.value = v;
      Future.microtask(() async => appStorage.setBool("show_groups_tab", v));
    }
  }

  static ValueNotifier<bool> keepSideNavExpandedListener = ValueNotifier(false);
  static bool get keepSideNavExpanded => keepSideNavExpandedListener.value;
  static set keepSideNavExpanded(bool v) {
    {
      keepSideNavExpandedListener.value = v;
      Future.microtask(
          () async => appStorage.setBool("keep_side_nav_expanded", v));
    }
  }

  static bool _showServers = false;
  static bool get showServers => _showServers;
  static set showServers(bool v) {
    {
      _showServers = v;
      Future.microtask(() async => appStorage.setBool("show_servers", v));
    }
  }

  static int _sidebarTopPadding = 0;
  static int get sidebarTopPadding => _sidebarTopPadding;
  static set sidebarTopPadding(int v) {
    {
      _sidebarTopPadding = v;
      Future.microtask(() async => appStorage.setInt("sidebar_top_padding", v));
    }
  }

  static initialize(VoidCallback onComplete) async {
    _powerUserMode = appStorage.getBool("power_user_mode") ?? false;
    _developerMode = appStorage.getBool("developer_mode") ?? false;
    _replyLayersToLoad = appStorage.getInt("reply_layers_to_load") ?? 1;
    _sidebarTopPadding = appStorage.getInt("sidebar_top_padding") ?? 0;
    _preferServerPreviews =
        appStorage.getBool("prefer_server_previews") ?? MyPlatform.isWeb;
    _forceServerPreviews =
        appStorage.getBool("force_server_previews") ?? MyPlatform.isWeb;
    showSettingsTabListener.value =
        appStorage.getBool("show_settings_tab") ?? false;
    showPeopleTabListener.value = appStorage.getBool("show_people_tab") ?? true;
    keepSideNavExpandedListener.value =
        appStorage.getBool("keep_side_nav_expanded") ?? false;
    showGroupsTabListener.value = appStorage.getBool("show_groups_tab") ?? true;
    _showServers = appStorage.getBool("show_servers") ?? false;
  }
}
