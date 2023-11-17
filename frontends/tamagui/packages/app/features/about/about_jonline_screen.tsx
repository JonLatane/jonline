import { Anchor, Button, H2, H4, Heading, isClient, ListItem, needsScrollPreservers, Paragraph, Text, useWindowDimensions, XStack, YStack } from '@jonline/ui';
import { RootState, selectAllPosts, useCredentialDispatch, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { Linking, Platform } from 'react-native';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { Container, Github } from '@tamagui/lucide-icons';
import { AppSection } from '../tabs/features_navigation';
import { setDocumentTitle } from 'app/utils/set_title';

const quotes = [
  'I read about it Jonline',
  'I saw it Jonline',
  'Jonline media is ruining young minds',
  'Let me check Jonline',
];
export function AboutJonlineScreen() {
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
  const [quote] = useState(quotes[Math.floor(Math.random() * quotes.length)]);
  // const quote= quotes[Math.floor(Math.random()*quotes.length)];

  useEffect(() => {
    setDocumentTitle(`About Jonline`);
  });

  return (
    <TabsNavigation appSection={AppSection.INFO}>
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
          <AboutListItem>
            <XStack flexWrap='wrap' space='$2'>
              <Anchor color={navColor} href="https://github.com/JonLatane/jonline" target="_blank">
                <XStack space='$2'>
                  <YStack my='auto'><Github color={navColor} /></YStack>
                  <Paragraph color={navColor} my='auto'>GitHub: https://github.com/JonLatane/jonline</Paragraph>
                </XStack>
              </Anchor>
              <Paragraph>(released under the AGPLv3)</Paragraph>
            </XStack>
          </AboutListItem>
          <AboutListItem mb='$3'>
            <Anchor color={navColor} href="https://hub.docker.com/r/jonlatane/jonline" target="_blank">
              <XStack space='$2'>
                <YStack my='auto'><Container color={navColor} /></YStack>
                <Paragraph color={navColor} my='auto'>DockerHub: https://hub.docker.com/r/jonlatane/jonline</Paragraph>
              </XStack>
            </Anchor>
          </AboutListItem>
          {showTechDetails
            ? <>
              <Paragraph ta="left">
                You're reading this from Jonline's{' '}
                <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/frontends/tamagui" target="_blank">
                  React/Tamagui frontend
                </Anchor> backed by data from its{' '}
                <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/backend" target="_blank">
                  Rust/gRPC backend
                </Anchor>. It's a work in progress to be sure! 👷🛠️🪲 The original{' '}
                <Anchor color={navColor} href="https://github.com/JonLatane/jonline/tree/main/frontends/flutter" target="_blank">
                  Flutter frontend
                </Anchor> is also available and compatible, with more administrator features for now.
              </Paragraph>
              <XStack justifyContent='center' marginTop={15} mb='$3' space='$2'>
                {Platform.OS == 'web' && showTechDetails ? <Button onPress={() => Linking.openURL('/flutter')}>Open Flutter Web UI</Button> : undefined}
              </XStack>
              <Heading size='$5' mb='$2' mt='$3'>Built with:</Heading>
              <Heading size='$4'>Backend</Heading>
              <ListItem>
                <YStack>
                  <AboutListHeading>
                    <Anchor color={navColor} href="https://www.rust-lang.org/" target="_blank">
                      Rust
                    </Anchor> (<Anchor color={navColor} href="https://github.com/JonLatane/jonline/blob/main/backend/Cargo.toml" target="_blank">Cargo.toml</Anchor>)
                  </AboutListHeading>
                  <AboutListItem>
                    <Anchor color={navColor} href="https://diesel.rs/" target="_blank">
                      Diesel
                    </Anchor> (ORM/migrations)
                  </AboutListItem>
                  <AboutListItem>
                    <Anchor color={navColor} href="https://github.com/hyperium/tonic" target="_blank">
                      Tonic
                    </Anchor> (gRPC server)
                  </AboutListItem>
                  <AboutListItem>
                    <Anchor color={navColor} href="https://rocket.rs/" target="_blank">
                      Rocket
                    </Anchor> (HTTP/S web server)
                  </AboutListItem>
                </YStack>
              </ListItem>
              <Heading size='$4'>Frontends</Heading>
              <ListItem>
                <YStack>
                  <AboutListHeading>
                    <Anchor color={navColor} href="https://flutter.dev/" target="_blank">
                      Flutter
                    </Anchor> (<Anchor color={navColor} href="https://dart.dev/" target="_blank">Dart</Anchor>) (<Anchor color={navColor} href="https://github.com/JonLatane/jonline/blob/main/frontends/flutter/pubspec.yaml" target="_blank">pubspec.yaml</Anchor>)
                  </AboutListHeading>
                  <AboutListItem>
                    <Anchor color={navColor} href="https://pub.dev/packages/provider" target="_blank">
                      provider
                    </Anchor> (state management/DI)
                  </AboutListItem>
                  <AboutListItem>
                    <Anchor color={navColor} href="https://pub.dev/packages/auto_route" target="_blank">
                      auto_route
                    </Anchor> (routing/navigation)
                  </AboutListItem>
                  <AboutListHeading>
                    <Anchor color={navColor} href="https://reactjs.org/" target="_blank">
                      React Web+Native
                    </Anchor> (<Anchor color={navColor} href="https://www.typescriptlang.org/" target="_blank">TypeScript</Anchor>)
                  </AboutListHeading>
                  <AboutListItem>
                    <Anchor color={navColor} href="https://redux.js.org/" target="_blank">
                      Redux
                    </Anchor> (state management)
                  </AboutListItem>
                  <ListItem>
                    <YStack>
                      <AboutListHeading>
                        <Anchor color={navColor} href="https://tamagui.dev/" target="_blank">
                          Tamagui
                        </Anchor> (UI library/project structure)
                      </AboutListHeading>
                      <AboutListItem>
                        <Anchor color={navColor} href="https://nextjs.org/" target="_blank">
                          NextJS
                        </Anchor> (web builds)
                      </AboutListItem>
                      <AboutListItem>
                        <Anchor color={navColor} href="https://expo.dev/" target="_blank">
                          Expo
                        </Anchor> (native builds)
                      </AboutListItem>
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
            Side-hobby software. Expect bugs! 🛠️👷🏼‍♂️🪲
          </Heading>
          <Heading size='$3' mt='$3' mb='$10' ta='center'>
            Made with ❤️ by{' '}
            <Anchor color={navColor} href="https://instagram.com/jons_meaningless_life" target="_blank">
              Jon Latané
            </Anchor>.
          </Heading>
          {/* <Paragraph ta="center">
        If this is a new server, create an admin account and go to server configuration
        to set up your server and hide this intro message.
      </Paragraph> */}
        </YStack>
      </YStack>

      {/* </ZStack> */}
    </TabsNavigation>
  )
}

function AboutListItem({ children, ...props }) {
  return <ListItem {...props}>
    <AboutListHeading>
      {children}
    </AboutListHeading>
  </ListItem>;
}

function AboutListHeading({ children, ...props }) {
  return <Text fontFamily='$body' fontSize='$4' {...props}>
    {children}
  </Text>;
}