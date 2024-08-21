import { FederatedGroup, federateId, useServerTheme } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Group, Post } from "@jonline/api";
import { Anchor, Image, ScrollView, Spinner, XStack, YStack, useMedia } from '@jonline/ui';
import { useIsVisible, useMediaUrl, usePostDispatch, useCurrentServer, useLocalConfiguration } from "app/hooks";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, XEmbed, YouTubeEmbed } from 'react-social-media-embed';
import { useLink } from "solito/link";

import { FadeInView } from 'app/components';
import { MediaRenderer } from "../media/media_renderer";
import { postBackgroundSize } from "./post_card";

export interface PostMediaRendererProps {
  post: Post;
  isPreview?: boolean;
  groupContext?: FederatedGroup;
  isVisible: boolean;
  smallPreview?: boolean;
  xsPreview?: boolean;
  detailsLink?: LinkProps;
}

export type LinkProps = {
  accessibilityRole: "link";
  onPress: (e?: any) => void;
  href: string;
}

export const PostMediaRenderer: React.FC<PostMediaRendererProps> = ({
  post,
  isPreview,
  groupContext,
  isVisible,
  smallPreview,
  xsPreview,
  detailsLink: parentDetailsLink
}) => {
  const { dispatch, accountOrServer } = usePostDispatch(post);
  const mediaQuery = useMedia();
  const { primaryColor, navColor } = useServerTheme(accountOrServer.server);

  const currentServer = useCurrentServer();
  const isPrimaryServer = !!currentServer &&
    currentServer?.host === accountOrServer.server?.host;
  const isGroupPrimaryServer = !!currentServer &&
    currentServer?.host === groupContext?.serverHost;

  const detailsLinkId = !isPrimaryServer
    ? federateId(post.id, accountOrServer.server)
    : post.id;
  const detailsGroupShortname = groupContext
    ? (!isGroupPrimaryServer
      ? federateId(groupContext.shortname, accountOrServer.server)
      : groupContext.shortname)
    : undefined;
  const postDetailsLink = useLink({
    href: groupContext
      ? `/g/${detailsGroupShortname}/p/${detailsLinkId}`
      : `/post/${detailsLinkId}`,
  });
  const detailsLink: LinkProps = parentDetailsLink ?? postDetailsLink;
  const { preloadPostMedia } = useLocalConfiguration();

  const embedSupported = post.embedLink && post.link && post.link.length;
  let embedComponent: React.ReactNode | undefined = undefined;
  if (embedSupported) {
    const url = new URL(post.link!);
    const hostname = url.hostname.split(':')[0]!;
    if (hostname.endsWith('twitter.com') || hostname.endsWith('t.co') || hostname.endsWith('x.com')) {
      embedComponent = <XEmbed url={post.link!} />;
    } else if (hostname.endsWith('instagram.com')) {
      embedComponent = <InstagramEmbed width='100%' url={post.link!} />;
    } else if (hostname.endsWith('facebook.com')) {
      embedComponent = <FacebookEmbed width='100%' url={post.link!} />;
    } else if (hostname.endsWith('youtube.com')) {
      embedComponent = <YouTubeEmbed width='100%' url={post.link!} />;
    } else if (hostname.endsWith('tiktok.com')) {
      embedComponent = <TikTokEmbed width='100%' url={post.link!} />;
    } else if (hostname.endsWith('pinterest.com')) {
      embedComponent = <PinterestEmbed width='100%' url={post.link!} />;
    } else if (hostname.endsWith('linkedin.com')) {
      embedComponent = <LinkedInEmbed width='100%' url={post.link!} />;
    }
  }
  embedComponent = embedComponent
    ? <YStack mx='auto' width='100%' ai='center'>{embedComponent}</YStack>
    : undefined;

  const [hasBeenVisible, setHasBeenVisible] = useState(preloadPostMedia || false);
  useEffect(() => {
    if (isVisible && !hasBeenVisible) {
      setHasBeenVisible(true);
    }
  }, [isVisible, hasBeenVisible]);

  const generatedPreview = post?.media?.find(m => m.contentType.startsWith('image') && m.generated);
  const hasGeneratedPreview = generatedPreview && post?.media?.length == 1 && !embedComponent;

  const scrollableMediaMinCount = isPreview && hasGeneratedPreview ? 3 : 2;
  const showScrollableMediaPreviews = (post?.media?.length ?? 0) >= scrollableMediaMinCount;
  const singleMediaPreview = showScrollableMediaPreviews
    ? undefined
    : post?.media?.find(m => !m.generated);//m.contentType.startsWith('image') /*&& (!m.generated || !isPreview)*/);
  const singleMediaPreviewUrl = useMediaUrl(singleMediaPreview?.id);
  const backgroundImageUrl = useMediaUrl(hasGeneratedPreview ? generatedPreview?.id : undefined);

  const isReply = post.replyToPostId != null;
  const backgroundSize = postBackgroundSize(mediaQuery);
  const foregroundSize = backgroundSize * 0.7;

  const singlePreviewSize = xsPreview ? 150 : smallPreview ? 300 : foregroundSize;
  // console.log('PostMediaRenderer', { singleMediaPreview, showScrollableMediaPreviews, hasBeenVisible, media: post.media })

  return <YStack zi={1000} width='100%' ai='center'>
    {hasBeenVisible && embedComponent
      ? <FadeInView><div>{embedComponent}</div></FadeInView>
      : embedComponent
        ? <Spinner color={primaryColor} />
        : undefined}
    {showScrollableMediaPreviews ?
      <XStack w='100%' maw={800}>
        <ScrollView horizontal w={isPreview ? '260px' : '100%'}
          h={mediaQuery.gtXs ? '400px' : '260px'} >
          <XStack gap='$2'>
            {post.media.map((mediaRef, i) => {
              // debugger;
              return <YStack key={mediaRef.id} w={mediaQuery.gtXs ? '400px' : '260px'} h='100%'>
                <MediaRenderer media={mediaRef} isVisible={isVisible} isPreview={isPreview} />
              </YStack>;
            })}
          </XStack>
        </ScrollView>
      </XStack> : undefined}

    <Anchor w='100%' textDecorationLine='none' {...{ ...(isPreview && singleMediaPreview?.contentType.startsWith('image') ? detailsLink : {}) }}>
      <YStack w='100%'>
        {singleMediaPreview
          ?
          <YStack key={singleMediaPreview.id} w={singlePreviewSize} maw='100%' mah='100%' h={isPreview ? singlePreviewSize : undefined} mx='auto'>
            <MediaRenderer media={singleMediaPreview} isVisible={isVisible} />
          </YStack>
          // <Image
          //   mb='$3'
          //   width={singlePreviewSize}
          //   height={singlePreviewSize}
          //   // width={foregroundSize}
          //   // height={foregroundSize}
          //   resizeMode="contain"
          //   als="center"
          //   source={{
          //     uri: isVisible ? singleMediaPreviewUrl : undefined,
          //     height: singlePreviewSize,
          //     width: singlePreviewSize
          //   }}
          //   borderRadius={10}
          // />
          : undefined}
      </YStack>
    </Anchor>
  </YStack>;
};

// export default PostMediaRenderer;
