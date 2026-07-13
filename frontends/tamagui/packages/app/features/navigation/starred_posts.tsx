import { Post, PostContext } from "@jonline/api";
import { Button, Heading, Paragraph, Popover, ScrollView, Tooltip, XStack, YStack, standardAnimation, useDebounceValue, useMedia } from "@jonline/ui";
import { reverseHorizontalAnimation } from '@jonline/ui/src/animations';
import { createSelector } from "@reduxjs/toolkit";
import { ChevronLeft, Fullscreen, Info, ListEnd, PanelLeftOpen } from "@tamagui/lucide-icons";
import { AccountOrServerContextProvider } from "app/contexts";
import { Selector, useAppSelector, useFederatedAccountOrServer, useFederatedDispatch } from "app/hooks";
import { RootState, federatedId, setDiscussionChatUI, setOpenedStarredPost, useServerTheme } from "app/store";
import { highlightedButtonBackground } from "app/utils";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useLink } from "solito/link";
import { InstanceTime } from "../event/instance_time";
import { AutoAnimatedList, ConversationContextProvider, ReplyArea, scrollToCommentsBottom, scrollToCommentsTop, useConversationCommentList, useReplyAncestors, useStatefulConversationContext } from "../post";
import { ThemedStar } from "../post/star_button";
import { AppSection, menuIcon } from "./features_navigation";
import { StarredPostCard, useStarredPostDetails } from "./starred_post_card";

type StarredPostFilter = 'posts' | 'events' | undefined;


const selectFilteredPostIds = (
  starredPostFilter: StarredPostFilter
): Selector<{ filteredPostIds: string[], hasPosts: boolean, hasEvents: boolean }> =>
  createSelector(
    [(state: RootState) => {
      const { starredPostIds } = state.config;
      let filteredPostIds: string[];
      if (starredPostFilter === 'posts') {
        filteredPostIds = starredPostIds.map(id => state.posts.entities[id])
          .filter(p => p && p?.context !== PostContext.EVENT_INSTANCE)
          .map(p => federatedId(p!));
      } else if (starredPostFilter === 'events') {
        filteredPostIds = starredPostIds.map(id => state.posts.entities[id])
          .filter(p => p?.context === PostContext.EVENT_INSTANCE)
          .map(p => federatedId(p!));
      } else {
        filteredPostIds = starredPostIds;
      }
      return {
        filteredPostIds,
        hasPosts: starredPostIds.some(id => [PostContext.POST, PostContext.REPLY].includes(state.posts.entities[id]?.context!)),
        hasEvents: starredPostIds.some(id => state.posts.entities[id]?.context === PostContext.EVENT_INSTANCE)
      };
    }],
    (data) => data
  );


export type StarredPostsProps = {};

