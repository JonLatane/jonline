import { useIsVisible } from 'app/hooks/use_is_visible';
import { FederatedEvent, FederatedGroup, FederatedPost, deleteEvent, federateId, federatedEntity, getServerTheme, updateEvent } from "app/store";
import React, { useEffect, useMemo, useState } from "react";

import { Event, EventInstance, Group, Location } from "@jonline/api";
import { Anchor, AnimatePresence, Button, Card, Dialog, Heading, Image, Input, Paragraph, ScrollView, Select, TamaguiElement, Text, TextArea, Theme, Tooltip, XStack, YStack, ZStack, reverseStandardAnimation, standardAnimation, standardHorizontalAnimation, useMedia, useWindowDimensions } from "@jonline/ui";
import { CalendarPlus, Check, ChevronDown, ChevronRight, Delete, Edit, History, Link, Menu, Repeat, Save, X as XIcon } from "@tamagui/lucide-icons";
import { FadeInView, ToggleRow, VisibilityPicker } from "app/components";
import { GroupPostManager } from "app/features/groups";
import { AuthorInfo, LinkProps, PostMediaManager, PostMediaRenderer, TamaguiMarkdown, postBackgroundSize, postVisibilityDescription } from "app/features/post";
import { useAccount, useAccountOrServer, useComponentKey, useCurrentAndPinnedServers, useFederatedDispatch, useForceUpdate, useMediaUrl } from "app/hooks";
import { themedButtonBackground } from "app/utils/themed_button_background";
import { instanceTimeSort, isNotPastInstance, isPastInstance } from "app/utils/time";
import moment from "moment";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from "react-social-media-embed";
import { useLink } from "solito/link";
// import { PostMediaRenderer } from "../post/post_media_renderer";
import { PayloadAction } from '@reduxjs/toolkit';
import { ShareableToggle } from 'app/components/shareable_toggle';
import { AccountOrServerContextProvider } from 'app/contexts';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { defaultEventInstance, supportDateInput, toProtoISOString } from "./create_event_sheet";
import { EventRsvpManager, RsvpMode } from './event_rsvp_manager';
import { InstanceTime, useInstanceLink } from "./instance_time";
import { LocationControl } from "./location_control";

interface Props {
  event: FederatedEvent;
  selectedInstance?: EventInstance;
  isPreview?: boolean;
  groupContext?: Group;
  horizontal?: boolean;
  xs?: boolean;
  hideEditControls?: boolean;
  onEditingChange?: (editing: boolean) => void;
  newRsvpMode?: RsvpMode;
  setNewRsvpMode?: (mode: RsvpMode) => void;
  onInstancesUpdated?: (instances: EventInstance[]) => void;
}

let newEventId = 0;

