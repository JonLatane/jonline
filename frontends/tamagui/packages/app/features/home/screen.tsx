import { Anchor, Button, H1, Heading, Paragraph, XStack, YStack } from '@jonline/ui';
import { GetPostsRequest } from '@jonline/ui/src';
import { RootState, selectAllPosts, setShowIntro, loadPostsPage, useCredentialDispatch, useTypedSelector } from 'app/store';
import React, { useState, useEffect } from 'react';
import { FlatList, Linking, Platform } from 'react-native';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';

export function HomeScreen() {
  const [showTechDetails, setShowTechDetails] = useState(false);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const app = useTypedSelector((state: RootState) => state.app);
  const posts = useTypedSelector((state: RootState) => selectAllPosts(state.posts));
  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  const [showScrollPreserver, setShowScrollPreserver] = useState(isSafari);
  let { dispatch, accountOrServer } = useCredentialDispatch();
  let primaryColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.primary;
  let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;


  const [loadingPosts, setLoadingPosts] = useState(false);
  useEffect(() => {
    if (postsState.baseStatus == 'unloaded' && !loadingPosts) {
      if (!accountOrServer.server) return;

      setLoadingPosts(true);
      reloadPosts();
    } else if (postsState.baseStatus == 'loaded') {
      setLoadingPosts(false);
      setTimeout(() => setShowScrollPreserver(false), 1500);
    }
  });

  function reloadPosts() {
    setTimeout(() => dispatch(loadPostsPage({ ...accountOrServer })), 1);
  }

  function hideIntro() {
    dispatch(setShowIntro(false));
  }

  let intro =
    <YStack space="$4" maw={600}>
      {app.showIntro ? <>
        <H1 ta="center">Let's Get Jonline 🙃</H1>
        <Paragraph ta="left" mb='$2'>
          <Anchor color={navColor} href="https://github.com/JonLatane/jonline" target="_blank">
            Jonline (give it a ⭐️!)
          </Anchor>{' '}
          is a federated social network built with Rust/gRPC.
          It's designed to let small businesses and communities run their own social network,{' '}
          with minimal cost, effort, and no creepy data mining;{' '}
          to make it easy to link to posts and events from other networks;{' '}
          and to be intuitive and fun for customers, members, and administrators alike.
        </Paragraph>
        {showTechDetails
          ? <Paragraph ta="left">
            This{' '}
            <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/frontends/tamagui" target="_blank">
              new UI
            </Anchor> for Jonline's{' '}
            <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/backend" target="_blank">
              Rust/gRPC backend
            </Anchor> is built with React and{' '}
            <Anchor
              color={navColor}
              href="https://github.com/tamagui/tamagui"
              target="_blank"
              rel="noreferrer"
            >Tamagui</Anchor>. It's a work in progress to be sure! 👷🛠️🪲 The{' '}
            <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/frontends/flutter" target="_blank">
              original Flutter UI
            </Anchor> is also available and compatible, with more features for now.
          </Paragraph>
          : <>
            <Button onPress={() => setShowTechDetails(true)}>
              More Tech Details
            </Button>
            <Heading size='$5' mt='$3' ta='center'>
              Beta software. Expect bugs! 🛠️👷🏼‍♂️🪲
            </Heading>
          </>}
        <Heading size='$3' mt='$3' ta='center'>
          Made by{' '}
          <Anchor color={navColor} href="https://instagram.com/jon_luvs_ya" target="_blank">
            Jon Latané
          </Anchor>.
        </Heading>
        {/* <Paragraph ta="center">
        If this is a new server, create an admin account and go to server configuration
        to set up your server and hide this intro message.
      </Paragraph> */}
        <Paragraph ta='center' mt='$2' size='$1'>(You can re-enable this message from your settings if you want to see it again!)</Paragraph>

        <XStack justifyContent='center' marginTop={15} space='$2'>
          {Platform.OS == 'web' && showTechDetails ? <Button onPress={() => Linking.openURL('/flutter')}>Open Flutter Web UI</Button> : undefined}
          <Button backgroundColor={primaryColor} onClick={hideIntro}>
            {Platform.OS == 'web' && showTechDetails ? 'Got It!' : 'Got It, Thanks!'}
          </Button>
        </XStack>
      </> : undefined}
      {serversState.server == undefined ? <Paragraph ta="center">
        Choose an account or server to get started.
      </Paragraph> : undefined}
    </YStack>;

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {(serversState.server == undefined || app.showIntro) ? intro : undefined}
        <FlatList data={posts}
          // onRefresh={reloadPosts}
          // refreshing={postsState.status == 'loading'}
          // Allow easy restoring of scroll position
          ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
          keyExtractor={(post) => post.id}
          renderItem={({ item: post }) => {
            return <PostCard post={post} isPreview />;
          }} />
      </YStack>
    </TabsNavigation>
  )
}
