import { Label, Switch, XStack } from '@jonline/ui';
import { useTypedDispatch } from 'app/store';
import React from 'react';


export interface ToggleRowProps {
  name: string;
  value: boolean;
  setter: (value: boolean) => any;
  disabled?: boolean;
  autoDispatch?: boolean;
}
export function ToggleRow({ name, value, setter, disabled = false, autoDispatch = false }: ToggleRowProps) {
  const dispatch = useTypedDispatch();
  return <XStack space='$3' o={disabled ? 0.5 : 1} my='$1'>
    <Label marginVertical='auto' f={1}>{name}</Label>
    <Switch size="$5" margin='auto'
      defaultChecked={value}
      checked={value}
      value={value.toString()}
      disabled={disabled}
      onCheckedChange={(checked) => autoDispatch ? dispatch(setter(checked)) : setter(checked)}>
      <Switch.Thumb animation="quick" backgroundColor='black' />
    </Switch>
  </XStack>;
}
