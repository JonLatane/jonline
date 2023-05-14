import { colorMeta, loadUser, RootState, selectUserById, serverUrl, useAccountOrServer, useCredentialDispatch, useServer, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Media } from "@jonline/api";
import { Card, Heading, Paragraph, Theme, useMedia, useTheme, XStack, YStack } from "@jonline/ui";
import { useOnScreen } from "app/hooks/use_on_screen";
import { TamaguiMarkdown } from "../post/tamagui_markdown";

interface Props {
  media: Media;
}

export const MediaRenderer: React.FC<Props> = ({ media }) => {
  const server = useServer();
  if (!server) return <></>;

  const type = media.contentType.split('/')[0];
  switch (type) {
    case 'image':
      return <img src={`${serverUrl(server)}/media/${media.id}`} />;
    default:
      return<Paragraph>Rendering is not implemented for this media type.</Paragraph>;
  }
};