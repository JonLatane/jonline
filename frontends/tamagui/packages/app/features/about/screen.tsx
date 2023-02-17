import { Anchor, Button, H2, H4, Heading, Text, Paragraph, XStack, YStack } from '@jonline/ui';
import { GetPostsRequest, isClient, ListItem, Spinner, useWindowDimensions, ZStack } from '@jonline/ui/src';
import { dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui/src/global';
import { RootState, selectAllPosts, setShowIntro, loadPostsPage, useCredentialDispatch, useTypedSelector } from 'app/store';
import React, { useState, useEffect } from 'react';
import { FlatList, Linking, Platform } from 'react-native';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';
import StickyBox from "react-sticky-box";

const quotes = [
  'I read about it Jonline',
  'I saw it Jonline',
  'Jonline media is ruining young minds',
  'Let me check Jonline',
];
export function AboutScreen() {
  const [showTechDetails, setShowTechDetails] = useState(false);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const app = useTypedSelector((state: RootState) => state.app);
  const posts = useTypedSelector((state: RootState) => selectAllPosts(state.posts));
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  let { dispatch, accountOrServer } = useCredentialDispatch();
  let primaryColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.primary;
  let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  const dimensions = useWindowDimensions();
  const [quote] = useState(quotes[Math.floor(Math.random()*quotes.length)]);
  // const quote= quotes[Math.floor(Math.random()*quotes.length)];


  return (
    <TabsNavigation>
      {/* <ZStack f={1} w='100%' jc="center" ai="center" p="$0"> */}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        <YStack space="$4" maw={600}>

          <H2 ta="center">About Jonline</H2>
          <H4 ta="center">As in: &ldquo;{quote}&rdquo; 🙃</H4>
          <Paragraph ta="left">
            Jonline is the federated social network platform built with Rust/gRPC that powers this
            web site{isClient ? <>{' ('}<Text color={navColor} fontFamily='$body'>{window.location.host}</Text>{')'}</> : ''}.
            It's designed to let small businesses and communities run their own social network,{' '}
            with minimal cost, effort, and no creepy corporate data mining;{' '}
            to make it easy to link to posts and events from other networks/local businesses;{' '}
            and to be intuitive and fun for customers, members, and administrators alike.
          </Paragraph>
          {showTechDetails
            ? <>
              <ListItem>
                <Anchor color={navColor} href="https://github.com/JonLatane/jonline" target="_blank">
                  Jonline on GitHub (give it a ⭐️!)
                </Anchor>
              </ListItem>
              <ListItem mb='$3'>
                <Anchor color={navColor} href="https://hub.docker.com/r/jonlatane/jonline" target="_blank">
                  Jonline on DockerHub
                </Anchor>
              </ListItem>
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
                >Tamagui</Anchor>. It's a work in progress to be sure! 👷🛠️🪲 The{' '}
                <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/frontends/flutter" target="_blank">
                  original Flutter UI
                </Anchor> is also available and compatible, with more features for now.
              </Paragraph>
              <Heading size='$5' mb='$2' mt='$3'>Built with:</Heading>
              <Heading size='$4'>Backend</Heading>
              <ListItem>
                <YStack>
                  <Anchor color={navColor} href="https://www.rust-lang.org/" target="_blank">
                    Rust
                  </Anchor>
                  <ListItem>
                    <Anchor color={navColor} href="https://diesel.rs/" target="_blank">
                      Diesel
                    </Anchor>
                  </ListItem>
                  <ListItem>
                    <Anchor color={navColor} href="https://github.com/hyperium/tonic" target="_blank">
                      Tonic (gRPC backend server)
                    </Anchor>
                  </ListItem>
                  <ListItem>
                    <Anchor color={navColor} href="https://rocket.rs/" target="_blank">
                      Rocket (HTTP/S web server)
                    </Anchor>
                  </ListItem>
                </YStack>
              </ListItem>
              <Heading size='$4'>Frontends</Heading>
              <ListItem>
                <YStack>
                  <Anchor color={navColor} href="https://flutter.dev/" target="_blank">
                    Flutter
                  </Anchor>
                  <ListItem>
                    <Anchor color={navColor} href="https://pub.dev/packages/provider" target="_blank">
                      provider
                    </Anchor>
                  </ListItem>
                  <ListItem>
                    <Anchor color={navColor} href="https://pub.dev/packages/auto_route" target="_blank">
                      auto_route
                    </Anchor>
                  </ListItem>
                  <Anchor color={navColor} href="https://reactjs.org/" target="_blank">
                    React
                  </Anchor>
                  <ListItem>
                    <Anchor color={navColor} href="https://redux.js.org/" target="_blank">
                      Redux
                    </Anchor>
                  </ListItem>
                  <ListItem>
                    <YStack>
                      <Anchor color={navColor} href="https://tamagui.dev/" target="_blank">
                        Tamagui
                      </Anchor>
                      <ListItem>
                        <Anchor color={navColor} href="https://nextjs.org/" target="_blank">
                          NextJS
                        </Anchor>
                      </ListItem>
                      <ListItem>
                        <Anchor color={navColor} href="https://expo.dev/" target="_blank">
                          Expo
                        </Anchor>
                      </ListItem>
                    </YStack>
                  </ListItem>
                </YStack>
              </ListItem>
            </>
            : <>
              <Button onPress={() => setShowTechDetails(true)}>
                More Tech Details
              </Button>
            </>}
          <Heading size='$5' mt='$3' ta='center'>
            Beta software. Expect bugs! 🛠️👷🏼‍♂️🪲
          </Heading>
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

          <XStack justifyContent='center' marginTop={15} mb='$10' space='$2'>
            {Platform.OS == 'web' && showTechDetails ? <Button onPress={() => Linking.openURL('/flutter')}>Open Flutter Web UI</Button> : undefined}
            {/* <Button backgroundColor={primaryColor} onClick={hideIntro}>
                {Platform.OS == 'web' && showTechDetails ? 'Got It!' : 'Got It, Thanks!'}
              </Button> */}
          </XStack>
        </YStack>
      </YStack>

      {/* </ZStack> */}
    </TabsNavigation>
  )
}
