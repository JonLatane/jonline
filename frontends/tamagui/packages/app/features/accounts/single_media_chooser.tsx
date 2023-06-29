
import { Button, Heading, XStack, YStack } from '@jonline/ui';
import { Camera, Trash } from "@tamagui/lucide-icons";

import { standardAnimation } from "@jonline/ui";
import { useServerTheme } from "app/store";
import React from "react";
import { MediaChooser } from "../media/media_chooser";
import { } from "../post/post_card";

interface Props {
  mediaId: string | undefined;
  setMediaId: (mediaId: string | undefined) => void;
  mediaUseName?: string;
}
export const SingleMediaChooser: React.FC<Props> = ({ mediaId, setMediaId, mediaUseName = 'Avatar' }) => {
  const { server, primaryColor, navColor, primaryTextColor, navTextColor, textColor } = useServerTheme();
  const elementKey = `media-chooser-${mediaUseName.replace(' ', '-').toLowerCase()}`;
  return <YStack key={elementKey} animation='quick' {...standardAnimation}
    space='$2' mb='$2'>
    <MediaChooser
      selectedMedia={mediaId ? [mediaId] : []}
      onMediaSelected={media => { setMediaId?.(media.length == 0 ? undefined : media[0]) }} >
      <XStack>
        <Camera color={navTextColor} />
        <Heading color={navTextColor} ml='$3' my='auto' size='$1'>Choose {mediaUseName}</Heading>
      </XStack>
    </MediaChooser>
    <Button disabled={!mediaId} opacity={mediaId ? 1 : 0.5}
      onPress={() => setMediaId(undefined)}>
      <XStack>
        <Trash />
        <Heading ml='$3' my='auto' size='$1'>Remove {mediaUseName}</Heading>
      </XStack>
    </Button>
  </YStack>
}