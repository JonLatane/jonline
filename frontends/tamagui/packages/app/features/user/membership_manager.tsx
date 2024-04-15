import { Moderation, Permission } from "@jonline/api";
import { Card, Heading, Paragraph, Spinner, XStack, YStack } from '@jonline/ui';
import { useGroupContext } from "app/contexts";
import { useAppSelector } from "app/hooks";
import { FederatedUser, federatedId } from "app/store";
import moment from "moment";
import { useState } from "react";
import { groupUserPermissions } from "../groups/group_details_sheet";
import { ModerationPicker, PermissionsEditor, PermissionsEditorProps } from "../post";

interface MembershipManagerProps {
  user: FederatedUser;
}

export const MembershipManager: React.FC<MembershipManagerProps> = ({
  user,
}) => {
  const { selectedGroup } = useGroupContext();
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
  console.log('MembershipManager', selectedGroupId, userGroupServerMatch, membership)

  function selectDefaultPermission(permission: Permission, permissionSet: Permission[], setPermissionSet: (permissions: Permission[]) => void) {
    if (permissionSet.includes(permission)) {
      setPermissionSet(permissionSet.filter(p => p != permission));
    } else {
      setPermissionSet([...permissionSet, permission]);
    }
  }
  function deselectDefaultPermission(permission: Permission, permissionSet: Permission[], setPermissionSet: (permissions: Permission[]) => void) {
    setPermissionSet(permissionSet.filter(p => p != permission));
  }
  const [membershipPermissions, setMembershipPermissions] = useState([] as Permission[]);

  const membershipPermissionsEditorProps: PermissionsEditorProps = {
    selectablePermissions: groupUserPermissions,
    selectedPermissions: membership?.permissions ?? [],
    selectPermission: (p: Permission) => selectDefaultPermission(p, membershipPermissions, setMembershipPermissions),
    deselectPermission: (p: Permission) => deselectDefaultPermission(p, membershipPermissions, setMembershipPermissions),
    editMode: false,
  };
  return membership ?
    <Card ml='auto'>
      <Card.Header>
        <YStack>
          <XStack w='100%' gap='$3' jc='space-between'>
            <Heading size='$1'>Member Since</Heading>
            <Paragraph size='$1'>{moment(membership.createdAt).format('YYYY-MM-DD HH:mm')}</Paragraph>
          </XStack>
          <XStack w='100%' gap='$3' flexWrap='wrap' jc='space-between'>
            <Heading size='$1'>User Moderation</Heading>
            {/* <Paragraph size='$1'>{membership.userModeration}</Paragraph> */}
            <ModerationPicker moderation={membership.userModeration}
              moderationDescription={() => undefined}
              onChange={() => { }}
              disabled />
          </XStack>
          <XStack w='100%' gap='$3' flexWrap='wrap' jc='space-between'>
            <Heading size='$1'>Group Moderation</Heading>
            <ModerationPicker moderation={membership.groupModeration}
              onChange={() => { }}
              moderationDescription={() => undefined}
              disabled />
            {/* <Paragraph size='$1'>{membership.groupModeration}</Paragraph> */}
          </XStack>
          <PermissionsEditor label='Membership Permissions'
            {...membershipPermissionsEditorProps} />
          <XStack ml='auto' position='absolute'>
            <Spinner size='small' />
          </XStack>
        </YStack>
      </Card.Header>
    </Card>
    : <></>
}
