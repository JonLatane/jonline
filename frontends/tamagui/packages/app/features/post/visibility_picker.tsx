import { Visibility } from "@jonline/api";
import { Adapt, Heading, Paragraph, Select, Sheet, XStack, YStack, standardAnimation } from "@jonline/ui";
import { LinearGradient } from "@tamagui/linear-gradient";
import { Check, ChevronDown, ChevronUp } from "@tamagui/lucide-icons";
import { styled } from 'tamagui';

export type VisibilityPickerProps = {
  id?: string;
  visibility: Visibility;
  onChange: (visibility: Visibility) => void;
  disabled?: boolean;
  label?: string;
  // unused as yet
  visibilityDescription?: (visibility: Visibility) => string | undefined;
};


export function VisibilityPicker({ id, visibility, onChange, disabled, label, visibilityDescription = defaultVisibilityDescription }: VisibilityPickerProps) {
  function onValueSelected(v: string) {
    const selectedVisibility = parseInt(v) as Visibility;
    onChange(selectedVisibility)
  }
  const description = visibilityDescription?.(visibility);



  return <YStack w='100%' maw={350}>
    {/* <style>
      select {
        width: 100%;
      }
    </style> */}
    <Select native id={id ?? 'visibility-picker'} onValueChange={onValueSelected} value={visibility.toString()}>
      <Select.Trigger w='100%' f={1} opacity={disabled ? 0.5 : 1} iconAfter={ChevronDown} {...{ disabled }}>
        <Select.Value w='100%' placeholder="Choose Visibility" />
      </Select.Trigger>

      {/* <Adapt when="xs" platform="touch">
      <Sheet modal dismissOnSnapToBottom>
        <Sheet.Frame>
          <Sheet.ScrollView>
            <Adapt.Contents />
          </Sheet.ScrollView>
        </Sheet.Frame>
        <Sheet.Overlay />
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

        <Select.Viewport minWidth={200} w='100%'
        // animation='quick' {...standardAnimation}
        >
          <XStack w='100%'>
            <Select.Group space="$0" w='100%'>
              <Select.Label w='100%'>{label ?? 'Visibility'}</Select.Label>
              {[Visibility.PRIVATE, Visibility.LIMITED, Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC,].map((item, i) => {
                // const description = visibilityDescription?.(item);
                return (
                  <Select.Item w='100%' index={i} key={`${item}`} value={item.toString()}>
                    <Select.ItemText w='100%'>
                      {/* <YStack> */}
                      {/* <Heading size='$2'> */}
                      {visibilityName(item)}
                      {/* </Heading> */}
                      {/* {description ? <Paragraph size='$1'>{description}</Paragraph> : undefined} */}
                      {/* </YStack> */}
                    </Select.ItemText>
                    <Select.ItemIndicator ml="auto">
                      <Check size={16} />
                    </Select.ItemIndicator>
                  </Select.Item>
                )
              })}
            </Select.Group>
            <YStack
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
          <ChevronDown size={20} />
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
    </Select>
    {description ? <Paragraph size='$1' mx='$2' my='$1'>{description}</Paragraph> : undefined}
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