import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack, Text, Heading, Label, Switch, SizeTokens, Dialog } from '@jonline/ui'
import { ChevronDown, ChevronUp, Plus, Delete, X as XIcon, User as UserIcon, Settings as SettingsIcon, FileWarning, AlertTriangle } from '@tamagui/lucide-icons'
import store, { resetCredentialedData, resetAllData, RootState, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState, useReducer } from 'react'
import { useLink } from 'solito/link'
// import { clearAlerts as clearServerAlerts, upsertServer, selectAllServers } from "../../store/modules/servers";
// import { clearAlerts as clearAccountAlerts, createAccount, login, selectAllAccounts } from "../../store/modules/accounts";
import { FlatList, View } from 'react-native';
import { setAllowServerSelection, setSeparateAccountsByServer, setShowIntro } from 'app/store/modules/local_app';
import { selectAccountTotal } from 'app/store/modules/accounts';
import { selectServerTotal } from 'app/store/modules/servers';


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

  function toggleRow(name: string, value:boolean, setter: (value: boolean) => any) {
    return <XStack space='$3'>
      <Label f={1}>{name}</Label>
      <Switch size="$5" style={{ marginLeft: 'auto', marginRight: 'auto' }}
        defaultChecked={value}
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
              <Heading style={{ flex: 1 }}>Settings</Heading>
              {toggleRow('Show Intro', app.showIntro, setShowIntro)}
              {toggleRow('Allow Server Selection', app.allowServerSelection, setAllowServerSelection)}
              {toggleRow('Group Accounts by Server', app.separateAccountsByServer, setSeparateAccountsByServer)}

              <XStack>
                <Button f={1} icon={XIcon} onPress={resetCredentialedData}>
                  Reset/Refresh Credentialed Data (Posts etc)
                </Button>
              </XStack>
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
