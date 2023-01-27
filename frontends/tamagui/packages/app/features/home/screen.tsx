import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack } from '@jonline/ui'
import { ChevronDown, ChevronUp } from '@tamagui/lucide-icons'
import { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { Platform, FlatList, Linking } from 'react-native'
import { useLink } from 'solito/link'
import { setShowIntro } from "../../store/modules/local_app";
import { TabsNavigation } from '../tabs/tabs_navigation';
import { selectAllPosts, updatePosts } from 'app/store/modules/posts';
import { GetPostsRequest } from '@jonline/ui/src';
import PostCard from '../post/post_card';


export function HomeScreen() {
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const app = useTypedSelector((state: RootState) => state.app);
  const posts = useTypedSelector((state: RootState) => selectAllPosts(state.posts));
  let { dispatch, account_or_server } = useCredentialDispatch();
  let primaryColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.primary;
  let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;

  if (postsState.status == 'unloaded') {
    reloadPosts();
  }

  function reloadPosts() {
    if (account_or_server == null) return;

    setTimeout(() =>
      dispatch(updatePosts({ ...account_or_server, ...GetPostsRequest.create() })), 1);
  }

  function hideIntro() {
    dispatch(setShowIntro(false));
  }

  let intro =
    <YStack space="$4" maw={600}>
      {app.showIntro ? <>
        <H1 ta="center">Let's Get Jonline 🙃</H1>
        <Paragraph ta="left">
          <Anchor color={navColor} href="https://github.com/JonLatane/jonline" target="_blank">
            Jonline (give it a ⭐️!)
          </Anchor>{' '}
          is a federated social network built with Rust/gRPC, originally with a{' '}
          <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/frontends/flutter" target="_blank">
            Flutter UI
          </Anchor>.
          It's designed to let small businesses and communities run their own social network,
          make it easy to link to posts and events from other networks, and be easy and fun for users.
          Made by{' '}
          <Anchor color={navColor} href="https://instagram.com/jon_luvs_ya" target="_blank">
            Jon Latané
          </Anchor>.
        </Paragraph>
        <Paragraph ta="left">
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
          >Tamagui</Anchor>. It's a work in progress to be sure! 👷🛠️
        </Paragraph>
        {/* <Paragraph ta="center">
        If this is a new server, create an admin account and go to server configuration
        to set up your server and hide this intro message.
      </Paragraph> */}
        <Paragraph ta='center' mt='$3' size='$1'>(You can re-enable this message from your settings if you want to see it again!)</Paragraph>

        <XStack justifyContent='center' marginTop={15} space='$2'>
          {Platform.OS == 'web' ? <Button onPress={() => Linking.openURL('/flutter')}>Open Flutter Web UI</Button> : undefined}
          <Button backgroundColor={primaryColor} onClick={hideIntro}>Got It!</Button>
        </XStack>
      </> : undefined}
      {serversState.server == undefined ? <Paragraph ta="center">
        Choose an account or server to get started.
      </Paragraph> : undefined}
    </YStack>;

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" p="$0" paddingHorizontal='$4' maw={800} space>
        {(serversState.server == undefined || app.showIntro) ? intro : undefined}
        <FlatList data={posts}
          onRefresh={reloadPosts}
          refreshing={postsState.status == 'loading'}
          keyExtractor={(post) => post.id}
          renderItem={({ item: post }) => {
            return <PostCard post={post} maxContentHeight={300} linkToDetails />;
          }} />
      </YStack>
    </TabsNavigation>
  )
}
