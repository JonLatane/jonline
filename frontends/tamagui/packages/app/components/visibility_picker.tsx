import { Visibility } from "@jonline/api";
import { Heading, Label, Paragraph, Select, Tooltip, XStack, YStack } from "@jonline/ui";
import { Check, ChevronDown } from "@tamagui/lucide-icons";
import { useComponentKey } from "app/hooks";
import { useCallback, useState } from "react";

export type VisibilityPickerProps = {
  id?: string;
  visibility: Visibility;
  onChange: (visibility: Visibility) => void;
  disabled?: boolean;
  label?: string;
  // unused as yet
  visibilityDescription?: (visibility: Visibility) => string | undefined;
  // Does not render a picker at all. Just the label with a description as a tooltip.
  readOnly?: boolean;

  canPublishLocally?: boolean;
  canPublishGlobally?: boolean;
};


let _key = 1;
export function VisibilityPicker({
  id,
  visibility,
  onChange,
  disabled,
  label,
  visibilityDescription = defaultVisibilityDescription,
  readOnly,
  canPublishLocally = true,
  canPublishGlobally = true,
}: VisibilityPickerProps) {
  const onValueSelected = useCallback((v: string) => {
    const selectedVisibility = parseInt(v) as Visibility;
    onChange(selectedVisibility)
  }, [onChange]);
  const description = visibilityDescription?.(visibility);

  const name = useComponentKey('visibility');

  if (readOnly) {
    return <Tooltip>
      <Tooltip.Trigger>
        <XStack my='auto' opacity={0.5} gap='$2'>
          {/* <Heading size='$1' mr='$2' opacity={0.5}>Visibility:</Heading> */}
          <Paragraph my='auto' size='$1'>{visibilityName(visibility)}</Paragraph>
          {/* <Text my='auto' mr='$2' fontSize={'$1'} fontFamily='$body'>{visibilityName(visibility)}</Text> */}
          {/* <XStack my='auto'>
            <Info size='$1 ' />
          </XStack> */}
        </XStack>
      </Tooltip.Trigger>
      {description ? <Tooltip.Content>
        <Paragraph size='$1'>{description}</Paragraph>
      </Tooltip.Content> : undefined}
    </Tooltip>
  }


  return <YStack w='100%' maw={350}>
    {/* {readOnly ? undefined : <Heading size='$1'>Visibility</Heading>} */}
    {/* <style>
      select {
        width: 100%;
      }
    </style> */}

    {disabled
      ? <XStack mx='auto'>

        <Heading size='$1' mr='$2' opacity={0.5}>Visibility:</Heading>
        <Heading size='$2' opacity={0.5}>{visibilityName(visibility)}</Heading>
      </XStack>
      : <Select id={id ?? name} name={name} onValueChange={onValueSelected}  {...{ disabled }} value={visibility.toString()}>
        <Select.Trigger f={1} opacity={disabled ? 0.5 : 1} iconAfter={ChevronDown} {...{ disabled }}>
          <Select.Value placeholder="Choose Visibility" />
        </Select.Trigger>

        <Select.Content zIndex={20000000}>

          <Select.Viewport minWidth={200}>
            <Select.Group gap="$0" w='100%'>
              <Select.Label>{label ?? 'Visibility'}</Select.Label>
              {[Visibility.PRIVATE, Visibility.LIMITED, Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC,].map((item, i) => {
                if (item != visibility) {
                  if (item == Visibility.SERVER_PUBLIC && !canPublishLocally) return undefined;
                  if (item == Visibility.GLOBAL_PUBLIC && !canPublishGlobally) return undefined;
                }

                const description = visibilityDescription?.(item);
                return (
                  <Select.Item index={i} key={`${item}`} value={item.toString()}>
                    <Select.ItemText>
                      <YStack>
                        <Heading size='$2'>
                          {visibilityName(item)}
                        </Heading>
                        {description ? <Paragraph size='$1'>{description}</Paragraph> : undefined}
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

        </Select.Content>
      </Select>}
    {/* {description
      ? <Label htmlFor={name}>
        <Paragraph size='$1' mx='$2' my='$1'>{description}</Paragraph>
      </Label> : undefined} */}
  </YStack>;
  // return <Select onValueChange={v => onChange(Visibility[v])} value={visibility.toString()}>
  //   {[Visibility.PRIVATE, Visibility.LIMITED, Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC,].map((item, i) => {
  //     return (
  //       <Select.Item index={i} key={`${item}`} value={item.toString()}>
  //         <Select.ItemText>{visibilityName(item)}</Select.ItemText>
  //         <Select.ItemIndicator ml="auto">
  //           <Check size={16} />
  //         </Select.ItemIndicator>
  //       </Select.Item>
  //     )
  //   })}
  // </Select>
}

export function defaultVisibilityDescription(v: Visibility) {
  switch (v) {
    case Visibility.GLOBAL_PUBLIC: return 'Visible to anyone on the internet.';
    case Visibility.SERVER_PUBLIC: return 'Visible to anyone on this server.';
    case Visibility.LIMITED: return 'Visible only to specific users or groups.';
    case Visibility.PRIVATE: return 'Visible only to you.';
  }
}

export function visibilityName(visibility: Visibility) {
  switch (visibility) {
    case Visibility.PRIVATE:
      return 'Private';
    case Visibility.LIMITED:
      return 'Limited';
    case Visibility.SERVER_PUBLIC:
      return 'Server Public';
    case Visibility.GLOBAL_PUBLIC:
      return 'Global Public';
    default:
      return 'Unknown';
  }
}