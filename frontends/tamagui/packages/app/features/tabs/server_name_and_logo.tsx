import { Group, Media, User, UserListingType, WebUserInterface } from "@jonline/api";
import { Button, Heading, isSafari, Paragraph, Popover, ScrollView, Theme, useMedia, XStack, YStack } from "@jonline/ui";
import { useTheme } from "@react-navigation/native";
import { Home as HomeIcon } from '@tamagui/lucide-icons';
import { JonlineServer, RootState, getUsersPage, loadUsersPage, markGroupVisit, useAccountOrServer, useServer, useServerTheme, useTypedDispatch, useTypedSelector } from "app/store";
import { Platform, TranslateXTransform } from 'react-native';
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupsSheet } from "../groups/groups_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, sectionTitle, useInlineFeatureNavigation } from "./features_navigation";
import { GroupContextProvider } from "../groups/group_context";
import { MediaRenderer } from "../media/media_renderer";
import { useEffect, useState } from "react";
import { serverID } from '../../store';

export type ServerNameAndLogoProps = {
  shrink?: boolean;
  server?: JonlineServer;
  enlargeSmallText?: boolean;
};

export function ServerNameAndLogo({ shrink, server: selectedServer, enlargeSmallText }: ServerNameAndLogoProps) {
  const mediaQuery = useMedia()

  const currentServer = useServer();
  const server = selectedServer ?? currentServer;
  console.log('ServerNameAndLogo', server?.host)

  const serverName = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  const serverNameEmoji = serverName.match(/\p{Emoji}/u)?.at(0);
  const [serverNameBeforeEmoji, serverNameAfterEmoji] = serverName
    .split(serverNameEmoji ?? '|', 2)
    .map(x => x.replace(/[^\x20-\x7E]/g, '').trim())
    ;
  const veryShortServername = serverNameBeforeEmoji!.length < 10;
  const shortServername = serverNameBeforeEmoji!.length < 12;
  const largeServername = (!serverNameAfterEmoji || serverNameAfterEmoji === '') && veryShortServername;

  const maxWidth = enlargeSmallText
    ? undefined
    : mediaQuery.gtXs
      ? 270
      : 200;
  const maxWidthAfterServerName = maxWidth ? maxWidth - (serverNameEmoji ? 50 : 0) : undefined;
  const logo = server?.serverConfiguration?.serverInfo?.logo;

  const canUseLogo = logo?.wideMediaId != undefined || logo?.squareMediaId != undefined;
  const useSquareLogo = canUseLogo && logo?.squareMediaId != undefined;
  const useWideLogo = canUseLogo && logo?.wideMediaId != undefined && !shrink;
  const useEmoji = serverNameEmoji && serverNameEmoji !== '';

  return shrink
    ? useSquareLogo
      ? <XStack h='100%' scale={1.1}
        transform={[
          { translateY: 1.5 },
          { translateX: isSafari() ? 8.0 : 2.0 }]
        } >
        <MediaRenderer server={server} forceImage media={Media.create({ id: logo?.squareMediaId })} failQuietly />
      </XStack>
      : <XStack h={'100%'} maw={maxWidthAfterServerName}>
        <Heading my='auto' whiteSpace="nowrap">{serverNameEmoji ?? ''}</Heading>
        {/* <Paragraph size='$1' lineHeight='$1' my='auto'>{serverNameWithoutEmoji}</Paragraph> */}
      </XStack>
    : <XStack h={'100%'} w='100%' space='$5' maw={maxWidthAfterServerName}>
      {useWideLogo
        ? <XStack h='100%' scale={1.05} transform={[{ translateY: 1.0 }, { translateX: 2.0 }]}>
          <MediaRenderer server={server} forceImage media={Media.create({ id: logo?.wideMediaId })} failQuietly />
        </XStack>
        : <>
          {useSquareLogo
            ? <XStack w={enlargeSmallText ? '$6' : '$3'} h={enlargeSmallText ? '$6' : '$3'} ml='$2' mr='$1' my='auto'>
              <MediaRenderer server={server} forceImage media={Media.create({ id: logo?.squareMediaId })} failQuietly />
            </XStack>
            : serverNameEmoji && serverNameEmoji != ''
              ? <Heading size={enlargeSmallText ? '$7' : undefined}
                my='auto' ml='$2' mr='$2' whiteSpace="nowrap">{serverNameEmoji}</Heading>
              : undefined}
          <YStack f={1} my='auto' mr='$2' space={enlargeSmallText ? '$2' : undefined}>
            {largeServername
              ? <Heading my='auto' whiteSpace="nowrap" overflow="hidden" textOverflow="ellipsis">{serverNameBeforeEmoji}</Heading>
              : <Paragraph size={enlargeSmallText ? '$7' : '$1'} fontWeight='bold' lineHeight={12} >{serverNameBeforeEmoji}{useSquareLogo && serverNameEmoji && serverNameEmoji != '' ? ` ${serverNameEmoji}` : undefined}</Paragraph>}
            {!largeServername && serverNameAfterEmoji && serverNameAfterEmoji !== '' && (mediaQuery.gtXs || shortServername)
              ? <Paragraph
                size={enlargeSmallText
                  ? serverNameAfterEmoji.length > 10 ? '$3' : '$7'
                  : '$1'
                }
                lineHeight={enlargeSmallText ? '$1' : 12}
              >
                {serverNameAfterEmoji}
              </Paragraph>
              : undefined}
          </YStack>
        </>}
    </XStack>;
}
