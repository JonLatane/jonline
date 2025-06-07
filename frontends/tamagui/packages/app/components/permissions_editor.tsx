import { Permission, permissionToJSON } from '@jonline/api';
import { Button, Heading, Paragraph, Select, XStack, YStack } from '@jonline/ui';
import { Check, ChevronDown, Plus, X as XIcon } from '@tamagui/lucide-icons';
import { useComponentKey } from 'app/hooks';
import React from 'react';

export type PermissionsEditorProps = {
  id?: string;
  label?: string;
  description?: string;
  selectablePermissions?: Permission[];
  selectedPermissions: Permission[];
  selectPermission: (p: Permission) => void;
  deselectPermission: (p: Permission) => void;
  editMode: boolean;
  disabled?: boolean;
}

function toTitleCase(str: string) {
  return str.replace(
    /\w\S*/g,
    function (txt: string) {
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

export const PermissionsEditor: React.FC<PermissionsEditorProps> = ({
  id,
  label,
  description,
  selectablePermissions,
  selectedPermissions,
  selectPermission,
  deselectPermission,
  editMode,
  disabled
}) => {
  const viewOnlyMode = !editMode;
  const allPermissions = selectablePermissions ??
    Object.keys(Permission)
      .filter(k => typeof Permission[k as any] === "number")
      .map(k => Permission[k as any]! as unknown as Permission)
      .filter(p => p != Permission.PERMISSION_UNKNOWN && p != Permission.UNRECOGNIZED);
  const addablePermissions = allPermissions.filter(p => !selectedPermissions.includes(p));
  const componentKey = useComponentKey('permissions-editor');
  return <YStack w='100%' key={componentKey}>
    <Heading key='permissions-editor-heading' size='$3' marginVertical='auto' o={editMode ? 1 : 0.5}>
      {label ?? 'Permissions'}
    </Heading>
    {description ? <Paragraph key='permissions-editor-description' size='$2' o={0.5}>
      {description}
    </Paragraph> : undefined}
    <XStack key='permissions-editor-permissions' w='100%' gap='$2' flexWrap='wrap' ai='center'>
      {selectedPermissions.map((p: Permission) =>
        <XStack key={`permission-${p}`} mb='$2' backgroundColor='$backgroundFocus' borderRadius='$2' px='$2' py='$1' gap='$2' ai='center'>
          <Paragraph size='$2'>{permissionName(p)}</Paragraph>
          {editMode
            ? <Button circular size='$1' icon={XIcon} disabled={disabled} o={disabled ? 0.5 : 1} onPress={() => deselectPermission(p)} />
            : undefined}
        </XStack>
        // <Button key={`permission-${p}`} disabled={!editMode} onPress={() => deselectPermission(p)} mb='$2'>
        //   <XStack>
        //     <Paragraph size='$2'>{permissionName(p)}</Paragraph>
        //   </XStack>
        // </Button>
      )
      }
      {editMode && addablePermissions.length > 0 ?
        <Select native key={`permissions-${JSON.stringify(selectedPermissions)}`}
          onValueChange={(p) => {
            if (p !== Permission.PERMISSION_UNKNOWN.toString()) {
              selectPermission(parseInt(p) as Permission);
            }
          }}
          value={undefined}>
          <Select.Trigger key='permission-selector' height='$2' f={1} maw={350} opacity={disabled ? 0.5 : 1} iconAfter={Plus}
            disabled={disabled}>
            <Select.Value placeholder="Add a Permission..." />
          </Select.Trigger>

          {/* <Adapt when="xs" platform="touch">
          <Sheet modal dismissOnSnapToBottom>
            <Sheet.Frame>
              <Sheet.ScrollView>
                <Adapt.Contents />
              </Sheet.ScrollView>
            </Sheet.Frame>
            <Sheet.Overlay  />
          </Sheet>
        </Adapt> */}

          <Select.Content zIndex={200000}>
            {/* <Select.ScrollUpButton ai="center" jc="center" pos="relative" w="100%" h="$3">
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
          </Select.ScrollUpButton> */}

            <Select.Viewport minWidth={200}>
              <XStack>
                <Select.Group key='permissions-editor' gap="$0" w='100%'>
                  <Select.Label>{'Available Permissions'}</Select.Label>
                  <Select.Item disabled index={0} key='placeholder' value={Permission.PERMISSION_UNKNOWN.toString()}>
                    <Select.ItemText>
                      Add a Permission...
                    </Select.ItemText>
                    {/* <Select.ItemIndicator ml="auto">
                    <Check size={16} />
                  </Select.ItemIndicator> */}
                  </Select.Item>
                  {addablePermissions.map((item, i) => {
                    const description = permissionDescription?.(item);
                    return (
                      <Select.Item index={i + 1} key={`${item}`} value={item.toString()}>
                        <Select.ItemText>
                          {/* <YStack> */}
                          {/* <Heading size='$2'> */}
                          {permissionName(item)}
                          {/* </Heading> */}
                          {/* <Paragraph size='$1'>{permissionDescription(item)}</Paragraph> */}
                          {/* </YStack> */}
                        </Select.ItemText>
                        <Select.ItemIndicator ml="auto">
                          <Check size={16} />
                        </Select.ItemIndicator>
                      </Select.Item>
                    )
                  })}
                </Select.Group>
                <YStack key='chevron-down'
                  position="absolute"
                  right={0}
                  top={0}
                  bottom={0}
                  alignItems="center"
                  justifyContent="center"
                  width={'$4'}
                  pointerEvents="none"
                >
                  <ChevronDown size='$2' />
                </YStack>
              </XStack>
            </Select.Viewport>

            {/* <Select.ScrollDownButton ai="center" jc="center" pos="relative" w="100%" h="$3">
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
          </Select.ScrollDownButton> */}
          </Select.Content>
        </Select> : undefined}

    </XStack>
  </YStack>;
};
