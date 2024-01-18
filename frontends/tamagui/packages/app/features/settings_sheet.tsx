import { Button, Dialog, Heading, Paragraph, Sheet, SizeTokens, Slider, XStack, YStack } from '@jonline/ui';
import { AlertTriangle, ChevronDown, Settings as SettingsIcon, X as XIcon } from '@tamagui/lucide-icons';
import { useAppDispatch } from 'app/hooks';
import { RootState, resetAllData, selectAccountTotal, selectServerTotal, setAllowServerSelection, setAutoHideNavigation, setAutoRefreshDiscussions, setBrowseRsvpsFromPreviews, setDiscussionRefreshIntervalSeconds, setInlineFeatureNavigation, setSeparateAccountsByServer, setShowUserIds, setShrinkFeatureNavigation, useRootSelector, useServerTheme } from 'app/store';
import React, { useState } from 'react';
import { ToggleRow } from '../components/toggle_row';
import { FeaturesNavigation } from './navigation/features_navigation';


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
              {/* {toggleRow('Show Intro on Homepage', app.showIntro, setShowIntro)} */}
              <Heading size='$5' mt='$3'>Discussions and Chat</Heading>
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

              <Heading size='$5' mt='$5'>Navigation</Heading>
              <ToggleRow name='Auto-Hide Navigation'
                description='Automatically hide navigation when scrolling down. For short (landscape phone) screens, this is automatically enabled.'
                value={app.autoHideNavigation}
                setter={(v) => setAutoHideNavigation(v)} autoDispatch />
              <XStack flexWrap='wrap' space='$3' ai='center' mt='$2'>
                <Heading size='$4'>Feature Navigation</Heading>
                <Paragraph o={0.5} size='$1'>(Posts, Events, People, Latest, Media, etc.)</Paragraph>
              </XStack>
              <YStack w='100%' backgroundColor={primaryColor} borderRadius='$3'>
                <XStack mx='auto' py='$1'>
                  <FeaturesNavigation disabled />
                </XStack>
              </YStack>
              <ToggleRow name='Auto Feature Navigation'
                description='Automatically enable/disable Inline Feature Navigation based on screen size.'
                value={app.inlineFeatureNavigation === undefined}
                setter={(v) => setInlineFeatureNavigation(v ? undefined : false)} autoDispatch />
              <ToggleRow name='Inline Feature Navigation' value={app.inlineFeatureNavigation}
                description='Show features in a horizontal row at the top of the screen.'
                disabled={app.inlineFeatureNavigation === undefined}
                setter={setInlineFeatureNavigation} autoDispatch />
              <ToggleRow name='Shrink Inline Feature Navigation'
                description='Shrink Feature Navigation when Inline Feature Navigation is enabled.'
                disabled={app.inlineFeatureNavigation === false}
                value={app.shrinkFeatureNavigation}
                setter={(v) => setShrinkFeatureNavigation(v)} autoDispatch />


              <Heading size='$5' mt='$5'>Accounts</Heading>
              <ToggleRow name='Group Accounts by Server' value={app.separateAccountsByServer} setter={setSeparateAccountsByServer} disabled={!app.allowServerSelection} autoDispatch />

              <Heading size='$5' mt='$5'>Testing</Heading>
              <ToggleRow name='Allow Server Selection'
                description={`For testing purposes. Allows you to use ${location.hostname}'s frontend as though it were the frontend of a different Jonline server, by selecting it from the Accounts Sheet (from where this Settings Sheet was opened). ${serverCount !== 1 ? ' Delete other servers to disable this setting.' : ''}`}
                // disabled={serverCount !== 1}
                value={app.allowServerSelection} setter={setAllowServerSelection} autoDispatch />
              <Paragraph size='$1' mb='$1' ta='right' opacity={app.allowServerSelection ? 1 : 0.5}>Servers can be selected in the Accounts sheet.</Paragraph>
              {/* <Heading size='$3' mt='$3'>Colors (Testing)</Heading>
              <ToggleRow name='Auto Dark Mode' value={app.darkModeAuto} setter={setDarkModeAuto} autoDispatch />
              <ToggleRow name='Dark Mode' value={app.darkMode} setter={setDarkMode} disabled={app.darkModeAuto} autoDispatch /> */}
              <Heading size='$5' mt='$5'>Development</Heading>
              <ToggleRow name='Browse RSVPs from Event Previews' value={app.browseRsvpsFromPreviews} setter={setBrowseRsvpsFromPreviews} autoDispatch />
              <ToggleRow name='Show User IDs' value={app.showUserIds} setter={setShowUserIds} autoDispatch />

              {/* <ToggleRow name='Show (WIP) Extended Navigation' value={app.showBetaNavigation} setter={setShowBetaNavigation} autoDispatch /> */}

              {/* <XStack>
                <Button f={1} icon={XIcon} onPress={resetCredentialedData}>
                  Reset/Refresh Credentialed Data (Posts etc)
                </Button>
              </XStack> */}
              <XStack>
                <Dialog>
                  <Dialog.Trigger asChild>

                    <Button f={1} icon={XIcon} iconAfter={AlertTriangle} color='red' mt='$5' mb='$3'>
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
      </Sheet>
    </>
  )
}

