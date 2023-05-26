import { Permission, permissionToJSON } from '@jonline/api';
import { Adapt, Button, Heading, Paragraph, Select, Sheet, XStack, YStack } from '@jonline/ui';
import { LinearGradient } from "@tamagui/linear-gradient";
import { Check, ChevronUp, Plus } from '@tamagui/lucide-icons';
import React from 'react';

export type PermissionsEditorProps = {
  id?: string;
  label?: string;
  selectablePermissions?: Permission[];
  selectedPermissions: Permission[];
  selectPermission: (p: Permission) => void;
  deselectPermission: (p: Permission) => void;
  editMode: boolean;
}

function toTitleCase(str: string) {
  return str.replace(
    /\w\S*/g,
    function(txt: string) {
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    }
  );
}

function permissionName(p: Permission): string {
  return toTitleCase(permissionToJSON(p).replace(/_/g, ' '));
}

function permissionDescription(p: Permission): string | undefined {
  switch (p) {
    case Permission.ADMIN:
      return 'Grants access to server configuration and all other permissions, such as moderation, creation, and publishing of media, posts, and events.';
  }
  return undefined;
}

export const PermissionsEditor: React.FC<PermissionsEditorProps> = ({ id, label, selectablePermissions, selectedPermissions, selectPermission, deselectPermission, editMode }) => {
  const disabled = !editMode;
  const allPermissions = selectablePermissions ??
    Object.keys(Permission)
      .filter(k => typeof Permission[k as any] === "number")
      .map(k => Permission[k as any]! as unknown as Permission)
      .filter(p => p != Permission.PERMISSION_UNKNOWN && p != Permission.UNRECOGNIZED);
  const addablePermissions = allPermissions.filter(p => !selectedPermissions.includes(p));
  return <YStack w='100%'>
    <Heading size='$3' marginVertical='auto' o={editMode ? 1 : 0.5}>
      {label ?? 'Permissions'}
    </Heading>
    <XStack w='100%' space='$2' flexWrap='wrap'>
      {selectedPermissions.map((p: Permission) =>
        <Button disabled={!editMode} onPress={() => deselectPermission(p)} mb='$2'>
          <XStack>
            <Paragraph size='$2'>{permissionName(p)}</Paragraph>
          </XStack>
        </Button>)
      }
      {editMode ? <Select key={`permissions-${JSON.stringify(selectedPermissions)}`} onValueChange={(p) => selectPermission(parseInt(p) as Permission)}
        value={undefined}>
        <Select.Trigger height='$2' f={1} maw={350} opacity={disabled ? 0.5 : 1} iconAfter={Plus} {...{ disabled }}>
          <Select.Value placeholder="Add a Permission..." />
        </Select.Trigger>

        <Adapt when="xs" platform="touch">
          <Sheet modal dismissOnSnapToBottom>
            <Sheet.Frame>
              <Sheet.ScrollView>
                <Adapt.Contents />
              </Sheet.ScrollView>
            </Sheet.Frame>
            <Sheet.Overlay backgroundColor='$colorTranslucent' />
          </Sheet>
        </Adapt>

        <Select.Content zIndex={200000}>
          <Select.ScrollUpButton ai="center" jc="center" pos="relative" w="100%" h="$3">
            <YStack zi={10}>
              <ChevronUp size={20} />
            </YStack>
            <LinearGradient
              start={[0, 0]}
              end={[0, 1]}
              fullscreen
              colors={['$background', '$backgroundTransparent']}
              br="$4"
            />
          </Select.ScrollUpButton>

          <Select.Viewport minWidth={200}>
            <Select.Group space="$0">
              <Select.Label>{'Available Permissions'}</Select.Label>
              {addablePermissions.map((item, i) => {
                const description = permissionDescription?.(item);
                return (
                  <Select.Item index={i} key={`${item}`} value={item.toString()}>
                    <Select.ItemText>
                      <YStack>
                        <Heading size='$2'>{permissionName(item)}</Heading>
                        <Paragraph size='$1'>{permissionDescription(item)}</Paragraph>
                      </YStack>
                    </Select.ItemText>
                    <Select.ItemIndicator ml="auto">
                      <Check size={16} />
                    </Select.ItemIndicator>
                  </Select.Item>
                )
              })}
            </Select.Group>
          </Select.Viewport>

          <Select.ScrollDownButton ai="center" jc="center" pos="relative" w="100%" h="$3">
            <YStack zi={10}>
              <Plus size={20} />
            </YStack>
            <LinearGradient
              start={[0, 0]}
              end={[0, 1]}
              fullscreen
              colors={['$backgroundTransparent', '$background']}
              br="$4"
            />
          </Select.ScrollDownButton>
        </Select.Content>
      </Select> : undefined}

    </XStack>
  </YStack>;
};
