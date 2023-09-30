import { deleteEvent, deletePost, loadMedia, loadUser, RootState, selectMediaById, selectUserById, updateEvent, updatePost, useAccount, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useRef, useState } from "react";
import { Platform, View } from "react-native";
import { useIsVisible } from 'app/hooks/use_is_visible';

import { Event, EventInstance, Group, Media } from "@jonline/api";
import { Anchor, Text, Button, Card, Heading, Image, Paragraph, ScrollView, createFadeAnimation, TamaguiElement, Theme, useMedia, XStack, YStack, Dialog, TextArea, Input, useWindowDimensions } from "@jonline/ui";
import { useMediaUrl } from "app/hooks/use_media_url";
import moment from "moment";
import { useLink } from "solito/link";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { InstanceTime } from "./instance_time";
import { instanceTimeSort, isNotPastInstance, isPastInstance } from "app/utils/time";
import { Repeat, Delete, Edit, Eye, History, Save, CalendarPlus, X as XIcon } from "@tamagui/lucide-icons";
import icons from "@tamagui/lucide-icons";
import { GroupPostManager } from "../post/group_post_manager";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from "react-social-media-embed";
import { MediaRenderer } from "../media/media_renderer";
import { FadeInView } from "../post/fade_in_view";
import { postBackgroundSize } from "../post/post_card";
import { defaultEventInstance } from "./create_event_sheet";

interface Props {
  event: Event;
  selectedInstance?: EventInstance;
  isPreview?: boolean;
  groupContext?: Group;
  horizontal?: boolean;
}

