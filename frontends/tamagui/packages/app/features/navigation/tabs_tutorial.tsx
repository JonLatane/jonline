import { AnimatePresence, Button, ButtonProps, Heading, Paragraph, Tooltip, XStack, YStack, ZStack, standardAnimation, useForceUpdate, useMedia } from "@jonline/ui";
import { CornerRightUp, HelpCircle, MoveUp } from '@tamagui/lucide-icons';
import { DarkModeToggle, doesPlatformPreferDarkMode } from "app/components/dark_mode_toggle";
import { useComponentKey, useAccount, useAccountOrServer, useAppDispatch, useLocalConfiguration } from "app/hooks";
import { setShowHelp, useServerTheme } from "app/store";
import { themedButtonBackground } from "app/utils/themed_button_background";
import moment, { Moment } from "moment";
import { useEffect, useState } from "react";
import { GestureResponderEvent } from "react-native";

// let reallyHideHelp = false;
let lastHideTime: Moment | undefined = undefined;
export function TutorialToggle(props: ButtonProps) {
  const { onPress: parentOnPress, ...rest } = props;
  const dispatch = useAppDispatch();
  const onPress = (event: GestureResponderEvent) => {
    dispatch(setShowHelp(true));
    lastHideTime = undefined;
    parentOnPress?.(event);
    window.scrollTo({ top: 0, behavior: 'smooth' });
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
  const account = useAccount();
  const [hidingStarted, setHidingStarted] = useState(undefined as Moment | undefined);

  const startHidingHelp = () => {
    lastHideTime = moment();
    setHidingStarted(lastHideTime);
  }
  useEffect(() => {
    setHidingStarted(undefined);
    if (showHelp) {
      setTimeout(startHidingHelp, 15000);
    }
  }, [showHelp]);
  useEffect(() => {
    if (hidingStarted) {
      setTimeout(() => {
        if (hidingStarted && hidingStarted === lastHideTime) {
          dispatch(setShowHelp(false))
        }
      }, 5000);
    }
  }, [hidingStarted]);
  const { primaryColor, primaryAnchorColor, navColor, navTextColor } = useServerTheme();

  const circularAccountsSheet = !mediaQuery.gtSm;
  const accountSheetMarginRight = circularAccountsSheet ? (account?.user?.avatar ? '$5' : '$3') : '$10';

  const stackGroupsBelow = true;

  const height = stackGroupsBelow ? '$8' : '$3';
  const measuredHomeButtonWidth = document.querySelector('.home-button')?.clientWidth ?? 0;
  const homeButtonWidth = measuredHomeButtonWidth > 0 ? measuredHomeButtonWidth : 0;

  const measuredGroupsButtonWidth = document.querySelector('.main-groups-button')?.clientWidth ?? 0;
  const groupsButtonWidth = measuredGroupsButtonWidth > 0 ? measuredGroupsButtonWidth : 0;

  const gotIt = () => {
    console.log('got it')
    if (nextPhase()) {
      console.log('moved to next phase, skipping hiding')
    } else if (!hidingStarted) {
      startHidingHelp();
    } else {
      dispatch(setShowHelp(false));
    }
  }


  const { darkMode, darkModeAuto } = useLocalConfiguration();
  const multiphase = !mediaQuery.gtXxxs;
  const [showPhase1, setShowPhase1] = useState(true);
  const [showPhase2, setShowPhase2] = useState(false);
  useEffect(() => {
    if (multiphase) {
      setShowPhase1(true);
      setShowPhase2(false);
    } else {
      // Display all phases
      setShowPhase1(true);
      setShowPhase2(true);
    }
  }, [multiphase, showHelp]);
  function nextPhase(): boolean {
    if (multiphase) {
      if (showPhase1) {
        console.log('moving to phase 2')
        setShowPhase1(false);
        setShowPhase2(true);
        return true;
      }
    }
    console.log('no phase shift')
    return false;
  }

  const isInDarkMode = darkModeAuto ? doesPlatformPreferDarkMode() : darkMode;
  return <AnimatePresence>
    {showHelp
      ? <ZStack w='100%' h={height} animation='standard' {...standardAnimation} mt='$3' pt='$2'>
        <XStack w='100%' ai='center' space='$2' animation='standard' o={hidingStarted ? 0 : showPhase1 ? 1 : 0}>
          <YStack space='$1' ai='center' jc='center' ac='center' ml={homeButtonWidth + ((groupsButtonWidth - 20) / 2) - 5} >
            <XStack ml='$1'><MoveUp size='$5' opacity={multiphase && showPhase2 ? 0.25 : 1} /></XStack>
            <Paragraph mt='$1' size='$2' fontWeight='bold' transform={[{ translateX: -12 }]}>Groups</Paragraph>
          </YStack>
          <YStack space='$1' ai='center' ml={-20 + (groupsButtonWidth - 20) / 2}>
            <MoveUp size='$5' opacity={!mediaQuery.gtXxs && showPhase2 ? 0.25 : 1} />
            <Paragraph mt='$1' size='$2' fontWeight='bold' transform={[{ translateX: 37 }]}>Features/Sections</Paragraph>
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
          <ZStack h='100%' f={1} animation='standard' o={showPhase2 || hidingStarted ? 1 : 0}>
            <Paragraph my='auto' size='$2' textAlign="right" fontWeight='bold' o={hidingStarted ? 1 : 0}>
              View this again later
            </Paragraph>
            <Paragraph my='auto' size='$2' textAlign="right" fontWeight='bold' animation='standard' o={showPhase2 && !hidingStarted ? 1 : 0}>
              Accounts and Settings
            </Paragraph>
          </ZStack>
          <Paragraph size='$2' fontWeight='bold' o={showPhase2 || hidingStarted ? 1 : 0}>(</Paragraph>
          <XStack mb='$1' opacity={hidingStarted ? 1 : 0.8} animation='standard' o={showPhase2 || hidingStarted ? 1 : 0}>
            {hidingStarted
              ? <TutorialToggle onPress={() => setHidingStarted(undefined)} />
              : <DarkModeToggle />}
          </XStack>
          <Paragraph size='$2' fontWeight='bold' o={showPhase2 || hidingStarted ? 1 : 0}>)</Paragraph>
          <XStack pb='$5' mb='$2' mr={accountSheetMarginRight} o={showPhase2 || hidingStarted ? 1 : 0}><CornerRightUp size='$4' /></XStack>
        </XStack>
      </ZStack>
      : undefined}
  </AnimatePresence>;
}
