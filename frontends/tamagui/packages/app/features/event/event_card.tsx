import useIsVisibleHorizontal from 'app/hooks/use_is_visible';
import { FederatedEvent, FederatedGroup, deleteEvent, federateId, federatedEntity, updateEvent, useServerTheme } from "app/store";
import React, { useCallback, useEffect, useMemo, useState } from "react";

import { Event, EventInstance, Location, Post, Visibility } from "@jonline/api";
import { Anchor, AnimatePresence, Button, Card, DateTimePicker, Dialog, Heading, Image, Input, Paragraph, ScrollView, Select, TextArea, Theme, Tooltip, XStack, YStack, ZStack, reverseStandardAnimation, standardAnimation, standardHorizontalAnimation, supportDateInput, toProtoISOString, useMedia, useWindowDimensions } from "@jonline/ui";
import { CalendarPlus, Check, ChevronDown, ChevronRight, Delete, Edit3 as Edit, History, Link, Link2, Menu, Repeat, Save, X as XIcon } from '@tamagui/lucide-icons';
import { ToggleRow, VisibilityPicker } from "app/components";
import { GroupPostManager } from "app/features/groups";
import { AuthorInfo, LinkProps, PostMediaManager, PostMediaRenderer, TamaguiMarkdown, postBackgroundSize, postVisibilityDescription } from "app/features/post";
import { useAppSelector, useComponentKey, useCurrentAccountOrServer, useFederatedDispatch, useForceUpdate, useLocalConfiguration, useMediaUrl, usePinnedAccountsAndServers } from "app/hooks";
import { themedButtonBackground } from "app/utils/themed_button_background";
import { instanceTimeSort, isNotPastInstance, isPastInstance } from "app/utils/time";
import moment from "moment";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from "react-social-media-embed";
import { useLink } from "solito/link";
// import { PostMediaRenderer } from "../post/post_media_renderer";
import { PayloadAction } from '@reduxjs/toolkit';
import { ShareableToggle } from 'app/components/shareable_toggle';
import { AccountOrServerContextProvider, useGroupContext } from 'app/contexts';
import { useSelector } from 'react-redux';
import { federatedId } from '../../store/federation';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { StarButton } from '../post/star_button';
import { defaultEventInstance, } from "./create_event_sheet";
import { EventCalendarExporter } from './event_calendar_exporter';
import { EventRsvpManager, RsvpMode, selectRsvpData } from './event_rsvp_manager';
import { InstanceTime } from "./instance_time";
import { LocationControl } from "./location_control";

interface Props {
  event: FederatedEvent;
  selectedInstance?: EventInstance;
  isModalPreview?: boolean;
  isPreview?: boolean;
  // groupContext?: FederatedGroup;
  horizontal?: boolean;
  xs?: boolean;
  hideEditControls?: boolean;
  onEditingChange?: (editing: boolean) => void;
  newRsvpMode?: RsvpMode;
  setNewRsvpMode?: (mode: RsvpMode) => void;
  onInstancesUpdated?: (instances: EventInstance[]) => void;
  ignoreShrinkPreview?: boolean;
  forceShrinkPreview?: boolean;
  // disableSharingButton?: boolean;
  onPress?: () => void;
  showPermalink?: boolean;
}

let newEventId = 0;

