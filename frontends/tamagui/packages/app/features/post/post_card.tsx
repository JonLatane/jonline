import { RootState, useCredentialDispatch, useTypedSelector, loadPostPreview } from "app/store";
import React, { PropsWithChildren, useEffect, useState } from "react";
import { Animated, Platform, Text as NativeText, View, ViewStyle } from "react-native";

import { Anchor, Card, Heading, Image, Post, Tooltip, useMedia, useTheme, XStack, YStack } from "@jonline/ui";
import moment from 'moment';
import ReactMarkdown from 'react-markdown';
import { useLink } from "solito/link";

interface Props {
  post: Post;
  isPreview?: boolean;
}

const PostCard: React.FC<Props> = ({ post, isPreview }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const media = useMedia();

  const theme = useTheme();
  const textColor: string = theme.color.val;
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;
  const preview: string | undefined = useTypedSelector((state: RootState) => state.posts.previews[post.id]);
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  // Call the hook passing in ref and root margin
  // In this case it would only be considered onScreen if more ...
  // ... than 300px of element is visible.
  const onScreen = useOnScreen(ref, "-1px");
  if (!preview && !loadingPreview && onScreen) {
    setLoadingPreview(true);
    setTimeout(() => dispatch(loadPostPreview({ ...post, ...accountOrServer })), 1);
  }

  const postLink = useLink({
    href: `/post/${post.id}`,
  });
  const authorLink = useLink({
    href: post.author?.username
      ? `/${post.author?.username}`
      : `/user/${post.author?.userId}`
  });
  const postLinkProps = isPreview ? postLink : { onPress: undefined };
  const authorLinkProps = post.author ? authorLink : undefined;
  const showDetailsShadow = isPreview && post.content && post.content.length > 1000;
  const detailsMargins = showDetailsShadow ? 20 : 0;
  const detailsProps = showDetailsShadow ? {
    marginHorizontal: -detailsMargins,
    shadowOpacity: 0.3,
    shadowOffset: { width: -5, height: -5 },
    shadowRadius: 10
  } : {};

  const cleanedContent = post.content?.replace(
    /((?!  ).)\n([^\n*])/g,
    (_, b, c) => {
      if (b[1] != ' ') b = `${b} `
      return `${b}${c}`;
    }
  );

  return (
    // <Theme inverse={false}>
    <>
      <Card theme="dark" elevate size="$4" bordered
        margin='$0'
        marginBottom='$3'
        padding='$0'
        f={isPreview ? undefined : 1}
        animation="bouncy"
        pressStyle={{ scale: 0.990 }}
        ref={ref!}
        {...postLinkProps}
      >
        <Card.Header>
          <XStack>
            <View style={{ flex: 1 }}>
              {post.link
                ? isPreview
                  ? <Heading size="$7" marginRight='auto' color={navColor}>{post.title}</Heading>
                  : <Anchor href={post.link} onPress={(e) => e.stopPropagation()} target="_blank" rel='noopener noreferrer'
                    color={navColor}><Heading size="$7" marginRight='auto' color={navColor}>{post.title}</Heading></Anchor>
                :
                <Heading size="$7" marginRight='auto'>{post.title}</Heading>
              }
            </View>
          </XStack>
        </Card.Header>
        <Card.Footer>
          <XStack width='100%' >
            {/* {...postLinkProps}> */}
            <YStack style={{ flex: 10 }} zi={1000}>
              <YStack maxHeight={isPreview ? 300 : undefined} overflow='hidden'>
                {(!isPreview && preview && preview != '') ?
                  <Image
                    // pos="absolute"
                    // width={400}
                    // opacity={0.25}
                    // height={400}
                    // minWidth={300}
                    // minHeight={300}
                    // width='100%'
                    // height='100%'
                    mb='$3'
                    width={media.sm ? 300 : 400}
                    height={media.sm ? 300 : 400}
                    resizeMode="contain"
                    als="center"
                    src={preview}
                    borderRadius={10}
                  // borderBottomRightRadius={5}
                  /> : undefined}
                {
                  post.content && post.content != '' ? Platform.select({
                    web: // web/cross-platform-ish
                      <NativeText style={{ color: textColor }}>
                        <ReactMarkdown className="postMarkdown" children={cleanedContent!}
                          components={{
                            // li: ({ node, ordered, ...props }) => <li }} {...props} />,
                            p: ({ node, ...props }) => <p style={{ display: 'inline-block', marginBottom: 10 }} {...props} />,
                            a: ({ node, ...props }) => isPreview ? <span style={{ color: navColor }} children={props.children} /> : <a style={{ color: navColor }} target='_blank' {...props} />,
                          }}
                        />
                      </NativeText>,
                    //TODO: Find a way to render markdown on native that doesn't break web.
                    // default: post.content ? <NativeMarkdownShim>{cleanedContent}</NativeMarkdownShim> : undefined
                    default: <Heading size='$1'>Native Markdown support pending!</Heading>
                  }) : undefined
                }
              </YStack>
              <XStack pt={10} {...detailsProps}>
                <YStack mr='auto' marginLeft={detailsMargins}>
                  <Heading size="$1">
                    {post.author
                      ? isPreview
                        ? `by ${post.author?.username}`
                        : <>by <Anchor {...authorLinkProps}>{post.author?.username}</Anchor></>
                      : 'by anonymous'}
                  </Heading>
                  <Tooltip placement="bottom-start">
                    <Tooltip.Trigger>
                      <Heading size="$1">
                        {moment.utc(post.createdAt).local().startOf('seconds').fromNow()}
                      </Heading>
                    </Tooltip.Trigger>
                    <Tooltip.Content>
                      <Heading size='$2'>{moment.utc(post.createdAt).local().format("ddd, MMM Do YYYY, h:mm:ss a")}</Heading>
                    </Tooltip.Content>
                  </Tooltip>
                </YStack>
                <XStack f={1} />
                <YStack h='100%'>
                  <Heading size="$1" marginRight='$3' marginTop='auto' marginBottom='auto'>{post.responseCount} response{post.responseCount == 1 ? '' : 's'}</Heading>
                </YStack>
              </XStack>
            </YStack>
          </XStack>
        </Card.Footer>
        <Card.Background>
          {(isPreview && preview && preview != '') ?
          <FadeInView>
            <Image
              pos="absolute"
              width={300}
              opacity={0.25}
              height={300}
              resizeMode="contain"
              als="flex-start"
              src={preview}
              blurRadius={1.5}
              // borderRadius={5}
              borderBottomRightRadius={5}
            />
            </FadeInView> : undefined}
        </Card.Background>
      </Card>
      {isPreview ?
        <Anchor {...authorLinkProps}>
          <XStack w={180} h={70}
            // backgroundColor='#42424277' 
            position='absolute' bottom={15} />
        </Anchor>
        : undefined}
      {isPreview && post.link ?
        <Anchor href={post.link} target='_blank'>
          <XStack w='100%' h={
            Math.max(1, (post.title?.length ?? 0) / Math.round(
              (media.xxxxxxs ? 15
                : media.xxxxxs ? 20
                  : media.xxxxs ? 25
                    : media.xxxs ? 30
                      : media.xxs ? 35
                        : media.xs ? 40
                          : media.sm ? 45
                            : media.md ? 50
                              : media.lg ? 55
                                : 70
              )
            )) * 36}
            // backgroundColor='#42424277' 
            position='absolute' top={15} />
        </Anchor>
        : undefined}
    </>
    // </Theme>
  );
};


// Hook
function useOnScreen(ref, rootMargin = "0px") {
  // State and setter for storing whether element is visible
  const [isIntersecting, setIntersecting] = useState(false);
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        // Update our state when observer callback fires
        setIntersecting(entry?.isIntersecting || false);
      },
      {
        rootMargin,
      }
    );
    if (ref.current) {
      observer.observe(ref.current);
    }
    return () => {
      ref.current && observer.unobserve(ref.current);
    };
  }, []); // Empty array ensures that effect is only run on mount and unmount
  return isIntersecting;
}
type FadeInViewProps = PropsWithChildren<{style?: ViewStyle}>;

const FadeInView: React.FC<FadeInViewProps> = props => {
  const fadeAnim = React.useRef(new Animated.Value(0)).current; // Initial value for opacity: 0

  useEffect(() => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 1500,
      useNativeDriver: true,
    }).start();
  }, [fadeAnim]);

  return (
    <Animated.View // Special animatable View
      style={{
        ...props.style,
        opacity: fadeAnim, // Bind opacity to animated value
      }}>
      {props.children}
    </Animated.View>
  );
};

export default PostCard;