export function StarredPosts({ }: StarredPostsProps) {
  const mediaQuery = useMedia();

  const starredPostIds = useAppSelector(state => state.config.starredPostIds) ?? [];

  const [open, setOpen] = useState(false);
  // const openDebounced300 = useDebounceValue(open, 300);
  // const openDebounced3000 = useDebounceValue(open, 3000);
  const openedPostId = useAppSelector(state => state.config.openedStarredPostId);
  const setOpenedPostId = (postId: string | undefined) =>
    dispatch(setOpenedStarredPost(postId));
  const [starredPostFilter, setStarredPostFilter] = useState<StarredPostFilter>(undefined);

  const { filteredPostIds, hasPosts, hasEvents } = useAppSelector(selectFilteredPostIds(starredPostFilter));

  useEffect(() => {
    if (starredPostFilter && !hasPosts && !hasEvents) {
      setStarredPostFilter(undefined);
    }
  }, [starredPostFilter, hasPosts, hasEvents]);

  // const starredPostUnreadCounts: Dictionary<number> = useAppSelector(state => {
  //   const counts = {} as Dictionary<number>;

  //   state.config.starredPostIds.forEach(id => {
  //     const lastUnreadCount = state.config.starredPostLastOpenedResponseCounts?.[id] ?? 0;
  //     const currentCount = state.posts.entities[id]?.responseCount ?? 0;
  //     counts[id] = currentCount - lastUnreadCount;
  //   });
  //   return counts;
  // });

  const scrollToTop = useCallback((smooth?: boolean) => document.getElementById('starred-post-scroll-top')
    ?.scrollIntoView({ block: 'center', behavior: smooth ? 'smooth' : undefined }), []);
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
  const { ancestorPost, ancestorEvent } = useReplyAncestors(basePost);
  const basePostTitle = event?.post?.title || basePost?.title ||
    (ancestorEvent?.post?.title
      ? `Comments | ${ancestorEvent.post.title}`
      : ancestorPost?.title
        ? `Comments | ${ancestorPost.title}`
        : 'Loading...');

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
  const openedPostAccountTheme = useServerTheme(openedPostAccount?.server);
  const { primaryColor, transparentPrimaryColor, primaryTextColor, navColor, navTextColor } = serverTheme;
  const { primaryAnchorColor: openedPostPrimaryAnchorColor, navAnchorColor: openedPostNavAnchorColor } = openedPostAccountTheme;

  // const openedPostAccount: AccountOrServer | undefined = useAppSelector(state =>
  //   basePost
  //     ? state.accounts.pinnedServers
  //       .find(s => s.serverId.includes(basePost.serverHost))
  //     : undefined);

  const chatUI = useAppSelector(state => state.config.discussionChatUI);
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
  const browser = useMemo(() => {
    const agent = window.navigator.userAgent.toLowerCase();
    switch (true) {
      case agent.indexOf("edge") > -1: return "Edge";
      case agent.indexOf("edg") > -1: return "Chromium Edge";
      case agent.indexOf("opr") > -1 && 'opr' in window: return "Opera";
      case agent.indexOf("chrome") > -1 && 'chrome' in window: return "Chrome";
      case agent.indexOf("trident") > -1: return "IE";
      case agent.indexOf("firefox") > -1: return "Firefox";
      case agent.indexOf("safari") > -1: return "Safari";
      default: return "browser";
    }
  }, []);

  const showFilters = hasPosts && hasEvents;

  return <AccountOrServerContextProvider value={accountOrServer}>
    <ConversationContextProvider value={conversationContext}>
      {/* <AnimatePresence> */}
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

            <Popover.Content
              zi={100000}
              borderWidth={1}
              p='$2'
              // color={primaryTextColor}
              backgroundColor={transparentPrimaryColor}
              backdropFilter="blur(10px)"
              // backdropFilter="fade(0.5)"
              borderColor="$borderColor"
              enterStyle={{ y: -10, opacity: 0 }}
              exitStyle={{ y: -10, opacity: 0 }}
              elevate
              animation={[
                'standard',
                {
                  opacity: {
                    overshootClamping: true,
                  },
                },
              ]}
            >
              {/* <YStack backgroundColor={transparentPrimaryColor}> */}
              <Popover.Arrow borderWidth={1} backgroundColor={transparentPrimaryColor} borderColor="$borderColor" />

              <YStack h='100%' ai='center'>
                <AutoAnimatedList direction='horizontal' style={{ width: '100%' }}>
                  {openedPostId
                    ? [
                      <div key='back'>
                        <Button circular size='$3' mr='$2' onPress={() => setOpenedPostId(undefined)} icon={ChevronLeft} />
                      </div>,
                      // <div key='flex-1' style={{ flex: 1 }} />
                    ] : [
                      showFilters
                        ? <div key='posts-filter'>
                          <Button icon={menuIcon(AppSection.POSTS, starredPostFilter === 'posts' ? navTextColor : primaryTextColor)}
                            px='$3'
                            onPress={() => setStarredPostFilter(
                              starredPostFilter === 'posts' ? undefined : 'posts'
                            )}
                            transparent
                            {...highlightedButtonBackground(serverTheme, 'nav', starredPostFilter === 'posts')}
                          />
                        </div>
                        : undefined,
                      showFilters
                        ? <div key='events-filter' style={{ marginRight: 10 }}>
                          <Button icon={menuIcon(AppSection.EVENTS, starredPostFilter === 'events' ? navTextColor : primaryTextColor)}
                            px='$3'
                            onPress={() => setStarredPostFilter(
                              starredPostFilter === 'events' ? undefined : 'events'
                            )}
                            transparent
                            {...highlightedButtonBackground(serverTheme, 'nav', starredPostFilter === 'events')}
                          />
                        </div>
                        : undefined,
                    ]}
                  {basePost
                    ? <div key='post-name' style={{ flex: 1 }}>
                      <Button transparent onPress={() => scrollToTop(true)} >
                        <YStack>
                          <Paragraph size='$1'
                            color={primaryTextColor}
                            maw={Math.min(400, window.innerWidth - 150 - (eventWithSingleInstance ? 80 : 0))}
                            overflow='hidden' textOverflow='ellipsis' whiteSpace='nowrap'
                            fontWeight='bold' my='auto' animation='standard' o={0.7} f={1}>
                            {basePostTitle}
                          </Paragraph>
                        </YStack>
                      </Button>
                    </div>
                    : [
                      <div key='heading-spacer' style={{ width: showFilters ? undefined : 10 }} />,
                      <div key='starred-heading' style={{ flex: 1 }}>

                        <Tooltip>
                          <Tooltip.Trigger>
                            <AutoAnimatedList style={{}}>
                              <XStack key='heading-spacer' style={{ height: showFilters ? undefined : 5 }} />

                              <XStack key='starred' ai='center' gap='$2'>
                                <Heading size='$4' color={primaryTextColor}>Starred</Heading>
                                <Info size={16} o={0.5} color={primaryTextColor} />
                              </XStack>

                              {starredPostFilter === 'posts'
                                ? <Heading key='starred-posts' size='$5' whiteSpace="nowrap" color={primaryTextColor}>
                                  Posts
                                </Heading>
                                : starredPostFilter === 'events'
                                  ? <Heading key='starred-events' size='$5' whiteSpace="nowrap" color={primaryTextColor}>
                                    Events
                                  </Heading>
                                  : undefined}
                            </AutoAnimatedList>
                          </Tooltip.Trigger>
                          <Tooltip.Content zi={100001}>
                            <Paragraph size='$1' >
                              Starred Posts/Events are completely anonymous and not tracked outside this {browser} session at {location.hostname}.
                            </Paragraph>
                            {/* <YStack ai='flex-start'>
                              <Paragraph size='$1' >
                                Starred Posts/Events are stored only in your current browser.
                              </Paragraph>
                              <Paragraph size='$1' >
                                They are <i>never</i> associated with any profile or any personal identifiable information (PII), even in server logs.
                              </Paragraph>
                              <Paragraph size='$1' >
                                Don't take Star Counts seriously. They are anonymous tallies, easily prone to manipulation, and don't affect who sees anything.
                              </Paragraph>
                            </YStack> */}
                          </Tooltip.Content>
                        </Tooltip>
                      </div>
                    ]}
                  {/* <div key='flex-2' style={{ flex: 1 }} /> */}

                  {eventWithSingleInstance
                    ? <div key='instance-time'>
                      <InstanceTime instance={eventWithSingleInstance.instances[0]!} event={eventWithSingleInstance} />
                    </div>
                    : basePost
                      ? undefined//<div key='flex-3' style={{ flex: 1 }} />
                      : undefined}
                </AutoAnimatedList>
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

                          icon={<ListEnd color={chatUI ? primaryTextColor : navTextColor} transform={[{ rotate: '180deg' }]} />}
                          onPress={() => {
                            dispatch(setDiscussionChatUI(false));
                            scrollToCommentsTop(openedPostId);
                          }}
                          mr={0}>
                          <Heading size='$4' color={chatUI ? primaryTextColor : navTextColor}>Discussion</Heading>
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
                          iconAfter={<ListEnd color={!chatUI ? primaryTextColor : navTextColor} />}
                          borderTopLeftRadius={0} borderBottomLeftRadius={0}
                          onPress={() => {
                            dispatch(setDiscussionChatUI(true));
                            if (chatUI)
                              scrollToCommentsBottom(openedPostId);
                            else
                              setTimeout(() => scrollToCommentsBottom(openedPostId), 800);
                          }}>
                          <Heading size='$4' color={!chatUI ? primaryTextColor : navTextColor}>Chat</Heading>
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
                      iconAfter={Fullscreen} >
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
                  <AutoAnimatedList>
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

                    {true //|| openDebounced300 || openDebounced3000 
                      ?
                      openedPostId// && basePost
                        ? [
                          <StarredPostCard key={`fullsize-starred-post-card-${openedPostId}`} {...{ postId: openedPostId }} fullSize hasMainServerPrimaryBackground />,
                          basePost ? conversationCommentList : undefined
                        ]
                        : filteredPostIds.map((postId) =>
                          <XStack w='100%' key={`starred-post-card-${postId}`}
                            animation='standard' {...standardAnimation}>
                            <StarredPostCard {...{ postId, onOpen: setOpenedPostId }}
                              unsortable={!!starredPostFilter} hasMainServerPrimaryBackground />
                          </XStack>
                        )
                      : undefined}

                  </AutoAnimatedList>
                </ScrollView>

                {/* {openedPostId && basePost
                        ? <> */}
                <ReplyArea replyingToPath={replyPostIdPath}
                  onStopReplying={() => openedPostId && setReplyPostIdPath([openedPostId])}
                  hidden={!showReplyArea} />
                {/* </>
                        : undefined} */}
              </YStack>
              {/* </YStack> */}
            </Popover.Content>
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
      {/* </AnimatePresence> */}

    </ConversationContextProvider>
  </AccountOrServerContextProvider>;
}