export const EventCard: React.FC<Props> = ({
  event,
  selectedInstance = event.instances.find(isNotPastInstance) ?? event.instances[0],
  isModalPreview,
  isPreview = isModalPreview,
  // groupContext,
  horizontal,
  xs,
  hideEditControls,
  onEditingChange,
  newRsvpMode,
  setNewRsvpMode,
  onInstancesUpdated,
  ignoreShrinkPreview: ignoreShrinkPreviewProp,
  forceShrinkPreview,
  // disableSharingButton,
  onPress,
  showPermalink
}) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(event);
  const currentUser = accountOrServer.account?.user;// useAccount()?.user;
  const server = accountOrServer.server;
  const isPrimaryServer = useCurrentAccountOrServer().server?.host === server?.host;
  const { selectedGroup } = useGroupContext();
  const isGroupPrimaryServer = useCurrentAccountOrServer().server?.host === selectedGroup?.serverHost;
  const currentAndPinnedServers = usePinnedAccountsAndServers();
  const showServerInfo = !isPrimaryServer || (isPreview && currentAndPinnedServers.length > 1);

  const mediaQuery = useMedia();
  const eventPost = federatedEntity(event.post!, server);

  const ignoreShrinkPreview = isModalPreview || ignoreShrinkPreviewProp;
  const disableSharingButton = isModalPreview;
  const { textColor, primaryColor, primaryTextColor, navColor, navAnchorColor, navTextColor, backgroundColor: themeBgColor, primaryAnchorColor, darkMode } = useServerTheme(server);
  const [editing, _setEditing] = useState(false);
  const setEditing = useCallback((value: boolean) => {
    _setEditing(value);
    onEditingChange?.(value);
  }, [onEditingChange]);
  const [previewingEdits, setPreviewingEdits] = useState(false);
  const [savingEdits, setSavingEdits] = useState(false);

  const [editedTitle, setEditedTitle] = useState(eventPost.title);
  const [editedLink, setEditedLink] = useState(eventPost.link);
  const [editedContent, setEditedContent] = useState(eventPost.content);
  const [editedMedia, setEditedMedia] = useState(eventPost.media);
  const [editedEmbedLink, setEditedEmbedLink] = useState(eventPost.embedLink);
  const [editedVisibility, setEditedVisibility] = useState(eventPost.visibility);
  const [editedShareable, setEditedShareable] = useState(eventPost.shareable);


  const [editedInstances, setEditedInstances] = useState(event.instances);
  useEffect(() => {
    setEditedInstances(editedInstances.map(i => ({
      ...i,
      post: Post.create({
        ...i.post,
        visibility: editedVisibility,
        shareable: editedShareable,
      })
    })))
  }, [editedInstances?.map(i => i.id).join(','), editedVisibility, editedShareable]);

  const [editedAllowRsvps, setEditedAllowRsvps] = useState(event.info?.allowsRsvps ?? false);
  const [editedAllowAnonymousRsvps, setEditedAllowAnonymousRsvps] = useState(event.info?.allowsAnonymousRsvps ?? false);
  const [editedHideLocation, setEditedHideLocation] = useState(event.info?.hideLocationUntilRsvpApproved ?? false);

  const title = editing ? editedTitle : eventPost.title;
  const content = editing ? editedContent : eventPost.content;
  const media = editing ? editedMedia : eventPost.media;
  const embedLink = editing ? editedEmbedLink : eventPost.embedLink;
  const visibility = editing ? editedVisibility : eventPost.visibility;
  const shareable = editing ? editedShareable : eventPost.shareable;
  const instances = editing ? editedInstances : event.instances;

  const hasPastInstances = instances.find(isPastInstance) != undefined;
  const [editingInstance, setEditingInstance] = useState(undefined as EventInstance | undefined);


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

  const rsvpData = useSelector(selectRsvpData(editingOrPrimary(instance => federateId(instance?.id ?? '', event.serverHost))));
  const currentInstanceLocation = editingOrPrimary(instance => {
    if (event.info?.hideLocationUntilRsvpApproved && !instance?.location && rsvpData?.hiddenLocation) {
      return rsvpData?.hiddenLocation;
    }
    return instance?.location ?? Location.create({});
  })
  const setCurrentInstanceLocation = useCallback((location: Location) => {
    if (editingInstance) {
      updateEditingInstance({ ...editingInstance, location });
    }
  }, [editingInstance?.id]);
  // console.log("EventCard", { currentInstanceLocation, rsvpData });
  // const post = useAppSelector(state => state.posts.entities[event.postId]);
  // Retrieve the Instance's post from the Posts store first.
  const storedInstancePost = useAppSelector(state => primaryInstance?.post?.id
    ? state.posts.entities[federateId(primaryInstance?.post?.id, server)]
    : undefined);
  const instancePost = primaryInstance?.post
    ? storedInstancePost ?? federatedEntity(primaryInstance?.post, server)
    : undefined;

  const saveEdits = useCallback(() => {
    if (savingEdits) return;

    requestAnimationFrame(() => {
      setSavingEdits(true);
      dispatch(updateEvent({
        ...accountOrServer,
        ...event,
        info: {
          ...event.info,
          allowsRsvps: editedAllowRsvps,
          allowsAnonymousRsvps: editedAllowRsvps && editedAllowAnonymousRsvps,
          hideLocationUntilRsvpApproved: editedHideLocation,
        },
        post: {
          ...eventPost,
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
        setPreviewingEdits(false);
        setEditedInstances(result.payload?.instances);
      })
        .finally(() => requestAnimationFrame(() => {
          setSavingEdits(false);
        }));
    });
  }, [savingEdits, event, editedAllowRsvps, editedAllowAnonymousRsvps, editedHideLocation, eventPost, editedTitle, editedLink, editedContent, editedMedia, editedVisibility, editedShareable, editedInstances]);

  const addInstance = useCallback(() => {
    const newInstance = { ...defaultEventInstance(), id: `unsynchronized-event-instance-${newEventId++}` };
    setEditedInstances([newInstance, ...editedInstances]);
    setEditingInstance(newInstance);
  }, [editedInstances]);
  const removeInstance = useCallback((target: EventInstance) => {
    if (target.id === editingInstance?.id) {
      setEditingInstance(undefined);
    }
    setEditedInstances(editedInstances.filter(i => i.id != target.id));
  }, [editedInstances]);
  const updateEditingInstance = useCallback((target: EventInstance) => {
    setEditedInstances(editedInstances.map(i => i.id === target.id ? target : i));
    if (target.id === editingInstance?.id) {
      setEditingInstance(target);
    }
  }, [editedInstances, editingInstance]);

  const { setStartTime, setEndTime } = useStartAndEndTime(editingInstance, updateEditingInstance);
  const [deleted, setDeleted] = useState(eventPost.author === undefined);
  const [deleting, setDeleting] = useState(false);
  const doDeletePost = useCallback(() => {
    setDeleting(true);
    dispatch(deleteEvent({ ...accountOrServer, ...event })).then(() => {
      setDeleted(true);
      setDeleting(false);
    });
  }, [accountOrServer, federatedId(event)]);

  const window = useWindowDimensions();
  const visibilityRef = React.createRef<HTMLDivElement>();
  const instanceScrollRef = React.createRef<ScrollView>();
  const isVisible = useIsVisibleHorizontal(visibilityRef);

  const authorId = eventPost.author?.userId;
  const authorName = eventPost.author?.username;

  const primaryInstanceIdString = primaryInstance?.id ?? 'no-primary-instance';
  const detailsLinkId = !isPrimaryServer
    ? federateId(primaryInstanceIdString, accountOrServer.server)
    : primaryInstanceIdString;
  const groupLinkId = selectedGroup ?
    (!isGroupPrimaryServer
      ? federateId(selectedGroup.shortname, accountOrServer.server)
      : selectedGroup.shortname)
    : undefined;
  const eventLink: LinkProps = useLink({
    href: primaryInstance ?
      selectedGroup
        ? `/g/${groupLinkId}/e/${detailsLinkId}`
        : `/event/${detailsLinkId}`
      : '.'
  });
  const { imagePostBackgrounds, fancyPostBackgrounds, shrinkPreviews } = useLocalConfiguration();

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
    ? (horizontal
      ? xs ? 275 : 350
      : 500)
    - (event.info?.allowsRsvps ? 100 : 0)
    - (currentInstanceLocation?.uniformlyFormattedAddress?.length ?? 0 > 0 ? 43 : 0)
    : undefined;
  // console.log({ maxTotalContentHeight })
  const numContentSections = ((content?.length ?? 0) > 0 ? 1 : 0)
    + (embedLink || media.length > 0 ? 1 : 0);
  const maxContentSectionHeight = isPreview ?
    (maxTotalContentHeight! - (maxTotalContentHeight! * (2 - numContentSections) * 0.25)) / numContentSections
    : undefined;

  const onPressDetails = onPress
    ? { onPress, accessibilityRole: "link" } as LinkProps
    : undefined;
  const detailsLink = isPreview ? { ...(onPressDetails ?? eventLink), cursor: 'pointer' } : undefined;
  const postLink = eventPost.link ? useLink({ href: eventPost.link }) : undefined;
  const authorLinkProps = eventPost.author ? authorLink : undefined;
  const contentLengthShadowThreshold = horizontal ? 180 : 700;
  const showDetailsShadow = isPreview && eventPost.content && eventPost.content.length > contentLengthShadowThreshold;
  const detailsShadowProps = showDetailsShadow ? {
    shadowOpacity: 0.3,
    shadowOffset: { width: -5, height: -5 },
    shadowRadius: 10
  } : {};
  const embedSupported = eventPost.embedLink && eventPost.link && eventPost.link.length;
  const embedComponent = useMemo(() => {
    if (embedSupported) {
      const url = new URL(eventPost.link!);
      const hostname = url.hostname.split(':')[0]!;
      if (hostname.endsWith('twitter.com')) {
        return <TwitterEmbed url={eventPost.link!} />;
      } else if (hostname.endsWith('instagram.com')) {
        return <InstagramEmbed url={eventPost.link!} />;
      } else if (hostname.endsWith('facebook.com')) {
        return <FacebookEmbed url={eventPost.link!} />;
      } else if (hostname.endsWith('youtube.com')) {
        return <YouTubeEmbed url={eventPost.link!} />;
      } else if (hostname.endsWith('tiktok.com')) {
        return <TikTokEmbed url={eventPost.link!} />;
      } else if (hostname.endsWith('pinterest.com')) {
        return <PinterestEmbed url={eventPost.link!} />;
      } else if (hostname.endsWith('linkedin.com')) {
        return <LinkedInEmbed url={eventPost.link!} />;
      }
    }
    return undefined;
  }, [embedSupported, eventPost.link]);

  const imagePreview = useMemo(() => media?.find(m => m.contentType.startsWith('image')), [media]);
  const showScrollableMediaPreviews = useMemo(() => (media?.filter(m => !m.generated).length ?? 0) >= 2, [media]);
  const previewUrl = useMediaUrl(imagePreview?.id, accountOrServer);

  const showBackgroundPreview = useMemo(() => !!imagePreview, [imagePreview]);

  const componentKey = useComponentKey('event-card');
  const recommendedHorizontalSize = useMemo(() => (mediaQuery.gtSm ? 400 : 310), [mediaQuery.gtSm]);
  const backgroundSize = useMemo(() => document.getElementById(componentKey)?.clientWidth ?? (
    isPreview && horizontal
      ? recommendedHorizontalSize
      : postBackgroundSize(mediaQuery)
  ), [componentKey, isPreview, horizontal, recommendedHorizontalSize, mediaQuery]);
  const foregroundSize = useMemo(() => backgroundSize * 0.7, [backgroundSize]);

  const author = useMemo(() => eventPost.author, [eventPost.author]);
  const isAuthor = useMemo(() => author && author.userId === currentUser?.id, [author, currentUser?.id]);
  const showEdit = useMemo(() => !!isAuthor && !isPreview && !hideEditControls, [isAuthor, isPreview, hideEditControls]);

  const [scrollInstancesVertically, setScrollInstancesVertically] = useState(false);
  const [showPastInstances, setShowPastInstances] = useState(false);
  const selectedInstanceIsPast = useMemo(() => selectedInstance && moment(selectedInstance.startsAt).isBefore(moment()), [selectedInstance]);
  useEffect(() => {
    if (!showPastInstances && selectedInstanceIsPast) {
      setShowPastInstances(true);
    }
  }, [selectedInstanceIsPast, showPastInstances])

  const canEasilySeeInstances = useCallback((instances: EventInstance[]) => mediaQuery.gtXxs ? instances.length <= 3 : instances.length <= 2, [mediaQuery.gtXxs]);
  const canEasilySeeAllPastInstances = useMemo(() => canEasilySeeInstances(instances), [canEasilySeeInstances, instances]);
  const filteredInstances = useMemo(() => showPastInstances
    ? instances
    : instances.filter(isNotPastInstance), [showPastInstances, instances]);
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
            <Paragraph size="$2" color={navAnchorColor} overflow="hidden" whiteSpace="nowrap" textOverflow="ellipsis">{eventPost.link}</Paragraph>
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
    {/* <YStack key='instances-buttons' my='$2' gap="$3"> */}
    {editing
      ? <Button my='auto' size='$3' circular icon={CalendarPlus} onPress={addInstance} />
      : undefined}
    {hasPastInstances && !canEasilySeeAllPastInstances
      ? <Tooltip placement='bottom-start'>
        <Tooltip.Trigger>
          <Button ml='$2' size='$3' my='auto' disabled={selectedInstanceIsPast}
            {...showPastInstances ? themedButtonBackground(navColor, navTextColor) : {}}
            o={selectedInstanceIsPast ? 0.5 : 1}
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
    ? <XStack my='auto'
      // pointerEvents={'none'}
      overflow='hidden'
      w={shrinkServerInfo ? '$5' : undefined}
      h={shrinkServerInfo ? '$5' : undefined} jc={shrinkServerInfo ? 'center' : undefined} mr='$2'>
      <ServerNameAndLogo server={server} shrinkToSquare={shrinkServerInfo} disableTooltip />
    </XStack>
    : undefined;
  const isGlobalPublicEvent = eventPost.visibility === Visibility.GLOBAL_PUBLIC && instancePost?.visibility === Visibility.GLOBAL_PUBLIC;
  const headerLinksView = <YStack f={1} key='header-links-view'>
    {isPreview
      ? <>
        <XStack>
          <YStack f={1}>
            <Anchor key='details-link' textDecorationLine='none' {...detailsLink}>
              <Heading size="$7" marginRight='auto'>{title}</Heading>
            </Anchor>
            {postLinkView}
          </YStack>
          {serverInfoView}
        </XStack>
        <XStack mr='$2'>
          <Anchor f={1} key='instance-link' textDecorationLine='none' {...detailsLink}>
            {primaryInstance ? <InstanceTime event={event} instance={primaryInstance} highlight noAutoScroll /> : undefined}
          </Anchor>
          {primaryInstance //&& (!isPreview || isVisible)
            ? <XStack my='$1'>
              <EventCalendarExporter tiny event={event}
                instance={primaryInstance}
                showSubscriptions={isGlobalPublicEvent
                  ? {
                    servers: server ? [server] : undefined
                  }
                  : undefined}
              />
            </XStack>
            : undefined}
        </XStack>
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
          {primaryInstance ? <EventCalendarExporter event={event} instance={primaryInstance} /> : undefined}
          {instanceManagementButtons}
        </XStack>
      </>}
  </YStack>;

  const headerLinksEdit = <YStack f={1} gap='$2' key='header-links-edit'>
    <XStack w='100%' gap='$2'>
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

  const contentView = editing || (eventPost.content && eventPost.content) != ''
    ? isPreview
      ? <Anchor key='content-link' textDecorationLine='none' {...detailsLink}>
        <TamaguiMarkdown text={eventPost.content} disableLinks={isPreview} />
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
          location: currentInstanceLocation,
          post: Post.create({
            visibility: eventPost.visibility,
          })
        });
        instances.push(repeatedInstance);
      });
    }
    return instances;
  }, [
    repeatWeeks,
    editingInstance?.startsAt,
    editingInstance?.endsAt, currentInstanceLocation?.uniformlyFormattedAddress
  ]);

  const doRepeatInstance = useCallback(() => {
    setEditedInstances([...editedInstances, ...repeatedInstances]);
    requestAnimationFrame(forceUpdate);
    // setTimeout(forceUpdate, 1);
  }, [editedInstances, repeatedInstances]);

  const renderInstance = useCallback((i: EventInstance) => {
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
                                <Select.Group gap="$0" w='100%'>
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

                    <XStack gap="$3" jc="flex-end">
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
  }, [editing, editedInstances, editingInstance, repeatedInstances, primaryInstance]);


  const deleteDialog = <Dialog key='delete-button-dialog'>
    <Dialog.Trigger asChild>
      <Button key='delete-button' my='auto' size='$2' icon={Delete} transparent
        disabled={deleting} o={deleting ? 0.5 : 1}>
        Delete
      </Button>
    </Dialog.Trigger>
    <Dialog.Portal zi={1000011}>
      <Dialog.Overlay
        key="overlay"
        animation='standard'
        o={0.5}
        enterStyle={{ o: 0 }}
        exitStyle={{ o: 0 }} />
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
          <Dialog.Title>Delete Event</Dialog.Title>
          <Dialog.Description>
            Really delete event? {event.instances.length > 1 ? `All ${event.instances.length} instances will be deleted. ` : undefined}
            The content and title, along with all event instances and RSVPs, will be deleted, and your user account de-associated, but any replies (including quotes) will still be present.
          </Dialog.Description>

          <XStack gap="$3" jc="flex-end">
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
  </Dialog>;
  const shrinkContent = isPreview && (
    forceShrinkPreview ||
    (shrinkPreviews && !ignoreShrinkPreview)
  );
  return (
    <AccountOrServerContextProvider value={accountOrServer}>
      <div ref={visibilityRef} style={{ width: isPreview && horizontal ? recommendedHorizontalSize : '100%' }}>
        <YStack key={`event-card--${imagePostBackgrounds ? '-bg' : ''}-${fancyPostBackgrounds ? '-fancy' : ''}`}
          w={isPreview && horizontal ? recommendedHorizontalSize : '100%'}>
          <Card theme="dark" size="$4" bordered id={componentKey}
            // key={`event-card-${event.id}-${isPreview ? primaryInstance?.id : 'details'}-${isPreview ? '-preview' : ''}`}
            animation='standard'
            borderColor={showServerInfo ? primaryColor : undefined}
            margin='$0'
            marginBottom='$3'
            marginTop='$3'
            padding={0}
            f={isPreview ? undefined : 1}
            // ref={ref}
            scale={1}
            opacity={1}
            y={0}
          // borderColor={primaryAnchorColor}
          >
            {eventPost.link || eventPost.title
              ? <Card.Header p={0}>
                <YStack w='100%'>
                  <XStack ai='center' w='100%'>
                    {/* {isVisible || true? <Eye size='$2' /> : undefined} */}
                    {instancePost
                      ? <StarButton post={instancePost} eventMargins />
                      : undefined}
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
                        ? <XStack key='instance-display' jc='center' animation='standard' {...standardAnimation} gap='$2' flexWrap='wrap' f={1}>
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
                          <Heading size='$2' key='label' f={1} marginVertical='auto'>Start Time</Heading>

                          <XStack ml='auto' my='auto'>
                            <DateTimePicker value={editingInstance.startsAt ?? moment(0).toISOString()} onChange={(v) => setStartTime(v)} />
                          </XStack>
                        </XStack>
                        <XStack mx='$2' key={`endsAt-${editingInstance?.id}`}>
                          <Heading size='$2' key='label' f={1} marginVertical='auto'>End Time</Heading>
                          <XStack ml='auto' my='auto'>
                            <DateTimePicker value={editingInstance.endsAt ?? moment(0).toISOString()} onChange={(v) => setEndTime(v)} />
                          </XStack>
                        </XStack>
                        {endDateInvalid ? <Paragraph size='$2' mx='$2'>Must be after Start Time</Paragraph> : undefined}
                      </>
                      : undefined}

                  </YStack>
                </YStack>
              </Card.Header>
              : undefined}
            <Card.Footer p={0} paddingTop='$2' >
              {deleted
                ? <Paragraph key='deleted-notification' size='$1'>This event has been deleted.</Paragraph>
                : <YStack key='footer-base' zi={1000} width='100%'>
                  <AnimatePresence>
                    {shrinkContent ? undefined
                      : <YStack key='event-content' animation='standard' {...reverseStandardAnimation}
                        pt={0} w='100%' maw={800} mx='auto'>
                        <YStack key='location' px='$3' >
                          {primaryInstance// && (!isPreview || isVisible)
                            ? event.info?.hideLocationUntilRsvpApproved && !rsvpData?.hiddenLocation
                              ? <Paragraph size='$1' my='$1' fontStyle='italic'>Location will be revealed to attendees after RSVP approval.</Paragraph>
                              : <XStack mx='$3' mt='$1'>
                                <LocationControl key='location-control'
                                  location={currentInstanceLocation}
                                  readOnly={!editing || previewingEdits}
                                  preview={isPreview}
                                  link={isPreview ? eventLink : undefined}
                                  setLocation={setCurrentInstanceLocation}
                                // setLocation={(location: Location) => {
                                //   if (editingInstance) {
                                //     updateEditingInstance({ ...editingInstance, location });
                                //   }
                                // }}
                                />
                              </XStack>
                            : undefined}

                        </YStack>
                        <YStack key='media-manager' mah={maxContentSectionHeight} overflow='hidden'>
                          {editing && !previewingEdits
                            ? <PostMediaManager
                              key='media-edit'
                              link={eventPost.link}
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

                              {...{ detailsLink, isPreview, groupContext: selectedGroup }}
                              post={{
                                ...eventPost,
                                media,
                                embedLink
                              }} />}
                        </YStack>
                        <YStack px='$3' key='content' maxHeight={maxContentSectionHeight} overflow='hidden'>
                          {contentView}
                        </YStack>
                        {editing && !previewingEdits
                          ? <YStack px='$3' key='content-editor-toggles'>
                            <ToggleRow key='rsvp-toggle' name='Allow RSVPs'
                              value={editedAllowRsvps} setter={setEditedAllowRsvps} />
                            <ToggleRow key='anonymous-rsvp-toggle' name='Allow Anonymous RSVPs'
                              value={editedAllowRsvps && editedAllowAnonymousRsvps}
                              setter={setEditedAllowAnonymousRsvps}
                              disabled={!editedAllowRsvps} />

                            <ToggleRow key='hide-location-toggle' name='Hide Location from Non-Attendees'
                              value={editedHideLocation} setter={setEditedHideLocation}
                              disabled={!editedAllowRsvps} />
                          </YStack >
                          : undefined}

                      </YStack>
                    }
                  </AnimatePresence>
                  {primaryInstance// && (!isPreview || isVisible)
                    ? <YStack key='rsvp-manager' maw={800} w='100%' px='$1' mx='auto' mt='$1'>
                      <EventRsvpManager
                        key={`rsvp-manager-${(editingInstance ?? primaryInstance)?.id}`}
                        event={event!}
                        isVisible={!isPreview || isVisible}
                        instance={editingInstance ?? primaryInstance}
                        {...{ isPreview, isModalPreview, newRsvpMode, setNewRsvpMode }} />
                    </YStack>
                    : undefined}
                  <AnimatePresence>
                    {shrinkContent ? undefined
                      : <YStack animation='standard' {...standardAnimation}>
                        <XStack key='save-buttons' gap='$2' px='$3' py='$2' pt={0} flexWrap="wrap"
                          flexDirection='row-reverse'>

                          <XStack key='visibility-etc' gap='$2' flexWrap="wrap" ml='auto' my='auto' maw='100%'>
                            <XStack key='visibility-edit' my='auto' ml='auto'>
                              <VisibilityPicker
                                id={`visibility-picker-${eventPost.id}${isPreview ? '-preview' : ''}`}
                                label='Event Visibility'
                                visibility={visibility}
                                onChange={setEditedVisibility}
                                visibilityDescription={v => postVisibilityDescription(v, selectedGroup, server, 'Event')}
                                readOnly={!editing || previewingEdits}
                              />
                            </XStack>
                            <XStack key='shareable-edit' my='auto' ml='auto' pb='$1'>
                              <ShareableToggle value={shareable}
                                isOwner={isAuthor}
                                setter={setEditedShareable}
                                readOnly={!editing || previewingEdits} />
                            </XStack>
                            {/* {isPrimaryServer
                              ?  */}
                            <XStack key='group-post-manager' my='auto' maw='100%' ml='auto'>

                              {disableSharingButton
                                ? <Anchor {...detailsLink}>
                                  <GroupPostManager
                                    post={eventPost}
                                    isVisible={isVisible}
                                    isDisabled />
                                </Anchor> :
                                <GroupPostManager
                                  post={eventPost}
                                  isVisible={isVisible} />}
                            </XStack>
                            {/* : undefined} */}
                          </XStack>
                          {event.id
                            ? <XStack py={showEdit ? '$2' : undefined} gap='$2' mr='auto'>
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

                                    {deleteDialog}
                                  </>
                                : isAuthor
                                  ? <XStack o={0.5}>{deleteDialog}</XStack>
                                  : undefined}
                            </XStack>
                            : undefined}
                        </XStack>

                      </YStack>}
                  </AnimatePresence>

                  <XStack {...detailsShadowProps} key='details' pl='$3' mb='$3'
                    mt={shrinkContent ? '$1' : undefined}>{/*showEdit ? -11 : -15} >*/}
                    <XStack f={1} key='author-details'>
                      <AuthorInfo {...{ post: eventPost }} />
                    </XStack>


                    {showPermalink
                      ? <Button circular icon={Link2} key='details-link' {...detailsLink}
                        my='auto' size='$2' mr='$2' />
                      : undefined}
                    <Anchor key='discussion-anchor' textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                      <YStack key='discussion-anchor-root' h='100%'>
                        <Button key='comments-link-button'
                          opacity={isPreview ? 1 : 0.9}
                          transparent={isPreview || !instancePost?.replyToPostId || instancePost.replyCount == 0}
                          disabled={true}
                          marginVertical='auto'
                          px='$2'
                        >
                          <XStack opacity={0.9}>
                            <YStack marginVertical='auto' scale={0.75}>
                              <Paragraph size="$1" ta='right'>
                                {instancePost?.responseCount ?? 0} comment{(instancePost?.responseCount ?? 0) == 1 ? '' : 's'}
                              </Paragraph>
                              {isPreview || (instancePost?.replyCount ?? 0) == 0 ? undefined : <Paragraph size="$1" ta='right'>
                                {instancePost?.replyCount ?? 0} repl{(instancePost?.replyCount ?? 0) == 1 ? 'y' : 'ies'}
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
            {imagePostBackgrounds ?
              <Card.Background>
                {(showBackgroundPreview) ?
                  <Image
                    pos="absolute"
                    width={backgroundSize}
                    opacity={fancyPostBackgrounds ? 0.11 : 0.04}
                    height={backgroundSize}
                    resizeMode="cover"
                    als="flex-start"
                    source={{ uri: previewUrl!, height: backgroundSize, width: backgroundSize }}
                    blurRadius={fancyPostBackgrounds ? 1.5 : undefined}
                    // borderRadius={5}
                    borderBottomRightRadius={5}
                  />
                  : undefined}
              </Card.Background>
              : undefined}
          </Card >
        </YStack>
      </div>
    </AccountOrServerContextProvider>
  );
};

export default EventCard;

function useStartAndEndTime(instance: EventInstance | undefined, setInstance: (instance: EventInstance) => void) {
  const [startTime, endTime] = [instance?.startsAt, instance?.endsAt]
  const setEndTime = useCallback((value: string) => {
    if (!instance) {
      return;
    }
    const updatedInstance = { ...instance, endsAt: toProtoISOString(value) };
    setInstance(updatedInstance);
  }, [instance]);
  const setStartTime = useCallback((value: string) => {
    if (!instance) {
      return;
    }
    const updatedInstance = { ...instance, startsAt: toProtoISOString(value) };
    setInstance(updatedInstance);
  }, [instance]);
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