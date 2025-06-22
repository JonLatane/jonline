import { EventInstance, Post, PostContext } from "@jonline/api";
import { AnimatePresence, Button, Paragraph, Spinner, XStack, YStack, standardAnimation, useMedia } from "@jonline/ui";
import { standardHorizontalAnimation } from '@jonline/ui/src/animations';
import { createSelector } from "@reduxjs/toolkit";
import { ChevronDown, ChevronUp, MessagesSquare } from "@tamagui/lucide-icons";
import { Selector, useAppDispatch, useAppSelector, useCurrentServer, useFederatedAccountOrServer, useFederatedDispatch } from "app/hooks";
import useIsVisibleHorizontal from "app/hooks/use_is_visible";
import { FederatedEvent, FederatedPost, PinnedServer, RootState, accountID, federatedId, getCachedServerClient, getServerClient, loadEvent, loadPost, moveStarredPostDown, moveStarredPostUp, parseFederatedId, selectPostById, serverID, useServerTheme } from "app/store";
import React, { createRef, useEffect, useState } from "react";
import EventCard from "../event/event_card";
import { PostCard, scrollToCommentsBottom, scrollToCommentsTop } from "../post";
import { StarButton } from "../post/star_button";
import { ShortAccountSelectorButton } from "./pinned_server_selector";
import { ServerNameAndLogo } from "./server_name_and_logo";

export type StarredPostCardProps = {
  postId: string;
  onOpen?: (postId: string) => void;
  fullSize?: boolean;
  unsortable?: boolean;
  unreadCount?: number;
  hideCurrentUser?: boolean;
  showPermalink?: boolean;
  hasMainServerPrimaryBackground?: boolean;
};

const selectStarredPostEventData = (
  basePost: FederatedPost | undefined
): Selector<{ eventInstanceId?: string; event?: FederatedEvent; }> =>
  createSelector(
    [(state: RootState) => {
      if (!basePost) return {};

      const postId = federatedId(basePost);
      const eventInstanceId = basePost?.context === PostContext.EVENT_INSTANCE
        ? state.events.postInstances[postId]
        : undefined;
      const event = eventInstanceId
        ? state.events.entities[state.events.instanceEvents[eventInstanceId]!]
        : undefined

      return { eventInstanceId, event };
    }],
    (data) => data
  );

export function useStarredPostDetails(postId: string, isVisible?: boolean) {
  const { id: serverPostId, serverHost } = parseFederatedId(postId, useCurrentServer()?.host);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const basePost = useAppSelector(state => selectPostById(state.posts, postId));
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
  const shouldReloadPost = !basePost && isServerReady && !loadingServer && !loadingPost && !hasFailedToLoadPost && postId && (isVisible ?? true);
  useEffect(() => {
    if (shouldReloadPost) {
      // console.log('StarredPosts: Fetching post', postId);
      setLoadingPost(true);
      dispatch(loadPost({ ...accountOrServer, id: serverPostId! }))
        .then((result) => {
          // console.log('StarredPosts: Fetched post', postId, 'result', result);
          setTimeout(() =>
            setLoadingPost(false),
            1500
          );
        });
    }
  }, [basePost?.id, accountID(accountOrServer?.account), serverHost, isServerReady, loadingServer, loadingPost,
    hasFailedToLoadPost, postId, isVisible]);

  // const eventInstanceId = useAppSelector(state =>
  //   basePost?.context === PostContext.EVENT_INSTANCE
  //     ? state.events.postInstances[postId]
  //     : undefined
  // );
  // const event = useAppSelector(state =>
  //   eventInstanceId
  //     ? state.events.entities[state.events.instanceEvents[eventInstanceId]!]
  //     : undefined
  // );

  const { eventInstanceId, event } = useAppSelector(selectStarredPostEventData(basePost));

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
  const hasFailedToLoadEvent = useAppSelector(state => state.events.failedPostIds.includes(postId));

  const shouldLoadEvent =
    isServerReady && basePost?.context === PostContext.EVENT_INSTANCE && !eventWithSingleInstance && !loadingEvent && !hasFailedToLoadEvent;
  // if (postId) debugger;
  useEffect(() => {
    // console.log('StarredPosts: loader', { shouldLoadEvent, postId, serverPostId, serverHost, isEvent: basePost?.context === PostContext.EVENT_INSTANCE, eventInstanceContext: PostContext.EVENT_INSTANCE, eventWithSingleInstance, loadingEvent, hasFailedToLoadEvent });
    // if (postId) debugger;

    if (shouldLoadEvent) {
      // console.log('StarredPosts: Fetching event by postId', postId);
      // console.log('StarredPosts: Fetching event by postId', { shouldLoadEvent, postId, serverPostId, serverHost, isEvent: basePost?.context === PostContext.EVENT_INSTANCE, eventWithSingleInstance, loadingEvent, hasFailedToLoadEvent });
      setLoadingEvent(true);
      dispatch(loadEvent({ ...accountOrServer, postId: serverPostId! })).then(() => {
        setTimeout(() =>
          setLoadingEvent(false),
          1500
        );
      });
    }
  }, [basePost?.id, shouldLoadEvent]);
  return {
    basePost,
    eventInstanceId,
    event,
    serverPostId,
    serverHost,
    serverEventInstanceId,
    eventWithSingleInstance,
    isServerReady,
    loadingServer,
    loadingPost: loadingPost || shouldReloadPost,
    loadingEvent
  };
}


