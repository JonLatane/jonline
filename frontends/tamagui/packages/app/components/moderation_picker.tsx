import { Moderation } from "@jonline/api";
import { Paragraph, Select, XStack, YStack } from "@jonline/ui";
import { Check, ChevronDown } from "@tamagui/lucide-icons";

export type ModerationPickerProps = {
  id?: string;
  moderation: Moderation;
  onChange: (moderation: Moderation) => void;
  disabled?: boolean;
  label?: string;
  values?: Moderation[];
  moderationDescription?: (moderation: Moderation) => string | undefined;
};

export function ModerationPicker({
  id,
  values = [Moderation.APPROVED, Moderation.PENDING, Moderation.REJECTED, Moderation.UNMODERATED],
  moderation,
  onChange,
  disabled,
  label,
  moderationDescription = defaultModerationDescription
}: ModerationPickerProps) {
  function onValueSelected(v: string) {
    const selectedModeration = parseInt(v) as Moderation;
    onChange(selectedModeration)
  }
  const description = moderationDescription(moderation);

  return <YStack w='100%' maw={350} opacity={disabled ? 0.5 : 1} pointerEvents={disabled ? 'none' : undefined}>
    <Select native id={id ?? 'moderation-picker'}
     value={moderation.toString()}
      onValueChange={onValueSelected} 
    // disabled={disabled}
    >
      <Select.Trigger w='100%' f={1}  iconAfter={ChevronDown}
       disabled={disabled}>
        <Select.Value w='100%' placeholder="Choose Moderation" />
      </Select.Trigger>
      <Select.Content zIndex={200000} >
        <Select.Viewport minWidth={200} w='100%'>
          <XStack w='100%'>
            <Select.Group gap="$0" w='100%'>
              <Select.Label w='100%'>{label ?? 'Moderation'}</Select.Label>
              {values.map((item, i) => {
                return (
                  <Select.Item w='100%' index={i} key={`${item}`} value={item.toString()}>
                    <Select.ItemText w='100%'>
                      {moderationName(item)}
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
      </Select.Content>
    </Select>
    {description ? <Paragraph size='$1' mx='$2' my='$1'>{description}</Paragraph> : undefined}
  </YStack>;
}

export function defaultModerationDescription(v: Moderation) {
  switch (v) {
    case Moderation.UNMODERATED: return 'Not moderated, nor awaiting moderation. Visible to users.';
    case Moderation.REJECTED: return 'Rejected by moderators. Visible only to you.';
    case Moderation.APPROVED: return 'Approved by moderators. Visible to users.';
    case Moderation.PENDING: return 'Awaiting moderation. Visible only to you.';
  }
}

export function moderationName(moderation: Moderation) {
  switch (moderation) {
    case Moderation.UNMODERATED:
      return 'Unmoderated';
    case Moderation.REJECTED:
      return 'Rejected';
    case Moderation.APPROVED:
      return 'Approved';
    case Moderation.PENDING:
      return 'Pending';
    default:
      return 'Unknown';
  }
}