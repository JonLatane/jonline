import { Event } from '@jonline/api';
import { Anchor, AnimatePresence, Button, Checkbox, CheckboxProps, DateTimePicker, Dialog, Heading, Label, Paragraph, RadioGroup, Sheet, SizeTokens, Slider, Switch, XStack, YStack, standardAnimation, useMedia } from '@jonline/ui';
import { AlertTriangle, Check, ChevronLeft, Router, Settings as SettingsIcon, X as XIcon } from '@tamagui/lucide-icons';
import { useAppDispatch, useAppSelector, useComponentKey } from 'app/hooks';
import { CalendarImplementation, resetAllData, selectAccountTotal, selectServer, selectServerTotal, serverIDHost, setAllowServerSelection, setAlwaysShowHideButton, setAutoHideNavigation, setAutoRefreshDiscussions, setBrowseRsvpsFromPreviews, setCalendarImplementation, setDateTimeRenderer, setDiscussionRefreshIntervalSeconds, setEventPagesOnHome, setFancyPostBackgrounds, setImagePostBackgrounds, setInlineFeatureNavigation, setShowUserIds, setShrinkFeatureNavigation, useServerTheme } from 'app/store';
import moment from 'moment';
import React, { useCallback, useState } from 'react';
import { ToggleRow } from '../components/toggle_row';
import { federatedEntity } from '../store/federation';
import { EventsFullCalendar } from './event/events_full_calendar';
import { FeaturesNavigation, useInlineFeatureNavigation } from './navigation/features_navigation';


export type SettingsSheetProps = {
  size?: SizeTokens;
  showIcon?: boolean;
  circular?: boolean;
}