export const EventCard: React.FC<Props> = ({ event, selectedInstance, isPreview, groupContext, horizontal }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const media = useMedia();
  const currentUser = useAccount()?.user;
  const post = event.post!;

  const { server, primaryColor, navAnchorColor: navColor, backgroundColor: themeBgColor, primaryAnchorColor, navAnchorColor } = useServerTheme();
  const [editing, setEditing] = useState(false);
  const [previewingEdits, setPreviewingEdits] = useState(false);
  const [savingEdits, setSavingEdits] = useState(false);

  const [editedTitle, setEditedTitle] = useState(post.title);
  const title = editing ? editedTitle : post.title;
  const [editedContent, setEditedContent] = useState(post.content);
  const content = editing ? editedContent : post.content;
  const [editedInstances, setEditedInstances] = useState(event.instances);
  const instances = editing ? editedInstances : event.instances;
  console.log('instances', instances);
  const [editingInstance, setEditingInstance] = useState(undefined as EventInstance | undefined);

  const endDateInvalid = editingInstance && !moment(editingInstance.endsAt).isAfter(moment(editingInstance.startsAt));
  const instance = editingInstance ?? selectedInstance ?? (instances.length === 1 ? instances[0] : undefined);

  function saveEdits() {
    setSavingEdits(true);
    dispatch(updateEvent({
      ...accountOrServer,
      ...event,
      post: { ...post, title: editedTitle, content: editedContent }
    })).then(() => {
      setEditing(false);
      setSavingEdits(false);
      setPreviewingEdits(false);
    });
  }

  function addInstance() {
    setEditedInstances([EventInstance.create(defaultEventInstance()), ...editedInstances]);
  }
  function removeInstance(target: EventInstance) {
    setEditedInstances(editedInstances.filter(i => i.id != target.id));
  }
  function updateInstance(target: EventInstance) {
    setEditedInstances(editedInstances.map(i => i.id == target.id ? target : i));
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
      ? instance
        ? `/g/${groupContext.shortname}/e/${event.id}/i/${instance!.id}`
        : `/g/${groupContext.shortname}/e/${event.id}`
      : instance
        ? `/event/${event.id}/i/${instance!.id}`
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
  const createGroupEventViewHref = (group: Group) => instance
    ? `/g/${group.shortname}/e/${event.id}/i/${instance!.id}`
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
    ? (media.gtSm ? 400 : 310)
    : postBackgroundSize(media);
  const foregroundSize = backgroundSize * 0.7;

  const author = post.author;
  const isAuthor = author && author.userId === currentUser?.id;
  const showEdit = isAuthor && !isPreview;
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

  const [showPastInstances, setShowPastInstances] = useState(false);
  const sortedFilteredInstances = (showPastInstances
    ? [...instances]
    : instances
      .filter(isNotPastInstance)
  ).sort(instanceTimeSort);
  const displayedInstances = editingInstance
    ? [editingInstance, ...sortedFilteredInstances.filter(i => i.id != editingInstance.id)]
    : sortedFilteredInstances;
  const hasPastInstances = instances.find(isPastInstance) != undefined;
  const headerLinks = (post.link?.length ?? 0) > 0
    ? <>
      <YStack>
        <Anchor textDecorationLine='none' {...(editing ? {} : postLink)}>
          <XStack>
            <YStack f={1}>
              {editing && !previewingEdits
                ?
                <Input textContentType="name" placeholder={`Event Title (required)`}
                  disabled={savingEdits} opacity={savingEdits || editedTitle == '' ? 0.5 : 1}
                  autoCapitalize='words'
                  value={editedTitle}
                  onChange={(data) => { setEditedTitle(data.nativeEvent.text) }} />
                : <Heading size="$7" color={navColor} marginRight='auto'>{post.title}</Heading>}
            </YStack>
          </XStack>
        </Anchor>
        {editing
          ? undefined
          : isPreview
            ? <Anchor textDecorationLine='none' {...detailsLink}>
              {instance ? <InstanceTime event={event} instance={instance} highlight={editing} /> : undefined}
            </Anchor>
            : instance ? <InstanceTime event={event} instance={instance} highlight={editing} /> : undefined}
      </YStack>
    </>
    : isPreview
      ? <Anchor textDecorationLine='none' {...detailsLink}>
        <YStack>
          <XStack>
            <YStack f={1}>
              <Heading size="$7" marginRight='auto'>{post.title}</Heading>
            </YStack>
          </XStack>
          {instance ? <InstanceTime event={event} instance={instance} /> : undefined}
        </YStack>
      </Anchor>
      : <YStack>
        <XStack>
          <YStack f={1}>
            <Heading size="$7" marginRight='auto'>{post.title}</Heading>
          </YStack>
        </XStack>
        {instance ? <InstanceTime event={event} instance={instance} /> : undefined}
      </YStack>;

  const contentView = post.content && post.content != ''
    ? isPreview
      ? <Anchor textDecorationLine='none' {...detailsLink}>
        <TamaguiMarkdown text={post.content} disableLinks={isPreview} />
      </Anchor>
      : editing && !previewingEdits
        ? <TextArea f={1} pt='$2' value={content}
          disabled={savingEdits} opacity={savingEdits || content == '' ? 0.5 : 1}
          onChangeText={t => setEditedContent(t)}
          placeholder={`Text content (optional). Markdown is supported.`} />
        : content && content != ''
          ? <TamaguiMarkdown text={content} disableLinks={isPreview} />
          : undefined
    : undefined;

  return (
    <>
      <YStack w='100%' key={`event-card-${event.id}-${instance?.id}-${isPreview ? '-preview' : ''}`}>
        <Card theme="dark" elevate size="$4" bordered
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
              <YStack>
                {headerLinks}

                {!isPreview && (instances.length > 1 || editing)
                  ? <XStack w='100%' mt='$2' ml='$4' space>
                    {hasPastInstances
                      ? <Theme inverse={showPastInstances}>
                        <Button my='auto' mr={-7} size='$3' circular={(displayedInstances?.length ?? 0) > 0} icon={History}
                          onPress={() => setShowPastInstances(!showPastInstances)} >
                          {(displayedInstances?.length ?? 0) === 0 ? 'Show Past Instances' : undefined}
                        </Button>
                      </Theme>
                      : undefined}
                    <ScrollView f={1} horizontal pb='$3'>
                      <XStack mt='$1'>
                        {/* {displayedInstances?.length == 0 && hasPastInstances
                        ? <Heading size="$1" mt='$2' color={primaryColor} mr='$2'>⬅️ Press "show past instances" to show past instances.</Heading>
                          : undefined } */}
                        {displayedInstances?.map((i) =>
                          <YStack mx={editing ? '$2' : undefined}>
                            <InstanceTime key={i.id} linkToInstance={!editing}
                              event={event} instance={i}
                              highlight={i.id == instance?.id}
                            />
                            {editing
                              ? <XStack w='100%'>
                                <Theme inverse={editingInstance?.id === i.id}>
                                  <Button mx='auto' mt='$2' size='$2' circular icon={Edit} onPress={() => setEditingInstance(i.id !== editingInstance?.id ? i : undefined)} />
                                </Theme>
                                <Dialog>
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
                                          {/* <YStack> */}
                                          <Paragraph size="$2">Repeat for:</Paragraph>
                                          {/* </YStack> */}
                                          <XStack> <Text fontFamily='$body'>weeks</Text></XStack>
                                        </Dialog.Description>

                                        <XStack space="$3" jc="flex-end">
                                          <Dialog.Close asChild>
                                            <Button>Cancel</Button>
                                          </Dialog.Close>
                                          <Theme inverse>
                                            <Button onPress={() => ({})}>Repeat</Button>
                                          </Theme>
                                          {/* </Dialog.Action> */}
                                        </XStack>
                                      </YStack>
                                    </Dialog.Content>
                                  </Dialog.Portal>
                                </Dialog>
                                <Button mx='auto' mt='$2' size='$2' circular icon={Delete} onPress={() => removeInstance(i)} />
                              </XStack>
                              : undefined}
                          </YStack>)}
                      </XStack>
                    </ScrollView>
                    {editing
                      ? <Button my='auto' mr='$4' size='$3' circular icon={CalendarPlus} onPress={addInstance} />
                      : undefined}
                  </XStack>
                  : undefined

                }
                {editingInstance
                  ? <>
                    <XStack mx='$2' key={editingInstance?.id}>
                      <Heading size='$2' f={1} marginVertical='auto'>Start Time</Heading>
                      <Text fontSize='$2' fontFamily='$body'>
                        <input type='datetime-local' style={{ padding: 10 }} 
                          value={editingInstance.startsAt}
                          onChange={(v) => {
                            const updatedInstance = { ...editingInstance, startsAt: v.target.value };
                            updateInstance(updatedInstance);
                            //  setStartTime(v.target.value)
                          }} />
                      </Text>
                    </XStack>
                    <XStack mx='$2' key={editingInstance?.id}>
                      <Heading size='$2' f={1} marginVertical='auto'>End Time</Heading>
                      <Text fontSize='$2' fontFamily='$body'>

                      <input type='datetime-local' style={{ padding: 10 }} 
                          value={editingInstance.endsAt}
                          onChange={(v) => {
                            const updatedInstance = { ...editingInstance, endsAt: v.target.value };
                            updateInstance(updatedInstance);
                          }} />                      </Text>
                    </XStack>
                    {endDateInvalid ? <Paragraph size='$2' mx='$2'>Must be after Start Time</Paragraph> : undefined}
                  </>
                  : undefined}
              </YStack>
            </Card.Header>
            : undefined}
          <Card.Footer p='$3' pr={media.gtXs ? '$3' : '$1'} >
            {deleted
              ? <Paragraph size='$1'>This event has been deleted.</Paragraph>
              : <YStack zi={1000} width='100%' {...footerProps}>
                {hasBeenVisible && embedComponent
                  ? <FadeInView><div>{embedComponent}</div></FadeInView>
                  : undefined}
                {showScrollableMediaPreviews ?
                  <XStack w='100%' maw={800}>
                    <ScrollView horizontal w={isPreview ? '260px' : '100%'}
                      h={media.gtXs ? '400px' : '260px'} >
                      <XStack space='$2'>
                        {post.media.map((mediaRef, i) => <YStack key={mediaRef.id} w={media.gtXs ? '400px' : '260px'} h='100%'>
                          <MediaRenderer media={mediaRef} />
                        </YStack>)}
                      </XStack>
                    </ScrollView>
                  </XStack> : undefined}
                <YStack maxHeight={maxContentHeight} overflow='hidden' {...contentProps}>
                  {singleMediaPreview
                    // (!isPreview && previewUrl && previewUrl != '' && hasGeneratedPreview) 
                    ? <Image
                      mb='$3'
                      width={foregroundSize}
                      height={foregroundSize}
                      resizeMode="contain"
                      als="center"
                      source={{ uri: previewUrl, height: foregroundSize, width: foregroundSize }}
                      borderRadius={10}
                    /> : undefined}
                  {contentView}
                </YStack>
                <XStack space='$2' flexWrap="wrap">
                  {showEdit
                    ? editing
                      ? <>
                        <Button my='auto' size='$2' icon={Save} onPress={saveEdits} color={primaryAnchorColor} disabled={savingEdits} transparent>
                          Save
                        </Button>
                        <Button my='auto' size='$2' icon={XIcon} onPress={() => setEditing(false)} disabled={savingEdits} transparent>
                          Cancel
                        </Button>
                        {previewingEdits
                          ? <Button my='auto' size='$2' icon={Edit} onPress={() => setPreviewingEdits(false)} color={navAnchorColor} disabled={savingEdits} transparent>
                            Edit
                          </Button>
                          :
                          <Button my='auto' size='$2' icon={Eye} onPress={() => setPreviewingEdits(true)} color={navAnchorColor} disabled={savingEdits} transparent>
                            Preview
                          </Button>}
                      </>
                      : <>
                        <Button my='auto' size='$2' icon={Edit} onPress={() => setEditing(true)} disabled={deleting} transparent>
                          Edit
                        </Button>

                        <Dialog>
                          <Dialog.Trigger asChild>
                            <Button my='auto' size='$2' icon={Delete} disabled={deleting} transparent>
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
                  <XStack pt={10} ml='auto' px='$2' maw='100%'>
                    <GroupPostManager post={post} isVisible={isVisible}
                      createViewHref={createGroupEventViewHref} />
                  </XStack>
                </XStack>
                <XStack {...detailsProps}>
                  <AuthorInfo {...{ post, detailsMargins, isVisible }} />
                  <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                    <YStack h='100%' mr='$3'>
                      <Button opacity={isPreview ? 1 : 0.9} transparent={isPreview || !post?.replyToPostId || post.replyCount == 0}

                        disabled={true}
                        marginVertical='auto'
                        mr={media.gtXs || isPreview ? 0 : -10}
                        // onPress={toggleReplies} 
                        px='$2'
                      >
                        <XStack opacity={0.9}>
                          <YStack marginVertical='auto'>
                            {!post.replyToPostId ? <Heading size="$1" ta='right'>
                              {post.responseCount} comment{post.responseCount == 1 ? '' : 's'}
                            </Heading> : undefined}
                            {(post.replyToPostId) && (post.responseCount != post.replyCount) ? <Heading size="$1" ta='right'>
                              {post.responseCount} response{post.responseCount == 1 ? '' : 's'}
                            </Heading> : undefined}
                            {isPreview || post.replyCount == 0 ? undefined : <Heading size="$1" ta='right'>
                              {post.replyCount} repl{post.replyCount == 1 ? 'y' : 'ies'}
                            </Heading>}
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
