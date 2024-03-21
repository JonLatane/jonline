import { EventInstance, Post, PostContext } from "@jonline/api";
import { AnimatePresence, Button, Heading, Paragraph, Popover, ScrollView, Tooltip, XStack, YStack, standardAnimation, useMedia, useTheme } from "@jonline/ui";
import { reverseHorizontalAnimation, standardFadeAnimation, standardHorizontalAnimation } from '@jonline/ui/src/animations';
import { ChevronDown, ChevronLeft, ChevronUp, ListEnd, ListStart, MessagesSquare, PanelLeftOpen } from "@tamagui/lucide-icons";
import { AccountOrServerContextProvider } from "app/contexts";
import { useAppDispatch, useAppSelector, useFederatedAccountOrServer, useFederatedDispatch, useServer } from "app/hooks";
import { FederatedEvent, accountID, getServerTheme, loadEvent, loadPost, moveStarredPostDown, moveStarredPostUp, parseFederatedId, setDiscussionChatUI, useServerTheme } from "app/store";
import { useEffect, useState } from "react";
import FlipMove from "react-flip-move";
import EventCard from "../event/event_card";
import { InstanceTime } from "../event/instance_time";
import { ConversationContextProvider, PostCard, ReplyArea, scrollToCommentsBottom, scrollToCommentsTop, useConversationCommentList, useStatefulConversationContext } from "../post";
import { StarButton, ThemedStar } from "../post/star_button";
import { useLink } from "solito/link";

export type StarredPostsProps = {};
function useStarredPostDetails(postId: string) {
  const { id: serverPostId, serverHost } = parseFederatedId(postId, useServer()?.host);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const basePost = useAppSelector(state => state.posts.entities[postId]);
  useEffect(() => {
    if (!basePost) {
      console.log('StarredPosts: Fetching post', postId);
      dispatch(loadPost({ ...accountOrServer, id: serverPostId! }));
    }
  }, [basePost, accountID(accountOrServer?.account), serverHost]);

  // const post = useAppSelector(state => state.posts.entities[postId]) as FederatedPost;
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

  // const [loadedEvent, setLoadedEvent] = useState(false);

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
    if (basePost?.context === PostContext.EVENT_INSTANCE && !eventWithSingleInstance) {
      console.log('StarredPosts: Fetching event by postId', postId);
      dispatch(loadEvent({ ...accountOrServer, postId: serverPostId! }));
    }
  }, [basePost, eventWithSingleInstance]);
  return { basePost, eventInstanceId, event, serverPostId, serverHost, serverEventInstanceId, eventWithSingleInstance };
}

