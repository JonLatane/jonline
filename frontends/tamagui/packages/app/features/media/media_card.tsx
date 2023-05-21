import React from "react";
import { View } from "react-native";

import { Media, Permission } from "@jonline/api";
import { AlertDialog, Button, Card, Heading, Theme, XStack, YStack, useMedia } from "@jonline/ui";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { MediaRenderer } from "./media_renderer";
import { DateViewer } from "@jonline/ui";
import { deleteMedia, useAccountOrServer, useCredentialDispatch, useServerTheme } from "app/store";
import { Trash } from '@tamagui/lucide-icons';

interface Props {
  media: Media;
  selected?: boolean;
  onSelect?: () => void;
}

export const MediaCard: React.FC<Props> = ({ media, onSelect, selected = false }) => {
  const mediaQuery = useMedia();
  const {primaryColor, navColor, navTextColor} = useServerTheme();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { account, server } = accountOrServer;
  const isAdmin = account?.user?.permissions.includes(Permission.ADMIN);
  const isOwnMedia = media.userId != null && media.userId == account?.user?.id;
  const canDelete = isAdmin || isOwnMedia;
  const mediaName = media.name && media.name.length > 0 ? media.name : undefined;
  return (
    <Theme inverse={selected}>
      <Card theme="dark" elevate size="$4" bordered
        key={`media-card-${media.id}`}
        margin='$0'
        my='$3'
        p='$0'
        animation="bouncy"
        width='100%'
        scale={1}
        opacity={1}
        y={0}
        enterStyle={{ y: -50, opacity: 0, }}
        exitStyle={{ opacity: 0, }}
        pressStyle={onSelect ? { scale: 0.990 } : {}}
        onPress={onSelect} >
        <Card.Header>
          <YStack>
            <XStack>
              <View style={{ flex: 1 }}>
                <Heading size='$7' marginRight='auto'>{media.name}</Heading>
              </View>
            </XStack>
          </YStack>
        </Card.Header>
        <Card.Footer>

          <YStack zi={1000} width='100%' mih={mediaQuery.gtXs ? '400px' : '260px'}>
            <YStack f={1}>
              <MediaRenderer media={media} />
            </YStack>

            <TamaguiMarkdown text={media.description} />
            <DateViewer date={media.createdAt} />

            {canDelete
              ? <>
                <AlertDialog native>
                  <AlertDialog.Trigger asChild mb='$3'>
                    <Button size='$2' circular icon={Trash} ml='auto' />
                  </AlertDialog.Trigger>

                  <AlertDialog.Portal>
                    <AlertDialog.Overlay
                      key="overlay"
                      animation="quick"
                      opacity={0.5}
                      enterStyle={{ opacity: 0 }}
                      exitStyle={{ opacity: 0 }}
                    />
                    <AlertDialog.Content
                      bordered
                      elevate
                      key="content"
                      animation={[
                        'quick',
                        {
                          opacity: {
                            overshootClamping: true,
                          },
                        },
                      ]}
                      // enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
                      // exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
                      x={0}
                      scale={1}
                      opacity={1}
                      y={0}
                    >
                      <YStack space>
                        <AlertDialog.Title>Confirmation</AlertDialog.Title>
                        <AlertDialog.Description>
                          Are you sure you want to delete {mediaName ?? 'this media'}? It will immediately be removed from your media, but it may continue to be available for the next 12 hours for some users.
                        </AlertDialog.Description>

                        <XStack space="$3" justifyContent="flex-end">
                          <AlertDialog.Cancel asChild>
                            <Button>Cancel</Button>
                          </AlertDialog.Cancel>
                          <AlertDialog.Action asChild>
                            <Button backgroundColor={navColor} color={navTextColor} onPress={() => {
                              console.log("calling deleteMedia!");
                              dispatch(deleteMedia({ id: media.id, ...accountOrServer }));
                            }}>Delete</Button>
                          </AlertDialog.Action>
                        </XStack>
                      </YStack>
                    </AlertDialog.Content>
                  </AlertDialog.Portal>
                </AlertDialog>
              </>
              : undefined}
          </YStack>
        </Card.Footer>
      </Card>
    </Theme >
  );
};
