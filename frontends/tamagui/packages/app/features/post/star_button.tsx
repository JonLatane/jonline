import { FederatedPost, JonlineServer, getCachedServerClient, getServerClient, getServerTheme, starPost, store, unstarPost, upsertPost, useServerTheme } from "app/store";
import React, { useEffect } from "react";

import { Button, Paragraph, Spinner, TamaguiMediaState, XStack, YStack, ZStack, useDebounce, useDebounceValue, useToastController } from '@jonline/ui';
import { Pin, PinOff, Star } from "@tamagui/lucide-icons";

import { useAppSelector } from "app/hooks";
import { federatedId, parseFederatedId } from 'app/store/federation';
import { useFederatedDispatch } from '../../hooks/credential_dispatch_hooks';
import { PostContext } from "@jonline/api/index";
import moment from "moment";

interface StarButtonProps {
  post: FederatedPost;
  eventMargins?: boolean;
}

export const StarButton: React.FC<StarButtonProps> = ({
  post,
  eventMargins = false
}) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(post);
  const federatedPostId = federatedId(post);
  const toast = useToastController();
  const starred = useAppSelector(state => state.app.starredPostIds.includes(federatedPostId));

  const { client } = accountOrServer.server
    ? getCachedServerClient(accountOrServer.server) ?? { client: undefined }
    : { client: undefined };

  const pendingStarChange = useDebounceValue(starred, 1500);
  const [firstStarred, setFirstStarred] = React.useState(starred);
  useEffect(() => {
    if (!accountOrServer.server) return;
    if (firstStarred === starred) return;

    if (pendingStarChange) {
      client?.starPost(post).then(post => {
        const federatedPost: FederatedPost = {
          ...post,
          serverHost: accountOrServer.server!.host,
        };
        store.dispatch(upsertPost(federatedPost));
      }).catch((e) => console.warn('Failed to star post on server', e));
    } else {
      client?.unstarPost(post).then(post => {
        const federatedPost: FederatedPost = {
          ...post,
          serverHost: accountOrServer.server!.host,
        };
        store.dispatch(upsertPost(federatedPost));
      }).catch((e) => console.warn('Failed to unstar post on server', e));
    }
    setFirstStarred(pendingStarChange);
  }, [pendingStarChange]);
  const eventInstanceId = useAppSelector(state => state.events.postInstances[federatedPostId]);
  const serverEventInstanceId = parseFederatedId(federatedPostId).id;
  const event = useAppSelector(state =>
    post.context === PostContext.EVENT_INSTANCE
      ? state.events.entities[
      state.events.instanceEvents[
      eventInstanceId ?? ''
      ] ?? ''
      ]
      : undefined);
  const eventInstance = event?.instances.find(i => i.id === serverEventInstanceId);
  const postTitle = event
    ? `${event?.post?.title}${eventInstance ? ` (${moment(eventInstance.startsAt).format('MMM D, h:mm a')})` : ''}`
    : post.title;
  function onPress() {
    if (starred) {
      dispatch(unstarPost(federatedPostId));
      toast.show(`Unstarred "${postTitle}"`);
    } else {
      dispatch(starPost(federatedPostId));
      toast.show(`Starred "${postTitle}"`);
    }
  }

  return <YStack ai='center'
    pt={5}
    ml={eventMargins ? 5 : -15}
    mr={eventMargins ? -12 : 3}
  >
    <Button transparent
      size='$2'
      p='$1'
      px={0}
      disabled={!post.id}
      onPress={onPress}
    >
      <ThemedStar {...{ starred, server: accountOrServer.server }} />
    </Button>
    <ZStack w='$2' h='$2'>
      <XStack animation='standard' mx='auto'
        o={firstStarred != starred ? 0.5 : 0}
      >
        <Spinner size='small' />
      </XStack>
      <XStack animation='standard' mx='auto'
        o={post.unauthenticatedStarCount > 0 ? 0.5 : 0}>
        <Paragraph size='$1' ta='center'>
          {post.unauthenticatedStarCount}
        </Paragraph>
      </XStack>
    </ZStack>
  </YStack>;
};

export type ThemedStarProps = {
  starred: boolean;
  server?: JonlineServer;
  invertColors?: boolean;
};

export const ThemedStar: React.FC<ThemedStarProps> = ({ starred, server, invertColors }) => {
  const { primaryAnchorColor, navColor } = useServerTheme(server);

  return <ZStack w='$2' h='$2' ml={2} mr={-2} mt={4}>
    <ZStack w='$2' h='$2' animation='standard' o={starred ? 0 : 1}>
      <Star o={0.5} />
    </ZStack>

    <ZStack w='$2' h='$2' animation='200ms' o={starred ? 1 : 0}>
      <Star scale={0.7} transform={[{ translateY: 0.5 }]} color={!invertColors ? navColor : primaryAnchorColor} />
    </ZStack>
    <ZStack w='$2' h='$2' animation='400ms' o={starred ? 1 : 0}>
      <Star scale={0.3} transform={[{ translateY: 2 }]} color={!invertColors ? navColor : primaryAnchorColor} />
    </ZStack>
    <ZStack w='$2' h='$2' animation='600ms' o={starred ? 1 : 0}>
      <Star scale={0.1} transform={[{ translateY: 7 }]} color={!invertColors ? navColor : primaryAnchorColor} />
    </ZStack>
    <ZStack w='$2' h='$2' animation='100ms' o={starred ? 1 : 0}>
      <Star scale={1} color={!invertColors ? primaryAnchorColor : navColor} />
    </ZStack>
    <ZStack w='$2' h='$2' animation='300ms' o={starred ? 1 : 0}>
      <Star scale={0.5} transform={[{ translateY: 1 }]} color={!invertColors ? primaryAnchorColor : navColor} />
    </ZStack>
    <ZStack w='$2' h='$2' animation='500ms' o={starred ? 1 : 0}>
      <Star scale={0.2} transform={[{ translateY: 2.5 }]} color={!invertColors ? primaryAnchorColor : navColor} />
    </ZStack>
    <ZStack w='$2' h='$2' animation='700ms' o={starred ? 1 : 0}>
      <Star scale={0.05} transform={[{ translateY: 12.5 }]} color={!invertColors ? primaryAnchorColor : navColor} />
    </ZStack>
  </ZStack>;
};