export const EventCard: React.FC<Props> = ({
  event,
  selectedInstance = event.instances.find(isNotPastInstance) ?? event.instances[0],
  isPreview,
  groupContext,
  horizontal,
  xs,
  hideEditControls,
  onEditingChange,
  newRsvpMode,
  setNewRsvpMode,
  onInstancesUpdated,
}) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(event);
  const server = accountOrServer.server;
  const isPrimaryServer = useAccountOrServer().server?.host === accountOrServer.server?.host;
  const currentAndPinnedServers = useCurrentAndPinnedServers();
  const showServerInfo = !isPrimaryServer || (isPreview && currentAndPinnedServers.length > 1);

  const mediaQuery = useMedia();
  const currentUser = useAccount()?.user;
  const post = federatedEntity(event.post!, server);

  const { textColor, primaryColor, primaryTextColor, navColor, navAnchorColor, navTextColor, backgroundColor: themeBgColor, primaryAnchorColor } = getServerTheme(server);
  const [editing, _setEditing] = useState(false);
  function setEditing(value: boolean) {
    _setEditing(value);
    onEditingChange?.(value);
  }
  const [previewingEdits, setPreviewingEdits] = useState(false);
  const [savingEdits, setSavingEdits] = useState(false);

  const [editedTitle, setEditedTitle] = useState(post.title);
  const [editedLink, setEditedLink] = useState(post.link);
  const [editedContent, setEditedContent] = useState(post.content);
  const [editedMedia, setEditedMedia] = useState(post.media);
  const [editedEmbedLink, setEditedEmbedLink] = useState(post.embedLink);
  const [editedVisibility, setEditedVisibility] = useState(post.visibility);
  const [editedShareable, setEditedShareable] = useState(post.shareable);

  const [editedInstances, setEditedInstances] = useState(event.instances);
  const [editedAllowRsvps, setEditedAllowRsvps] = useState(event.info?.allowsRsvps ?? false);
  const [editedAllowAnonymousRsvps, setEditedAllowAnonymousRsvps] = useState(event.info?.allowsAnonymousRsvps ?? false);

  const title = editing ? editedTitle : post.title;
  const content = editing ? editedContent : post.content;
  const media = editing ? editedMedia : post.media;
  const embedLink = editing ? editedEmbedLink : post.embedLink;
  const visibility = editing ? editedVisibility : post.visibility;
  const shareable = editing ? editedShareable : post.shareable;
  const instances = editing ? editedInstances : event.instances;

  const hasPastInstances = instances.find(isPastInstance) != undefined;
  const [editingInstance, setEditingInstance] = useState(undefined as EventInstance | undefined);

  const { setStartTime, setEndTime } = useStartAndEndTime(editingInstance, updateEditingInstance);

  const [repeatWeeks, setRepeatWeeks] = useState(1);

  const endDateInvalid = editingInstance && !moment(editingInstance.endsAt).isAfter(moment(editingInstance.startsAt));
  const primaryInstance = /*editingInstance ??*/
    editing && previewingEdits && !editedInstances.some(i => i.id === selectedInstance?.id)
      ? undefined
      : selectedInstance ?? (instances.length === 1 ? instances[0] : undefined);

  function editingOrPrimary<T>(getter: (i: EventInstance | undefined) => T): T {
    if (editingInstance) {
      return getter(editingInstance);
    } else {
      return getter(primaryInstance);
    }
  }

  function saveEdits() {
    setSavingEdits(true);
    dispatch(updateEvent({
      ...accountOrServer,
      ...event,
      info: {
        ...event.info,
        allowsRsvps: editedAllowRsvps,
        allowsAnonymousRsvps: editedAllowRsvps && editedAllowAnonymousRsvps,
      },
      post: {
        ...post,
        title: editedTitle,
        link: editedLink,
        content: editedContent,
        media: editedMedia,
        visibility: editedVisibility,
        shareable: editedShareable,
      },
      instances: editedInstances,
    })).then((result: PayloadAction<Event, any, any, any>) => {
      onInstancesUpdated?.(result.payload?.instances);
      setEditing(false);
      setSavingEdits(false);
      setPreviewingEdits(false);
      setEditedInstances(result.payload?.instances);
    });
  }

  function addInstance() {
    const newInstance = { ...defaultEventInstance(), id: `unsynchronized-event-instance-${newEventId++}` };
    setEditedInstances([newInstance, ...editedInstances]);
    setEditingInstance(newInstance);
  }
  function removeInstance(target: EventInstance) {
    if (target.id === editingInstance?.id) {
      setEditingInstance(undefined);
    }
    setEditedInstances(editedInstances.filter(i => i.id != target.id));
  }
  function updateEditingInstance(target: EventInstance) {
    setEditedInstances(editedInstances.map(i => i.id === target.id ? target : i));
    if (target.id === editingInstance?.id) {
      setEditingInstance(target);
    }
  }
  function repeatInstance(target: EventInstance, repititions: { weeks?: number, days?: number, hours?: number }) {
    // setEditedInstances(editedInstances.map(i => i.id == target.id ? target : i));
  }
  function editInstance(target: EventInstance) {
    setEditingInstance(target);
  }

  const [deleted, setDeleted] = useState(post.author === undefined);
  const [deleting, setDeleting] = useState(false);
  function doDeletePost() {
    setDeleting(true);
    dispatch(deleteEvent({ ...accountOrServer, ...event })).then(() => {
      setDeleted(true);
      setDeleting(false);
    });
  }

  const window = useWindowDimensions();
  const ref = React.createRef<TamaguiElement>();
  const instanceScrollRef = React.createRef<ScrollView>();
  const isVisible = useIsVisible(ref);
  const [hasBeenVisible, setHasBeenVisible] = useState(false);
  useEffect(() => {
    if (isVisible && !hasBeenVisible) {
      setHasBeenVisible(true);
    }
  }, [isVisible]);

  const authorId = post.author?.userId;
  const authorName = post.author?.username;

  const primaryInstanceIdString = primaryInstance?.id ?? 'no-primary-instance';
  const detailsLinkId = showServerInfo
    ? federateId(primaryInstanceIdString, accountOrServer.server)
    : primaryInstanceIdString;
  const groupLinkId = groupContext ?
    (showServerInfo
      ? federateId(groupContext.shortname, accountOrServer.server)
      : groupContext.shortname)
    : undefined;
  const eventLink: LinkProps = useLink({
    href: primaryInstance ?
      groupContext
        ? `/g/${groupLinkId}/e/${detailsLinkId}`
        : `/event/${detailsLinkId}`
      : '.'
  });

  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : `/user/${authorId}`
  });
  const createGroupEventViewHref = (group: FederatedGroup) => {
    const groupLinkId = (group.serverHost !== server?.host
      ? federateId(group.shortname, accountOrServer.server)
      : group.shortname);

    return primaryInstance
      ? `/g/${groupLinkId}/e/${detailsLinkId}`
      : `.`;
  }

  const maxTotalContentHeight = isPreview
    ? (horizontal ? xs ? 225 : 350 : 500)
    - (event.info?.allowsRsvps ? 100 : 0)
    - (primaryInstance?.location?.uniformlyFormattedAddress?.length ?? 0 > 0 ? 43 : 0)
    : undefined;
  // console.log({ maxTotalContentHeight })
  const numContentSections = ((content?.length ?? 0) > 0 ? 1 : 0)
    + (embedLink || media.length > 0 ? 1 : 0);
  const maxContentSectionHeight = isPreview ?
    (maxTotalContentHeight! - (maxTotalContentHeight! * (2 - numContentSections) * 0.25)) / numContentSections
    : undefined;

  const detailsLink: LinkProps | undefined = isPreview ? eventLink : undefined;
  const postLink = post.link ? useLink({ href: post.link }) : undefined;
  const authorLinkProps = post.author ? authorLink : undefined;
  const contentLengthShadowThreshold = horizontal ? 180 : 700;
  const showDetailsShadow = isPreview && post.content && post.content.length > contentLengthShadowThreshold;
  const detailsShadowProps = showDetailsShadow ? {
    shadowOpacity: 0.3,
    shadowOffset: { width: -5, height: -5 },
    shadowRadius: 10
  } : {};
  const embedSupported = post.embedLink && post.link && post.link.length;
  let embedComponent: React.ReactNode | undefined = undefined;
  if (embedSupported) {
    const url = new URL(post.link!);
    const hostname = url.hostname.split(':')[0]!;
    if (hostname.endsWith('twitter.com')) {
      embedComponent = <TwitterEmbed url={post.link!} />;
    } else if (hostname.endsWith('instagram.com')) {
      embedComponent = <InstagramEmbed url={post.link!} />;
    } else if (hostname.endsWith('facebook.com')) {
      embedComponent = <FacebookEmbed url={post.link!} />;
    } else if (hostname.endsWith('youtube.com')) {
      embedComponent = <YouTubeEmbed url={post.link!} />;
    } else if (hostname.endsWith('tiktok.com')) {
      embedComponent = <TikTokEmbed url={post.link!} />;
    } else if (hostname.endsWith('pinterest.com')) {
      embedComponent = <PinterestEmbed url={post.link!} />;
    } else if (hostname.endsWith('linkedin.com')) {
      embedComponent = <LinkedInEmbed url={post.link!} />;
    }
  }

  const imagePreview = media?.find(m => m.contentType.startsWith('image'));
  // const scrollableMediaMinCount = isPreview && hasSingleImagePreview ? 3 : 2;
  const showScrollableMediaPreviews = (media?.filter(m => !m.generated).length ?? 0) >= 2;
  const previewUrl = useMediaUrl(imagePreview?.id, accountOrServer);

  const showBackgroundPreview = !!imagePreview;
  //  && isPreview
  ;// hasBeenVisible && isPreview && hasPrimaryImage && previewUrl;

  const componentKey = useComponentKey('event-card');
  const recommendedHorizontalSize = (mediaQuery.gtSm ? 400 : 310);
  const backgroundSize = document.getElementById(componentKey)?.clientWidth ?? (
    isPreview && horizontal
      ? recommendedHorizontalSize
      : postBackgroundSize(mediaQuery)
  );
  const foregroundSize = backgroundSize * 0.7;

  const author = post.author;
  const isAuthor = author && author.userId === currentUser?.id;
  const showEdit = !!isAuthor && !isPreview && !hideEditControls;

  const [scrollInstancesVertically, setScrollInstancesVertically] = useState(false);
  const [showPastInstances, setShowPastInstances] = useState(false);

  const canEasilySeeInstances = (instances: EventInstance[]) => mediaQuery.gtXxs ? instances.length <= 3 : instances.length <= 2;
  const canEasilySeeAllPastInstances = canEasilySeeInstances(instances);
  const filteredInstances = showPastInstances
    ? instances
    : instances.filter(isNotPastInstance);
  const sortedFilteredInstances = [...filteredInstances].sort(instanceTimeSort);
  const canEasilySeeAllInstances = canEasilySeeInstances(sortedFilteredInstances);
  const displayedInstances = canEasilySeeAllPastInstances
    ? instances
    : sortedFilteredInstances;


  useEffect(() => {
    if (!isPreview /*&& !scrollInstancesVertically*/) {
      setTimeout(() =>
        document.querySelectorAll('.highlighted-instance-time')
          .forEach(e => e.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' })),
        scrollInstancesVertically ? 800 : 500);
    }
  }, [selectedInstance?.id, editingInstance?.id, showPastInstances]);
  useEffect(() => {
    if (!isPreview && !scrollInstancesVertically) {
      document.querySelectorAll('.highlighted-instance-time')
        .forEach(e => e.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' }));
    }
  }, [scrollInstancesVertically]);

  const postLinkView = postLink
    ? editing && !previewingEdits
      ? <>

        <Input f={1} textContentType="URL" placeholder={`Event Link (required)`}
          disabled={savingEdits} opacity={savingEdits || editedLink == '' ? 0.5 : 1}
          value={editedLink}
          onChange={(data) => { setEditedLink(data.nativeEvent.text) }} />
      </>
      : <Anchor key='post-link' textDecorationLine='none' {...(editing ? {} : postLink)} target="_blank">
        <XStack>
          <YStack my='auto' mr='$1'>
            <Link size='$1' color={navAnchorColor} />
          </YStack>
          <YStack f={1} my='auto'>
            <Paragraph size="$2" color={navAnchorColor} overflow="hidden" whiteSpace="nowrap" textOverflow="ellipsis">{post.link}</Paragraph>
          </YStack>
        </XStack>
      </Anchor>
    : undefined;

  const instanceModeButton = canEasilySeeAllInstances
    ? undefined
    : <Button p='$2' onPress={() => setScrollInstancesVertically(!scrollInstancesVertically)} ml="$1">
      <ZStack h='$1' w='$1' mx='auto' my='auto' transform={[{ translateY: -1 }]}>
        <XStack animation='standard' o={scrollInstancesVertically ? 1 : 0} rotate={scrollInstancesVertically ? '90deg' : '0deg'}>
          <ChevronRight />
        </XStack>
        <XStack animation='standard' o={!scrollInstancesVertically ? 1 : 0} rotate={scrollInstancesVertically ? '90deg' : '0deg'}>
          <Menu />
        </XStack>
      </ZStack>
    </Button>;
  const instanceManagementButtons = <>
    {/* <YStack key='instances-buttons' my='$2' space="$3"> */}
    {editing
      ? <Button my='auto' size='$3' circular icon={CalendarPlus} onPress={addInstance} />
      : undefined}
    {hasPastInstances && !canEasilySeeAllPastInstances
      ? <Tooltip placement='bottom-start'>
        <Tooltip.Trigger>
          <Button ml='$2' size='$3' my='auto'
            {...showPastInstances ? themedButtonBackground(navColor, navTextColor) : {}}
            // color={showPastInstances ? navAnchorColor : undefined}
            circular={(displayedInstances?.length ?? 0) > 0} icon={History}
            onPress={() => setShowPastInstances(!showPastInstances)} >
            {(displayedInstances?.length ?? 0) === 0 ? 'Show Past Instances' : undefined}
          </Button>
        </Tooltip.Trigger>
        {(displayedInstances?.length ?? 0) === 0
          ? undefined
          : <Tooltip.Content>
            <Paragraph size='$1'>{showPastInstances ? 'Show' : 'Hide'} Past Instances</Paragraph>
          </Tooltip.Content>}
      </Tooltip>
      : undefined}
    {/* </YStack> */}
  </>;

  const shrinkServerInfo = isPreview || !mediaQuery.gtXxxs;
  const serverInfoView = showServerInfo
    ? <XStack my='auto' w={shrinkServerInfo ? '$4' : undefined} h={shrinkServerInfo ? '$4' : undefined} jc={shrinkServerInfo ? 'center' : undefined} mr='$2'>
      <ServerNameAndLogo server={server} shrinkToSquare={shrinkServerInfo} />
    </XStack>
    : undefined;
  const headerLinksView = <YStack f={1} key='header-links-view'>
    {isPreview
      ? <>
        <Anchor key='details-link' textDecorationLine='none' {...detailsLink}>
          <XStack>
            <YStack f={1}>
              <Heading size="$7" marginRight='auto'>{title}</Heading>
            </YStack>
            {serverInfoView}
          </XStack>
        </Anchor>
        {postLinkView}
        <Anchor key='instance-link' textDecorationLine='none' {...detailsLink}>
          {primaryInstance ? <InstanceTime event={event} instance={primaryInstance} highlight noAutoScroll /> : undefined}
        </Anchor>
      </>
      : <>
        <XStack key='title'>
          <YStack f={1} my='auto'>
            <Heading size="$7" marginRight='auto'>{title}</Heading>
          </YStack>
          {serverInfoView}
          {instanceModeButton}
        </XStack>
        {postLinkView}
        <XStack w='100%' mt='$1'>
          <YStack>
            {primaryInstance
              ? <InstanceTime key='instance-time' event={event} instance={primaryInstance} highlight noAutoScroll />
              : editing && previewingEdits
                ? <Paragraph key='missing-instance' size='$1'>This instance no longer exists.</Paragraph>
                : undefined}
          </YStack>
          <XStack f={1} />
          {instanceManagementButtons}
        </XStack>
      </>}
  </YStack>;

  const headerLinksEdit = <YStack f={1} space='$2' key='header-links-edit'>
    <XStack w='100%' space='$2'>
      <Input f={1} textContentType="name" placeholder={`Event Title (required)`}
        disabled={savingEdits} opacity={savingEdits || editedTitle == '' ? 0.5 : 1}
        value={editedTitle}
        onChange={(data) => { setEditedTitle(data.nativeEvent.text) }} />

      {serverInfoView}
      {instanceModeButton}
    </XStack>
    <XStack w='100%'>
      {postLinkView}
      <XStack f={1} />
      {instanceManagementButtons}
    </XStack>
  </YStack>;

  const headerLinks = <XStack w='100%'>
    {editing && !previewingEdits ? headerLinksEdit : headerLinksView}
  </XStack>;

  const contentView = editing || (post.content && post.content) != ''
    ? isPreview
      ? <Anchor key='content-link' textDecorationLine='none' {...detailsLink}>
        <TamaguiMarkdown text={post.content} disableLinks={isPreview} />
      </Anchor>
      : editing && !previewingEdits
        ? <TextArea key='content-editor' f={1} pt='$2' value={content}
          disabled={savingEdits} opacity={savingEdits || content == '' ? 0.5 : 1}
          h={(editedContent?.length ?? 0) > 300 ? Math.min(800, Math.max(120, window.height - 100)) : undefined}

          onChangeText={t => setEditedContent(t)}
          placeholder={`Text content (optional). Markdown is supported.`} />
        : content && content != ''
          ? <TamaguiMarkdown key='content' text={content} disableLinks={isPreview} />
          : undefined
    : undefined;

  const weeklyRepeatOptions = [...Array(52).keys()];
  const forceUpdate = useForceUpdate();

  const repeatedInstances = useMemo(() => {
    const instances: EventInstance[] = [];
    if (editingInstance) {
      [...Array(repeatWeeks).keys()].map(i => i + 1).forEach(weeksAfter => {
        const repeatedInstance = EventInstance.create({
          id: `unsynchronized-event-instance-${newEventId++}`,
          startsAt: moment(editingInstance.startsAt).add(weeksAfter, 'weeks').toISOString(),
          endsAt: moment(editingInstance.endsAt).add(weeksAfter, 'weeks').toISOString(),
          location: editingInstance.location,
        });
        instances.push(repeatedInstance);
      });
    }
    return instances;
  }, [
    repeatWeeks,
    editingInstance?.startsAt,
    editingInstance?.endsAt, editingInstance?.location?.uniformlyFormattedAddress
  ]);

  function doRepeatInstance() {
    setEditedInstances([...editedInstances, ...repeatedInstances]);
    setTimeout(forceUpdate, 1);
  }

  function renderInstance(i: EventInstance) {
    const isPrimary = i.id == primaryInstance?.id;
    const isEditingInstance = i.id == editingInstance?.id;
    const highlight = editing ? isEditingInstance : isPrimary;
    let result = <YStack key={`instance-${i.id}`} mx={editing ? '$1' : undefined} animation='standard'
      {...standardHorizontalAnimation} o={highlight ? 1 : 0.5} mb={scrollInstancesVertically ? '$2' : undefined}>
      <InstanceTime key={i.id} linkToInstance={!editing}
        event={event} instance={i}
        highlight={highlight}
      />
      {editing
        ? <XStack w='100%' mt='$2'>
          <Theme inverse={editingInstance?.id === i.id}>
            <Button mx='auto' size='$2' circular icon={Edit} onPress={() => setEditingInstance(i.id !== editingInstance?.id ? i : undefined)} />
          </Theme>
          {i.id == editingInstance?.id
            ? <Dialog>
              <Dialog.Trigger asChild>
                <Button mx='auto' size='$2' circular icon={Repeat} onPress={() => setEditingInstance(i)} />
              </Dialog.Trigger>
              <Dialog.Portal zi={1000011}>
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
                    <Dialog.Title>Repeat Instance</Dialog.Title>
                    <Dialog.Description>
                      <Paragraph size="$2">Repeat for:</Paragraph>
                      <XStack>
                        <Select native id={'repeat-weeks'} onValueChange={v => setRepeatWeeks(parseInt(v))} value={repeatWeeks.toString()}>
                          <Select.Trigger w='100%' f={1} iconAfter={ChevronDown}>
                            <Select.Value w='100%' placeholder="Choose Visibility" />
                          </Select.Trigger>

                          <Select.Content zIndex={200000}>
                            <Select.Viewport minWidth={200} w='100%'>
                              <XStack w='100%'>
                                <Select.Group space="$0" w='100%'>
                                  {weeklyRepeatOptions.map(i => i + 1).map((item, i) => {
                                    return (
                                      <Select.Item
                                        debug="verbose"
                                        index={i}
                                        key={item.toString()}
                                        value={item.toString()}
                                      >
                                        <Select.ItemText>{item} {item === 1 ? 'week' : 'weeks'}</Select.ItemText>
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
                        {/* <Text fontFamily='$body'>weeks</Text> */}
                      </XStack>
                      {repeatedInstances.length > 0
                        ? <YStack>
                          <XStack mt='$2'>
                            <Paragraph f={1} my='auto'>Last:</Paragraph>
                            <InstanceTime key={i.id} event={event} instance={repeatedInstances[repeatedInstances.length - 1]!} />
                          </XStack>
                        </YStack>
                        : undefined}
                    </Dialog.Description>

                    <XStack space="$3" jc="flex-end">
                      <Dialog.Close asChild>
                        <Button>Cancel</Button>
                      </Dialog.Close>

                      <Dialog.Close asChild>
                        {/* <Dialog.A> */}
                        {/* <Theme inverse> */}
                        <Button color={primaryAnchorColor} onPress={doRepeatInstance}>Repeat</Button>
                        {/* </Theme> */}
                        {/* </Dialog.Action> */}
                      </Dialog.Close>
                      {/* </Dialog.Action> */}
                    </XStack>
                  </YStack>
                </Dialog.Content>
              </Dialog.Portal>
            </Dialog>
            : undefined}
          {editedInstances.length > 1
            ? <Button mx='auto' size='$2' circular icon={Delete} onPress={() => removeInstance(i)} />
            : undefined}
        </XStack>
        : undefined}
    </YStack>;

    if (editing) {
      result = <YStack ml='$1' h={100} mb='$1' key={`instance-${i.id}-wrapper`}
        padding='$2'
        borderRadius='$3' backgroundColor='$backgroundStrong'>
        {result}
      </YStack>
    }

    return result;
  }


  return (
    <AccountOrServerContextProvider value={accountOrServer}>
      <YStack w={isPreview && horizontal ? recommendedHorizontalSize : '100%'}>
        <Card theme="dark" size="$4" bordered id={componentKey}
          // key={`event-card-${event.id}-${isPreview ? primaryInstance?.id : 'details'}-${isPreview ? '-preview' : ''}`}
          animation='standard'
          borderColor={showServerInfo ? primaryColor : undefined}
          margin='$0'
          marginBottom='$3'
          marginTop='$3'
          padding={0}
          f={isPreview ? undefined : 1}
          ref={ref!}
          scale={1}
          opacity={1}
          y={0}
        // borderColor={primaryAnchorColor}
        >
          {post.link || post.title
            ? <Card.Header p={0}>
              <YStack w='100%'>
                <XStack ai='center' w='100%'>
                  <YStack key='primary-header' f={1} pt='$4' pb={0}>
                    <YStack key='header-links' w='100%' pl='$4' pr={isPreview && showServerInfo ? 0 : '$4'}>
                      {headerLinks}
                    </YStack>
                  </YStack>

                  {/* {showServerInfo
                    ? <XStack my='auto' w={shrinkServerInfo ? '$4' : undefined} h={shrinkServerInfo ? '$4' : undefined} jc={shrinkServerInfo ? 'center' : undefined} mr='$2'>
                      <ServerNameAndLogo server={server} shrinkToSquare={shrinkServerInfo} />
                    </XStack>
                    : undefined} */}
                </XStack>
                {!isPreview && (instances.length > 1 || editing)
                  ? <XStack key='instances' w='100%' mt='$2' space>


                    {scrollInstancesVertically
                      ? <XStack key='instance-display' jc='center' animation='standard' {...standardAnimation} space='$2' flexWrap='wrap' f={1}>
                        <AnimatePresence>
                          {displayedInstances?.map((i) => renderInstance(i))}
                        </AnimatePresence>
                      </XStack>
                      : <ScrollView key='instance-scroller' animation='standard' {...reverseStandardAnimation} f={1} horizontal pb='$3'>
                        <XStack mt='$1' px='$3' key='instance-scroller-list'>
                          <AnimatePresence key='instance-scroll-animator'>
                            {displayedInstances?.map((i) => renderInstance(i))}
                          </AnimatePresence>
                        </XStack>
                      </ScrollView>}

                  </XStack>
                  : undefined
                }
                <YStack w='100%' maw={800} mx='auto'>
                  {editingInstance && editing && !previewingEdits
                    ? <>
                      <XStack mx='$2' key={`startsAt-${editingInstance?.id}`}>
                        <Heading size='$2' f={1} marginVertical='auto'>Start Time</Heading>
                        <Text fontSize='$2' fontFamily='$body'>
                          <input type='datetime-local' style={{ padding: 10 }}
                            min={supportDateInput(moment(0))}
                            value={supportDateInput(moment(editingInstance.startsAt))}
                            onChange={(v) => setStartTime(v.target.value)} />
                        </Text>
                      </XStack>
                      <XStack mx='$2' key={`endsAt-${editingInstance?.id}`}>
                        <Heading size='$2' f={1} marginVertical='auto'>End Time</Heading>
                        <Text fontSize='$2' fontFamily='$body' color={textColor}>
                          <input type='datetime-local' style={{ padding: 10 }}
                            min={editingInstance.startsAt}
                            value={supportDateInput(moment(editingInstance.endsAt))}
                            onChange={(v) => setEndTime(v.target.value)} />
                        </Text>
                      </XStack>
                      {endDateInvalid ? <Paragraph size='$2' mx='$2'>Must be after Start Time</Paragraph> : undefined}
                    </>
                    : undefined}

                </YStack>
                {primaryInstance
                  ?
                  <XStack mx='$3' mt='$1'>
                    <LocationControl key='location-control' location={editingOrPrimary(i => i?.location ?? Location.create({}))}
                      readOnly={!editing || previewingEdits}
                      preview={isPreview && horizontal}
                      link={isPreview ? eventLink : undefined}
                      setLocation={(location: Location) => {
                        if (editingInstance) {
                          updateEditingInstance({ ...editingInstance, location });
                        }
                      }} />
                  </XStack>
                  : undefined}
              </YStack>
            </Card.Header>
            : undefined}
          <Card.Footer p={0} paddingTop='$2' >
            {deleted
              ? <Paragraph key='deleted-notification' size='$1'>This event has been deleted.</Paragraph>
              : <YStack key='footer-base' zi={1000} width='100%'>
                <YStack key='event-content' px='$3' pt={0} w='100%' maw={800} mx='auto' pl='$3'>
                  <YStack key='media-manager' mah={maxContentSectionHeight} overflow='hidden'>
                    {editing && !previewingEdits
                      ? <PostMediaManager
                        key='media-edit'
                        link={post.link}
                        media={editedMedia}
                        setMedia={setEditedMedia}
                        embedLink={editedEmbedLink}
                        setEmbedLink={setEditedEmbedLink}
                        disableInputs={savingEdits}

                      />
                      : <PostMediaRenderer
                        key='media-view'
                        smallPreview={horizontal && isPreview}
                        xsPreview={xs && isPreview}
                        {...{ detailsLink, isPreview, groupContext, hasBeenVisible }}
                        post={{
                          ...post,
                          media,
                          embedLink
                        }} />}
                  </YStack>
                  <YStack key='content' maxHeight={maxContentSectionHeight} overflow='hidden'>
                    {contentView}
                  </YStack>
                  {editing && !previewingEdits
                    ? <>
                      <ToggleRow key='rsvp-toggle' name='Allow RSVPs' value={editedAllowRsvps} setter={setEditedAllowRsvps} />
                      <ToggleRow key='anonymous-rsvp-toggle' name='Allow Anonymous RSVPs' value={editedAllowRsvps && editedAllowAnonymousRsvps}
                        disabled={!editedAllowRsvps}
                        setter={setEditedAllowAnonymousRsvps} />
                    </>
                    : undefined}

                </YStack>
                {primaryInstance && (!isPreview || hasBeenVisible)
                  ? <YStack key='rsvp-manager' maw={800} w='100%' px='$1' mx='auto' mt='$1'>
                    <EventRsvpManager
                      key={`rsvp-manager-${(editingInstance ?? primaryInstance)?.id}`}
                      event={event!}
                      instance={editingInstance ?? primaryInstance} {...{ isPreview, newRsvpMode, setNewRsvpMode }} />
                  </YStack>
                  : undefined}
                <XStack key='save-buttons' space='$2' px='$3' py='$2' pt={0} flexWrap="wrap">
                  {showEdit
                    ? editing
                      ? <>
                        <Button my='auto' key='save-button' size='$2' icon={Save} onPress={saveEdits} color={primaryAnchorColor} transparent
                          disabled={savingEdits} o={savingEdits ? 0.5 : 1}>
                          Save
                        </Button>
                        <Button my='auto' key='cancel-button' size='$2' icon={XIcon} onPress={() => { setEditing(false); setPreviewingEdits(false); }} transparent
                          disabled={savingEdits} o={savingEdits ? 0.5 : 1}>
                          Cancel
                        </Button>
                        <Button my='auto' key='preview-button' size='$2' icon={Edit} onPress={() => setPreviewingEdits(!previewingEdits)} color={navAnchorColor} transparent
                          disabled={savingEdits} o={savingEdits ? 0.5 : 1}>
                          {previewingEdits ? 'Edit' : 'Preview'}
                        </Button>
                      </>
                      : <>
                        <Button my='auto' key='edit-button' size='$2' icon={Edit}
                          onPress={() => {
                            setEditing(true); if (editedInstances.some(i => i.id === selectedInstance?.id)) {
                              setEditingInstance(selectedInstance)
                            }
                          }} transparent
                          disabled={deleting} o={deleting ? 0.5 : 1}>
                          Edit
                        </Button>

                        <Dialog key='delete-button-dialog'>
                          <Dialog.Trigger asChild>
                            <Button key='delete-button' my='auto' size='$2' icon={Delete} transparent
                              disabled={deleting} o={deleting ? 0.5 : 1}>
                              Delete
                            </Button>
                          </Dialog.Trigger>
                          <Dialog.Portal zi={1000011}>
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
                                <Dialog.Title>Delete Event</Dialog.Title>
                                <Dialog.Description>
                                  Really delete event?
                                  The content and title, along with all event instances and RSVPs, will be deleted, and your user account de-associated, but any replies (including quotes) will still be present.
                                </Dialog.Description>

                                <XStack space="$3" jc="flex-end">
                                  <Dialog.Close asChild>
                                    <Button>Cancel</Button>
                                  </Dialog.Close>
                                  <Theme inverse>
                                    <Button onPress={doDeletePost}>Delete</Button>
                                  </Theme>
                                </XStack>
                              </YStack>
                            </Dialog.Content>
                          </Dialog.Portal>
                        </Dialog>
                      </>
                    : undefined}

                  <XStack key='visibility-etc' space='$2' flexWrap="wrap" ml='auto' my='auto' maw='100%'>
                    <XStack key='visibility-edit' my='auto' ml='auto'>
                      <VisibilityPicker
                        id={`visibility-picker-${post.id}${isPreview ? '-preview' : ''}`}
                        label='Event Visibility'
                        visibility={visibility}
                        onChange={setEditedVisibility}
                        visibilityDescription={v => postVisibilityDescription(v, groupContext, server, 'event')}
                        readOnly={!editing || previewingEdits}
                      />
                    </XStack>
                    <XStack key='shareable-edit' my='auto' ml='auto' pb='$1'>
                      <ShareableToggle value={shareable}
                        setter={setEditedShareable}
                        readOnly={!editing || previewingEdits} />
                    </XStack>
                    {isPrimaryServer
                      ? <XStack key='group-post-manager' my='auto' maw='100%' ml='auto'>
                        <GroupPostManager post={post} isVisible={isVisible}
                          createViewHref={createGroupEventViewHref} />
                      </XStack>
                      : undefined}
                  </XStack>
                </XStack>

                <XStack {...detailsShadowProps} key='details' mt={showEdit ? -11 : -15} pl='$3' mb='$3'>
                  <AuthorInfo key='author-details' {...{ post, isVisible }} />
                  <Anchor key='author-anchor' textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                    <YStack key='author-anchor-root' h='100%'>
                      <Button key='comments-link-button'
                        opacity={isPreview ? 1 : 0.9}
                        transparent={isPreview || !post?.replyToPostId || post.replyCount == 0}
                        disabled={true}
                        marginVertical='auto'
                        px='$2'
                      >
                        <XStack opacity={0.9}>
                          <YStack marginVertical='auto' scale={0.75}>
                            <Paragraph size="$1" ta='right'>
                              {post.responseCount} comment{post.responseCount == 1 ? '' : 's'}
                            </Paragraph>
                            {isPreview || post.replyCount == 0 ? undefined : <Paragraph size="$1" ta='right'>
                              {post.replyCount} repl{post.replyCount == 1 ? 'y' : 'ies'}
                            </Paragraph>}
                          </YStack>
                        </XStack>
                      </Button>
                    </YStack>
                  </Anchor>
                </XStack>
              </YStack>
            }
          </Card.Footer>
          <Card.Background>
            {(showBackgroundPreview) ?
              <FadeInView>
                <Image
                  pos="absolute"
                  width={backgroundSize}
                  opacity={0.11}
                  height={backgroundSize}
                  resizeMode="cover"
                  als="flex-start"
                  source={{ uri: previewUrl!, height: backgroundSize, width: backgroundSize }}
                  blurRadius={1.5}
                  // borderRadius={5}
                  borderBottomRightRadius={5}
                />
              </FadeInView>
              : undefined}
          </Card.Background>
        </Card >
      </YStack>
    </AccountOrServerContextProvider>
  );
};

export default EventCard;


function useStartAndEndTime(instance: EventInstance | undefined, setInstance: (instance: EventInstance) => void) {
  const [startTime, endTime] = [instance?.startsAt, instance?.endsAt]
  function setEndTime(value: string) {
    if (!instance) {
      return;
    }
    const updatedInstance = { ...instance, endsAt: toProtoISOString(value) };
    setInstance(updatedInstance);
  }
  function setStartTime(value: string) {
    if (!instance) {
      return;
    }
    const updatedInstance = { ...instance, startsAt: toProtoISOString(value) };
    setInstance(updatedInstance);
  }
  const [duration, _setDuration] = useState(0);
  useEffect(() => {
    if (startTime && endTime) {
      const start = moment(startTime);
      const end = moment(endTime);
      _setDuration(end.diff(start, 'minutes'));
    }
  }, [endTime]);
  useEffect(() => {
    if (startTime && duration) {
      const start = moment(startTime);
      const end = start.add(duration, 'minutes');
      setEndTime(supportDateInput(end));
    }
  }, [startTime]);

  return { startTime, setStartTime, endTime, setEndTime };
}