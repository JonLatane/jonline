import { getServerTheme } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Group, Post } from "@jonline/api";
import { Anchor, Image, ScrollView, Spinner, XStack, YStack, useMedia } from '@jonline/ui';
import { useIsVisible, useMediaUrl, usePostDispatch } from "app/hooks";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from 'react-social-media-embed';
import { useLink } from "solito/link";

import { FadeInView } from 'app/components';
import { MediaRenderer } from "../media/media_renderer";
import { postBackgroundSize } from "./post_card";

export interface PostMediaRendererProps {
  post: Post;
  isPreview?: boolean;
  groupContext?: Group;
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
  const { primaryColor, navColor } = getServerTheme(accountOrServer.server);
  const postDetailsLink = useLink({
    href: groupContext
      ? `/g/${groupContext.shortname}/p/${post.id}`
      : `/post/${post.id}`,
  });
  const detailsLink: LinkProps = parentDetailsLink ?? postDetailsLink;

  const embedSupported = post.embedLink && post.link && post.link.length;
  let embedComponent: React.ReactNode | undefined = undefined;
  if (embedSupported) {
    const url = new URL(post.link!);
    const hostname = url.hostname.split(':')[0]!;
    if (hostname.endsWith('twitter.com')) {
      embedComponent = <TwitterEmbed url={post.link!} />;
    } else if (hostname.endsWith('instagram.com')) {
      embedComponent = <InstagramEmbed url={post.link!} />;
    } else if (hostname.endsWith('facebook.com')) {
      embedComponent = <FacebookEmbed url={post.link!} />;
    } else if (hostname.endsWith('youtube.com')) {
      embedComponent = <YouTubeEmbed url={post.link!} />;
    } else if (hostname.endsWith('tiktok.com')) {
      embedComponent = <TikTokEmbed url={post.link!} />;
    } else if (hostname.endsWith('pinterest.com')) {
      embedComponent = <PinterestEmbed url={post.link!} />;
    } else if (hostname.endsWith('linkedin.com')) {
      embedComponent = <LinkedInEmbed url={post.link!} />;
    }
  }

  const [hasBeenVisible, setHasBeenVisible] = useState(false);
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
    : post?.media?.find(m => m.contentType.startsWith('image') /*&& (!m.generated || !isPreview)*/);
  const singleMediaPreviewUrl = useMediaUrl(singleMediaPreview?.id);
  const backgroundImageUrl = useMediaUrl(hasGeneratedPreview ? generatedPreview?.id : undefined);

  const backgroundSize = postBackgroundSize(mediaQuery);
  const foregroundSize = backgroundSize * 0.7;

  const singlePreviewSize = xsPreview ? 150 : smallPreview ? 300 : foregroundSize;

  return <YStack zi={1000} width='100%'>
    {hasBeenVisible && embedComponent && false
      ? <FadeInView><div>{embedComponent}</div></FadeInView>
      : embedComponent
        ? <Spinner color={primaryColor} />
        : undefined}
    {showScrollableMediaPreviews ?
      <XStack w='100%' maw={800}>
        <ScrollView horizontal w={isPreview ? '260px' : '100%'}
          h={mediaQuery.gtXs ? '400px' : '260px'} >
          <XStack gap='$2'>
            {post.media.map((mediaRef, i) => <YStack key={mediaRef.id} w={mediaQuery.gtXs ? '400px' : '260px'} h='100%'>
              <MediaRenderer media={mediaRef} isVisible={isVisible} />
            </YStack>)}
          </XStack>
        </ScrollView>
      </XStack> : undefined}

    <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
      <YStack>
        {singleMediaPreview
          ? <Image
            mb='$3'
            width={500}
            height={500}
            // width={foregroundSize}
            // height={foregroundSize}
            resizeMode="contain"
            als="center"
            source={{
              uri: isVisible ? singleMediaPreviewUrl : undefined,
              height: singlePreviewSize,
              width: singlePreviewSize
            }}
            borderRadius={10}
          /> : undefined}
      </YStack>
    </Anchor>
  </YStack>;
};

// export default PostMediaRenderer;
