import { Button, Heading, Paragraph, YStack } from "@jonline/ui";
import { useServerTheme } from "app/store";

export type SubnavButtonProps = {
  title: string;
  icon?: React.JSX.Element;
  selected: boolean;
  select: () => void;
}
export const SubnavButton: React.FC<SubnavButtonProps> = ({ title, icon, selected, select }) => {
  const { navAnchorColor } = useServerTheme();
  return <Button f={1} h={56} transparent
    onPress={select}
  >
    <YStack alignItems='center'>
      {icon}
      {icon ?
      <Paragraph size='$1' color={selected ? navAnchorColor : undefined}>
        {title}
      </Paragraph> :
      <Heading size='$3' color={selected ? navAnchorColor : undefined}>
        {title}
      </Heading>}
    </YStack>
  </Button>
}