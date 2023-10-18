import { useAccount, useCredentialDispatch, useServerTheme } from "app/store";
import React from "react";

import { Group, Post } from "@jonline/api";
import { Anchor, Image, ScrollView, Spinner, TamaguiMediaState, useMedia, useTheme, XStack, YStack } from '@jonline/ui';
import { useMediaUrl } from "app/hooks/use_media_url";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from 'react-social-media-embed';
import { useLink } from "solito/link";

import { MediaRenderer } from "../media/media_renderer";
import { FadeInView } from './fade_in_view';
import { postBackgroundSize } from "./post_card";

interface PostMediaRendererProps {
  post: Post;
  isPreview?: boolean;
  groupContext?: Group;
  hasBeenVisible?: boolean;
}

export const PostMediaRenderer: React.FC<PostMediaRendererProps> = ({
  post,
  isPreview,
  groupContext,
  hasBeenVisible
}) => {
  const mediaQuery = useMedia();
  const { primaryColor } = useServerTheme();
  const detailsLink = useLink({
    href: groupContext
      ? `/g/${groupContext.shortname}/p/${post.id}`
      : `/post/${post.id}`,
  });

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

  const generatedPreview = post?.media?.find(m => m.contentType.startsWith('image') && m.generated);
  const hasGeneratedPreview = generatedPreview && post?.media?.length == 1 && !embedComponent;

  const scrollableMediaMinCount = isPreview && hasGeneratedPreview ? 3 : 2;
  const showScrollableMediaPreviews = (post?.media?.length ?? 0) >= scrollableMediaMinCount;
  const singleMediaPreview = showScrollableMediaPreviews
    ? undefined
    : post?.media?.find(m => m.contentType.startsWith('image') && (!m.generated /*|| !isPreview*/));
  const singleMediaPreviewUrl = useMediaUrl(singleMediaPreview?.id);
  const backgroundImageUrl = useMediaUrl(hasGeneratedPreview ? generatedPreview?.id : undefined);

  const backgroundSize = postBackgroundSize(mediaQuery);
  const foregroundSize = backgroundSize * 0.7;

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
          <XStack space='$2'>
            {post.media.map((mediaRef, i) => <YStack key={mediaRef.id} w={mediaQuery.gtXs ? '400px' : '260px'} h='100%'>
              <MediaRenderer media={mediaRef} />
            </YStack>)}
          </XStack>
        </ScrollView>
      </XStack> : undefined}

    <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
      <YStack maxHeight={isPreview ? 300 : undefined} overflow='hidden'>
        {singleMediaPreview
          ? <Image
            mb='$3'
            width={500}
            height={500}
            // width={foregroundSize}
            // height={foregroundSize}
            resizeMode="contain"
            als="center"
            source={{ uri: singleMediaPreviewUrl, height: foregroundSize, width: foregroundSize }}
            borderRadius={10}
          /> : undefined}
      </YStack>
    </Anchor>
  </YStack>;
};

// export default PostMediaRenderer;
