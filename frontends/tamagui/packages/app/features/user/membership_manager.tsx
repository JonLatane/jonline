import { Membership, Moderation, Permission } from "@jonline/api";
import { Card, Heading, Paragraph, Spinner, XStack, YStack, useToastController } from '@jonline/ui';
import { useGroupContext } from "app/contexts";
import { useAppDispatch, useAppSelector, useFederatedDispatch } from "app/hooks";
import { FederatedUser, actionFailed, federatedId, updateMembership } from "app/store";
import moment from "moment";
import { useState } from "react";
import { groupUserPermissions } from "../groups/group_details_sheet";
import { ModerationPicker, PermissionsEditor, PermissionsEditorProps } from "../post";
import { hasPermission, passes, rejected } from "app/utils";

interface MembershipManagerProps {
  user: FederatedUser;
}

export const MembershipManager: React.FC<MembershipManagerProps> = ({
  user,
}) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(user);
  const { selectedGroup } = useGroupContext();
  const currentUser = accountOrServer.account?.user;
  const currentUserMembership = selectedGroup?.currentUserMembership;
  const selectedGroupId = selectedGroup ? federatedId(selectedGroup) : undefined;
  const userGroupServerMatch = user.serverHost === selectedGroup?.serverHost;
  const membership = useAppSelector(
    state => userGroupServerMatch && selectedGroupId
      ? user.currentGroupMembership?.groupId === selectedGroup.id
        ? user.currentGroupMembership
        : state.groups.groupMembershipPages[selectedGroupId]
          ?.[Moderation.MODERATION_UNKNOWN]?.[0]
          ?.find(m => m.userId === user.id)
      : undefined);
  // console.log('MembershipManager', selectedGroupId, userGroupServerMatch, membership)

  const [saving, setSaving] = useState(false);
  const toast = useToastController();
  function saveMembership(m: Membership) {
    // console.log('saveMembership', m);
    setSaving(true);
    dispatch(updateMembership({ ...m, ...accountOrServer })).then(action => {
      if (actionFailed(action)) {
        toast.show('Failed to save membership', { type: 'error' });
      }
      setSaving(false);
    }
    );
  }

  const isGroupOrSystemAdmin = hasPermission(currentUser, Permission.ADMIN)
    || hasPermission(currentUserMembership, Permission.ADMIN);

  const canEditPermissions = isGroupOrSystemAdmin;
  const isForCurrentUser = currentUser && membership && currentUser?.id === membership?.userId;
  const canEditGroupModeration = isGroupOrSystemAdmin || hasPermission(currentUserMembership, Permission.MODERATE_USERS);

  const membershipPermissionsEditorProps: PermissionsEditorProps = {
    selectablePermissions: groupUserPermissions,
    selectedPermissions: membership?.permissions ?? [],
    selectPermission: (p: Permission) => membership
      ? saveMembership({ ...membership, permissions: [...membership.permissions, p] })
      : undefined,
    // selectDefaultPermission(p, membershipPermissions, setMembershipPermissions),
    deselectPermission: (p: Permission) => membership
      ? saveMembership({ ...membership, permissions: membership.permissions.filter(p1 => p1 != p) })
      : undefined,
    // deselectDefaultPermission(p, membershipPermissions, setMembershipPermissions),
    editMode: canEditPermissions,
    disabled: saving,
  };
  const isMember = membership && passes(membership.userModeration) && passes(membership.groupModeration);
  const isInvited = membership && !passes(membership.userModeration) && passes(membership.groupModeration);
  const hasRequestedMembership = membership && passes(membership.userModeration) && !passes(membership.groupModeration);

  return membership ?
    <Card ml='auto'>
      <Card.Header>
        <YStack>
          {isMember ? undefined : <Heading size='$1'>Nonmember</Heading>}
          <XStack w='100%' gap='$3' jc='space-between'>
            <Heading size='$1'>{
              isMember ? 'Member Since'
                : isInvited ? 'Invited Since'
                  : hasRequestedMembership ? 'Requsted Membership'
                    : 'Non-Member Since'}</Heading>
            <Paragraph size='$1'>{moment(membership.createdAt).format('YYYY-MM-DD HH:mm')}</Paragraph>
          </XStack>
          <XStack w='100%' gap='$3' flexWrap='wrap' jc='space-between'>
            <Heading size='$1'>Member Invite Moderation</Heading>
            {/* <Paragraph size='$1'>{membership.userModeration}</Paragraph> */}
            <ModerationPicker moderation={membership.userModeration}
              moderationDescription={(m) => {
                switch (m) {
                  case Moderation.PENDING:
                    return 'User has been invited to the group.';
                  case Moderation.APPROVED:
                  case Moderation.UNMODERATED:
                    return passes(membership.groupModeration) ? 'User is a member of the group.' : 'User has requested to be a member of the group.';
                  case Moderation.REJECTED:
                    return rejected(membership.groupModeration)
                      ? 'User has rejected their membership or invitation to the group.'
                      : 'User has rejected their membership or invitation to the group. They may separately choose to delete it at their own discretion.';
                  default:
                    return undefined;
                }
              }}
              onChange={(m) => membership
                ? saveMembership({ ...membership, userModeration: m })
                : undefined}
              disabled={!isForCurrentUser || saving} />
          </XStack>
          <XStack w='100%' gap='$3' flexWrap='wrap' jc='space-between'>
            <Heading size='$1'>Group Moderation</Heading>
            <ModerationPicker moderation={membership.groupModeration}
              onChange={(m) => membership
                ? saveMembership({ ...membership, groupModeration: m })
                : undefined}
              moderationDescription={(m) => {
                switch (m) {
                  case Moderation.PENDING:
                    return 'User has requested membership in the group.';
                  case Moderation.APPROVED:
                    return passes(membership.userModeration) ? 'User is a member of the group.' : 'User invitation has been approved by the group.';
                  case Moderation.UNMODERATED:
                    return passes(membership.userModeration) ? 'User is a member of the group.' : 'User invitation will be accepted by the group.';
                  case Moderation.REJECTED:
                    return 'User has been rejected from the group by moderators.';
                  default:
                    return undefined;
                }
              }}
              disabled={!canEditGroupModeration || saving} />
            {/* <Paragraph size='$1'>{membership.groupModeration}</Paragraph> */}
          </XStack>
          <PermissionsEditor label='Membership Permissions'
            {...membershipPermissionsEditorProps} />
          <XStack ml='auto' position='absolute' bottom={0} right={0} animation='standard' pointerEvents="none" o={saving ? 1 : 0}>
            <Spinner size='small' />
          </XStack>
        </YStack>
      </Card.Header>
    </Card>
    : <></>
}
