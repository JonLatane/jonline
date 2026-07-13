import { AnimatePresence, Button, ButtonProps, Heading, Paragraph, XStack, YStack, ZStack, standardAnimation, useForceUpdate, useMedia } from "@jonline/ui";
import { CornerRightUp, HelpCircle, MoveUp } from '@tamagui/lucide-icons';
import { DarkModeToggle, doesPlatformPreferDarkMode } from "app/components/dark_mode_toggle";
import { useCurrentAccount, useAppDispatch, useLocalConfiguration } from "app/hooks";
import { serverID, setShowHelp, useServerTheme } from "app/store";
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
    // window.scrollTo({ top: 0, behavior: 'smooth' });
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
  const account = useCurrentAccount();
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
  const { server, primaryColor, primaryAnchorColor, navColor, navTextColor } = useServerTheme();

  const circularAccountsSheet = !mediaQuery.gtSm;
  const accountSheetMarginRight = circularAccountsSheet ? (account?.user?.avatar ? '$5' : '$3') : '$10';

  const stackGroupsBelow = true;

  const height = stackGroupsBelow ? '$8' : '$3';
  const measuredHomeButtonWidth = document.querySelector('#home-button')?.clientWidth ?? 0;
  const homeButtonWidth = Math.max(0, measuredHomeButtonWidth);

  const measuredGroupsButtonWidth = document.querySelector('#main-groups-button')?.clientWidth ?? 0;
  const groupsButtonWidth = Math.max(0, measuredGroupsButtonWidth);

  const gotIt = () => {
    if (nextPhase()) {
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
        setShowPhase1(false);
        setShowPhase2(true);
        return true;
      }
    }
    return false;
  }

  const isInDarkMode = darkModeAuto ? doesPlatformPreferDarkMode() : darkMode;
  return <AnimatePresence>
    {showHelp && false
      ? <ZStack w='100%' h={height} animation='standard' {...standardAnimation} mt='$3' pt='$2'>
        <XStack w='100%' ai='center' gap='$2' animation='standard' o={hidingStarted ? 0 : showPhase1 ? 1 : 0}>
          <YStack gap='$1' ai='center' jc='center' ac='center' ml={homeButtonWidth + ((groupsButtonWidth - 20) / 2) - 5} >
            <XStack ml='$1'><MoveUp size='$5' opacity={multiphase && showPhase2 ? 0.25 : 1} /></XStack>
            <Paragraph mt='$1' size='$2' fontWeight='bold' transform={[{ translateX: -12 }]}>Groups</Paragraph>
          </YStack>
          <YStack gap='$1' ai='center' ml={-20 + (groupsButtonWidth - 20) / 2}>
            <MoveUp size='$5' opacity={!mediaQuery.gtXxs && showPhase2 ? 0.25 : 1} />
            <Paragraph mt='$1' size='$2' fontWeight='bold' transform={[{ translateX: 37 }]}>Features/Sections</Paragraph>
          </YStack>
        </XStack>
        <XStack w='100%' ai='center' gap='$2' mt={-4}>
          <YStack my='auto' ai='center' gap='$2' mt='$4'>
            <Button ml='$3' {...themedButtonBackground(navColor, navTextColor)} size='$3' py='$1' px='$2' onPress={gotIt}>
              <Heading size='$1' color={navTextColor}>
                {hidingStarted ? 'Okay' : 'Got it!'}
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
