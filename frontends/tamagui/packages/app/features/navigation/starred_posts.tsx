import { EventInstance, Post, PostContext } from "@jonline/api";
import { AnimatePresence, Button, Heading, Paragraph, Popover, ScrollView, Spinner, Tooltip, XStack, YStack, standardAnimation, useDebounce, useDebounceValue, useMedia, useTheme } from "@jonline/ui";
import { reverseHorizontalAnimation, reverseStandardAnimation, standardFadeAnimation, standardHorizontalAnimation } from '@jonline/ui/src/animations';
import { ChevronDown, ChevronLeft, ChevronUp, Info, ListEnd, ListStart, MessagesSquare, PanelLeftOpen } from "@tamagui/lucide-icons";
import { AccountOrServerContextProvider } from "app/contexts";
import { useAppDispatch, useAppSelector, useFederatedAccountOrServer, useFederatedDispatch, useCurrentServer } from "app/hooks";
import { FederatedEvent, FederatedPost, accountID, federatedId, getCachedServerClient, getServerClient, getServerTheme, loadEvent, loadPost, moveStarredPostDown, moveStarredPostUp, parseFederatedId, serverID, setDiscussionChatUI, setOpenedStarredPost, useServerTheme } from "app/store";
import { createRef, use, useEffect, useState } from "react";
import FlipMove from "react-flip-move";
import EventCard from "../event/event_card";
import { InstanceTime } from "../event/instance_time";
import { ConversationContextProvider, PostCard, ReplyArea, scrollToCommentsBottom, scrollToCommentsTop, useConversationCommentList, useStatefulConversationContext } from "../post";
import { StarButton, ThemedStar } from "../post/star_button";
import { useLink } from "solito/link";
import { AppSection, menuIcon } from "./features_navigation";
import { highlightedButtonBackground, themedButtonBackground } from "app/utils";
import { Dictionary } from "@reduxjs/toolkit";
import { CreateAccountOrLoginSheet } from "../accounts/create_account_or_login_sheet";
import { ShortAccountSelectorButton } from "./pinned_server_selector";
import { ServerNameAndLogo } from "./server_name_and_logo";
import useIsVisibleHorizontal from "app/hooks/use_is_visible";

type StarredPostFilter = 'posts' | 'events' | undefined;
export type StarredPostsProps = {};
function useStarredPostDetails(postId: string, isVisible?: boolean) {
  const { id: serverPostId, serverHost } = parseFederatedId(postId, useCurrentServer()?.host);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const basePost = useAppSelector(state => state.posts.entities[postId]);
  const isServerReady = accountOrServer?.server
    ? !!getCachedServerClient(accountOrServer.server)
    : false;
  const [loadingServer, setLoadingServer] = useState(false);
  useEffect(() => {
    if (!loadingServer && !isServerReady && accountOrServer?.server && (isVisible ?? true)) {
      getServerClient(accountOrServer?.server).then(() => {
        setTimeout(() =>
          setLoadingServer(false),
          1500
        );
      });
    }

  }, [isServerReady, loadingServer, accountOrServer?.server?.host, isVisible])

  const [loadingPost, setLoadingPost] = useState(false);
  const hasFailedToLoadPost = useAppSelector(state => state.posts.failedPostIds.includes(postId));
  useEffect(() => {
    if (!basePost && isServerReady && !loadingServer && !loadingPost && !hasFailedToLoadPost && postId && (isVisible ?? true)) {
      console.log('StarredPosts: Fetching post', postId);
      setLoadingPost(true);
      dispatch(loadPost({ ...accountOrServer, id: serverPostId! }))
        .then((result) => {
          console.log('StarredPosts: Fetched post', postId, 'result', result);
          setTimeout(() =>
            setLoadingPost(false),
            1500
          );
        });
    }
  }, [basePost?.id, accountID(accountOrServer?.account), serverHost, isServerReady, loadingServer, loadingPost,
    hasFailedToLoadPost, postId, isVisible]);

  const eventInstanceId = useAppSelector(state =>
    basePost?.context === PostContext.EVENT_INSTANCE
      ? state.events.postInstances[postId]
      : undefined
  );
  const event = useAppSelector(state =>
    eventInstanceId
      ? state.events.entities[state.events.instanceEvents[eventInstanceId]!]
      : undefined
  );

  const [loadingEvent, setLoadingEvent] = useState(false);

  const serverEventInstanceId = eventInstanceId
    ? parseFederatedId(eventInstanceId!).id
    : undefined;
  // const { id: serverEventInstanceId } = parseFederatedId(eventInstanceId!);
  const targetInstance: EventInstance | undefined = event?.instances?.find(i => i.id === serverEventInstanceId);
  const eventWithSingleInstance: FederatedEvent | undefined = event && targetInstance
    ? {
      ...event,
      instances: [targetInstance]
    } : undefined;

  useEffect(() => {
    if (isServerReady && basePost?.context === PostContext.EVENT_INSTANCE && !eventWithSingleInstance && !loadingEvent) {
      console.log('StarredPosts: Fetching event by postId', postId);
      setLoadingEvent(true);
      dispatch(loadEvent({ ...accountOrServer, postId: serverPostId! })).then(() => {
        setTimeout(() =>
          setLoadingEvent(false),
          1500
        );
      });
    }
  }, [basePost?.context, eventWithSingleInstance?.id, isServerReady, loadingEvent]);
  return { basePost, eventInstanceId, event, serverPostId, serverHost, serverEventInstanceId, eventWithSingleInstance, isServerReady, loadingServer, loadingPost, loadingEvent };
}

