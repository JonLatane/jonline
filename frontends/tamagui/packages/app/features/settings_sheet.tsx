import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack, Text, Heading, Label, Switch, SizeTokens } from '@jonline/ui'
import { ChevronDown, ChevronUp, Plus, Delete, X as XIcon, User as UserIcon, Settings as SettingsIcon } from '@tamagui/lucide-icons'
import store, { resetCredentialedData, RootState, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { useLink } from 'solito/link'
// import { clearAlerts as clearServerAlerts, upsertServer, selectAllServers } from "../../store/modules/servers";
// import { clearAlerts as clearAccountAlerts, createAccount, login, selectAllAccounts } from "../../store/modules/accounts";
import { FlatList, View } from 'react-native';
import { setShowIntro } from 'app/store/modules/local_app';


export type SettingsSheetProps = {
  size?: SizeTokens;
  showIcon?: boolean;
  circular?: boolean;
}

export function SettingsSheet({ size = '$3' }: SettingsSheetProps) {
  const [open, setOpen] = useState(false)
  const [position, setPosition] = useState(0)
  const dispatch = useTypedDispatch();
  const app = useTypedSelector((state: RootState) => state.app);

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
              <XStack space='$3'>
                <Label f={1}>Show Intro</Label>
                <Switch size="$5" style={{ marginLeft: 'auto', marginRight: 'auto' }} id="newServerSecure" 

                              defaultChecked={app.showIntro}
                              onCheckedChange={(checked) => dispatch(setShowIntro(checked))}>
                                        <Switch.Thumb animation="quick" />

                                </Switch>

              </XStack>
              <XStack>
                <Button f={1} icon={XIcon} onPress={resetCredentialedData}>
                  Reset Credentialed Data (Posts etc)
                </Button>
              </XStack>
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
