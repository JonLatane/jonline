import { WebUserInterface } from "@jonline/api";
import { Paragraph, Select, XStack, YStack } from "@jonline/ui";
import { Check, ChevronDown } from "@tamagui/lucide-icons";
import { useCallback } from "react";

export type WebUserInterfacePickerProps = {
  id?: string;
  webUserInterface: WebUserInterface;
  onChange: (webUserInterface: WebUserInterface) => void;
  disabled?: boolean;
  label?: string;
  values?: WebUserInterface[];
  webUserInterfaceDescription?: (webUserInterface: WebUserInterface) => string | undefined;
};

export function WebUserInterfacePicker({
  id,
  values = [WebUserInterface.REACT_TAMAGUI, WebUserInterface.ELM_SPA],
  webUserInterface,
  onChange,
  disabled,
  label,
  webUserInterfaceDescription = defaultWebUserInterfaceDescription
}: WebUserInterfacePickerProps) {
  const onValueSelected = useCallback((v: string) => {
    const selectedWebUserInterface = parseInt(v) as WebUserInterface;
    onChange(selectedWebUserInterface)
  }, [onChange]);
  const description = webUserInterfaceDescription(webUserInterface);

  return <YStack w='100%' maw={350} opacity={disabled ? 0.5 : 1} pointerEvents={disabled ? 'none' : undefined}>
    <Select native id={id ?? 'web-user-interface-picker'}
      value={webUserInterface.toString()}
      onValueChange={onValueSelected}
    >
      <Select.Trigger w='100%' f={1} iconAfter={ChevronDown}
        disabled={disabled}>
        <Select.Value w='100%' placeholder="Choose Web UI" />
      </Select.Trigger>
      <Select.Content zIndex={200000} >
        <Select.Viewport minWidth={200} w='100%'>
          <XStack w='100%'>
            <Select.Group gap="$0" w='100%'>
              <Select.Label w='100%'>{label ?? 'Default Web UI'}</Select.Label>
              {values.map((item, i) => {
                return (
                  <Select.Item w='100%' index={i} key={`${item}`} value={item.toString()}>
                    <Select.ItemText w='100%'>
                      {webUserInterfaceName(item)}
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

export function defaultWebUserInterfaceDescription(v: WebUserInterface) {
  switch (v) {
    case WebUserInterface.REACT_TAMAGUI: return 'React/Redux/Tamagui UI. Fast to load and full-featured. Always accessible at /tamagui.';
    case WebUserInterface.ELM_SPA: return 'Elm SPA UI. Lightweight and functional. Always accessible at /elm.';
    case WebUserInterface.FLUTTER_WEB: return 'Flutter Web UI. Currently disabled. Always accessible at /flutter.';
    case WebUserInterface.HANDLEBARS_TEMPLATES: return 'Deprecated. Will revert to the Tamagui UI if chosen.';
    default: return undefined;
  }
}

export function webUserInterfaceName(webUserInterface: WebUserInterface) {
  switch (webUserInterface) {
    case WebUserInterface.REACT_TAMAGUI:
      return 'React/Tamagui';
    case WebUserInterface.ELM_SPA:
      return 'Elm';
    case WebUserInterface.FLUTTER_WEB:
      return 'Flutter Web';
    case WebUserInterface.HANDLEBARS_TEMPLATES:
      return 'Handlebars Templates';
    default:
      return 'Unknown';
  }
}
