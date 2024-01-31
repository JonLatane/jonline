import { Button, Dialog, Heading, Label, Paragraph, Sheet, SizeTokens, Slider, Switch, View, XStack, YStack } from '@jonline/ui';
import { AlertTriangle, ChevronDown, Settings as SettingsIcon, X as XIcon } from '@tamagui/lucide-icons';
import { useAppDispatch } from 'app/hooks';
import { RootState, resetAllData, selectAccountTotal, selectServerTotal, setAllowServerSelection, setAutoHideNavigation, setAutoRefreshDiscussions, setBrowseRsvpsFromPreviews, setDiscussionRefreshIntervalSeconds, setFancyPostBackgrounds, setInlineFeatureNavigation, setSeparateAccountsByServer, setShowUserIds, setShrinkFeatureNavigation, useRootSelector, useServerTheme } from 'app/store';
import React, { useState } from 'react';
import { ToggleRow } from '../components/toggle_row';
import { FeaturesNavigation, useInlineFeatureNavigation } from './navigation/features_navigation';


export type SettingsSheetProps = {
  size?: SizeTokens;
  showIcon?: boolean;
  circular?: boolean;
}

export function SettingsSheet({ size = '$3' }: SettingsSheetProps) {
  // const [_, forceUpdate] = useReducer((x) => x + 1, 0);
  const forceUpdate = React.useReducer(() => ({}), {})[1] as () => void
  const { primaryColor } = useServerTheme();

  const [open, setOpen] = useState(false)
  const [position, setPosition] = useState(0)
  const dispatch = useAppDispatch();
  const app = useRootSelector((state: RootState) => state.app);
  const accountCount = useRootSelector((state: RootState) => selectAccountTotal(state.accounts));
  const serverCount = useRootSelector((state: RootState) => selectServerTotal(state.servers));

  function doResetAllData() {
    resetAllData();
    setTimeout(forceUpdate, 2000);
  }

  const { shrinkNavigation, inlineNavigation} = useInlineFeatureNavigation();

  return (
    <>
      <Button
        size={size}
        icon={SettingsIcon}
        circular
        onPress={() => setOpen((x) => !x)}
      />
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[81]}
        position={position}
        onPositionChange={setPosition}
        dismissOnSnapToBottom
      >
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />
          <Button
            alignSelf='center'
            size="$6"
            circular
            icon={ChevronDown}
            onPress={() => {
              setOpen(false)
            }}
          />
          <Sheet.ScrollView p="$4" space>
            <YStack maxWidth={800} width='100%' alignSelf='center' space='$1'>
              <Heading>Settings</Heading>

              <Heading size='$5' mt='$5'>Navigation</Heading>
              <YStack space='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Auto-Hide Navigation'
                  description='Automatically hide navigation when scrolling down. For short (landscape phone) screens, this is automatically enabled.'
                  value={app.autoHideNavigation}
                  setter={(v) => setAutoHideNavigation(v)} autoDispatch />
              </YStack>
              <XStack flexWrap='wrap' space='$3' ai='center' mt='$2'>
                <Heading size='$4'>Feature Navigation</Heading>
                <Paragraph o={0.5} size='$1'>(Posts, Events, People, Latest, Media, etc.)</Paragraph>
              </XStack>
              <YStack space='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <YStack w='100%' backgroundColor={primaryColor} borderRadius='$3'>
                  <XStack mx='auto' py='$1'>
                    <FeaturesNavigation disabled />
                  </XStack>
                </YStack>
                <XStack my='$2' o={app.inlineFeatureNavigation === undefined ? 0.5 : 1}>
                  <Label htmlFor='nav-mode-toggle' my='auto' f={1}>
                    <YStack w='100%'>
                      <Paragraph size='$7' fontWeight='800' my='auto' ta='right' mx='$2' animation='standard' o={inlineNavigation ? 0.5 : 1}>
                        Popover
                      </Paragraph>
                    </YStack>
                  </Label>
                  <Switch name='nav-mode-toggle' size="$5" margin='auto'
                    defaultChecked={app.inlineFeatureNavigation}
                    checked={inlineNavigation}
                    value={inlineNavigation.toString()}
                    disabled={app.inlineFeatureNavigation === undefined}
                    onCheckedChange={(checked) => dispatch(setInlineFeatureNavigation(checked))}>
                    <Switch.Thumb animation="quick" backgroundColor='black' />
                  </Switch>
                  <Label htmlFor='nav-mode-toggle' my='auto' f={1}>
                    <YStack w='100%'>
                      <Paragraph size='$7' fontWeight='800' my='auto' ta='left' mx='$2' animation='standard' o={!inlineNavigation ? 0.5 : 1}>
                        Inline
                      </Paragraph>
                    </YStack>
                  </Label>
                </XStack>
                <ToggleRow name='Auto Popover/Inline'
                  description='Choose Popover or Inline based on screen size.'
                  value={app.inlineFeatureNavigation === undefined}
                  setter={(v) => setInlineFeatureNavigation(v ? undefined : true)} autoDispatch />
                <Heading size='$4' mt='$2' o={app.inlineFeatureNavigation === false ? 0.5 : 1}>Inline Navigation</Heading>
                <ToggleRow name='Auto Shrink Inline Navigation'
                  description='Automatically Shrink Inline Navigation based on screen size.'
                  disabled={app.inlineFeatureNavigation === false}
                  value={app.shrinkFeatureNavigation === undefined}
                  setter={(v) => setShrinkFeatureNavigation(v ? undefined : true )} autoDispatch />
                <ToggleRow name='Shrink Inline Navigation'
                  description='Shrink inactive icons in the Inline Navigation UI.'
                  disabled={app.inlineFeatureNavigation === false}
                  value={app.shrinkFeatureNavigation}
                  setter={(v) => setShrinkFeatureNavigation(v)} autoDispatch />
              </YStack>
              <Heading size='$5' mt='$3'>Posts, Events, and People</Heading>
              <YStack space='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>

                <ToggleRow name='Fancy Backgrounds'
                  description='Add pretty blurred background images to the UI. Memory and CPU intensive; may lead to crashes. Runs fine on my M1 Max MacBook Pro, crashes my iPhone 12 Pro.'
                  value={app.fancyPostBackgrounds} setter={setFancyPostBackgrounds} autoDispatch />

              </YStack>

              {/* {toggleRow('Show Intro on Homepage', app.showIntro, setShowIntro)} */}
              <Heading size='$5' mt='$3'>Discussions and Chat</Heading>
              <YStack space='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Auto-Refresh Chat'
                  description='Automatically refresh the discussion chat every few seconds. Only supported in Chat Mode.'
                  value={app.autoRefreshDiscussions}
                  setter={setAutoRefreshDiscussions}
                  autoDispatch />

                <XStack opacity={app.autoRefreshDiscussions ? 1 : 0.5}>
                  <Slider size="$4" f={1} marginVertical='auto'
                    disabled={!app.autoRefreshDiscussions}
                    defaultValue={[app.discussionRefreshIntervalSeconds]}
                    onValueChange={(value) => dispatch(setDiscussionRefreshIntervalSeconds(value[0]!))}
                    min={3} max={30} step={1}>
                    <Slider.Track>
                      <Slider.TrackActive />
                    </Slider.Track>
                    <Slider.Thumb circular index={0} />
                  </Slider>
                  <YStack w={80} paddingHorizontal='$3'>
                    <Heading size='$1' marginHorizontal='auto'>Every</Heading>
                    <Heading size='$4' marginHorizontal='auto'>{app.discussionRefreshIntervalSeconds}s</Heading>
                    {/* <Heading size='$1'>seconds</Heading> */}
                  </YStack>
                </XStack>
              </YStack>

              <Heading size='$5' mt='$5'>Accounts</Heading>
              <YStack space='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Group Accounts by Server' value={app.separateAccountsByServer} setter={setSeparateAccountsByServer} disabled={!app.allowServerSelection} autoDispatch />
              </YStack>

              <Heading size='$5' mt='$5'>Testing</Heading>
              <YStack space='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Allow Server Selection'
                  description={`For testing purposes. Allows you to use ${location.hostname}'s frontend as though it were the frontend of a different Jonline server, by selecting it from the Accounts Sheet (from where this Settings Sheet was opened). ${serverCount !== 1 ? ' Delete other servers to disable this setting.' : ''}`}
                  // disabled={serverCount !== 1}
                  value={app.allowServerSelection} setter={setAllowServerSelection} autoDispatch />
                <Paragraph size='$1' mt='$1' ta='right' opacity={app.allowServerSelection ? 1 : 0.5}>Servers can be selected in the Accounts sheet.</Paragraph>
                <Paragraph size='$1' mb='$1' ta='right' opacity={app.allowServerSelection ? 1 : 0.5} ai='center'>An alert triangle (<AlertTriangle size='$1' style={{transform: 'scale(0.8) translateY(7px)'}} />) will appear in the UI when a different server is selected.</Paragraph>

                {/* <Heading size='$3' mt='$3'>Colors (Testing)</Heading>
              <ToggleRow name='Auto Dark Mode' value={app.darkModeAuto} setter={setDarkModeAuto} autoDispatch />
              <ToggleRow name='Dark Mode' value={app.darkMode} setter={setDarkMode} disabled={app.darkModeAuto} autoDispatch /> */}
              </YStack>
              <Heading size='$5' mt='$5'>Development</Heading>
              <YStack space='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Browse RSVPs from Event Previews' value={app.browseRsvpsFromPreviews} setter={setBrowseRsvpsFromPreviews} autoDispatch />
                <ToggleRow name='Show User IDs' value={app.showUserIds} setter={setShowUserIds} autoDispatch />

              </YStack>
              <XStack>
                <Dialog>
                  <Dialog.Trigger asChild>

                    <Button f={1} icon={XIcon} iconAfter={AlertTriangle} color='red' mt='$3' mb='$3'>
                      Reset ALL Local Data
                    </Button>
                    {/* <Button onClick={(e) => { e.stopPropagation(); }} icon={<Trash />} color="red" circular /> */}
                  </Dialog.Trigger>
                  <Dialog.Portal>
                    <Dialog.Overlay
                      key="overlay"
                      animation="quick"
                      o={0.5}
                      enterStyle={{ o: 0 }}
                      exitStyle={{ o: 0 }}
                    />
                    <Dialog.Content
                      bordered
                      elevate
                      key="content"
                      animation={[
                        'quick',
                        {
                          opacity: {
                            overshootClamping: true,
                          },
                        },
                      ]}
                      m='$3'
                      enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
                      exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
                      x={0}
                      scale={1}
                      opacity={1}
                      y={0}
                    >
                      <YStack space>
                        <Dialog.Title>Reset app data</Dialog.Title>
                        <Dialog.Description>
                          {/* <Paragraph> */}
                          Really remove all settings, {accountCount} account{accountCount == 1 ? '' : 's'} and {serverCount} server{serverCount == 1 ? '' : 's'}?
                          {/* </Paragraph> */}
                        </Dialog.Description>

                        <XStack space="$3" jc="flex-end">
                          <Dialog.Close asChild>
                            <Button>Cancel</Button>
                          </Dialog.Close>
                          {/* <Dialog.Action asChild onClick={doRemoveServer}> */}

                          <Dialog.Close asChild>
                            <Button theme="active" onPress={doResetAllData}>Reset all data</Button>
                          </Dialog.Close>
                          {/* </Dialog.Action> */}
                        </XStack>
                      </YStack>
                    </Dialog.Content>
                  </Dialog.Portal>
                </Dialog>
              </XStack>
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet >
    </>
  )
}

