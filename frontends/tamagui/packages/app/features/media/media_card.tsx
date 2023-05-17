import React from "react";
import { View } from "react-native";

import { Media } from "@jonline/api";
import { Card, Heading, Theme, XStack, YStack } from "@jonline/ui";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { MediaRenderer } from "./media_renderer";
import { DateViewer } from "@jonline/ui";

interface Props {
  media: Media;
}

export const MediaCard: React.FC<Props> = ({ media }) => {
  return (
    <Theme inverse={false}>
      <Card theme="dark" elevate size="$4" bordered
        margin='$0'
        marginBottom='$3'
        marginTop='$3'
        padding='$0'
        animation="bouncy"
        width='100%'
        opacity={1}
        scale={1}
        y={0}
        enterStyle={{ y: -50, opacity: 0, }}
        exitStyle={{ opacity: 0, }} >
        <Card.Header>
          <YStack>
            <XStack>
              <View style={{ flex: 1 }}>

                <Heading size="$7" marginRight='auto'>{media.name}</Heading>

              </View>
            </XStack>
          </YStack>
        </Card.Header>
        <Card.Footer>

          <YStack zi={1000} width='100%'>
            <MediaRenderer media={media} />
            <YStack>
              <TamaguiMarkdown text={media.description} />
            </YStack>
            <DateViewer date={media.createdAt} />
          </YStack>
        </Card.Footer>
      </Card>
    </Theme>
  );
};
