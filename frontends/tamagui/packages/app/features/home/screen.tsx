import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack } from '@jonline/ui'
import { ChevronDown, ChevronUp } from '@tamagui/lucide-icons'
import { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { Platform, FlatList } from 'react-native'
import { useLink } from 'solito/link'
import { upsertServer, selectAllServers } from "../../store/modules/servers";
import { selectAllAccounts } from "../../store/modules/accounts";
import { AccountsSheet } from '../accounts/accounts_sheet';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { selectAllPosts, updatePosts } from 'app/store/modules/posts';
import { GetPostsRequest } from '@jonline/ui/src';
import PostCard from '../post/post_card';


export function HomeScreen() {
  const [showIntro, setShowIntro] = useState(true);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const posts = useTypedSelector((state: RootState) => selectAllPosts(state.posts));
  let { dispatch, account_or_server } = useCredentialDispatch();
  if (postsState.status == 'unloaded') {
    reloadPosts();
  }

  function reloadPosts() {
    if (account_or_server == null) return;

    dispatch(updatePosts({ ...account_or_server, ...GetPostsRequest.create() }));
  }

  function hideIntro() {
    // debugger;
    setShowIntro(() => false);
  }
  const linkProps = useLink({
    href: '/user/nate',
  });
  const postLinkProps = useLink({
    href: '/post/asdf123',
  });
  const flutterLinkProps = useLink({
    href: '/flutter',
  });
  // const { dispatch, account_or_server } = useCredentialDispatch();

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" p="$4" maw={800} space>
        <YStack space="$4" maw={600}>
          {showIntro && <>
            <H1 ta="center">Let's Get Jonline 🙃</H1>
            <Paragraph ta="center">
              <Anchor color="$color12" href="https://github.com/JonLatane/jonline" target="_blank">
                Jonline (give it a ⭐️!)
              </Anchor>{' '}
              is a federated social network built with Rust/gRPC, originally with a{' '}
              <Anchor color="$color12" href="https://github.com/JonLatane/jonline/tree/main/frontends/flutter" target="_blank">
                Flutter UI
              </Anchor>.
              It's designed to let small businesses and communities run their own social network,
              make it easy to link to posts and events from other networks, and be easy and fun for users.
              Made by{' '}
              <Anchor color="$color12" href="https://instagram.com/jon_luvs_ya" target="_blank">
                Jon Latané
              </Anchor>.
            </Paragraph>
            <Paragraph ta="center">
              This{' '}
              <Anchor color="$color12" href="https://github.com/JonLatane/jonline/tree/main/frontends/tamagui" target="_blank">
                new UI
              </Anchor> for Jonline's{' '}
              <Anchor color="$color12" href="https://github.com/JonLatane/jonline/tree/main/backend" target="_blank">
                Rust/gRPC backend
              </Anchor> is built with React and{' '}
              <Anchor
                color="$color12"
                href="https://github.com/tamagui/tamagui"
                target="_blank"
                rel="noreferrer"
              >Tamagui</Anchor>. It's a work in progress (WIP).
            </Paragraph>
            {/* <Paragraph ta="center">
              If this is a new server, create an admin account and go to server configuration
              to set up your server and hide this intro message.
            </Paragraph> */}
            <XStack justifyContent='center' marginTop={15} space='$2'>
              {Platform.OS == 'web' && <Button {...flutterLinkProps}>Switch to Flutter UI</Button>}
              <Button theme="active" onClick={hideIntro}>Got It!</Button>
            </XStack>
          </>}
          {serversState.server != undefined || <Paragraph ta="center">
            Choose an account or server to get started.
          </Paragraph>}
        </YStack>

        <FlatList data={posts}
          keyExtractor={(post) => post.id}
          renderItem={({ item: post }) => {
            return <PostCard post={post} />;
          }} />

        <XStack>
          <Button {...linkProps} marginRight='$1'>[WIP] Link to user</Button>
          <Button {...postLinkProps}>[WIP] Link to post</Button>
        </XStack>

        {/* <AccountsSheet /> */}
      </YStack>
    </TabsNavigation>
  )
}
