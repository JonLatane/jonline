import { accountOrServerId, deleteEvent, deletePost, getCredentialClient, loadMedia, loadUser, RootState, selectMediaById, selectUserById, updateEvent, updatePost, useAccount, useAccountOrServer, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { Platform, View } from "react-native";
import { useIsVisible } from 'app/hooks/use_is_visible';

import { Event, EventAttendance, EventInstance, Group, Media, Permission, Visibility } from "@jonline/api";
import { Anchor, Text, Button, Card, Heading, Image, Paragraph, ScrollView, createFadeAnimation, TamaguiElement, Theme, useMedia, XStack, YStack, Dialog, TextArea, Input, useWindowDimensions, Select, getFontSize, Sheet, Adapt } from "@jonline/ui";
import { useMediaUrl } from "app/hooks/use_media_url";
import moment from "moment";
import { useLink } from "solito/link";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { InstanceTime } from "./instance_time";
import { instanceTimeSort, isNotPastInstance, isPastInstance } from "app/utils/time";
import { Repeat, Delete, Edit, Eye, History, Save, CalendarPlus, X as XIcon, Link, Check, ChevronDown, ChevronUp, Plus } from "@tamagui/lucide-icons";
import icons from "@tamagui/lucide-icons";
import { GroupPostManager } from "../groups/group_post_manager";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from "react-social-media-embed";
import { MediaRenderer } from "../media/media_renderer";
import { FadeInView } from "../../components/fade_in_view";
import { postBackgroundSize } from "../post/post_card";
import { defaultEventInstance, supportDateInput, toProtoISOString } from "./create_event_sheet";
import { LinearGradient } from '@tamagui/linear-gradient';
import { PostMediaManager } from "../post/post_media_manager";
import { PostMediaRenderer } from "../post/post_media_renderer";
import { VisibilityPicker } from "../../components/visibility_picker";
import { postVisibilityDescription } from "../post/base_create_post_sheet";
import { hasPermission } from "app/utils/permission_utils";
import { createParam } from "solito";

export interface EventRsvpManagerProps {
  event: Event;
  instance: EventInstance;
  newRsvpMode: RsvpMode;
  setNewRsvpMode: (mode: RsvpMode) => void;
}

export type RsvpMode = 'anonymous' | 'user' | undefined;

// let newEventId = 0;
const { useParam } = createParam<{ anonymousAuthToken: string }>()

export const EventRsvpManager: React.FC<EventRsvpManagerProps> = ({
  event,
  instance,
  newRsvpMode,
  setNewRsvpMode
}) => {
  const { server, primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor, navAnchorColor } = useServerTheme();

  let { dispatch, accountOrServer } = useCredentialDispatch();
  const { account } = accountOrServer;

  const showRsvpSection = event?.info?.allowsRsvps &&
    (event?.info?.allowsAnonymousRsvps || hasPermission(accountOrServer?.account?.user, Permission.RSVP_TO_EVENTS));

  // const [newRsvpMode, setNewRsvpMode] = useState(undefined as RsvpMode);
  const [attendances, setAttendances] = useState([] as EventAttendance[]);
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [loadFailed, setLoadFailed] = useState(false);
  const [creatingRsvp, setCreatingRsvp] = useState(false);
  const [previewingRsvp, setPreviewingRsvp] = useState(false);

  const numberOfGuestsOptions = [...Array(52).keys()];
  const [queryAnonAuthToken, setQueryAnonAuthToken] = useParam('anonymousAuthToken');
  const anonymousAuthToken = queryAnonAuthToken ?? '';

  useEffect(() => {
    if (!loaded && !loading) {
      setLoading(true);
      setTimeout(async () => {
        try {
          const client = await getCredentialClient(accountOrServer);
          const data = await client.getEventAttendances(instance);
          setAttendances(data.attendances);
        } catch (e) {
          setLoadFailed(true);
        } finally {
          setLoaded(true);
          setLoading(false);
        }
      }, 1);

      // setLoaded(true);
    }
  }, [accountOrServerId(accountOrServer), event?.id, instance?.id, loading, loaded]);
  const [anonymousRsvpName, setAnonymousRsvpName] = useState('');
  const [publicNote, setPublicNote] = useState('');
  const [privateNote, setPrivateNote] = useState('');
  const [numberOfGuests, setNumberOfGuests] = useState(0);

  const canRsvp = (newRsvpMode === 'user' && account?.user) || anonymousRsvpName.length > 0;
  return showRsvpSection
    ? <YStack space='$2' mb='$4' mx='$3' >
      <Heading size='$6' mx='auto'>RSVP</Heading>
      <XStack space='$2' w='100%'>
        {hasPermission(accountOrServer?.account?.user, Permission.RSVP_TO_EVENTS)
          ? <Button transparent={newRsvpMode != 'user'} h='$7' f={1} p={0} onPress={() => setNewRsvpMode('user')}>
            <YStack ai='center'>
              <Plus color={primaryAnchorColor} />
              <Heading color={primaryAnchorColor} size='$5'>RSVP</Heading>
            </YStack>
          </Button>
          : undefined}
        {event?.info?.allowsAnonymousRsvps
          ? <>
            <Button mb='$2' transparent={newRsvpMode != 'anonymous'} h='$7' f={1} p={0} onPress={() => setNewRsvpMode('anonymous')}>
              <YStack ai='center'>
                <Plus color={navAnchorColor} />
                <Heading color={navAnchorColor} size='$3'>Anonymous</Heading>
                <Heading color={navAnchorColor} size='$2'>RSVP</Heading>
              </YStack>
            </Button>
          </>
          : undefined}
      </XStack>
      {newRsvpMode !== undefined
        ? <>
          {newRsvpMode === 'anonymous'
            ? <>
              {!previewingRsvp
                ? <Input textContentType="name" f={1}
                  my='$1'

                  placeholder={`Anonymous Guest Name (required)`}
                  disabled={creatingRsvp} opacity={creatingRsvp || anonymousRsvpName == '' ? 0.5 : 1}
                  autoCapitalize='words'
                  value={anonymousRsvpName}
                  onChange={(data) => { setAnonymousRsvpName(data.nativeEvent.text) }} />
                : <Heading my='auto' f={1}>{anonymousRsvpName}</Heading>}
            </>
            : previewingRsvp
              ? <Heading my='auto' f={1}>{account?.user?.username}</Heading>
              : undefined}


          <Select native onValueChange={v => setNumberOfGuests(parseInt(v))} value={numberOfGuests.toString()}>
            <Select.Trigger w='100%' f={1} iconAfter={ChevronDown}>
              <Select.Value w='100%' placeholder="Choose Visibility" />
            </Select.Trigger>

            <Select.Content zIndex={200000}>
              <Select.Viewport minWidth={200} w='100%'>
                <XStack w='100%'>
                  <Select.Group space="$0" w='100%'>
                    {numberOfGuestsOptions.map(i => i + 1).map((item, i) => {
                      return (
                        <Select.Item
                          debug="verbose"
                          index={i}
                          key={item.toString()}
                          value={item.toString()}
                        >
                          <Select.ItemText>{item} {item === 1 ? 'attendee' : 'attendees'}</Select.ItemText>
                          <Select.ItemIndicator marginLeft="auto">
                            <Check size={16} />
                          </Select.ItemIndicator>
                        </Select.Item>
                      )
                    })}
                  </Select.Group>
                  <YStack
                    position="absolute"
                    right={0}
                    top={0}
                    bottom={0}
                    alignItems="center"
                    justifyContent="center"
                    width={'$4'}
                    pointerEvents="none"
                  >
                    <ChevronDown size='$2' />
                  </YStack>
                </XStack>
              </Select.Viewport>
            </Select.Content>
          </Select>

          {!previewingRsvp
            ? <TextArea f={1} pt='$2' my='$1' value={publicNote}
              disabled={creatingRsvp} opacity={creatingRsvp || publicNote == '' ? 0.5 : 1}
              h={(publicNote?.length ?? 0) > 300 ? window.innerHeight - 100 : undefined}
              onChangeText={setPublicNote}
              placeholder={`Public note (optional). Markdown is supported.`} />
            : <YStack maw={600} als='center' width='100%'>
              <TamaguiMarkdown text={publicNote} />
            </YStack>}

          {!previewingRsvp
            ? <TextArea f={1} pt='$2' my='$1' value={privateNote}
              disabled={creatingRsvp} opacity={creatingRsvp || privateNote == '' ? 0.5 : 1}
              h={(privateNote?.length ?? 0) > 300 ? window.innerHeight - 100 : undefined}
              onChangeText={setPrivateNote}
              placeholder={`Private note (optional). Markdown is supported.`} />
            : <YStack maw={600} als='center' width='100%'>
              <TamaguiMarkdown text={privateNote} />
            </YStack>}
          {newRsvpMode === 'anonymous'
            ? <Paragraph size='$1' mx='$4' my='$1'>
              When you press "RSVP", you will be assigned a unique RSVP code.
              You can use this code to edit or delete your RSVP later.
              The code will be shown to you here along with a link you can save in
              your browser bookmarks, notes app, or calendar event.
            </Paragraph>
            : undefined}
          <XStack w='100%' space='$2'>
            <Button f={1} disabled={!canRsvp} opacity={canRsvp ? 1 : 0.5}
              onPress={() => { }} color={newRsvpMode === 'anonymous' ? navAnchorColor : primaryAnchorColor}>
              RSVP
            </Button>
            <Button f={1} onPress={() => setNewRsvpMode(undefined)}>
              Cancel
            </Button>
          </XStack>
        </>
        : undefined}
    </YStack>
    : <></>;
};
