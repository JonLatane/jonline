import { deleteEvent, deletePost, loadMedia, loadUser, RootState, selectMediaById, selectUserById, updateEvent, updatePost, useAccount, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { Platform, View } from "react-native";
import { useIsVisible } from 'app/hooks/use_is_visible';

import { Event, EventInstance, Group, Media, Visibility } from "@jonline/api";
import { Anchor, Text, Button, Card, Heading, Image, Paragraph, ScrollView, createFadeAnimation, TamaguiElement, Theme, useMedia, XStack, YStack, Dialog, TextArea, Input, useWindowDimensions, Select, getFontSize, Sheet, Adapt, ZStack, AnimatePresence, standardAnimation, reverseStandardAnimation, standardHorizontalAnimation } from "@jonline/ui";
import { useMediaUrl } from "app/hooks/use_media_url";
import moment from "moment";
import { useLink } from "solito/link";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { InstanceTime } from "./instance_time";
import { instanceTimeSort, isNotPastInstance, isPastInstance } from "app/utils/time";
import { Repeat, Delete, Edit, Eye, History, Save, CalendarPlus, X as XIcon, Link, Check, ChevronDown, ChevronUp, ChevronRight, Menu, Scroll } from "@tamagui/lucide-icons";
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
import { RsvpMode } from "./event_rsvp_manager";
import { ToggleRow } from "app/components/toggle_row";
import { themedButtonBackground } from "app/utils/themed_button_background";

interface Props {
  event: Event;
  selectedInstance?: EventInstance;
  isPreview?: boolean;
  groupContext?: Group;
  horizontal?: boolean;
  hideEditControls?: boolean;
  onEditingChange?: (editing: boolean) => void;
}

let newEventId = 0;

export const EventCard: React.FC<Props> = ({
  event,
  selectedInstance,
  isPreview,
  groupContext,
  horizontal,
  hideEditControls,
  onEditingChange,
}) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const mediaQuery = useMedia();
  const currentUser = useAccount()?.user;
  const post = event.post!;

  const { server, textColor, primaryColor, primaryTextColor, navColor, navAnchorColor, navTextColor, backgroundColor: themeBgColor, primaryAnchorColor } = useServerTheme();
  const [editing, _setEditing] = useState(false);
  function setEditing(value: boolean) {
    _setEditing(value);
    onEditingChange?.(value);
  }
  const [previewingEdits, setPreviewingEdits] = useState(false);
  const [savingEdits, setSavingEdits] = useState(false);

  const [editedTitle, setEditedTitle] = useState(post.title);
  const title = editing ? editedTitle : post.title;
  const [editedContent, setEditedContent] = useState(post.content);
  const [editedMedia, setEditedMedia] = useState(post.media);
  const [editedEmbedLink, setEditedEmbedLink] = useState(post.embedLink);
  const [editedVisibility, setEditedVisibility] = useState(post.visibility);
  const visibility = editing ? editedVisibility : post.visibility;
  const [editedAllowRsvps, setEditedAllowRsvps] = useState(event.info?.allowsRsvps ?? false);
  const [editedAllowAnonymousRsvps, setEditedAllowAnonymousRsvps] = useState(event.info?.allowsAnonymousRsvps ?? false);

  const content = editing ? editedContent : post.content;
  const media = editing ? editedMedia : post.media;
  const embedLink = editing ? editedEmbedLink : post.embedLink;
  const [editedInstances, setEditedInstances] = useState(event.instances);
  const instances = editing ? editedInstances : event.instances;
  // console.log('instances', instances);
  const [editingInstance, setEditingInstance] = useState(undefined as EventInstance | undefined);
  const [repeatWeeks, setRepeatWeeks] = useState(1);

  const endDateInvalid = editingInstance && !moment(editingInstance.endsAt).isAfter(moment(editingInstance.startsAt));
  const primaryInstance = /*editingInstance ??*/
    editing && previewingEdits && !editedInstances.some(i => i.id === selectedInstance?.id)
      ? undefined
      : selectedInstance ?? (instances.length === 1 ? instances[0] : undefined);

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
        content: editedContent,
        media: editedMedia,
        visibility: editedVisibility
      },
      instances: editedInstances,
    })).then(result => {
      setEditing(false);
      setSavingEdits(false);
      setPreviewingEdits(false);
      setEditedInstances(event.instances);
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

  const eventLink = useLink({
    href: groupContext
      ? primaryInstance
        ? `/g/${groupContext.shortname}/e/${event.id}/i/${primaryInstance!.id}`
        : `/g/${groupContext.shortname}/e/${event.id}`
      : primaryInstance
        ? `/event/${event.id}/i/${primaryInstance!.id}`
        : `/event/${event.id}`,
    // instance
    //   ? groupContext
    //     ? `/g/${groupContext.shortname}/e/${event.id}/i/${instance!.id}`
    //     : `/event/${event.id}/i/${instance!.id}`
    //   : groupContext
    //     ? `/g/${groupContext.shortname}/e/${event.id}`
    //     : `/event/${event.id}`,
  });
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : `/user/${authorId}`
  });
  const createGroupEventViewHref = (group: Group) => primaryInstance
    ? `/g/${group.shortname}/e/${event.id}/i/${primaryInstance!.id}`
    : `/g/${group.shortname}/e/${event.id}`;

  const maxContentHeight = isPreview ? horizontal ? 100 : 300 : undefined;
  const detailsLink = isPreview ? eventLink : undefined;
  const postLink = post.link ? useLink({ href: post.link }) : undefined;
  const authorLinkProps = post.author ? authorLink : undefined;
  const contentLengthShadowThreshold = horizontal ? 180 : 700;
  const showDetailsShadow = isPreview && post.content && post.content.length > contentLengthShadowThreshold;
  const detailsMargins = showDetailsShadow ? 20 : 0;
  const footerProps = isPreview ? {
    // ml: -detailsMargins,
    mr: -detailsMargins,
  } : {};
  const contentProps = isPreview ? {
    // ml: detailsMargins,
    // mr: 2 * detailsMargins,
  } : {};
  const detailsProps = isPreview ? showDetailsShadow ? {
    ml: -detailsMargins,
    mr: -2 * detailsMargins,
    pr: 1 * detailsMargins,
    mb: -detailsMargins,
    pb: detailsMargins,
    shadowOpacity: 0.3,
    shadowOffset: { width: -5, height: -5 },
    shadowRadius: 10
  } : {
    mr: -20,
  } : {
    // mr: -2 * detailsMargins,
  };
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

  const generatedPreview = post?.media?.find(m => m.contentType.startsWith('image') && m.generated);
  const hasGeneratedPreview = generatedPreview && post?.media?.length == 1 && !embedComponent;

  const scrollableMediaMinCount = isPreview && hasGeneratedPreview ? 3 : 2;
  const showScrollableMediaPreviews = (post?.media?.length ?? 0) >= scrollableMediaMinCount;
  const singleMediaPreview = showScrollableMediaPreviews
    ? undefined
    : post?.media?.find(m => m.contentType.startsWith('image') && (!m.generated /*|| !isPreview*/));
  const previewUrl = useMediaUrl(hasGeneratedPreview ? generatedPreview?.id : undefined);

  const showBackgroundPreview = hasGeneratedPreview;// hasBeenVisible && isPreview && hasPrimaryImage && previewUrl;
  const backgroundSize = isPreview && horizontal
    ? (mediaQuery.gtSm ? 400 : 310)
    : postBackgroundSize(mediaQuery);
  const foregroundSize = backgroundSize * 0.7;

  const author = post.author;
  const isAuthor = author && author.userId === currentUser?.id;
  const showEdit = isAuthor && !isPreview && !hideEditControls;
  // const authorAvatar = useTypedSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useTypedSelector((state: RootState) => authorId ? state.users.failedUserIds.includes(authorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
  useEffect(() => {
    if (hasBeenVisible && authorId) {
      if (!loadingAuthor && !author && !authorLoadFailed) {
        setLoadingAuthor(true);
        setTimeout(() => dispatch(loadUser({ id: authorId, ...accountOrServer })), 1);
      } else if (loadingAuthor && author) {
        setLoadingAuthor(false);
      }
    }
  }, [authorId, loadingAuthor, author, authorLoadFailed]);

  const [scrollInstancesVertically, setScrollInstancesVertically] = useState(false);
  const [showPastInstances, setShowPastInstances] = useState(false);

  const canEasilySeeInstances = (instances: EventInstance[]) => mediaQuery.gtXxs ? instances.length <= 3 : instances.length <= 2;
  const canEasilySeeAllPastInstances = canEasilySeeInstances(instances);
  const filteredInstances = showPastInstances
    ? instances
    : instances.filter(isNotPastInstance);
  const sortedFilteredInstances = [...filteredInstances].sort(instanceTimeSort);
  const canEasilySeeAllInstances = canEasilySeeInstances(sortedFilteredInstances);
  const arrangedInstances = canEasilySeeAllPastInstances
    ? instances
    : canEasilySeeAllInstances
      ? sortedFilteredInstances
      : editing || scrollInstancesVertically || canEasilySeeAllInstances
        ? sortedFilteredInstances
        : [
          ...(selectedInstance ? [selectedInstance] : []),
          ...sortedFilteredInstances.filter(i => i.id != selectedInstance?.id)
        ];

  const displayedInstances = selectedInstance && !editing
    ? arrangedInstances.map(i => i.id).includes(selectedInstance.id ?? 'undefinedid')
      ? arrangedInstances
      : [selectedInstance, ...arrangedInstances]
    : arrangedInstances;
  ;
  // Old displayedInstances:
  //editingInstance
  //? [editingInstance, ...sortedFilteredInstances.filter(i => i.id != editingInstance.id)]
  //: 
  // sortedFilteredInstances
  const hasPastInstances = instances.find(isPastInstance) != undefined;
  const postLinkView = postLink
    ? <Anchor key='post-link' textDecorationLine='none' {...(editing ? {} : postLink)} target="_blank">
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
  const headerLinksView = <YStack f={1} key='header-links-view'>
    {isPreview
      ? <>
        <Anchor key='details-link' textDecorationLine='none' {...detailsLink}>
          <XStack>
            <YStack f={1}>
              <Heading size="$7" marginRight='auto'>{title}</Heading>
            </YStack>
          </XStack>
        </Anchor>
        {postLinkView}
        <Anchor key='instance-link' textDecorationLine='none' {...detailsLink}>
          {primaryInstance ? <InstanceTime event={event} instance={primaryInstance} highlight /> : undefined}
        </Anchor>
      </>
      : <>
        <XStack key='title'>
          <YStack f={1}>
            <Heading size="$7" marginRight='auto'>{title}</Heading>
          </YStack>
        </XStack>
        {postLinkView}
        {primaryInstance
          ? displayedInstances.length > 1 ? undefined : <InstanceTime key='instance-time' event={event} instance={primaryInstance} highlight />
          : editing && previewingEdits
            ? <Paragraph key='missing-instance' size='$1'>This instance no longer exists.</Paragraph>
            : undefined}
      </>}
  </YStack>;
  const headerLinksEdit = <YStack f={1} space='$2' key='header-links-edit'>
    <Input textContentType="name" placeholder={`Event Title (required)`}
      disabled={savingEdits} opacity={savingEdits || editedTitle == '' ? 0.5 : 1}
      autoCapitalize='words'
      value={editedTitle}
      onChange={(data) => { setEditedTitle(data.nativeEvent.text) }} />
    {postLinkView}
  </YStack>;

  const headerLinks = <XStack w='100%'>
    {editing && !previewingEdits ? headerLinksEdit : headerLinksView}
    {canEasilySeeAllInstances
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
      </Button>}
  </XStack>;

  const contentView = editing || (post.content && post.content) != ''
    ? isPreview
      ? <Anchor key='content-link' textDecorationLine='none' {...detailsLink}>
        <TamaguiMarkdown text={post.content} disableLinks={isPreview} />
      </Anchor>
      : editing && !previewingEdits
        ? <TextArea key='content-editor' f={1} pt='$2' value={content}
          disabled={savingEdits} opacity={savingEdits || content == '' ? 0.5 : 1}
          h={(editedContent?.length ?? 0) > 300 ? Math.max(120, window.height - 100) : undefined}

          onChangeText={t => setEditedContent(t)}
          placeholder={`Text content (optional). Markdown is supported.`} />
        : content && content != ''
          ? <TamaguiMarkdown key='content' text={content} disableLinks={isPreview} />
          : undefined
    : undefined;

  const weeklyRepeatOptions = [...Array(52).keys()];
  const forceUpdate = React.useReducer(() => ({}), {})[1] as () => void

  const repeatedInstances = useMemo(() => {
    const instances: EventInstance[] = [];
    if (editingInstance) {
      [...Array(repeatWeeks).keys()].map(i => i + 1).forEach(weeksAfter => {
        const repeatedInstance = EventInstance.create({
          id: `unsynchronized-event-instance-${newEventId++}`,
          startsAt: moment(editingInstance.startsAt).add(weeksAfter, 'weeks').toISOString(),
          endsAt: moment(editingInstance.endsAt).add(weeksAfter, 'weeks').toISOString()
        });
        instances.push(repeatedInstance);
      });
    }
    return instances;
  }, [repeatWeeks, editingInstance?.startsAt, editingInstance?.endsAt]);

  function doRepeatInstance() {
    // const repeatedInstances: EventInstance[] = [];
    // [...Array(repeatWeeks).keys()].map(i => i + 1).forEach(weeksAfter => {
    //   const repeatedInstance = EventInstance.create({
    //     id: `${newEventId++}`,
    //     startsAt: moment(editingInstance!.startsAt).add(weeksAfter, 'weeks').toISOString(),
    //     endsAt: moment(editingInstance!.endsAt).add(weeksAfter, 'weeks').toISOString()
    //   });
    //   repeatedInstances.push(repeatedInstance);
    // });
    setEditedInstances([...editedInstances, ...repeatedInstances]);
    setTimeout(forceUpdate, 1);
  }

  function renderInstance(i: EventInstance) {
    const isPrimary = i.id == primaryInstance?.id;
    const isEditingInstance = i.id == editingInstance?.id;
    const highlight = editing ? isEditingInstance : isPrimary;
    let result = <YStack key={`instance-${i.id}`} mx={editing ? '$2' : undefined} animation='standard' {...standardHorizontalAnimation} o={highlight ? 1 : 0.5} mb={scrollInstancesVertically ? '$2' : undefined}>
      <InstanceTime key={i.id} linkToInstance={!editing}
        event={event} instance={i}
        highlight={highlight}
      />
      {editing
        ? <XStack w='100%'>
          <Theme inverse={editingInstance?.id === i.id}>
            <Button mx='auto' mt='$2' size='$2' circular icon={Edit} onPress={() => setEditingInstance(i.id !== editingInstance?.id ? i : undefined)} />
          </Theme>
          {i.id == editingInstance?.id
            ? <Dialog>
              <Dialog.Trigger asChild>
                <Button mx='auto' mt='$2' size='$2' circular icon={Repeat} onPress={() => setEditingInstance(i)} />
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
            ? <Button mx='auto' mt='$2' size='$2' circular icon={Delete} onPress={() => removeInstance(i)} />
            : undefined}
        </XStack>
        : undefined}
    </YStack>;

    if (editing) {
      result = <YStack ml='$2' h={100}
        padding='$2'
        borderRadius='$3' backgroundColor='$backgroundStrong'>
        {result}
      </YStack>
    }

    return result;
  }
  return (
    <>
      <YStack w='100%' key={`event-card-${event.id}-${primaryInstance?.id}-${isPreview ? '-preview' : ''}`}>
        <Card theme="dark" elevate size="$4" bordered
          key='event-card'
          margin='$0'
          marginBottom='$3'
          marginTop='$3'
          f={isPreview ? undefined : 1}
          ref={ref!}
          scale={1}
          opacity={1}
          y={0}
        >
          {post.link || post.title
            ? <Card.Header>
              <YStack w='100%'>
                {headerLinks}
                {!isPreview && (instances.length > 1 || editing)
                  ? <XStack key='instances' w='100%' mt='$2' ml='$4' space>
                    <YStack key='instances-buttons' my='$2' space="$3">
                      {hasPastInstances && !canEasilySeeAllPastInstances
                        ? <Button mr={-7} size='$3'
                          {...showPastInstances ? themedButtonBackground(navColor, navTextColor) : {}}
                          // color={showPastInstances ? navAnchorColor : undefined}
                          circular={(displayedInstances?.length ?? 0) > 0} icon={History}
                          onPress={() => setShowPastInstances(!showPastInstances)} >
                          {(displayedInstances?.length ?? 0) === 0 ? 'Show Past Instances' : undefined}
                        </Button>
                        : undefined}
                      {editing
                        ? <Button mt='$2' size='$3' circular icon={CalendarPlus} onPress={addInstance} />
                        : undefined}
                    </YStack>

                    {scrollInstancesVertically
                      ? <XStack key='instance-display' animation='standard' {...standardAnimation} space='$2' flexWrap='wrap' f={1}>
                        <AnimatePresence>
                          {displayedInstances?.map((i) => renderInstance(i))}
                        </AnimatePresence>
                      </XStack>
                      : <ScrollView key='instance-scroller' animation='standard' {...reverseStandardAnimation} f={1} horizontal pb='$3'>
                        <XStack mt='$1'>
                          <AnimatePresence>
                            {displayedInstances?.map((i) => renderInstance(i))}
                          </AnimatePresence>
                        </XStack>
                      </ScrollView>}

                  </XStack>
                  : undefined
                }
                {editingInstance && editing && !previewingEdits
                  ? <>
                    <XStack mx='$2' key={`startsAt-${editingInstance?.id}`}>
                      <Heading size='$2' f={1} marginVertical='auto'>Start Time</Heading>
                      <Text fontSize='$2' fontFamily='$body'>
                        <input type='datetime-local' style={{ padding: 10 }}
                          min={supportDateInput(moment(0))}
                          value={supportDateInput(moment(editingInstance.startsAt))}
                          onChange={(v) => {
                            const updatedInstance = { ...editingInstance, startsAt: toProtoISOString(v.target.value) };
                            updateEditingInstance(updatedInstance);
                            //  setStartTime(v.target.value)
                          }} />
                      </Text>
                    </XStack>
                    <XStack mx='$2' key={`endsAt-${editingInstance?.id}`}>
                      <Heading size='$2' f={1} marginVertical='auto'>End Time</Heading>
                      <Text fontSize='$2' fontFamily='$body' color={textColor}>
                        <input type='datetime-local' style={{ padding: 10 }}
                          min={editingInstance.startsAt}
                          value={supportDateInput(moment(editingInstance.endsAt))}
                          onChange={(v) => {
                            const updatedInstance = { ...editingInstance, endsAt: toProtoISOString(v.target.value) };
                            updateEditingInstance(updatedInstance);
                          }} />
                      </Text>
                    </XStack>
                    {endDateInvalid ? <Paragraph size='$2' mx='$2'>Must be after Start Time</Paragraph> : undefined}
                  </>
                  : undefined}
              </YStack>
            </Card.Header>
            : undefined}
          <Card.Footer p='$3' pr={mediaQuery.gtXs ? '$3' : '$1'} >
            {deleted
              ? <Paragraph key='deleted-notification' size='$1'>This event has been deleted.</Paragraph>
              : <YStack key='footer-base' zi={1000} width='100%' {...footerProps}>
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
                    horizontalPreview={horizontal && isPreview}
                    {...{
                      post: {
                        ...post,
                        media,
                        embedLink
                      }, isPreview, groupContext, hasBeenVisible
                    }} />}
                {/* {hasBeenVisible && embedComponent
                  ? <FadeInView><div>{embedComponent}</div></FadeInView>
                  : undefined}
                {showScrollableMediaPreviews ?
                  <XStack w='100%' maw={800}>
                    <ScrollView horizontal w={isPreview ? '260px' : '100%'}
                      h={mediaQuery.gtXs ? '400px' : '260px'} >
                      <XStack space='$2'>
                        {post.media.map((mediaRef, i) => <YStack key={mediaRef.id} w={mediaQuery.gtXs ? '400px' : '260px'} h='100%'>
                          <MediaRenderer media={mediaRef} />
                        </YStack>)}
                      </XStack>
                    </ScrollView>
                  </XStack> : undefined} */}
                <YStack key='content' maxHeight={maxContentHeight} overflow='hidden' {...contentProps}>
                  {/* {singleMediaPreview
                    // (!isPreview && previewUrl && previewUrl != '' && hasGeneratedPreview) 
                    ? <Image
                      mb='$3'
                      width={foregroundSize}
                      height={foregroundSize}
                      resizeMode="contain"
                      als="center"
                      source={{ uri: previewUrl, height: foregroundSize, width: foregroundSize }}
                      borderRadius={10}
                    /> : undefined} */}
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
                <XStack space='$2' flexWrap="wrap" key='save-buttons'>
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

                        <Dialog key='delete-button'>
                          <Dialog.Trigger asChild>
                            <Button my='auto' size='$2' icon={Delete} transparent
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
                                  {/* <Dialog.Action asChild> */}
                                  <Theme inverse>
                                    <Button onPress={doDeletePost}>Delete</Button>
                                  </Theme>
                                  {/* </Dialog.Action> */}
                                </XStack>
                              </YStack>
                            </Dialog.Content>
                          </Dialog.Portal>
                        </Dialog>
                      </>
                    : undefined}

                  {editing && !previewingEdits
                    ? <XStack key='visibility-edit' mt='$2' ml='$2'>
                      <VisibilityPicker
                        id={`visibility-picker-${post.id}${isPreview ? '-preview' : ''}`}
                        label='Post Visibility'
                        visibility={visibility}
                        onChange={setEditedVisibility}
                        visibilityDescription={v => postVisibilityDescription(v, groupContext, server, 'event')} />
                    </XStack>
                    : visibility != Visibility.GLOBAL_PUBLIC && !horizontal
                      ? <Paragraph key='visibility-info' size='$1' my='auto' ml='$2'>
                        {postVisibilityDescription(visibility, groupContext, server, 'Event')}
                      </Paragraph>
                      : undefined}
                  <XStack pt={10} ml='auto' my='auto' px='$2' maw='100%'>
                    <GroupPostManager post={post} isVisible={isVisible}
                      createViewHref={createGroupEventViewHref} />
                  </XStack>
                </XStack>
                <XStack {...detailsProps} key='details'>
                  <AuthorInfo key='author-details' {...{ post, detailsMargins, isVisible }} />
                  <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                    <YStack h='100%' mr='$3'>
                      <Button opacity={isPreview ? 1 : 0.9} transparent={isPreview || !post?.replyToPostId || post.replyCount == 0}

                        disabled={true}
                        marginVertical='auto'
                        mr={isPreview ? horizontal ? '$1' : '$2' : undefined}
                        // onPress={toggleReplies} 
                        px='$2'
                      >
                        <XStack opacity={0.9}>
                          <YStack marginVertical='auto' scale={0.75}>
                            <Paragraph size="$1" ta='right'>
                              {post.responseCount} comment{post.responseCount == 1 ? '' : 's'}
                            </Paragraph>
                            {/* {(post.replyToPostId) && (post.responseCount != post.replyCount) ? <Paragraph size="$1" ta='right'>
                              {post.responseCount} response{post.responseCount == 1 ? '' : 's'}
                            </Paragraph> : undefined} */}
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
                  opacity={0.15}
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
    </>
  );
};

export default EventCard;
