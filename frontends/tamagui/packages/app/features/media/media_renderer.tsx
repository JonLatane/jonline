import { useCredentialDispatch, useIsVisible, useProvidedDispatch } from "app/hooks";
import { JonlineServer, RootState, getServerTheme, loadMedia, selectMediaById, useRootSelector, useServerTheme } from "app/store";
import React, { useEffect, useState } from 'react';
import { View } from 'react-native';

import { Anchor, Paragraph, Text, XStack, YStack, useMedia } from "@jonline/ui";
import ReactPlayer from 'react-player/lazy';
import { useMediaUrl } from '../../hooks/use_media_url';
import { MediaRef } from "./media_chooser";
import { FadeInView } from "../post";

interface Props {
  media: MediaRef;
  failQuietly?: boolean;
  serverOverride?: JonlineServer;
  forceImage?: boolean;
  isVisible?: boolean;
}

// MediaRenderers will always be styled with width=100% and height=100%.
// Use them accordingly.
export const MediaRenderer: React.FC<Props> = ({
  media,
  failQuietly = false,
  serverOverride,
  forceImage,
  isVisible = true
}) => {
  const { dispatch, accountOrServer } = useProvidedDispatch(serverOverride);
  const server = accountOrServer.server;
  const { navAnchorColor } = getServerTheme(server);
  const mediaQuery = useMedia();

  const [hasBeenVisible, setHasBeenVisible] = useState(false);
  useEffect(() => {
    if (isVisible && !hasBeenVisible) {
      setHasBeenVisible(true);
    }
  }, [isVisible, hasBeenVisible]);

  const ReactPlayerShim = ReactPlayer as any;

  const mediaUrl = useMediaUrl(media.id, { server });
  // console.log(`mediaUrl for ${server.host} is ${mediaUrl}`)
  let [type, subType] = media.contentType.split('/');
  if (forceImage) {
    type = 'image';
  }

  if (!server) return <></>;
  if (!hasBeenVisible) return <></>;

  let view: JSX.Element;
  switch (type) {
    case 'image':
      if (!isVisible) return <></>;

      return <FadeInView w='100%' h='100%'>
        <img style={{ width: '100%', height: '100%', objectFit: 'contain' }}
          src={mediaUrl} />
      </FadeInView>;
    case 'video':
      return <FadeInView w='100%' h='100%'>
        <YStack w='100%' h='100%' ac='center' jc='center'>
          <ReactPlayerShim width='100%' style={{ maxHeight: mediaQuery.gtXs ? '500px' : '300px' }}
            height='100%' url={mediaUrl} controls muted />
        </YStack>
      </FadeInView>;
    default:
      // If all else fails, render it as an HTML object and rely on the tag's standard fallback.
      return <FadeInView w='100%' h='100%'>
        <object style={{ width: '100%', height: '100%', backgroundColor: 'white' }} data={mediaUrl} type={media.contentType} width="100%" height={mediaQuery.gtXs ? '500px' : '350px'}>
          {failQuietly ? undefined : <YStack p='$3'>
            <Paragraph size='$2' color={'black'}>
              Media rendering is not supported in your browser for type <Text fontFamily='$mono' color={'black'}>{media.contentType}</Text>. <Anchor href={mediaUrl} color={navAnchorColor}>Download it instead.</Anchor>
            </Paragraph>
          </YStack>}
        </object>
      </FadeInView>;
  }
};
