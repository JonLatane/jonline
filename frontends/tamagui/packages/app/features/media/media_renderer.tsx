import { RootState, loadMedia, selectMediaById, serverUrl, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useState, useEffect } from 'react';

import { Media, MediaReference } from "@jonline/api";
import { Anchor, Image, Paragraph, Text, YStack, useMedia } from "@jonline/ui";
import ReactPlayer from 'react-player/lazy';
import { useMediaUrl } from '../../hooks/use_media_url';
import { MediaRef } from "./media_chooser";

interface Props {
  media: MediaRef;
  failQuietly?: boolean;
}

export const MediaRenderer: React.FC<Props> = ({ media: sourceMedia, failQuietly = false }) => {
  const { server, navAnchorColor } = useServerTheme();
  const mediaQuery = useMedia();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  if (!server) return <></>;

  const ReactPlayerShim = ReactPlayer as any;

  const reduxMedia = useTypedSelector((state: RootState) => selectMediaById(state.media, sourceMedia.id));
  useEffect(() => {
    if (reduxMedia?.contentType.length ?? 0 == 0) {
      dispatch(loadMedia({ ...sourceMedia, ...accountOrServer }));
    }
  }, [reduxMedia]);
  const media = reduxMedia ?? sourceMedia;

  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  const mediaUrl = useMediaUrl(media.id);
  const [type, subType] = media.contentType.split('/');

  switch (type) {
    case 'image':
      return <img style={{ height: '95%', width: '95%', objectFit: 'contain' }} src={mediaUrl} />;
    // return <Image source={{ uri: mediaUrl }}
    //   resizeMode='contain'
    //   height='95%'
    //   width='95%' />;
    case 'video':
      return <YStack w='100%' ac='center' jc='center' h='100%'>
        <ReactPlayerShim width='100%' style={{ maxHeight: mediaQuery.gtXs ? '500px' : '300px' }}
          height='100%' url={mediaUrl} controls muted />
      </YStack>;
    default:
  }

  // If all else fails, render it as an HTML object and rely on the tag's standard fallback.
  return <object style={{ backgroundColor: 'white' }} data={mediaUrl} type={media.contentType} width="100%" height={mediaQuery.gtXs ? '500px' : '350px'}>
    {failQuietly ? undefined : <YStack p='$3'>
      <Paragraph size='$2' color={'black'}>
        Media rendering is not supported in your browser for type <Text fontFamily='$mono' color={'black'}>{media.contentType}</Text>. <Anchor href={mediaUrl} color={navAnchorColor}>Download it instead.</Anchor>
      </Paragraph>
    </YStack>}
  </object>;
};
