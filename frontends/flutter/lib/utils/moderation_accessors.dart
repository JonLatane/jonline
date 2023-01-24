import '../generated/groups.pb.dart';
import '../generated/users.pb.dart';
import '../generated/visibility_moderation.pbenum.dart';

extension ModerationAccessors on Moderation {
  bool get passes =>
      this == Moderation.UNMODERATED || this == Moderation.APPROVED;
  bool get pending => this == Moderation.PENDING;
}

extension MembershipModerationAccessors on Membership {
  bool get member => userModeration.passes && groupModeration.passes;
  bool get invited => userModeration.pending;
  bool get requested => groupModeration.pending;
  bool get wantsToJoinGroup => groupModeration.pending;
}

extension GroupModerationAccessors on Group {
  bool get member => currentUserMembership.member;
  bool get invited => currentUserMembership.invited;
  bool get requested => currentUserMembership.requested;
  bool get wantsToJoinGroup => currentUserMembership.wantsToJoinGroup;
}

extension FollowModerationAccessors on User {
  bool get friends => following && followsYou;
  bool get following => currentUserFollow.targetUserModeration.passes;
  bool get followRequestPending =>
      currentUserFollow.targetUserModeration.pending;
  bool get followsYou => targetCurrentUserFollow.targetUserModeration.passes;
  bool get wantsToFollowYou =>
      targetCurrentUserFollow.targetUserModeration.pending;
}