export function StarredPosts({ }: StarredPostsProps) {
  const mediaQuery = useMedia();

  const starredPostIds = useAppSelector(state => (state.app.starredPostIds ?? []));

  const [open, setOpen] = useState(false);
  const [openedPostId, setOpenedPostId] = useState<string | undefined>(undefined);
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
          ? <XStack animation='standard' {...reverseHorizontalAnimation} exitStyle={{ x: 29, o: 0, }} >


            <Popover size="$5" allowFlip placement='bottom-end' keepChildrenMounted open={open} onOpenChange={setOpen}>
              <Popover.Trigger asChild><Button transparent
                // icon={Pin}
                px='$2'
                onPress={() => setOpen(!open)}
                color={primaryTextColor}
              >
                <ThemedStar starred invertColors />
              </Button>
              </Popover.Trigger>

              <Popover.Content
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
                  <FlipMove style={{ width: '100%', display: 'flex', flexDirection: 'row', alignItems: 'center' }}>
                    {openedPostId
                      ? <div key='back'>
                        <Button onPress={() => setOpenedPostId(undefined)} icon={ChevronLeft} />
                      </div>
                      : undefined}
                    <div key='flex-1' style={{ flex: 1 }} />
                    {basePost
                      ? <div key='post-name'>
                        <Button onPress={() => scrollToTop(true)} >
                          <YStack>
                            <Paragraph size='$1'
                              maw={Math.min(400, window.innerWidth - 200 - (eventWithSingleInstance ? 100 : 0))}
                              overflow='hidden' textOverflow='ellipsis' whiteSpace='nowrap'
                              fontWeight='bold' my='auto' animation='standard' o={0.7} f={1}>
                              {event?.post?.title ?? basePost?.title ?? 'Loading...'}
                            </Paragraph>
                            {openedPostAccount?.account
                              ?
                              <XStack o={0.5}>
                                <Paragraph size='$1' fontWeight='bold' >
                                  as&nbsp;
                                </Paragraph>
                                <Paragraph size='$1' fontWeight='bold' color={openedPostNavAnchorColor}>
                                  {openedPostAccount.account?.user?.username ?? 'anonymous'}
                                </Paragraph>
                                <Paragraph size='$1' fontWeight='bold' >
                                  @
                                </Paragraph>
                                <Paragraph size='$1' fontWeight='bold' color={openedPostPrimaryAnchorColor}>
                                  {openedPostAccount.server!.host}
                                </Paragraph>
                              </XStack>
                              : undefined}
                          </YStack>
                        </Button>
                      </div>
                      : <div key='starred-heading'>
                        <Heading size='$5'>Starred</Heading>
                      </div>}
                    <div key='flex-2' style={{ flex: 1 }} />

                    {eventWithSingleInstance
                      ? <div key='instance-time'>
                        <InstanceTime instance={eventWithSingleInstance.instances[0]!} event={eventWithSingleInstance} />
                      </div>
                      : basePost
                        ? undefined//<div key='flex-3' style={{ flex: 1 }} />
                        : undefined}
                    {basePost ? <Button
                      size='$3' px='$1'
                      // onPress={() => setOpen(false)}
                      {...basePostLink}
                      icon={PanelLeftOpen} /> : undefined}
                  </FlipMove>
                  {openedPostId && basePost //&& basePost.responseCount > 0
                    ? <XStack animation='standard' {...standardAnimation} key='chat-ui-toggle'
                      w='100%' maw={800} mx='auto' mt='$1' ai='center'>
                      <XStack f={1} />
                      <Tooltip placement="bottom">
                        <Tooltip.Trigger>
                          <Button h='$2'
                            backgroundColor={chatUI ? undefined : navColor}
                            hoverStyle={{ backgroundColor: chatUI ? undefined : navColor }}
                            transparent={chatUI}
                            borderTopRightRadius={0} borderBottomRightRadius={0}

                            icon={<ListEnd transform={[{ rotate: '180deg' }]} />}
                            onPress={() => {
                              dispatch(setDiscussionChatUI(false));
                              scrollToCommentsTop(openedPostId.split('@')[0]!);
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

                      <Tooltip placement="bottom">
                        <Tooltip.Trigger>
                          <Button h='$2'
                            backgroundColor={!chatUI ? undefined : navColor}
                            hoverStyle={{ backgroundColor: !chatUI ? undefined : navColor }}
                            transparent={!chatUI}
                            iconAfter={ListEnd}
                            borderTopLeftRadius={0} borderBottomLeftRadius={0}
                            onPress={() => {
                              dispatch(setDiscussionChatUI(true));
                              if (chatUI)
                                scrollToCommentsBottom(openedPostId.split('@')[0]!);
                              else
                                setTimeout(() => scrollToCommentsBottom(openedPostId.split('@')[0]!), 800);
                            }}>
                            <Heading size='$4' color={!chatUI ? undefined : navTextColor}>Chat</Heading>
                          </Button>
                        </Tooltip.Trigger>
                        <Tooltip.Content>
                          <Heading size='$2'>Newest on bottom.</Heading>
                          <Heading size='$1'>Sorted by time.</Heading>
                        </Tooltip.Content>
                      </Tooltip>
                      <XStack f={1} />
                    </XStack>
                    : undefined}
                  {/* </AnimatePresence> */}
                  <ScrollView
                    w={Math.max(100, Math.min(650, window.innerWidth - 50))}
                    h={Math.max(100, Math.min(650, window.innerHeight - 280 - (showReplyArea ? mediaQuery.gtXxxs ? 200 : 100 : 0)))}
                  >
                    <FlipMove style={{ alignItems: 'center' }}>
                      <div id='starred-post-scroll-top' key='starred-post-scroll-top' style={{ height: 0 }} />
                      {starredPostIds.length === 0
                        ? <div key='no-starred-posts' style={{
                          display: 'flex',
                          marginLeft: 'auto',
                          marginRight: 'auto',
                          marginTop: Math.max(50, Math.min(350, window.innerHeight - 150)) / 2 - 50,
                        }}>
                          <Paragraph size='$3' w='100%' ta='center' o={0.5}>No starred Posts.</Paragraph>
                        </div>
                        : undefined}

                      {openedPostId && basePost
                        ? <>
                          <div key={`fullsize-starred-post-card-${openedPostId}`} style={{ width: '100%' }}>
                            <StarredPostCard key='fullsize-post' {...{ postId: openedPostId }} fullSize />
                          </div>
                          {conversationCommentList}
                        </>
                        : starredPostIds.map((postId) =>
                          <div key={`starred-post-card-${postId}`} style={{ width: '100%' }}>
                            <XStack w='100%'
                              animation='standard' {...standardAnimation}>
                              <StarredPostCard {...{ postId, onOpen: setOpenedPostId }} />
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
            </Popover >

            <XStack pointerEvents="none" o={0.7}
              position='absolute' right={0} top={0}
              borderRadius={30} minWidth={20}
              backgroundColor={navColor} >
              <XStack f={1} />
              <Paragraph fontWeight='900' size='$3' ta='center' color={navTextColor}>
                {starredPostIds.length}
              </Paragraph>
              <XStack f={1} />
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
};
export function StarredPostCard({ postId, onOpen, fullSize }: StarredPostCardProps) {
  const mediaQuery = useMedia();
  const dispatch = useAppDispatch();

  const { basePost, eventInstanceId, event, serverPostId, serverHost, serverEventInstanceId, eventWithSingleInstance } = useStarredPostDetails(postId);

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
        ? <Paragraph size='$1' o={0.5} mb={-10}>Event instance {eventInstanceId}</Paragraph>
        : undefined}
      <PostCard
        post={basePost}
        isPreview={!fullSize} forceShrinkPreview
        onPress={() => onOpen?.(postId)}
      />
    </YStack>;
  } else {
    renderedCardView = <XStack w='100%'
      animation='standard' {...standardAnimation} jc='center' ai='center'>
      <StarButton post={{ ...Post.create({ id: serverPostId }), serverHost }} />
      <Paragraph size='$3' ta='center' o={0.5}>Post {postId} not found.</Paragraph>
    </XStack>;
  }
  const renderedCard = <XStack w='100%' key={`starred-post-${postId}`} ai='center' gap='$2'>

    <AnimatePresence>
      <XStack f={1} key='card-view'>
        {renderedCardView}
      </XStack>
      {fullSize ? undefined :
        <YStack key='side-buttons' ai='center' gap='$2' my='$1' animation='standard' {...standardHorizontalAnimation}>
          <Button size='$2' circular
            disabled={!canMoveUp} o={canMoveUp ? 1 : 0.5}
            onPress={(e) => { e.stopPropagation(); moveUp(); }}
            icon={ChevronUp} />

          <Button h='auto' px='$2' py='$1' onPress={() => onOpen?.(postId)}>
            <YStack ai='center'>
              <MessagesSquare size='$1' />
              <Paragraph size='$1' o={0.5}>{basePost?.responseCount}</Paragraph>
            </YStack>
          </Button>

          <Button size='$2' circular
            disabled={!canMoveDown} o={canMoveDown ? 1 : 0.5}
            onPress={(e) => { e.stopPropagation(); moveDown(); }}
            icon={ChevronDown} />
        </YStack>
      }
    </AnimatePresence>
  </XStack>
  return renderedCard;
}