
import { Button, Heading, XStack, YStack } from '@jonline/ui';
import { Camera, Trash } from "@tamagui/lucide-icons";

import { standardAnimation } from "@jonline/ui";
import { useServerTheme } from "app/store";
import React from "react";
import { MediaChooser, MediaRef } from "../media/media_chooser";
import { } from "../post/post_card";

interface Props {
  selectedMedia: MediaRef | undefined;
  setSelectedMedia: (media?: MediaRef) => void;
  mediaUseName?: string;
  disabled?: boolean;
}
export const SingleMediaChooser: React.FC<Props> = ({ selectedMedia, setSelectedMedia, mediaUseName = 'Avatar', disabled }) => {
  const { server, primaryColor, navColor, primaryTextColor, navTextColor, textColor } = useServerTheme();
  const elementKey = `media-chooser-${mediaUseName.replace(' ', '-').toLowerCase()}`;
  return <YStack key={elementKey} animation='quick' {...standardAnimation}
    space='$2' mb='$2'>
    <MediaChooser
      selectedMedia={selectedMedia ? [selectedMedia] : []}
      disabled={disabled}
      onMediaSelected={media => { setSelectedMedia?.(media.length == 0 ? undefined : media[media.length -1 ]) }} >
      <XStack>
        <Camera color={navTextColor} />
        <Heading color={navTextColor} ml='$3' my='auto' size='$1'>Choose {mediaUseName}</Heading>
      </XStack>
    </MediaChooser>
    <Button disabled={!selectedMedia || disabled} opacity={selectedMedia ? 1 : 0.5}
      onPress={() => setSelectedMedia(undefined)}>
      <XStack>
        <Trash />
        <Heading ml='$3' my='auto' size='$1'>Remove {mediaUseName}</Heading>
      </XStack>
    </Button>
  </YStack>
}