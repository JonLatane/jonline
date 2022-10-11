import 'package:recase/recase.dart';

import '../generated/permissions.pbenum.dart';
import '../generated/visibility_moderation.pbenum.dart';

extension PermissionConversions on Permission {
  String get displayName {
    switch (this) {
      case Permission.GLOBALLY_PUBLISH_USERS:
        return 'Globally Publish Profile';
      default:
        return name.replaceAll('_', ' ').titleCase;
    }
  }
}

extension VisibilityDisplayName on Visibility {
  String get displayName {
    switch (this) {
      // case Permission.GLOBALLY_PUBLISH_USERS:
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

  bool get passes =>
      this == Moderation.UNMODERATED || this == Moderation.APPROVED;
  bool get pending => this == Moderation.PENDING;
}
