
import { Permission } from '@jonline/api';
import { Heading, Tooltip } from "@jonline/ui";
import { Bot, Shield } from '@tamagui/lucide-icons';

export type PermissionIndicatorProps = {
  permission: Permission;
  color?: string;
}

export const PermissionIndicator = ({ permission , color}: PermissionIndicatorProps) => {
  const descriptions = {
    [Permission.ADMIN]: <Heading size='$2'>User is an admin.</Heading>,
    [Permission.RUN_BOTS]: <>
      <Heading size='$2' ta='center' als='center'>User may be (or run) a bot.</Heading>
      <Heading size='$1' ta='center' als='center'>Posts may be written by an algorithm rather than a human.</Heading>
    </>,
  };

  return <Tooltip placement="bottom">
    <Tooltip.Trigger>
      {permission == Permission.ADMIN ? <Shield color={color}/> : undefined}
      {permission == Permission.RUN_BOTS ? <Bot color={color}/> : undefined}
    </Tooltip.Trigger>
    <Tooltip.Content>
      {descriptions[permission]}
    </Tooltip.Content>
  </Tooltip>;
}
