import { Button, Paragraph, XStack, ZStack } from '@jonline/ui';
import { Moon, Sun } from '@tamagui/lucide-icons';
import { useAppDispatch, useLocalConfiguration } from 'app/hooks';
import { setDarkMode, setDarkModeAuto, } from 'app/store';
import React from 'react';

export const doesPlatformPreferDarkMode = () =>
  window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

export function DarkModeToggle({ }) {
  const dispatch = useAppDispatch();

  const { darkMode, darkModeAuto } = useLocalConfiguration();

  const isInDarkMode = darkModeAuto ? doesPlatformPreferDarkMode() : darkMode;
  const toggleDarkMode = () => {
    if (darkModeAuto) {
      dispatch(setDarkModeAuto(false));
      dispatch(setDarkMode(!doesPlatformPreferDarkMode()));
    } else if (darkMode == doesPlatformPreferDarkMode()) {
      dispatch(setDarkModeAuto(true));
    } else {
      dispatch(setDarkMode(!darkMode));
    }
  }

  return <Button size='$3' circular p={0}
    onPress={toggleDarkMode}>
    <ZStack w='$3' h='$3'>
      <Paragraph size='$1' mx='auto' my='auto' o={darkModeAuto ? 1 : 0} animation='standard' transform={[{ translateX: 10 }, { translateY: 10 }]}>
        Auto
      </Paragraph>
      <XStack mx='auto' my='auto' o={isInDarkMode ? darkModeAuto ? 0.5 : 1 : 0} animation='standard'>
        <Moon size='$1' />
      </XStack>
      <XStack mx='auto' my='auto' o={isInDarkMode ? 0 : darkModeAuto ? 0.5 : 1} animation='standard'>
        <Sun size='$1' />
      </XStack>
    </ZStack>
  </Button>;
}
