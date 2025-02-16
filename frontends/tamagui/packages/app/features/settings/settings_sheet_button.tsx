import { Button, SizeTokens } from '@jonline/ui';
import { Settings } from '@tamagui/lucide-icons';
import { useSettingsSheetContext } from 'app/contexts/settings_sheet_context';
import React from 'react';

export type SettingsSheetButtonProps = {
  size?: SizeTokens;
}

export function SettingsSheetButton({ size }: SettingsSheetButtonProps) {
  const { open: [open, setOpen] } = useSettingsSheetContext();

  return <Button
    size={size}
    icon={Settings}
    circular
    onPress={() => setOpen(!open)}
  />
}