export function SettingsSheet({ size = '$3' }: SettingsSheetProps) {
  const mediaQuery = useMedia();
  // const [_, forceUpdate] = useReducer((x) => x + 1, 0);
  const forceUpdate = React.useReducer(() => ({}), {})[1] as () => void
  const { primaryColor, primaryAnchorColor } = useServerTheme();

  const [open, setOpen] = useState(false)
  const [position, setPosition] = useState(0)
  const dispatch = useAppDispatch();
  const app = useAppSelector(state => state.app);
  const accountCount = useAppSelector(state => selectAccountTotal(state.accounts));
  const serverCount = useAppSelector(state => selectServerTotal(state.servers));

  const currentServerIDHost = useAppSelector(state =>
    state.servers.currentServerId
      ? serverIDHost(state.servers.currentServerId)
      : undefined
  );
  const currentServerMatchesLocationHostname = currentServerIDHost === location.hostname;
  const currentHostServer = useAppSelector(state => state.servers.entities[
    state.servers.ids.find(sid => serverIDHost(sid as string) === location.hostname) ?? 'no-server-has-this-id'
  ]);

  const doResetAllData = useCallback(() => {
    resetAllData();
    setTimeout(forceUpdate, 2000);
  }, []);

  const { shrinkNavigation, inlineNavigation } = useInlineFeatureNavigation();

  return (
    <>
      <Button
        size={size}
        icon={SettingsIcon}
        circular
        onPress={() => setOpen((x) => !x)}
      />
      <Sheet
        zIndex={500001}
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
          <XStack w='100%' ai='center' gap='$2' px='$3' pb='$2'>
            <Button
              // alignSelf='center'
              size="$3"
              circular
              icon={ChevronLeft}
              onPress={() => {
                setOpen(false)
              }}
            />
            <Heading>Settings</Heading>
          </XStack>
          <Sheet.ScrollView p="$4" space>
            <YStack maxWidth={800} width='100%' alignSelf='center' gap='$1'>

              <Heading size='$5' mt='$5'>Navigation</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Always Show Hide Button'
                  description={<>
                    <Paragraph o={app.alwaysShowHideButton ? 0.5 : 0.25} size='$1'>Always show a button to hide navigation (so long as the Pinned Server selector is visible (i.e. not on singular Event, Post or Profile pages, but on listing pages).</Paragraph>
                    <Paragraph o={!mediaQuery.gtXShort ? 0.5 : 0.25} size='$1'>For very short (landscape phone) screens, this is force-enabled.</Paragraph>
                  </>}
                  // 'Always show a button to hide navigation (so long as the Pinned Server selector is visible (i.e. not on singular Event, Post or Profile pages, but on listing pages).'
                  value={app.alwaysShowHideButton}
                  setter={setAlwaysShowHideButton} autoDispatch />
                <ToggleRow name='Auto-Hide Navigation'
                  description={<>
                    <Paragraph o={app.autoHideNavigation ? 0.5 : 0.25} size='$1'>Automatically hide navigation when scrolling down.</Paragraph>
                    <Paragraph o={!mediaQuery.gtXShort ? 0.5 : 0.25} size='$1'>For very short (landscape phone) screens, this is force-enabled.</Paragraph>
                  </>}
                  value={app.autoHideNavigation}
                  setter={setAutoHideNavigation} autoDispatch />
              </YStack>
              <XStack flexWrap='wrap' gap='$3' ai='center' mt='$2'>
                <Heading size='$4'>Feature Navigation</Heading>
                <Paragraph o={0.5} size='$1'>(Posts, Events, People, Latest, Media, etc.)</Paragraph>
              </XStack>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
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
                    <Switch.Thumb animation='standard' backgroundColor='black' />
                  </Switch>
                  <Label htmlFor='nav-mode-toggle' my='auto' f={1}>
                    <YStack w='100%'>
                      <Paragraph size='$7' fontWeight='800' my='auto' ta='left' mx='$2' animation='standard' o={!inlineNavigation ? 0.5 : 1}>
                        Inline
                      </Paragraph>
                    </YStack>
                  </Label>
                </XStack>


                {/* <ToggleRow name='Auto Popover/Inline'
                  description='Use Popover or Inline based on screen size.'
                  value={app.inlineFeatureNavigation === undefined}
                  setter={(v) => setInlineFeatureNavigation(v ? undefined : true)} autoDispatch /> */}

                <XStack w='100%' ai='center'>
                  <XStack f={1} />
                  <CheckboxWithLabel name='auto-popover-inline' id='auto-popover-inline'
                    label='Auto Popover/Inline'
                    description='Automatically use Popover Navigation when the screen is narrow (i.e., on phone).'
                    checked={app.inlineFeatureNavigation === undefined}
                    defaultChecked={app.inlineFeatureNavigation === undefined}
                    value={app.inlineFeatureNavigation?.toString()}
                    onCheckedChange={(v) => {
                      dispatch(setInlineFeatureNavigation(v ? undefined : true));
                    }} />
                </XStack>



                {/* <ToggleRow name='Auto Shrink Inline Navigation'
                  description='Automatically Shrink Inline Navigation based on screen size.'
                  disabled={app.inlineFeatureNavigation === false}
                  value={app.shrinkFeatureNavigation === undefined}
                  setter={(v) => setShrinkFeatureNavigation(v ? undefined : true)} autoDispatch /> */}

                <AnimatePresence>
                  {app.inlineFeatureNavigation !== false
                    ? <YStack key='inline-nav-options' animation='standard' {...standardAnimation}>
                      <Heading size='$4' mt='$2'>Inline Navigation</Heading>
                      <ToggleRow name='Shrink Inline Navigation'
                        description='Shrink inactive icons in the Inline Navigation UI.'
                        // disabled={app.inlineFeatureNavigation === false}
                        value={app.shrinkFeatureNavigation}
                        setter={(v) => setShrinkFeatureNavigation(v)} autoDispatch />
                      <XStack w='100%' ai='center'>
                        <XStack f={1} />
                        <XStack f={1} >
                          <CheckboxWithLabel name='auto-shrink-inline' id='auto-popover-inline'
                            label='Auto Shrink Inline Navigation'
                            description='Automatically Shrink Inline Navigation when the screen is narrow.'
                            // disabled={app.inlineFeatureNavigation === false}
                            checked={app.shrinkFeatureNavigation === undefined}
                            defaultChecked={app.shrinkFeatureNavigation === undefined}
                            value={app.shrinkFeatureNavigation?.toString()}
                            onCheckedChange={(v) => {
                              dispatch(setShrinkFeatureNavigation(v ? undefined : false));
                            }} />
                        </XStack>
                      </XStack>
                    </YStack>
                    : undefined}
                </AnimatePresence>
              </YStack>
              <Heading size='$5' mt='$3'>Home Screen</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Paginate Events on Home'
                  description='On the Home/Latest Screen (and Group Home/Latest screens), show pagination controls for Events (when not in Big Calendar mode).'
                  value={app.eventPagesOnHome} setter={setEventPagesOnHome} autoDispatch />
                {/* <ToggleRow name='Blur Backgrounds'
                  disabled={!app.imagePostBackgrounds}
                  description='Blurred background images. Even more memory and CPU intensive!'
                  value={app.fancyPostBackgrounds} setter={setFancyPostBackgrounds} autoDispatch /> */}

              </YStack>
              <Heading size='$5' mt='$3'>Post/Event/User Cards</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Enable Background Images'
                  description='Show background images on Posts, Events, and People. Turning this off may improve performance on much older devices.'
                  value={app.imagePostBackgrounds} setter={setImagePostBackgrounds} autoDispatch />
                <ToggleRow name='Blur Backgrounds'
                  disabled={!app.imagePostBackgrounds}
                  description='Blurred background images. Turning this off may improve performance on older devices.'
                  value={app.fancyPostBackgrounds} setter={setFancyPostBackgrounds} autoDispatch />

              </YStack>

              {/* {toggleRow('Show Intro on Homepage', app.showIntro, setShowIntro)} */}
              <Heading size='$5' mt='$3'>Discussions and Chat</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
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

              <Heading size='$5' mt='$3'>Calendar UI</Heading>
              <YStack gap='$1' w='100%' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <EventsFullCalendar weeklyOnly width='100%' disableSelection
                  events={[
                    federatedEntity(
                      Event.create({
                        post: {
                          title: 'Example Event'
                        },
                        instances: [
                          {
                            startsAt: moment().toISOString(),
                            endsAt: moment().add(1, 'hour').toISOString()
                          }
                        ]
                      }),
                      currentHostServer
                    )
                  ]} />
                <RadioGroup value={app.calendarImplementation ?? 'big-calendar'} onValueChange={v => dispatch(setCalendarImplementation(v as CalendarImplementation))}>
                  <RadioGroupItemWithLabel value="big-calendar"
                    label={<YStack my='$2' w='100%'>
                      <Paragraph size='$5' fontFamily='$mono'>react-big-calendar</Paragraph>
                      <Anchor target='_blank' href='https://github.com/jquense/react-big-calendar' color={primaryAnchorColor} size='$2'>https://github.com/jquense/react-big-calendar</Anchor>
                    </YStack>} />
                  <RadioGroupItemWithLabel value="fullcalendar"

                    label={<YStack my='$2' w='100%'>
                      <Paragraph size='$5'>Full Calendar</Paragraph>
                      <Anchor target='_blank' href='https://fullcalendar.io' color={primaryAnchorColor} size='$2'>https://fullcalendar.io</Anchor>
                    </YStack>} />
                  <RadioGroupItemWithLabel value="daypilot"
                    label={<YStack my='$2' w='100%'>
                      <Paragraph size='$5'>Daypilot Calendar</Paragraph>
                      <Anchor target='_blank' href='https://daypilot.org' color={primaryAnchorColor} size='$2'>https://daypilot.org</Anchor>
                      <Paragraph size='$2' maw='100%'>TESTING ONLY. Daypilot devs: heightSpec=Parent100Pct is not working as documented; this breaks scrolling for this calendar option.</Paragraph>
                    </YStack>}
                  />
                </RadioGroup>
              </YStack>

              <Heading size='$5' mt='$3'>DateTime Inputs</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <YStack ai='center' mx='center'>
                  <DateTimePicker value={moment(0).toISOString()} onChange={(v) => { }} />
                </YStack>

                <XStack my='$2'>
                  <Label htmlFor='date-type-toggle' my='auto' f={1}>
                    <YStack w='100%'>
                      <Paragraph size='$7' fontWeight='800' my='auto' ta='right' mx='$2' animation='standard'
                        o={app.dateTimeRenderer === 'native' ? 0.5 : 1}>
                        Custom
                      </Paragraph>
                      <Paragraph size='$1' my='auto' ta='right' mx='$2' animation='standard'
                        fontFamily='$mono'
                        o={app.dateTimeRenderer === 'native' ? 0.5 : 1}>
                        react-datetime-picker
                      </Paragraph>
                    </YStack>
                  </Label>
                  <Switch name='date-type-toggle' size="$5" margin='auto'
                    defaultChecked={app.dateTimeRenderer === 'native'}
                    checked={app.dateTimeRenderer === 'native'}
                    value={(app.dateTimeRenderer === 'native').toString()}
                    // disabled={app.inlineFeatureNavigation === undefined}
                    onCheckedChange={(checked) => dispatch(setDateTimeRenderer(checked ? 'native' : 'custom'))}>
                    <Switch.Thumb animation='standard' backgroundColor='black' />
                  </Switch>
                  <Label htmlFor='date-type-toggle' my='auto' f={1}>
                    <YStack w='100%'>
                      <Paragraph size='$7' fontWeight='800' my='auto' ta='left' mx='$2' animation='standard'
                        o={app.dateTimeRenderer !== 'native' ? 0.5 : 1}>
                        Native
                      </Paragraph>
                      <Paragraph size='$1' my='auto' mx='$2' animation='standard'
                        o={app.dateTimeRenderer !== 'native' ? 0.5 : 1}>
                        Safari/Chrome/Firefox/Edge-specific UI
                      </Paragraph>
                    </YStack>
                  </Label>
                </XStack>
              </YStack>

              {/* <Heading size='$5' mt='$5'>Accounts</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Group Accounts by Server' value={app.separateAccountsByServer} setter={setSeparateAccountsByServer} disabled={!app.allowServerSelection} autoDispatch />
              </YStack> */}

              <Heading size='$5' mt='$5'>Testing</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
                <ToggleRow name='Server Changing'
                  description={
                    <>
                      {!currentHostServer ?
                        <Paragraph size='$1'>
                          Create a server for {location.hostname} to disable this setting. It shouldn't be possible to see this message!
                        </Paragraph>
                        : undefined}
                      {!currentServerMatchesLocationHostname ?
                        <Paragraph size='$1'>
                          The server at {location.hostname} will be selected if Server Changing is disabled (currently, {currentServerIDHost} is selected).
                        </Paragraph>
                        : undefined}
                      <Paragraph size='$1' o={app.allowServerSelection ? 0.7 : 0.3}>
                        For testing purposes.
                        Allows you to use {location.hostname} as though you were browsing from a different Jonline server (i.e., with the same theme/default groups as {location.hostname === 'jonline.io' ? 'bullcity.social' : 'jonline.io'}).
                      </Paragraph>
                      <Paragraph size='$1' o={app.allowServerSelection ? 0.7 : 0.3}>
                        After enabling this toggle, from the Accounts Sheet (behind/above this Settings Sheet),{' '}
                        {!app.browsingServers ? <>first, browse servers by pressing <Router size='$1' />, then </> : undefined}
                        simply select a server from the Accounts Sheet (behind/above this Settings Sheet).
                      </Paragraph>
                    </>
                  }
                  disabled={!currentHostServer}
                  value={!currentServerMatchesLocationHostname || app.allowServerSelection}
                  setter={v => {
                    dispatch(setAllowServerSelection(v));
                    if (!v && !currentServerMatchesLocationHostname) {
                      dispatch(selectServer(currentHostServer));
                    }
                  }} />
                {/* <Paragraph size='$1' mt='$1' ta='right' opacity={app.allowServerSelection ? 1 : 0.5}>Servers can be selected in the Accounts sheet.</Paragraph> */}
                <Paragraph size='$1' mb='$1' ta='right' opacity={app.allowServerSelection ? 1 : 0.5} ai='center'>An alert triangle (<AlertTriangle size='$1' style={{ transform: 'scale(0.8) translateY(7px)' }} />) will appear in the UI when a different server is selected.</Paragraph>

                {/* <Heading size='$3' mt='$3'>Colors (Testing)</Heading>
              <ToggleRow name='Auto Dark Mode' value={app.darkModeAuto} setter={setDarkModeAuto} autoDispatch />
              <ToggleRow name='Dark Mode' value={app.darkMode} setter={setDarkMode} disabled={app.darkModeAuto} autoDispatch /> */}
              </YStack>
              <Heading size='$5' mt='$5'>Development</Heading>
              <YStack gap='$1' p='$2' backgroundColor='$backgroundFocus' borderRadius='$3' borderColor='$backgroundPress' borderWidth={1}>
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
                  <Dialog.Portal zIndex={20000000}>
                    <Dialog.Overlay
                      key="overlay"
                      animation='standard'
                      o={0.5}
                      enterStyle={{ o: 0 }}
                      exitStyle={{ o: 0 }}
                    />
                    <Dialog.Content
                      bordered
                      elevate
                      key="content"
                      animation={[
                        'standard',
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

                        <XStack gap="$3" jc="flex-end">
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

export function CheckboxWithLabel({
  label,
  description,
  // label = 'Accept terms and conditions',
  ...checkboxProps
}: CheckboxProps & { size?: SizeTokens; label: string; description?: string; }) {
  const mediaQuery = useMedia();
  const componentKey = useComponentKey('checkbox-with-label');
  const id = `checkbox-${componentKey}`
  return (

    // <XStack maw='100%'>
    <Label ml='auto' htmlFor={id}>
      <XStack ai="center" w={mediaQuery.gtXs ? 300 : 250} maw='100%' gap="$4" o={checkboxProps.disabled ? 0.5 : 1}>

        <YStack f={1}>
          <Paragraph size='$3'>
            {label}
          </Paragraph>
          {description
            ? <Paragraph size='$2' o={checkboxProps.checked ? 0.7 : 0.25}>
              {description}
            </Paragraph>
            : undefined}
        </YStack>

        <Checkbox {...checkboxProps} id={id} name={id} size={'$6'}>
          <Checkbox.Indicator>
            <Check />
          </Checkbox.Indicator>
        </Checkbox>
      </XStack>
    </Label>
    // </XStack>
  )
}


export function RadioGroupItemWithLabel(props: {
  size?: SizeTokens
  value: string
  label: string | JSX.Element
}) {
  const id = `radiogroup-${props.value}`
  return (
    <XStack width={300} alignItems="center" gap="$4">
      <RadioGroup.Item value={props.value} id={id} size={props.size}>
        <RadioGroup.Indicator />
      </RadioGroup.Item>

      <Label size={props.size} htmlFor={id}>
        {props.label}
      </Label>
    </XStack>
  )
}