export function StarredPosts({ }: StarredPostsProps) {
  const mediaQuery = useMedia();

  const starredPostIds = useAppSelector(state => (state.app.starredPostIds ?? []));

  const [open, setOpen] = useState(false);
  const [hasOpened, setHasOpened] = useState(open);
  useEffect(() => {
    if (open && !hasOpened) {
      setHasOpened(true);
    }
  }, [hasOpened, open]);
  const openChanged = useDebounceValue(open, 3000);
  useEffect(() => {
    if (!openChanged) {
      setHasOpened(false);
    }
  }, [openChanged])

  // const [openedPostId, setOpenedPostId] = useState<string | undefined>(undefined);
  const openedPostId = useAppSelector(state => state.app.openedStarredPostId);
  const setOpenedPostId = (postId: string | undefined) =>
    dispatch(setOpenedStarredPost(postId));
  const [starredPostFilter, setStarredPostFilter] = useState<StarredPostFilter>(undefined);

  const filteredPostIds = useAppSelector(state => {
    if (starredPostFilter === 'posts') {
      return starredPostIds.map(id => state.posts.entities[id])
        .filter(p => p && p?.context !== PostContext.EVENT_INSTANCE)
        .map(p => federatedId(p!));
    } else if (starredPostFilter === 'events') {
      return starredPostIds.map(id => state.posts.entities[id])
        .filter(p => p?.context === PostContext.EVENT_INSTANCE)
        .map(p => federatedId(p!));
    } else {
      return starredPostIds;
    }
  });

  const starredPostUnreadCounts: Dictionary<number> = useAppSelector(state => {
    const counts = {} as Dictionary<number>;

    state.app.starredPostIds.forEach(id => {
      const lastUnreadCount = state.app.starredPostLastOpenedResponseCounts?.[id] ?? 0;
      const currentCount = state.posts.entities[id]?.responseCount ?? 0;
      counts[id] = currentCount - lastUnreadCount;
    });
    return counts;
  });

  const scrollToTop = (smooth?: boolean) => document.getElementById('starred-post-scroll-top')
    ?.scrollIntoView({ block: 'center', behavior: smooth ? 'smooth' : undefined });
  useEffect(() => {
    if (openedPostId && chatUI) {
      // if (chatUI) {
      setTimeout(() => scrollToCommentsBottom(openedPostId.split('@')[0]!), 1000)
      // } else {
      //   scrollToTop();
      // }
    } else {
      scrollToTop();
    }
  }, [openedPostId])
  const { serverHost, basePost, event, eventInstanceId, eventWithSingleInstance } = useStarredPostDetails(openedPostId ?? '');

  useEffect(() => {
  }, [openedPostId, basePost]);
  const basePostLink = useLink({
    href:
      eventWithSingleInstance
        ? `/event/${eventWithSingleInstance.instances[0]!.id}@${serverHost}`
        : `/post/${basePost?.id}@${serverHost}`
  });
  const basePostLinkWithClose = {
    ...basePostLink, onPress: (e) => {
      basePostLink.onPress?.(e);
      // setOpenedPostId(undefined);
      setOpen(false);
    }
  }
  const openedPostAccount = useFederatedAccountOrServer(basePost);

  const serverTheme = useServerTheme();
  const openedPostAccountTheme = getServerTheme(openedPostAccount?.server, useTheme());
  const { primaryTextColor, navColor, navTextColor } = serverTheme;
  const { primaryAnchorColor: openedPostPrimaryAnchorColor, navAnchorColor: openedPostNavAnchorColor } = openedPostAccountTheme;

  // const openedPostAccount: AccountOrServer | undefined = useAppSelector(state =>
  //   basePost
  //     ? state.accounts.pinnedServers
  //       .find(s => s.serverId.includes(basePost.serverHost))
  //     : undefined);

  const chatUI = useAppSelector(state => state.app.discussionChatUI);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const conversationContext = useStatefulConversationContext();
  const { editingPosts, replyPostIdPath, setReplyPostIdPath, editHandler } = conversationContext;
  const conversationCommentList = useConversationCommentList({
    post: basePost ?? { ...Post.create(), serverHost: accountOrServer.server?.host || 'jonline.io' },
    disableScrollPreserver: true,
    forStarredPost: true,
    conversationContext: conversationContext,
  });
  const showReplyArea = openedPostId && basePost && accountOrServer.account;

  return <AccountOrServerContextProvider value={accountOrServer}>
    <ConversationContextProvider value={conversationContext}>
      <AnimatePresence>
        {starredPostIds.length > 0
          ? <XStack key='starred-posts' animation='standard' {...reverseHorizontalAnimation} exitStyle={{ x: 29, o: 0, }} >

            {/* <Button transparent
              px='$2'
              onPress={() => setOpen(true)}
              color={primaryTextColor}
            >
              <ThemedStar starred invertColors />
            </Button> */}

            <Popover key='popover' size="$5" allowFlip placement='bottom-end' keepChildrenMounted
              open={open} onOpenChange={setOpen}>
              <Popover.Trigger asChild>

                <Button transparent
                  px='$2'
                  onPress={() => setOpen(true)}
                  color={primaryTextColor}
                >
                  <ThemedStar starred invertColors />
                </Button>
              </Popover.Trigger>

              {hasOpened
                ? <Popover.Content
                  borderWidth={1}
                  // px={0}
                  pr='$2'
                  pl='$2'
                  borderColor="$borderColor"
                  enterStyle={{ y: -10, opacity: 0 }}
                  exitStyle={{ y: -10, opacity: 0 }}
                  elevate
                  animation={[
                    'quick',
                    {
                      opacity: {
                        overshootClamping: true,
                      },
                    },
                  ]}
                >
                  <Popover.Arrow borderWidth={1} borderColor="$borderColor" />

                  <YStack gap="$3" h='100%' ai='center'>
                    <FlipMove style={{ width: '100%', display: 'flex', flexDirection: 'row', alignItems: 'center', flexWrap: 'none' }}>
                      {openedPostId
                        ? [
                          <div key='back'>
                            <Button circular size='$3' mr='$2' onPress={() => setOpenedPostId(undefined)} icon={ChevronLeft} />
                          </div>,
                          // <div key='flex-1' style={{ flex: 1 }} />
                        ] : [
                          <div key='posts-filter'>
                            <Button icon={menuIcon(AppSection.POSTS, starredPostFilter === 'posts' ? navTextColor : undefined)}
                              onPress={() => setStarredPostFilter(
                                starredPostFilter === 'posts' ? undefined : 'posts'
                              )}
                              transparent
                              {...highlightedButtonBackground(serverTheme, 'nav', starredPostFilter === 'posts')}
                            />
                          </div>,
                          <div key='events-filter' style={{ marginRight: 10 }}>
                            <Button icon={menuIcon(AppSection.EVENTS, starredPostFilter === 'events' ? navTextColor : undefined)}
                              onPress={() => setStarredPostFilter(
                                starredPostFilter === 'events' ? undefined : 'events'
                              )}
                              transparent
                              {...highlightedButtonBackground(serverTheme, 'nav', starredPostFilter === 'events')}
                            />
                          </div>,
                        ]}
                      {basePost
                        ? <div key='post-name' style={{ flex: 1 }}>
                          <Button transparent onPress={() => scrollToTop(true)} >
                            <YStack>
                              <Paragraph size='$1'
                                maw={Math.min(400, window.innerWidth - 150 - (eventWithSingleInstance ? 80 : 0))}
                                overflow='hidden' textOverflow='ellipsis' whiteSpace='nowrap'
                                fontWeight='bold' my='auto' animation='standard' o={0.7} f={1}>
                                {event?.post?.title ?? basePost?.title ?? 'Loading...'}
                              </Paragraph>
                            </YStack>
                          </Button>
                        </div>
                        : <div key='starred-heading' style={{ flex: 1 }}>

                          <Tooltip>
                            <Tooltip.Trigger>
                              <FlipMove style={{ width: '100%' }}>
                                <div key='starred'>
                                  <XStack ai='center' gap='$2'>
                                    <Heading size='$4'>Starred</Heading>
                                    <Info size={16} o={0.5} />
                                  </XStack>
                                </div>
                                {starredPostFilter === 'posts'
                                  ?
                                  <div key='starred-posts'>
                                    <Heading size='$5' whiteSpace="nowrap">Posts</Heading>
                                  </div>
                                  : starredPostFilter === 'events'
                                    ?
                                    <div key='starred-events'>
                                      <Heading size='$5' whiteSpace="nowrap">Events</Heading>
                                    </div>
                                    : undefined}
                              </FlipMove>
                            </Tooltip.Trigger>
                            <Tooltip.Content>
                              <Paragraph size='$1' >
                                Starred Posts/Events are stored only in your current browser.
                              </Paragraph>
                              <Paragraph size='$1' >
                                The are never associated with your profile or any personal information.
                              </Paragraph>
                              <Paragraph size='$1' >
                                Server star counts are anonymous.
                              </Paragraph>
                            </Tooltip.Content>
                          </Tooltip>
                        </div>}
                      {/* <div key='flex-2' style={{ flex: 1 }} /> */}

                      {eventWithSingleInstance
                        ? <div key='instance-time'>
                          <InstanceTime instance={eventWithSingleInstance.instances[0]!} event={eventWithSingleInstance} />
                        </div>
                        : basePost
                          ? undefined//<div key='flex-3' style={{ flex: 1 }} />
                          : undefined}
                    </FlipMove>
                    {openedPostId && basePost //&& basePost.responseCount > 0
                      ? <XStack animation='standard' {...standardAnimation} key='chat-ui-toggle'
                        w='100%' maw={800} mx='auto' mt='$1' ai='center'>
                        <XStack key='spacer1' f={1} />
                        <Tooltip key='discussionUI' placement="bottom">
                          <Tooltip.Trigger>
                            <Button h='$2' px='$2'
                              backgroundColor={chatUI ? undefined : navColor}
                              hoverStyle={{ backgroundColor: chatUI ? undefined : navColor }}
                              transparent={chatUI}
                              borderTopRightRadius={0} borderBottomRightRadius={0}

                              icon={<ListEnd color={chatUI ? undefined : navTextColor} transform={[{ rotate: '180deg' }]} />}
                              onPress={() => {
                                dispatch(setDiscussionChatUI(false));
                                scrollToCommentsTop(openedPostId);
                              }}
                              mr={0}>
                              <Heading size='$4' color={chatUI ? undefined : navTextColor}>Discussion</Heading>
                            </Button>
                          </Tooltip.Trigger>
                          <Tooltip.Content>
                            <Heading size='$2'>Newest on top.</Heading>
                            <Heading size='$1'>Grouped into threads.</Heading>
                          </Tooltip.Content>
                        </Tooltip>

                        <Tooltip key='chatUI' placement="bottom">
                          <Tooltip.Trigger>
                            <Button h='$2' px='$2'
                              backgroundColor={!chatUI ? undefined : navColor}
                              hoverStyle={{ backgroundColor: !chatUI ? undefined : navColor }}
                              transparent={!chatUI}
                              iconAfter={<ListEnd color={!chatUI ? undefined : navTextColor} />}
                              borderTopLeftRadius={0} borderBottomLeftRadius={0}
                              onPress={() => {
                                dispatch(setDiscussionChatUI(true));
                                if (chatUI)
                                  scrollToCommentsBottom(openedPostId);
                                else
                                  setTimeout(() => scrollToCommentsBottom(openedPostId), 800);
                              }}>
                              <Heading size='$4' color={!chatUI ? undefined : navTextColor}>Chat</Heading>
                            </Button>
                          </Tooltip.Trigger>
                          <Tooltip.Content>
                            <Heading size='$2'>Newest on bottom.</Heading>
                            <Heading size='$1'>Sorted by time.</Heading>
                          </Tooltip.Content>
                        </Tooltip>
                        <XStack key='spacer2' f={1} />



                        {/* {basePost ? */}
                        <Button
                          h='$2' px='$2' ml='$2'
                          // onPress={() => setOpen(false)}
                          {...basePostLinkWithClose}
                          iconAfter={PanelLeftOpen} >
                          <Heading size='$4'>Open</Heading>
                        </Button>
                        {/* : undefined} */}
                      </XStack>
                      : undefined}
                    {/* </AnimatePresence> */}
                    <ScrollView
                      w={Math.max(100, Math.min(650, window.innerWidth - 50))}
                      h={Math.max(100, Math.min(650, window.innerHeight - 280 - (showReplyArea ? mediaQuery.gtXxxs ? 200 : 100 : 0)))}
                    >
                      <FlipMove style={{ alignItems: 'center' }}>
                        <div id='starred-post-scroll-top' key='starred-post-scroll-top' style={{ height: 0 }} />
                        {filteredPostIds.length === 0
                          ? <div key='no-starred-posts' style={{
                            display: 'flex',
                            marginLeft: 'auto',
                            marginRight: 'auto',
                            marginTop: Math.max(50, Math.min(350, window.innerHeight - 150)) / 2 - 50,
                          }}>
                            <Paragraph size='$3' w='100%' ta='center' o={0.5}>
                              {starredPostFilter === 'events'
                                ? 'No starred events.'
                                : 'No starred posts.'}
                            </Paragraph>
                          </div>
                          : undefined}

                        {openedPostId// && basePost
                          ? [
                            <div key={`fullsize-starred-post-card-${openedPostId}`} style={{ width: '100%' }}>
                              <StarredPostCard key='fullsize-post' {...{ postId: openedPostId }} fullSize />
                            </div>,
                            basePost ? conversationCommentList : undefined
                          ]
                          : filteredPostIds.map((postId) =>
                            <div key={`starred-post-card-${postId}`} style={{ width: '100%' }}>
                              <XStack w='100%'
                                animation='standard' {...standardAnimation}>
                                <StarredPostCard {...{ postId, onOpen: setOpenedPostId }}
                                  unsortable={!!starredPostFilter} />
                              </XStack>
                            </div>)}

                      </FlipMove>
                    </ScrollView>

                    {/* {openedPostId && basePost
                        ? <> */}
                    <ReplyArea replyingToPath={replyPostIdPath}
                      onStopReplying={() => openedPostId && setReplyPostIdPath([openedPostId])}
                      hidden={!showReplyArea} />
                    {/* </>
                        : undefined} */}
                  </YStack>
                </Popover.Content>
                : undefined}
            </Popover >

            <XStack key='count' pointerEvents="none" o={0.7}
              position='absolute' right={0} top={0}
              borderRadius={30} minWidth={20}
              backgroundColor={navColor} >
              <XStack key='left-space' f={1} />
              <Paragraph key='count-value' fontWeight='900' size='$3' ta='center' color={navTextColor}>
                {starredPostIds.length}
              </Paragraph>
              <XStack key='right-space' f={1} />
            </XStack>
          </XStack>
          : undefined}
      </AnimatePresence>

    </ConversationContextProvider>
  </AccountOrServerContextProvider>;
}