const selectStarredMovability = (
  postId: string,
): Selector<{ canMoveUp: boolean, canMoveDown: boolean }> =>
  createSelector(
    [(state: RootState) => ({
      canMoveUp: state.config.starredPostIds.indexOf(postId) > 0,
      canMoveDown: state.config.starredPostIds.indexOf(postId) < state.config.starredPostIds.length - 1,
    })],
    (data) => data
  );


export function StarredPostCard({ postId, onOpen, fullSize, unsortable, unreadCount, hideCurrentUser, showPermalink, hasMainServerPrimaryBackground }: StarredPostCardProps) {
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
  const mainServerPrimaryTextColor = useServerTheme(useCurrentServer())?.primaryTextColor;
  // debugger;
  const { navColor, navTextColor, navAnchorColor, primaryTextColor } = useServerTheme(server);

  const pinnedServer: PinnedServer | undefined = useAppSelector(state => state.accounts.pinnedServers.find(s => server && s.serverId === serverID(server)));

  const isActuallyStarred = useAppSelector(state => state.config.starredPostIds.includes(postId));
  const { canMoveUp, canMoveDown } = useAppSelector(selectStarredMovability(postId));

  function moveUp() {
    requestAnimationFrame(() => dispatch(moveStarredPostUp(postId)));
  }
  function moveDown() {
    requestAnimationFrame(() => dispatch(moveStarredPostDown(postId)));
  }

  let renderedCardView: React.JSX.Element;
  if (eventWithSingleInstance) {
    renderedCardView = <EventCard
      event={eventWithSingleInstance}
      isPreview={!fullSize} forceShrinkPreview
      onPress={() => onOpen?.(postId)}
      showPermalink={showPermalink}
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
        isPreview={!fullSize && basePost.context != PostContext.REPLY}
        forceShrinkPreview
        onPress={() => onOpen?.(postId)}
        showPermalink={showPermalink}
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
        ? <Paragraph size='$3' ta='center' o={0.5} color={hasMainServerPrimaryBackground ? mainServerPrimaryTextColor : undefined}>Post {postId} not found</Paragraph>
        : <>
          <Spinner color={navAnchorColor} />
          <Paragraph size='$3' ml='$2' o={0.5} color={hasMainServerPrimaryBackground ? mainServerPrimaryTextColor : undefined}>Post {postId} is loading...</Paragraph>
        </>}
      <XStack w='$3' h='$3' ml='auto'>
        <ServerNameAndLogo server={server} shrinkToSquare />
      </XStack>
    </XStack>;
  }
  const chatUI = useAppSelector(state => state.config.discussionChatUI);
  const renderedCard = <YStack w='100%' key={`starred-post-${postId}`}>
    {!hideCurrentUser && server && (pinnedServer?.accountId || !basePost) ?
      <XStack ml='auto' mr='$9' mb={-14}>
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
        {fullSize || !isActuallyStarred ? undefined :
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
        }
      </AnimatePresence>
    </XStack >
  </YStack>;

  return <div ref={visibilityRef} style={{ width: '100%' }}>{renderedCard}</div>;
}
