import { Button, Dialog, Heading, Label, Paragraph, Sheet, SizeTokens, Slider, Switch, XStack, YStack } from '@jonline/ui';
import { AlertTriangle, ChevronDown, Settings as SettingsIcon, X as XIcon } from '@tamagui/lucide-icons';
import { resetAllData, resetCredentialedData, RootState, selectAccountTotal, selectServerTotal, setAllowServerSelection, setAutoRefreshDiscussions, setDiscussionRefreshIntervalSeconds, setSeparateAccountsByServer, setShowBetaNavigation, setShowIntro, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useState } from 'react';


export type SettingsSheetProps = {
  size?: SizeTokens;
  showIcon?: boolean;
  circular?: boolean;
}

export function SettingsSheet({ size = '$3' }: SettingsSheetProps) {
  // const [_, forceUpdate] = useReducer((x) => x + 1, 0);
  const forceUpdate = React.useReducer(() => ({}), {})[1] as () => void

  const [open, setOpen] = useState(false)
  const [position, setPosition] = useState(0)
  const dispatch = useTypedDispatch();
  const app = useTypedSelector((state: RootState) => state.app);
  const accountCount = useTypedSelector((state: RootState) => selectAccountTotal(state.accounts));
  const serverCount = useTypedSelector((state: RootState) => selectServerTotal(state.servers));
  // const forceUpdate: () => void = React.useState({})[1].bind(null, {})  // see NOTE below

  function doResetAllData() {
    resetAllData();
    setTimeout(forceUpdate, 2000);
  }

  function toggleRow(name: string, value: boolean, setter: (value: boolean) => any, disabled: boolean = false) {
    return <XStack space='$3' o={disabled ? 0.5 : 1}>
      <Label f={1}>{name}</Label>
      <Switch size="$5" style={{ marginLeft: 'auto', marginRight: 'auto' }}
        defaultChecked={value}
        {...{ disabled }}
        onCheckedChange={(checked) => dispatch(setter(checked))}>
        <Switch.Thumb animation="quick" />
      </Switch>
    </XStack>;
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
        snapPoints={[85]}
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
            <YStack maxWidth={800} width='100%' alignSelf='center' space='$3'>
              <Heading>Settings</Heading>
              {toggleRow('Show Intro on Homepage', app.showIntro, setShowIntro)}
              {toggleRow('Auto-Refresh Discussion Chat', app.autoRefreshDiscussions, setAutoRefreshDiscussions)}
              <Paragraph size='$1' mb='$1' ta='right' opacity={app.autoRefreshDiscussions ? 1 : 0.5}>Only supported in Chat Mode.</Paragraph>

              <XStack opacity={app.autoRefreshDiscussions ? 1 : 0.5}>
                <Slider size="$4" f={1} marginVertical='auto'
                  disabled={!app.autoRefreshDiscussions}
                  defaultValue={[app.discussionRefreshIntervalSeconds]}
                  onValueChange={(value) => dispatch(setDiscussionRefreshIntervalSeconds(value[0]!))}
                  min={5} max={30} step={1}>
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
              <Heading size='$3' mt='$3'>Multi-Server</Heading>
              {toggleRow('Allow Server Selection', app.allowServerSelection, setAllowServerSelection)}
              <Paragraph size='$1' mb='$1' ta='right' opacity={app.allowServerSelection ? 1 : 0.5}>Servers can be selected in the Accounts sheet.</Paragraph>
              {toggleRow('Group Accounts by Server', app.separateAccountsByServer, setSeparateAccountsByServer, !app.allowServerSelection)}
              <Heading size='$3' mt='$3'>Testing</Heading>
              {toggleRow('Show Beta Navigation', app.showBetaNavigation, setShowBetaNavigation)}

              {/* <XStack>
                <Button f={1} icon={XIcon} onPress={resetCredentialedData}>
                  Reset/Refresh Credentialed Data (Posts etc)
                </Button>
              </XStack> */}
              <XStack>
                <Dialog>
                  <Dialog.Trigger asChild>

                    <Button f={1} icon={XIcon} iconAfter={AlertTriangle} color='red'>
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
                            <Button theme="active" onClick={doResetAllData}>Reset all data</Button>
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
