import { Post, PostContext } from "@jonline/api";
import { AnimatePresence, Button, Heading, Paragraph, Popover, ScrollView, XStack, YStack, standardAnimation, useMedia } from "@jonline/ui";
import { reverseHorizontalAnimation } from '@jonline/ui/src/animations';
import { useAppSelector } from "app/hooks";
import { FederatedPost, parseFederatedId, useServerTheme } from "app/store";
import { useState } from "react";
import FlipMove from "react-flip-move";
import { PostCard } from "../post";
import { StarButton, ThemedStar } from "../post/star_button";
import EventCard from "../event/event_card";

export type StarredPostsProps = {};
export function StarredPosts({ }: StarredPostsProps) {
  const mediaQuery = useMedia();

  const { primaryTextColor, navColor, navTextColor } = useServerTheme();

  const [open, setOpen] = useState(false);
  const starredPostIds = useAppSelector(state => (state.app.starredPostIds ?? []));
  // const starredPosts = useAppSelector(state => starredPostIds.map(id => state.posts.entities[id]))
  //   .filter(post => !!post) as FederatedPost[];
  // const unfoundPostCount = starredPostIds.length - starredPosts.length;
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
              <Heading size='$5'>Starred</Heading>
              <ScrollView
                w={Math.max(100, Math.min(650, window.innerWidth - 100))}
                h={Math.max(100, Math.min(650, window.innerHeight - 150))}
              >
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

                  {starredPostIds.map((postId) =>
                    <div key={`post-${postId}`} style={{ width: '100%' }}>
                      <XStack w='100%'
                        animation='standard' {...standardAnimation}>
                        <StarredPostCard {...{ postId }} />
                      </XStack>
                    </div>)}

                </FlipMove>
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
};
export function StarredPostCard({ postId }: StarredPostCardProps) {
  const mediaQuery = useMedia();

  const { primaryTextColor, navColor, navTextColor } = useServerTheme();
  const basePost = useAppSelector(state => state.posts.entities[postId]);
  const { id: serverPostId, serverHost } = parseFederatedId(postId);
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



  if (!basePost) {
    return <XStack w='100%'
      animation='standard' {...standardAnimation} jc='center' ai='center'>
      <StarButton post={{ ...Post.create({ id: serverPostId }), serverHost }} />
      <Paragraph size='$3' ta='center' o={0.5}>Post {postId} not found.</Paragraph>
    </XStack>;
  }

  if (event) {
    return <EventCard event={event} isPreview />;
  }
  return <PostCard post={basePost} isPreview forceShrinkPreview />;
}
