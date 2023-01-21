import 'package:recase/recase.dart';

import '../generated/permissions.pbenum.dart';
import '../generated/visibility_moderation.pbenum.dart';

extension PermissionConversions on Permission {
  String get displayName {
    switch (this) {
      case Permission.PUBLISH_USERS_GLOBALLY:
        return 'Globally Publish Profile';
      default:
        return name.replaceAll('_', ' ').titleCase;
    }
  }
}

extension VisibilityDisplayName on Visibility {
  String get displayName {
    switch (this) {
      // case Permission.PUBLISH_USERS_GLOBALLY:
      //   return 'Globally Publish Profile';
      default:
        return name.replaceAll('_', ' ').titleCase;
    }
  }
}

extension ModerationConversions on Moderation {
  String get displayName {
    switch (this) {
      default:
        return name.replaceAll('_', ' ').titleCase;
    }
  }
}
