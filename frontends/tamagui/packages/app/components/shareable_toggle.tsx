import { Label, Paragraph, Switch, YStack } from '@jonline/ui';
import { useComponentKey } from 'app/hooks';
import { useCurrentAccount, useAppDispatch } from 'app/hooks';
import React from 'react';


export interface ShareableToggleProps {
  value: boolean | undefined;
  setter: (value: boolean) => any;
  disabled?: boolean;
  readOnly?: boolean;
  autoDispatch?: boolean;
  isOwner?: boolean;
}

let _key = 1;
export function ShareableToggle({
  value: optionalValue,
  setter,
  disabled = false,
  readOnly = false,
  autoDispatch = false,
  isOwner = false,
}: ShareableToggleProps) {
  const dispatch = useAppDispatch();
  const value = !!optionalValue;
  const name = useComponentKey('shareable');

  const label = value ? 'Shareable' :
    readOnly && isOwner
      ? 'Not shareable for others'
      : 'Not Shareable';

  if (!useCurrentAccount()) {
    return <></>;
  }

  if (readOnly) {
    return <Paragraph size='$1' o={0.5} my='auto' lineHeight='$1' pt='$1'>
      {label}
    </Paragraph>
  }

  // const nameKey = name.toLowerCase().replace(/[^\w]/g, '_');
  return <YStack gap='$1' o={disabled ? 0.5 : 1} my='auto'>
    <Label htmlFor={name} my='auto' f={1}>
      <Paragraph size='$1' mx='auto' lineHeight='$1'>
        Shareable
      </Paragraph>
    </Label>
    <Switch name={name} id={name} size="$1" mx='auto'
      defaultChecked={value}
      checked={value}
      value={value.toString()}
      disabled={disabled}
      onCheckedChange={(checked) => autoDispatch ? dispatch(setter(checked)) : setter(checked)}>
      <Switch.Thumb animation='standard' backgroundColor='$background' />
    </Switch>
  </YStack>;
}
