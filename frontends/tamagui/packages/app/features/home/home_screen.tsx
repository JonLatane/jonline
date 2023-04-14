import { EventListingType, PostListingType } from '@jonline/api';
import { Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, useMedia, useWindowDimensions } from '@jonline/ui';
import { RootState, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { FlatList } from 'react-native';
import StickyBox from "react-sticky-box";
import EventCard from '../event/event_card';
import { StickyCreateButton } from '../post/create_post_sheet';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { useEventsPage } from './events_screen';
import { usePostsPage } from './posts_screen';

export function HomeScreen() {
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const eventsState = useTypedSelector((state: RootState) => state.events);
  const media = useMedia();

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();

  const dimensions = useWindowDimensions();

  useEffect(() => {
    document.title = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  });

  const { posts, loadingPosts, reloadPosts } = usePostsPage(
    PostListingType.PUBLIC_POSTS,
    0,
    () => dismissScrollPreserver(setShowScrollPreserver)
  );

  const { events, loadingEvents, reloadEvents } = useEventsPage(
    EventListingType.PUBLIC_EVENTS,
    0,
    () => dismissScrollPreserver(setShowScrollPreserver)
  );


  function onHomePressed() {
    if (isClient && window.scrollY > 0) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      reloadPosts();
      reloadEvents();
    }
  }

  return (
    <TabsNavigation customHomeAction={onHomePressed}>
      {postsState.baseStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {events.length == 0
          ? eventsState.loadStatus != 'loading' && eventsState.loadStatus != 'unloaded'
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No events found.</Heading>
              <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : undefined
          : <ScrollView horizontal
            w='100%'
            animation="bouncy"
            opacity={1}
            scale={1}
            y={0}
            enterStyle={{
              // scale: 1.5,
              y: -50,
              opacity: 0,
            }}
            exitStyle={{
              // scale: 1.5,
              // y: 50,
              opacity: 0,
            }}>
            <XStack space='$2'>
              <XStack w={media.gtSm ? 400 : 260}>
                {events.map((event) => <EventCard event={event} isPreview />)}
              </XStack>
            </XStack>
            {/* <FlatList data={events}
              horizontal={true}
              // onRefresh={reloadEvents}
              // refreshing={eventsState.status == 'loading'}
              // Allow easy restoring of scroll position
              // ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
              keyExtractor={(event) => event.id}
              renderItem={({ item: event }) => {
                return <EventCard event={event} isPreview />;
                // return <PostCard post={event.post!} isPreview />;
              }} /> */}
          </ScrollView>}
        {posts.length == 0
          ? postsState.baseStatus != 'loading' && postsState.baseStatus != 'unloaded'
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No posts found.</Heading>
              <Heading size='$3' ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : undefined
          : <FlatList data={posts}
            // onRefresh={reloadPosts}
            // refreshing={postsState.status == 'loading'}
            // Allow easy restoring of scroll position
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
            keyExtractor={(post) => post.id}
            renderItem={({ item: post }) => {
              return <PostCard post={post} isPreview />;
            }} />}
      </YStack>
      <StickyCreateButton />
    </TabsNavigation>
  )
}
