import { Heading, Label, Paragraph, Switch, XStack, YStack } from '@jonline/ui';
import { useAppDispatch } from 'app/hooks';
import React from 'react';


export interface ToggleRowProps {
  name: string;
  description?: string;
  value: boolean | undefined;
  setter: (value: boolean) => any;
  disabled?: boolean;
  autoDispatch?: boolean;
}
export function ToggleRow({ name, description, value: optionalValue, setter, disabled = false, autoDispatch = false }: ToggleRowProps) {
  const dispatch = useAppDispatch();
  const nameKey = name.toLowerCase().replace(/[^\w]/g, '_');
  const value = !!optionalValue;
  return <XStack space='$3' o={disabled ? 0.5 : 1} my='$1'>
    <Label htmlFor={nameKey} my='auto' f={1}>
      <YStack w='100%'>
        <Paragraph size='$5' my='auto'>
          {name}
        </Paragraph>
        {description
          ? <Paragraph lineHeight='$1' size='$1' o={value ? 1 : 0.5}>
            {description}
          </Paragraph>
          : undefined}
      </YStack>
    </Label>
    <Switch name={nameKey} size="$5" margin='auto'
      defaultChecked={value}
      checked={value}
      value={value.toString()}
      disabled={disabled}
      onCheckedChange={(checked) => autoDispatch ? dispatch(setter(checked)) : setter(checked)}>
      <Switch.Thumb animation="quick" backgroundColor='black' />
    </Switch>
  </XStack>;
}
