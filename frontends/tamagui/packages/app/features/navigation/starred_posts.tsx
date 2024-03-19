import { Post, PostContext } from "@jonline/api";
import { AnimatePresence, Button, Heading, Paragraph, Popover, ScrollView, XStack, YStack, standardAnimation, useMedia } from "@jonline/ui";
import { reverseHorizontalAnimation } from '@jonline/ui/src/animations';
import { ChevronDown, ChevronLeft, ChevronUp, MessagesSquare } from "@tamagui/lucide-icons";
import { useAppDispatch, useAppSelector, useFederatedDispatch, useServer } from "app/hooks";
import { moveStarredPostDown, moveStarredPostUp, parseFederatedId, useServerTheme } from "app/store";
import { useState } from "react";
import FlipMove from "react-flip-move";
import EventCard from "../event/event_card";
import { ConversationContextProvider, ConversationManager, PostCard, useConversationCommentList, useStatefulConversationContext } from "../post";
import { StarButton, ThemedStar } from "../post/star_button";
import { AccountOrServerContextProvider } from "app/contexts";
import { InstanceTime } from "../event/instance_time";

export type StarredPostsProps = {};
function useStarredPostDetails(postId: string) {
  const basePost = useAppSelector(state => state.posts.entities[postId]);
  const { id: serverPostId, serverHost } = parseFederatedId(postId, useServer()?.host);
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

  const serverEventInstanceId = eventInstanceId
    ? parseFederatedId(eventInstanceId!).id
    : undefined;
  // const { id: serverEventInstanceId } = parseFederatedId(eventInstanceId!);
  const eventWithSingleInstance = event && serverEventInstanceId ? {
    ...event,
    instances: [event.instances.find(i => i.id === serverEventInstanceId)!]
  } : undefined;

  return { basePost, eventInstanceId, event, serverPostId, serverHost, serverEventInstanceId, eventWithSingleInstance };
}

export function StarredPosts({ }: StarredPostsProps) {
  const mediaQuery = useMedia();

  const { primaryTextColor, navColor, navTextColor } = useServerTheme();
  const starredPostIds = useAppSelector(state => (state.app.starredPostIds ?? []));

  const [open, setOpen] = useState(false);
  const [openedPostId, setOpenedPostId] = useState<string | undefined>(undefined);

  const { serverHost, basePost, event, eventInstanceId, eventWithSingleInstance } = useStarredPostDetails(openedPostId ?? '');

  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const conversationContext = useStatefulConversationContext();

  const conversationCommentList = useConversationCommentList({
    post: basePost ?? { ...Post.create(), serverHost: accountOrServer.server?.host || 'jonline.io' },
    disableScrollPreserver: true,
    forceChatUI: true,
    conversationContext: conversationContext,
  });

  return <AnimatePresence>
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
              <XStack w='100%' ai='center' gap='$2'>
                {openedPostId
                  ? <Button onPress={() => setOpenedPostId(undefined)} icon={ChevronLeft} />
                  : undefined}
                <XStack f={1} />
                {basePost
                  ? <Paragraph size='$1' fontWeight='bold' my='auto' animation='standard' o={0.5} f={1}>
                    {event?.post?.title ?? basePost?.title ?? 'Loading...'}
                  </Paragraph>
                  : <Heading size='$5'>Starred</Heading>}
                {eventWithSingleInstance
                  ? <InstanceTime instance={eventWithSingleInstance.instances[0]!} event={eventWithSingleInstance} />
                  : undefined}
                {/* <Heading size='$5'>{
                  basePost ? event?.post?.title ?? basePost.title
                    : 'Starred'}
                    </Heading> */}
                <XStack f={1} />
              </XStack>
              <ScrollView
                w={Math.max(100, Math.min(650, window.innerWidth - 70))}
                h={Math.max(100, Math.min(650, window.innerHeight - 150))}
              >
                <AccountOrServerContextProvider value={accountOrServer}>
                  <ConversationContextProvider value={conversationContext}>
                    <FlipMove style={{ alignItems: 'center' }}>
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

                      {basePost
                        ? conversationCommentList
                        : starredPostIds.map((postId) =>
                          <div key={`post-${postId}`} style={{ width: '100%' }}>
                            <XStack w='100%'
                              animation='standard' {...standardAnimation}>
                              <StarredPostCard {...{ postId, onOpen: setOpenedPostId }} />
                            </XStack>
                          </div>)}

                    </FlipMove>
                  </ConversationContextProvider>
                </AccountOrServerContextProvider>
              </ScrollView>
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
  </AnimatePresence>;
}


export type StarredPostCardProps = {
  postId: string;
  onOpen?: (postId: string) => void;
};
export function StarredPostCard({ postId, onOpen }: StarredPostCardProps) {
  const mediaQuery = useMedia();
  const dispatch = useAppDispatch();

  const { primaryTextColor, navColor, navTextColor } = useServerTheme();

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
    renderedCardView = <EventCard event={eventWithSingleInstance} isPreview forceShrinkPreview />;
  } else if (basePost) {
    renderedCardView = <PostCard post={basePost} isPreview forceShrinkPreview />;
  } else {
    renderedCardView = <XStack w='100%'
      animation='standard' {...standardAnimation} jc='center' ai='center'>
      <StarButton post={{ ...Post.create({ id: serverPostId }), serverHost }} />
      <Paragraph size='$3' ta='center' o={0.5}>Post {postId} not found.</Paragraph>
    </XStack>;
  }
  const renderedCard = <XStack w='100%' ai='center' gap='$2'>
    <XStack f={1}>
      {renderedCardView}
    </XStack>
    <YStack ai='center' gap='$2'>
      <Button disabled={!canMoveUp} o={canMoveUp ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveUp(); }} icon={ChevronUp} circular />

      <Button size='$3' onPress={() => onOpen?.(postId)} icon={MessagesSquare} />

      <Button disabled={!canMoveDown} o={canMoveDown ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveDown(); }} icon={ChevronDown} circular />
    </YStack>
  </XStack>
  return renderedCard;
}
