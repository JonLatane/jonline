import { Visibility } from "@jonline/api";
import { Adapt, Heading, Paragraph, Select, Sheet, YStack } from "@jonline/ui";
import { LinearGradient } from "@tamagui/linear-gradient";
import { Check, ChevronDown, ChevronUp } from "@tamagui/lucide-icons";

export type VisibilityPickerProps = {
  id?: string;
  visibility: Visibility;
  onChange: (visibility: Visibility) => void;
  disabled?: boolean;
  label?: string;
  // unused as yet
  visibilityDescription?: (visibility: Visibility) => string | undefined;
};

export function VisibilityPicker({ id, visibility, onChange, disabled, label, visibilityDescription = visiblityDescription }: VisibilityPickerProps) {
  function onValueSelected(v: string) {
    const selectedVisibility = parseInt(v) as Visibility;
    onChange(selectedVisibility)
  }

  return <Select id={id ?? 'visibility-picker'} onValueChange={onValueSelected} value={visibility.toString()}>
    <Select.Trigger f={1} maw={350} opacity={disabled ? 0.5 : 1} iconAfter={ChevronDown} {...{ disabled }}>
      <Select.Value placeholder="Something" />
    </Select.Trigger>

    <Adapt when="xs" platform="touch">
      <Sheet modal dismissOnSnapToBottom>
        <Sheet.Frame>
          <Sheet.ScrollView>
            <Adapt.Contents />
          </Sheet.ScrollView>
        </Sheet.Frame>
        <Sheet.Overlay />
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
        <Select.Group space="$-0">
          <Select.Label>{label ?? 'Visibility'}</Select.Label>
          {[Visibility.PRIVATE, Visibility.LIMITED, Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC,].map((item, i) => {
            const description = visibilityDescription?.(item);
            return (
              <Select.Item index={i} key={`${item}`} value={item.toString()}>
                <Select.ItemText>
                  <YStack>
                    <Heading size='$2'>{visibilityName(item)}</Heading>
                    <Paragraph size='$1'>{visibilityDescription(item)}</Paragraph>
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
          <ChevronDown size={20} />
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
  </Select>;
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

export function visiblityDescription(v: Visibility) {
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