export type StarredPostCardProps = {
  postId: string;
  onOpen?: (postId: string) => void;
  fullSize?: boolean;
  unsortable?: boolean;
  unreadCount?: number;
};
export function StarredPostCard({ postId, onOpen, fullSize, unsortable, unreadCount }: StarredPostCardProps) {
  const mediaQuery = useMedia();
  const dispatch = useAppDispatch();

  const visibilityRef = createRef<HTMLDivElement>();
  const isVisible = useIsVisibleHorizontal(visibilityRef);

  const {
    basePost,
    eventInstanceId,
    serverPostId,
    serverHost,
    eventWithSingleInstance,
    isServerReady,
    loadingServer,
    loadingPost,
    loadingEvent
  } = useStarredPostDetails(postId, isVisible);

  const server = useFederatedAccountOrServer(serverHost)?.server;
  const pinnedServer = useAppSelector(state => state.accounts.pinnedServers.find(s => server && s.serverId === serverID(server)));
  const { navColor, navTextColor, navAnchorColor } = getServerTheme(server, useTheme());

  const { canMoveUp, canMoveDown } = useAppSelector(state => ({
    canMoveUp: state.app.starredPostIds.indexOf(postId) > 0,
    canMoveDown: state.app.starredPostIds.indexOf(postId) < state.app.starredPostIds.length - 1,
  }));

  function moveUp() {
    dispatch(moveStarredPostUp(postId));
  }
  function moveDown() {
    dispatch(moveStarredPostDown(postId));
  }

  let renderedCardView: JSX.Element;
  if (eventWithSingleInstance) {
    renderedCardView = <EventCard
      event={eventWithSingleInstance}
      isPreview={!fullSize} forceShrinkPreview
      onPress={() => onOpen?.(postId)}
    />;
  } else if (basePost) {
    renderedCardView = <YStack w='100%'>
      {basePost.context === PostContext.EVENT_INSTANCE
        ? loadingEvent
          ? <XStack>
            <Spinner color={navAnchorColor} />
            <Paragraph ml='$2' size='$1' o={0.5} mb={-10}>Loading event data...</Paragraph>
          </XStack>
          : <Paragraph size='$1' o={0.5} mb={-10}>Post is for an Event Instance.</Paragraph>
        : undefined}
      <PostCard
        post={basePost}
        isPreview={!fullSize} forceShrinkPreview
        onPress={() => onOpen?.(postId)}
      />
    </YStack>;
  } else {
    renderedCardView = <XStack w='100%'
      pl='$5'
      animation='standard' {...standardAnimation} jc='center' ai='center'>
      <XStack mb={-20}>
        <StarButton post={{ ...Post.create({ id: serverPostId }), serverHost }} />
      </XStack>
      {isServerReady && !loadingServer && !loadingPost
        ? <Paragraph size='$3' ta='center' o={0.5}>Post {postId} not found</Paragraph>
        : <>
          <Spinner color={navAnchorColor} />
          <Paragraph size='$3' ml='$2' o={0.5}>Post {postId} is loading...</Paragraph>
        </>}
      <XStack w='$3' h='$3' ml='auto'>
        <ServerNameAndLogo server={server} shrinkToSquare />
      </XStack>
    </XStack>;
  }
  const chatUI = useAppSelector(state => state.app.discussionChatUI);
  const renderedCard = <YStack w='100%' key={`starred-post-${postId}`}>
    {server && (pinnedServer?.accountId || !basePost) ?
      <XStack ml='auto' mr='$9' mb={-10}>
        <ShortAccountSelectorButton {...{ server, pinnedServer }} />
        {/* <SingleServerAccountsSheet
          server={server}

          button={(onPress) => <ShortAccountSelectorButton {...{ server, pinnedServer, onPress }} />}
        /> */}
      </XStack>
      : undefined}

    <XStack w='100%' ai='center' gap='$2'>
      <AnimatePresence>
        <XStack f={1} key='card-view'>
          {renderedCardView}
        </XStack>
        {fullSize ? undefined :
          <YStack key='side-buttons' ai='center' gap='$2' my='$1' animation='standard' {...standardHorizontalAnimation}>
            <Button key='moveUp' size='$2' circular
              animation='standard'
              disabled={unsortable || !canMoveUp}
              o={unsortable ? 0 : canMoveUp ? 1 : 0.5}
              transform={[{ translateY: unsortable ? 10 : 0 }]}
              pointerEvents={unsortable ? 'none' : undefined}
              onPress={(e) => { e.stopPropagation(); moveUp(); }}
              icon={ChevronUp} />

            <Button h='auto' px='$2' py='$1' onPress={() => {
              onOpen?.(postId);
              setTimeout(
                () => chatUI
                  ? scrollToCommentsBottom(postId)
                  : scrollToCommentsTop(postId),
                2000
              );
            }}>
              <YStack ai='center'>
                {(unreadCount ?? 0) > 0
                  ? <>
                    <Paragraph size='$1' o={0.5}
                      backgroundColor={navColor}
                      color={navTextColor}
                    >{unreadCount} unread</Paragraph>
                    {/* <ListStart size='$1' /> */}
                  </>
                  : undefined}
                <MessagesSquare size='$1' />
                <Paragraph size='$1' o={0.5}>{basePost?.responseCount}</Paragraph>
              </YStack>
            </Button>
            <Button key='moveDown' size='$2' circular
              animation='standard'
              disabled={unsortable || !canMoveDown}
              o={unsortable ? 0 : canMoveDown ? 1 : 0.5}
              transform={[{ translateY: unsortable ? -10 : 0 }]}
              pointerEvents={unsortable ? 'none' : undefined}
              onPress={(e) => { e.stopPropagation(); moveDown(); }}
              icon={ChevronDown} />
          </YStack>
        }</AnimatePresence>
    </XStack >
  </YStack>;

  return <div ref={visibilityRef} style={{ width: '100%' }}>{renderedCard}</div>;
}
