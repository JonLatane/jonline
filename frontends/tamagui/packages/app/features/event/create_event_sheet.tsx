import { Event, EventListingType, Post, Visibility } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, Text, TextArea, XStack, YStack, useMedia } from '@jonline/ui';
import { ChevronDown, Settings } from '@tamagui/lucide-icons';
import { RootState, clearPostAlerts, createEvent, loadEventsPage, selectAllAccounts, selectAllServers, serverID, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { Platform, View } from 'react-native';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import moment from 'moment';
import { VisibilityPicker } from '../post/visibility_picker';
import EventCard from './event_card';

export type CreateEventSheetProps = {
  // primaryServer?: JonlineServer;
  // operation: string;
}

enum RenderType { Edit, FullPreview, ShortPreview }
const edit = (r: RenderType) => r == RenderType.Edit;
const fullPreview = (r: RenderType) => r == RenderType.FullPreview;
const shortPreview = (r: RenderType) => r == RenderType.ShortPreview;

// export enum LoginMethod {
//   Login = 'login',
//   CreateAccount = 'create_account',
// }
export function CreateEventSheet({ }: CreateEventSheetProps) {
  const media = useMedia();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const account = accountOrServer.account!;
  const [open, _setOpen] = useState(false);
  const [position, setPosition] = useState(0);

  const [renderType, setRenderType] = useState(RenderType.Edit);
  const [showSettings, setShowSettings] = useState(false);
  const [renderSheet, setRenderSheet] = useState(true);
  function setOpen(v: boolean) {
    if (v && !open && title.length == 0) {
      console.log(moment().format('YYYY-MM-DDTHH:mm'));
      setStartTime(moment().format('YYYY-MM-DDTHH:mm'));
      setEndTime(moment().add(1, 'hour').format('YYYY-MM-DDTHH:mm'));
    }
    if (v && !renderSheet) {
      setRenderSheet(true);
      setTimeout(() => _setOpen(true), 1);
    } else {
      _setOpen(v);
    }
  }

  // Form fields
  const [visibility, setVisibility] = useState(Visibility.GLOBAL_PUBLIC);
  const [title, setTitle] = useState('');
  const [link, setLink] = useState('');
  const [content, setContent] = useState('');
  // const [instances, setInstances] = useState<EventInstance[]>([]);
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');

  const previewPost = Post.create({ title, link, content, author: { userId: account?.user.id, username: account?.user.username } })
  const previewEvent = Event.create({
    post: previewPost,
    instances: [{ startsAt: moment(startTime).utc().toISOString(), endsAt: moment(endTime).utc().toISOString() }],
  });
  const textAreaRef = React.useRef() as React.MutableRefObject<HTMLElement | View>;

  const [posting, setPosting] = useState(false);

  const app = useTypedSelector((state: RootState) => state.app);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const browsingOn = Platform.OS == 'web' ? window.location.hostname : undefined

  const { server, primaryColor, primaryTextColor, navColor, navTextColor, textColor } = useServerTheme();
  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

  const eventsState = useTypedSelector((state: RootState) => state.events);
  const accountsLoading = accountsState.status == 'loading';
  const valid = title.length > 0 && moment(endTime).isAfter(moment(startTime));
  const endDateInvalid = !moment(endTime).isAfter(moment(startTime))

  const showEditor = edit(renderType);
  const showFullPreview = fullPreview(renderType);
  const showShortPreview = shortPreview(renderType);

  useEffect(() => {
    if (open) {
      setRenderSheet(true);
    } else if (!open && renderSheet) {
      // setTimeout(() => {
      //   if (!open && renderSheet) {
      //     setRenderSheet(false);
      //   }
      // },1500)
    }
  }, [open]);

  function doCreate() {

    // const newPost: Post = { title, link, content };

    dispatch(createEvent({ ...previewEvent, ...accountOrServer })).then((action) => {
      if (action.type == createEvent.fulfilled.type) {
        dispatch(loadEventsPage({ ...accountOrServer, listingType: EventListingType.PUBLIC_EVENTS, page: 0 }));
        setOpen(false);
        setTitle('');
        setContent('');
        setLink('');
        setStartTime('');
        setEndTime('');
        setRenderType(RenderType.Edit);
        window.scrollTo({ top: 0, behavior: 'smooth' });
        dispatch(clearPostAlerts!());
      }
    });
  }
  const disableInputs = ['creating', 'created'].includes(eventsState.createStatus ?? '');
  const disablePreview = disableInputs || !valid;
  const disableCreate = disableInputs || !valid;
  return (
    <>
      <Button backgroundColor={primaryColor} color={primaryTextColor} f={1}
        disabled={serversState.server === undefined}
        onPress={() => setOpen(!open)}>
        <Heading size='$2' color={primaryTextColor}>Create Event</Heading>
      </Button>
      {open || renderSheet
        ? <Sheet
          modal
          open={open}
          onOpenChange={setOpen}
          // snapPoints={[80]}
          snapPoints={[90]} dismissOnSnapToBottom
          position={position}
          onPositionChange={setPosition}
        // dismissOnSnapToBottom
        >
          <Sheet.Overlay backgroundColor='$colorTranslucent' />
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
            <XStack marginHorizontal='$5' mb='$2'>
              <Heading marginVertical='auto' f={1} size='$7'>Create Event</Heading>
              <Button backgroundColor={showSettings ? navColor : undefined} onPress={() => setShowSettings(!showSettings)} circular mr='$2'>
                <Settings color={showSettings ? navTextColor : textColor} />
              </Button>
              <Button backgroundColor={primaryColor} disabled={disableCreate} opacity={disableCreate ? 0.5 : 1} onPress={doCreate}>
                <Heading size='$1' color={primaryTextColor}>Create</Heading>
              </Button>
            </XStack>
            {eventsState.createStatus == "errored" && eventsState.errorMessage ?
              <Heading size='$1' color='red' p='$2' ac='center' jc='center' ta='center'>{eventsState.errorMessage}</Heading> : undefined}
            {showSettings
              ? <XStack ac='center' jc='center' marginHorizontal='$5' animation="bouncy"
                p='$3'
                opacity={1}
                scale={1}
                y={0}
                enterStyle={{ y: -50, opacity: 0, }}
                exitStyle={{ opacity: 0, }}>
                {/* <Heading marginVertical='auto' f={1} size='$2'>Visibility</Heading> */}
                <VisibilityPicker label='Event Visibility' visibility={visibility} onChange={setVisibility}
                  visibilityDescription={(v) => {
                    switch (v) {
                      case Visibility.PRIVATE:
                        return 'Only you can see this event.';
                      case Visibility.LIMITED:
                        return 'Only your followers and groups you choose can see this event.';
                      case Visibility.SERVER_PUBLIC:
                        return 'Anyone on this server can see this event.';
                      case Visibility.GLOBAL_PUBLIC:
                        return 'Anyone on the internet can see this event.';
                      default:
                        return 'Unknown';
                    }
                  }} />
              </XStack> : undefined}
            <XStack marginHorizontal='auto' marginVertical='$3'>
              <Button backgroundColor={showEditor ? navColor : undefined}
                transparent={!showEditor}
                borderTopRightRadius={0} borderBottomRightRadius={0}
                onPress={() => setRenderType(RenderType.Edit)}>
                <Heading size='$4' color={showEditor ? navTextColor : textColor}>Edit</Heading>
              </Button>
              <Button backgroundColor={showFullPreview ? navColor : undefined}
                transparent={!showFullPreview}
                borderRadius={0}
                disabled={disablePreview}
                opacity={disablePreview ? 0.5 : 1}
                // borderTopRightRadius={0} borderBottomRightRadius={0}
                onPress={() => setRenderType(RenderType.FullPreview)}>
                <Heading size='$4' color={showFullPreview ? navTextColor : textColor}>Preview</Heading>
              </Button>
              <Button backgroundColor={showShortPreview ? navColor : undefined}
                transparent={!showShortPreview}
                borderTopLeftRadius={0} borderBottomLeftRadius={0}
                disabled={disablePreview}
                opacity={disablePreview ? 0.5 : 1}
                onPress={() => setRenderType(RenderType.ShortPreview)}>
                <Heading size='$4' color={showShortPreview ? navTextColor : textColor}>Feed Preview</Heading>
              </Button>
            </XStack>
            <Sheet.ScrollView>
              <XStack space="$2" maw={600} w='100%' als='center' paddingHorizontal="$5">
                {showEditor
                  ? <YStack space="$2" w='100%'>
                    {/* <Heading size="$6">{server?.host}/</Heading> */}
                    <Input textContentType="name" placeholder="Event Title"
                      disabled={disableInputs} opacity={disableInputs ? 0.5 : 1}
                      autoCapitalize='words'
                      value={title}
                      onChange={(data) => { setTitle(data.nativeEvent.text) }} />
                    <XStack marginHorizontal='$2'>
                      <Heading size='$2' f={1} marginVertical='auto'>Start Time</Heading>
                      <Text fontSize='$2' fontFamily='$body'>
                        <input type='datetime-local' value={startTime} onChange={(v) => setStartTime(v.target.value)} style={{ padding: 10 }} />
                      </Text>
                    </XStack>
                    <XStack marginHorizontal='$2'>
                      <YStack marginVertical='auto' f={1}>
                        <Heading size='$2' marginVertical='auto'>End Time</Heading>
                        {endDateInvalid ? <Paragraph size='$2' f={1} marginVertical='auto'>Must be after Start Time</Paragraph> : undefined}
                      </YStack>
                      <Text fontSize='$2' fontFamily='$body'>
                        <input type='datetime-local' value={endTime} min={startTime} onChange={(v) => setEndTime(v.target.value)} style={{ padding: 10 }} />
                      </Text>
                    </XStack>
                    <Input textContentType="URL" autoCorrect={false} placeholder="Optional Link"
                      disabled={disableInputs} opacity={disableInputs ? 0.5 : 1}
                      // autoCapitalize='words'
                      value={link}
                      onChange={(data) => { setLink(data.nativeEvent.text) }} />

                    <TextArea f={1} h='$19' value={content} ref={textAreaRef}
                      disabled={posting} opacity={posting ? 0.5 : 1}
                      onChangeText={t => setContent(t)}
                      // onFocus={() => { _replyTextFocused = true; /*window.scrollTo({ top: window.scrollY - _viewportHeight/2, behavior: 'smooth' });*/ }}
                      // onBlur={() => _replyTextFocused = false}
                      placeholder={`Optional Content. Markdown is supported.`} />
                    {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                    {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}
                  </YStack>
                  : undefined}
                {showFullPreview
                  ? <EventCard event={previewEvent} />
                  : undefined}
                {showShortPreview
                  ? <EventCard event={previewEvent} isPreview />
                  : undefined}
              </XStack>
            </Sheet.ScrollView>
          </Sheet.Frame>
        </Sheet>
        : undefined}
    </>
  )
}
