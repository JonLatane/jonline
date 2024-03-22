import { useCredentialDispatch, useProvidedDispatch } from "app/hooks";
import { JonlineServer, RootState, getServerTheme, loadMedia, selectMediaById, useRootSelector, useServerTheme } from "app/store";
import React, { useEffect } from 'react';

import { Anchor, Paragraph, Text, YStack, useMedia } from "@jonline/ui";
import ReactPlayer from 'react-player/lazy';
import { useMediaUrl } from '../../hooks/use_media_url';
import { MediaRef } from "./media_chooser";

interface Props {
  media: MediaRef;
  failQuietly?: boolean;
  serverOverride?: JonlineServer;
  forceImage?: boolean;
}

export const MediaRenderer: React.FC<Props> = ({ media, failQuietly = false, serverOverride, forceImage }) => {
  const { dispatch, accountOrServer } = useProvidedDispatch(serverOverride);
  const server = accountOrServer.server;
  const { navAnchorColor } = getServerTheme(server);
  const mediaQuery = useMedia();
  if (!server) return <></>;

  const ReactPlayerShim = ReactPlayer as any;

  const mediaUrl = useMediaUrl(media.id, { server });
  // console.log(`mediaUrl for ${server.host} is ${mediaUrl}`)
  let [type, subType] = media.contentType.split('/');
  if (forceImage) {
    type = 'image';
  }

  switch (type) {
    case 'image':
      return <img style={{ height: '100%', width: '100%', objectFit: 'contain' }} src={mediaUrl} />;
    case 'video':
      return <YStack w='100%' ac='center' jc='center' h='100%'>
        <ReactPlayerShim width='100%' style={{ maxHeight: mediaQuery.gtXs ? '500px' : '300px' }}
          height='100%' url={mediaUrl} controls muted />
      </YStack>;
    default:
      // If all else fails, render it as an HTML object and rely on the tag's standard fallback.
      return <object style={{ backgroundColor: 'white' }} data={mediaUrl} type={media.contentType} width="100%" height={mediaQuery.gtXs ? '500px' : '350px'}>
        {failQuietly ? undefined : <YStack p='$3'>
          <Paragraph size='$2' color={'black'}>
            Media rendering is not supported in your browser for type <Text fontFamily='$mono' color={'black'}>{media.contentType}</Text>. <Anchor href={mediaUrl} color={navAnchorColor}>Download it instead.</Anchor>
          </Paragraph>
        </YStack>}
      </object>;
  }
};
