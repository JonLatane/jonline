import { MediaReference } from '@jonline/api';
import { Button, ScrollView, XStack, YStack, ZStack, standardAnimation, useMedia } from '@jonline/ui';
import { ArrowLeft, ArrowRight, Delete } from '@tamagui/lucide-icons';
import React from 'react';
import { MediaChooser } from '../media/media_chooser';
import { MediaRenderer } from '../media/media_renderer';
import { ToggleRow } from 'app/components';
import FlipMove from 'lumen5-react-flip-move';

export type PostMediaManagerProps = {
  entityName?: string;
  link?: string;
  media: MediaReference[];
  setMedia: (media: MediaReference[]) => void;
  embedLink: boolean;
  setEmbedLink: (embedLink: boolean) => void;
  // editing?: boolean;
  disableInputs?: boolean;
}

export function PostMediaManager({ entityName = 'Post', media, setMedia, link = '', embedLink, setEmbedLink, disableInputs }: PostMediaManagerProps) {
  const mediaQuery = useMedia();

  const canEmbedLink = ['instagram', 'facebook', 'linkedin', 'tiktok', 'youtube', 'twitter', 'pinterest']
    .map(x => link.includes(x)).reduce((a, b) => a || b, false);

  function moveRefLeft(mediaRef: MediaReference, index: number) {
    const updatedMedia = new Array<MediaReference>(...media);
    const leftValue = updatedMedia[index - 1]!;
    updatedMedia[index - 1] = mediaRef;
    updatedMedia[index] = leftValue;
    setMedia(updatedMedia);
  }

  function moveRefRight(mediaRef: MediaReference, index: number) {
    const updatedMedia = new Array<MediaReference>(...media);
    const rightValue = updatedMedia[index + 1]!;
    updatedMedia[index + 1] = mediaRef;
    updatedMedia[index] = rightValue;
    setMedia(updatedMedia);
  }
  return <YStack key='post-media-manager' ac='center'
    jc='center'
    marginHorizontal='$5'
    p='$3'
    animation='standard'
    {...standardAnimation}
  >
    {media.length > 0 ? <ScrollView horizontal w='100%'>
      {/* <XStack gap='$2'> */}
      <FlipMove style={{ display: 'flex', gap: 10, }}>
        {media.map((mediaRef, index) =>
          <ZStack key={`media-renderer-${mediaRef.id}`} w={mediaQuery.gtXs ? 350 : 148} h={mediaQuery.gtXs ? 280 : 195}>
            {/* <ZStack> */}
            <MediaRenderer key={`media-renderer-${mediaRef.id}`} media={mediaRef} />
            <XStack w='100%' my='auto' zi={1000}>
              <Button ml='$2' circular o={index == 0 ? 0.3 : 0.9} icon={ArrowLeft} onPress={() => {
                const updatedMedia = new Array<MediaReference>(...media);
                const leftValue = updatedMedia[index - 1]!;
                updatedMedia[index - 1] = mediaRef;
                updatedMedia[index] = leftValue;
                setMedia(updatedMedia);
              }} />
              <YStack f={1} />
              <Button mr='$2' circular o={index < media.length - 1 ? 0.9 : 0.3} icon={ArrowRight} onPress={() => {
                const updatedMedia = new Array<MediaReference>(...media);
                const rightValue = updatedMedia[index + 1]!;
                updatedMedia[index + 1] = mediaRef;
                updatedMedia[index] = rightValue;
                setMedia(updatedMedia);
              }} />
            </XStack>
            <XStack w='100%' zi={1000}>
              <YStack f={1} />
              <Button size='$2' mr='$2' circular icon={Delete} onPress={() => {
                setMedia(media.filter((_, i) => i != index));
              }} />
            </XStack>
            {/* </ZStack> */}
          </ZStack>
        )}
      </FlipMove>
      {/* </XStack> */}
    </ScrollView> : undefined}
    <MediaChooser selectedMedia={media} onMediaSelected={setMedia} multiselect />
    <YStack h='$0' mt='$2' />
    {canEmbedLink
      ? <ToggleRow name='Embed Link'
        value={embedLink && canEmbedLink}
        setter={(v) => setEmbedLink(v)}
        disabled={disableInputs || !canEmbedLink} />
      : undefined}
  </YStack>
}
