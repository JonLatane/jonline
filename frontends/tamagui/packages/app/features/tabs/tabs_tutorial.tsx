import { AnimatePresence, Button, ButtonProps, Heading, Paragraph, Tooltip, XStack, YStack, ZStack, standardAnimation, useForceUpdate, useMedia } from "@jonline/ui";
import { CornerRightUp, HelpCircle, MoveUp } from '@tamagui/lucide-icons';
import { DarkModeToggle, doesPlatformPreferDarkMode } from "app/components/dark_mode_toggle";
import { setShowHelp, useAppDispatch, useLocalConfiguration, useServerTheme } from "app/store";
import { themedButtonBackground } from "app/utils/themed_button_background";
import { useEffect, useState } from "react";
import { GestureResponderEvent } from "react-native";

let reallyHideHelp = false;
export function TutorialToggle(props: ButtonProps) {
  const { onPress: parentOnPress, ...rest } = props;
  const dispatch = useAppDispatch();
  const onPress = (event: GestureResponderEvent) => {
    dispatch(setShowHelp(true));
    reallyHideHelp = false;
    parentOnPress?.(event);
  };
  return <Button {...rest} onPress={onPress} size='$3' p='$1' circular icon={HelpCircle} />;
}

export function TabsTutorial({ }) {
  const mediaQuery = useMedia();
  const config = useLocalConfiguration();
  // debugger;
  const showHelp = config.showHelp ?? true;
  const dispatch = useAppDispatch();
  const focueUpdate = useForceUpdate();
  const [hidingStarted, setHidingStarted] = useState(false);
  const startHidingHelp = () => {
    reallyHideHelp = true;
    setHidingStarted(true);
  }
  useEffect(() => {
    setHidingStarted(false);
    if (showHelp) {
      setTimeout(startHidingHelp, 15000);
    }
  }, [showHelp]);
  useEffect(() => {
    if (hidingStarted) {
      setTimeout(() => {
        if (reallyHideHelp) {
          dispatch(setShowHelp(false))
        }
      }, 5000);
    }
  }, [hidingStarted]);
  const { primaryColor, primaryAnchorColor, navColor, navTextColor } = useServerTheme();

  const circularAccountsSheet = !mediaQuery.gtSm;

  const stackGroupsBelow = true;

  const height = stackGroupsBelow ? '$8' : '$3';
  const measuredHomeButtonWidth = document.querySelector('.home-button')?.clientWidth ?? 0;
  const homeButtonWidth = measuredHomeButtonWidth > 0 ? measuredHomeButtonWidth : 0;

  const measuredGroupsButtonWidth = document.querySelector('.main-groups-button')?.clientWidth ?? 0;
  const groupsButtonWidth = measuredGroupsButtonWidth > 0 ? measuredGroupsButtonWidth : 0;

  const gotIt = () => {
    if (!hidingStarted) {
      setHidingStarted(true);
    } else {
      dispatch(setShowHelp(false));
    }
  }


  const { darkMode, darkModeAuto } = useLocalConfiguration();

  const isInDarkMode = darkModeAuto ? doesPlatformPreferDarkMode() : darkMode;
  return <AnimatePresence>
    {showHelp
      ? <ZStack w='100%' h={height} animation='standard' {...standardAnimation} mt='$3' pt='$2'>
        <XStack w='100%' ai='center' space='$2' animation='standard' o={hidingStarted ? 0 : 1}>
          <YStack space='$1' ai='center' jc='center' ac='center' ml={homeButtonWidth + ((groupsButtonWidth - 20) / 2) - 5} >
            <XStack ml='$1'><MoveUp size='$5' opacity={mediaQuery.gtXxxs ? 1 : 0.25} /></XStack>
            <Paragraph mt='$1' size='$2' fontWeight='bold'>Groups</Paragraph>
          </YStack>
          <YStack space='$1' ai='center' ml={-20 + (groupsButtonWidth - 20) / 2}>
            <MoveUp size='$5' opacity={mediaQuery.gtXxs ? 1 : 0.25} />
            <Paragraph mt='$1' size='$2' fontWeight='bold'>Features/Sections</Paragraph>
          </YStack>
        </XStack>
        <XStack w='100%' ai='center' space='$2' mt={-4}>
          <YStack my='auto' ai='center' space='$2' mt='$4'>
            <Button ml='$3' {...themedButtonBackground(navColor, navTextColor)} size='$3' py='$1' px='$2' onPress={gotIt}>
              <Heading size='$1' color={navTextColor}>
                {hidingStarted ? 'Yes, okay' : 'Got it!'}
              </Heading>
            </Button>
          </YStack>
          <XStack f={1} />
          <Paragraph size='$2' textAlign="right" fontWeight='bold'>
            {hidingStarted
              ? 'View this again later'
              : 'Accounts and Settings'}
          </Paragraph>
          <Paragraph size='$2' fontWeight='bold'>(</Paragraph>
          <XStack mb='$1' opacity={hidingStarted ? 1 : 0.8} animation='standard'>
            {hidingStarted
              ? <TutorialToggle onPress={() => setHidingStarted(false)} />
              : <DarkModeToggle />}
          </XStack>
          <Paragraph size='$2' fontWeight='bold'>)</Paragraph>
          <XStack pb='$5' mb='$2' mr={circularAccountsSheet ? '$5' : '$10'}><CornerRightUp size='$4' /></XStack>
        </XStack>
      </ZStack>
      : undefined}
  </AnimatePresence>;
}
