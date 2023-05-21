import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MyPlatform {
  static const bool isWeb = kIsWeb;
  static const bool isNative = !kIsWeb;
  static final bool isIOS = !kIsWeb && Platform.isIOS;
  static bool get isIPad {
    Size size = WidgetsBinding.instance.renderView.size;
    return isIOS && !isMacOS && size.width > 600 || size.height > 600;
  }

  static final bool isMacOS = !kIsWeb && Platform.isMacOS;
  static final bool isAppleOS = isIOS || isMacOS;
  static final bool isAndroid = !kIsWeb && Platform.isAndroid;
  static final bool isMobile = isAndroid || isIOS;
  static const bool isDebug = kDebugMode;

  static String appVersion = "unknown";

  static String get operatingSystem => isWeb
      ? 'Web'
      : isIOS
          ? 'iOS'
          : isMacOS
              ? 'macOS'
              : isAndroid
                  ? 'Android'
                  : 'Other OS';

  static String get userAgent =>
      "$operatingSystem:Jonline:v$appVersion (by Jon Latané)";
}
