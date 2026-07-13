import React from 'react';
import { Theme, useThemeName } from 'tamagui';

// Tamagui 2.x removed `<Theme inverse>`. Theme names are `light`/`dark`,
// optionally suffixed with a color (e.g. `dark_orange`), so inverting just
// swaps that prefix while preserving the color suffix.
export function InverseTheme({ active = true, children }: { active?: boolean; children: React.ReactNode }) {
  const themeName = useThemeName();
  if (!active) return <>{children}</>;

  const inverseName = themeName.startsWith('dark')
    ? themeName.replace(/^dark/, 'light')
    : themeName.replace(/^light/, 'dark');

  return <Theme name={inverseName as any}>{children}</Theme>;
}
