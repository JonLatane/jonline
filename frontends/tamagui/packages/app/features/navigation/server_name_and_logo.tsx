import { Media } from "@jonline/api";
import { Heading, Paragraph, Tooltip, XStack, YStack, useMedia } from "@jonline/ui";
import { Home } from "@tamagui/lucide-icons";
import { useServer } from "app/hooks";
import { JonlineServer } from "app/store";
import { MediaRenderer } from "../media/media_renderer";

export type ServerNameAndLogoProps = {
  shrinkToSquare?: boolean;
  server?: JonlineServer;
  enlargeSmallText?: boolean;
  fallbackToHomeIcon?: boolean;
  disableWidthLimits?: boolean;
  textColor?: string;
};

export function splitOnFirstEmoji(
  text: string, supportPipe?: boolean
): [string, string | undefined, string | undefined] {
  let partBeforeEmoji = text;
  let emoji = undefined as string | undefined;
  let partAfterEmoji = undefined as string | undefined;

  const regex = /\p{Extended_Pictographic}/u;
  const emojiMatch = text.match(regex);


  if (emojiMatch || supportPipe) {
    let fullySplitString = [...new Intl.Segmenter().segment(text)].map(x => x.segment)
    let fullySplitEmojiIndex = fullySplitString.findIndex(
      x => x.match(regex) || (supportPipe && x === '|')
    );
    if (fullySplitEmojiIndex !== -1) {
      partBeforeEmoji = fullySplitString.slice(0, fullySplitEmojiIndex).join('');
      emoji = fullySplitString[fullySplitEmojiIndex];
      partAfterEmoji = fullySplitString.slice(fullySplitEmojiIndex + 1).join('');
    }
  }

  return [partBeforeEmoji, emoji, partAfterEmoji];
}

export function ServerNameAndLogo({
  shrinkToSquare,
  server: selectedServer,
  enlargeSmallText = false,
  fallbackToHomeIcon = false,
  disableWidthLimits = false,
  textColor,
}: ServerNameAndLogoProps) {
  const mediaQuery = useMedia()

  const currentServer = useServer();
  const server = selectedServer ?? currentServer;

  const serverName = server?.serverConfiguration?.serverInfo?.name ?? '...';
  const [serverNameBeforeEmoji, serverNameEmoji, serverNameAfterEmoji] = splitOnFirstEmoji(serverName, true);
  const veryShortServername = serverNameBeforeEmoji!.length < 10;
  const shortServername = serverNameBeforeEmoji!.length < 12;
  const largeServername = veryShortServername && (['', undefined].includes(serverNameAfterEmoji));

  const maxWidth = enlargeSmallText || disableWidthLimits
    ? undefined
    : mediaQuery.gtXs
      ? 270
      : 170;
  const maxWidthAfterServerName = maxWidth ? maxWidth - (serverNameEmoji ? 50 : 0) : undefined;
  const logo = server?.serverConfiguration?.serverInfo?.logo;

  const canUseLogo = logo?.wideMediaId != undefined || logo?.squareMediaId != undefined;
  const useSquareLogo = canUseLogo && logo?.squareMediaId != undefined;
  const useWideLogo = canUseLogo && logo?.wideMediaId != undefined && !shrinkToSquare;
  const hasEmoji = serverNameEmoji && serverNameEmoji !== '';

  const imageLogoSize = enlargeSmallText ? '$6' : '$3';
  const serverEmojiFontSize = enlargeSmallText ? '$10' : '$8';

  const serverNameBreakdown = <YStack my='auto' f={1}
    ml='$1'
  // space={enlargeSmallText ? '$2' : '$0'}
  >
    <Heading my='auto'
      fontSize={largeServername
        ? enlargeSmallText ? '$9' : '$8'
        : enlargeSmallText ? '$8' : '$3'}
      m={0}
      p={0}
      color={textColor}
      lineHeight={largeServername || enlargeSmallText ? '$1' : 12}
    // whiteSpace="nowrap" overflow="hidden" textOverflow="ellipsis"
    >
      {serverNameBeforeEmoji}{useSquareLogo && hasEmoji && serverNameEmoji != '|' ? ` ${serverNameEmoji}` : undefined}
    </Heading>
    {!largeServername && serverNameAfterEmoji && serverNameAfterEmoji !== '' && (mediaQuery.gtXs || shortServername || true)
      ? <Paragraph
        color={textColor}
        size={enlargeSmallText
          ? serverNameAfterEmoji.length > 10 ? '$3' : '$7'
          : '$1'
        }
        lineHeight={enlargeSmallText ? '$1' : 12}
      >
        {serverNameAfterEmoji}
      </Paragraph>
      : undefined}
  </YStack>;

  return shrinkToSquare
    ? <Tooltip>
      <Tooltip.Trigger>
        {useSquareLogo
          ? <XStack h='100%'
            w='100%'
            scale={1.1}
            transform={[
              // { translateY: 1.5 },
              // { translateX: isSafari() ? 8.0 : 2.0 }
            ]} >
            <MediaRenderer serverOverride={server} forceImage media={Media.create({ id: logo?.squareMediaId })} failQuietly />
          </XStack>
          : <XStack h={'100%'} w='100%' scale={1.1}>
            <Heading m='auto' whiteSpace="nowrap" size='$9'>{serverNameEmoji ?? ''}</Heading>
            {/* <Paragraph size='$1' lineHeight='$1' my='auto'>{serverNameWithoutEmoji}</Paragraph> */}
          </XStack>}
      </Tooltip.Trigger >
      <Tooltip.Content>
        {serverNameBreakdown}
      </Tooltip.Content>
    </Tooltip>
    : <XStack
      mr={'$2'}
      h={'100%'} w='100%'
      space='$5'
      pl={useSquareLogo ? '$1' : undefined}
      maw={maxWidth}
    >
      {useWideLogo
        ?
        <Tooltip>
          <Tooltip.Trigger><XStack h='100%' scale={1.05} transform={[{ translateY: 1.0 }, { translateX: 2.0 }]}>
            <MediaRenderer serverOverride={server} forceImage media={Media.create({ id: logo?.wideMediaId })} failQuietly />
          </XStack>
          </Tooltip.Trigger>
          <Tooltip.Content>
            {serverNameBreakdown}
          </Tooltip.Content>
        </Tooltip>
        : <>
          {useSquareLogo
            ? <XStack
              w={imageLogoSize}
              h={imageLogoSize} ml='$2' mr='$1' my='auto'>
              <MediaRenderer serverOverride={server} forceImage media={Media.create({ id: logo?.squareMediaId })} failQuietly />
            </XStack>
            : hasEmoji
              ? <Heading size={serverEmojiFontSize}
                color={textColor}
                my='auto' ml='$2' mr='$2' whiteSpace="nowrap">{serverNameEmoji}</Heading>
              : fallbackToHomeIcon
                ? <XStack my='auto' mr='$1'><Home size={enlargeSmallText ? '$5' : '$2'} /> </XStack>
                : undefined}

          {serverNameBreakdown}
        </>}
    </XStack>;
}
