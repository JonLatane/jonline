import { serverUrl, useServer, useServerTheme } from "app/store";
import React from "react";

import { Media } from "@jonline/api";
import { Anchor, Paragraph, Text, YStack, useMedia } from "@jonline/ui";
import ReactPlayer from 'react-player/lazy'

interface Props {
  media: Media;
}

export const MediaRenderer: React.FC<Props> = ({ media }) => {
  const { server, navAnchorColor } = useServerTheme();
  const mediaQuery = useMedia();
  if (!server) return <></>;

  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  const mediaUrl = `${serverUrl(server)}/media/${media.id}`;
  const type = media.contentType.split('/')[0];
  const subType = media.contentType.split('/')[1];
  switch (type) {
    case 'image':
      return <img src={mediaUrl} width='95%' />;
    case 'video':
      return <YStack w='100%' ac='center' jc='center'>
        <ReactPlayer width='100%' height={mediaQuery.gtXs ? '500px' : '300px'}
          url={mediaUrl} controls muted />
      </YStack>;
    default:
  }

  // If all else fails, render it as an HTML object and rely on the tag's standard fallback.
  return <object style={{backgroundColor: isSafari ? 'white': undefined}} data={mediaUrl} type={media.contentType} width="100%" height={mediaQuery.gtXs ? '500px' : '350px'}>
    <Paragraph>
      Media rendering is not yet implemented for type <Text fontFamily='monospace'>{media.contentType}</Text>. <Anchor href={mediaUrl} color={navAnchorColor}>Download</Anchor> instead.
    </Paragraph>
  </object>;
};