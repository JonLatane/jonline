import { AnimatePresence, Button, Heading, Paragraph, Popover, ScrollView, XStack, YStack, standardAnimation, useMedia } from "@jonline/ui";
import { Pin } from "@tamagui/lucide-icons";
import { useAppSelector } from "app/hooks";
import { FederatedPost, federatedId, useServerTheme } from "app/store";
import FlipMove from "react-flip-move";
import { PostCard } from "../post";
import { reverseHorizontalAnimation } from '../../../ui/src/animations';

export type PinnedThreadsProps = {};
export function PinnedThreads({ }: PinnedThreadsProps) {
  const mediaQuery = useMedia();

  const { primaryTextColor, navColor, navTextColor } = useServerTheme();

  const pinnedPosts = useAppSelector(state => (state.app.pinnedPostIds ?? []).map(id => state.posts.entities[id]))
    .filter(post => !!post) as FederatedPost[];
  return <AnimatePresence>
    {pinnedPosts.length > 0
      ? <XStack animation='standard' {...reverseHorizontalAnimation} exitStyle={{ x: 29, o: 0, }} >

        <Popover size="$5" allowFlip placement='bottom-end' keepChildrenMounted>
          <Popover.Trigger asChild>
            <Button transparent
              icon={Pin}
              color={primaryTextColor}
            />
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
              <Heading size='$5'>Pinned Posts</Heading>
              <ScrollView
                w={Math.max(100, Math.min(650, window.innerWidth - 100))}
                h={Math.max(100, Math.min(650, window.innerHeight - 150))}
              >
                <FlipMove style={{ alignItems: 'center' }}>
                  {pinnedPosts.length === 0
                    ? <div key='discussion' style={{
                      display: 'flex',
                      marginLeft: 'auto',
                      marginRight: 'auto',
                      marginTop: Math.max(50, Math.min(350, window.innerHeight - 150)) / 2 - 50,
                    }}>
                      <Paragraph size='$3' w='100%' ta='center' o={0.5}>No pinned Posts.</Paragraph>
                    </div>
                    : undefined}

                  {pinnedPosts.map((post) => {
                    return <div key={`post-${federatedId(post)}`} style={{ width: '100%' }}>
                      <XStack w='100%'
                        animation='standard' {...standardAnimation}>
                        <PostCard post={post} isPreview forceShrinkPreview />
                      </XStack>
                    </div>;
                  })}
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
            {pinnedPosts.length}
          </Paragraph>
          <XStack f={1} />
        </XStack>
      </XStack>
      : undefined}
  </AnimatePresence>;
}