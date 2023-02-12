import { loadPostPreview, loadPostReplies, loadUser, RootState, selectPostById, selectUserById, useCredentialDispatch, useServerInfo, useTypedSelector } from "app/store";
import React, { PropsWithChildren, useEffect, useState } from "react";
import { Animated, Platform, View, ViewStyle, Dimensions } from "react-native";

import { Anchor, Button, Card, Group, Heading, Image, ListItem, Paragraph, Post, Tooltip, useMedia, useTheme, XStack, YStack, Text, User } from "@jonline/ui";
import { Bot, ChevronRight, Shield } from "@tamagui/lucide-icons";
import moment from 'moment';
import ReactMarkdown from 'react-markdown';
import { useLink } from "solito/link";
import { Permission } from "@jonline/ui/src";

interface Props {
  post: Post;
  isPreview?: boolean;
  groupContext?: Group;
  replyPostIdPath?: string[];
  collapseReplies?: boolean;
  toggleCollapseReplies?: () => void;
  previewParent?: Post;
}

export const PostCard: React.FC<Props> = ({ post, isPreview, groupContext, replyPostIdPath, toggleCollapseReplies, collapseReplies, previewParent }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const media = useMedia();

  const theme = useTheme();
  const textColor: string = theme.color.val;
  const { server, primaryColor, navColor } = useServerInfo();
  const postsStatus = useTypedSelector((state: RootState) => state.posts.status);
  // const postsBaseStatus = useTypedSelector((state: RootState) => state.posts.baseStatus);
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

  const authorId = post.author?.userId;
  const authorName = post.author?.username;

  const postLink = useLink({
    href: groupContext
      ? `/g/${groupContext.shortname}/p/${post.id}`
      : `/post/${post.id}`,
  });
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : `/user/${authorId}`
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

  const author = useTypedSelector((state: RootState) => authorId ? selectUserById(state.users, authorId) : undefined);
  const authorAvatar = useTypedSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useTypedSelector((state: RootState) => authorId ? state.users.failedUserIds.includes(authorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
  useEffect(() => {
    if (authorId) {
      if (!loadingAuthor && (!author || authorAvatar == undefined) && !authorLoadFailed) {
        setLoadingAuthor(true);
        setTimeout(() => dispatch(loadUser({ id: authorId, ...accountOrServer })), 1);
      } else if (loadingAuthor && author) {
        setLoadingAuthor(false);
      }
    }
  });

  // const loadingReplies = postsStatus == 'loading';
  const [loadingReplies, setLoadingReplies] = useState(false);
  useEffect(() => {
    if (loadingReplies && (post.replyCount == 0 || post.replies.length > 0 || postsStatus != 'loading')) {
      setLoadingReplies(false);
    }
  });
  function toggleReplies() {
    setTimeout(() => {
      if (post.replies.length == 0) {
        setLoadingReplies(true);
        dispatch(loadPostReplies({ ...accountOrServer, postIdPath: replyPostIdPath! }));
      } else if (toggleCollapseReplies) {
        toggleCollapseReplies();
      }
    }, 1);
  }
  const cannotToggleReplies = !replyPostIdPath || post.replyCount == 0
    || (post.replies.length > 0 && !toggleCollapseReplies);
  const collapsed = collapseReplies || post.replies?.length == 0;
  return (
    // <Theme inverse={false}>
    <>
      <YStack w='100%'>
        {previewParent && post.replyToPostId
          ? <XStack mt='-12%' ml='-28%' mb='-14%' scale={0.5}>
            <PostCard post={previewParent} isPreview={true} />
          </XStack> : undefined}
        {/* {previewParent ? <PostCard post={post.parent!} isPreview={true}  /> : undefined} */}
        <Card theme="dark" elevate size="$4" bordered
          margin='$0'
          marginBottom={replyPostIdPath ? '$0' : '$3'}
          marginTop={replyPostIdPath ? '$0' : '$3'}
          padding='$0'
          f={isPreview ? undefined : 1}
          animation="bouncy"
          pressStyle={{ scale: 0.990 }}
          ref={ref!}
          {...postLinkProps}
        >
          {post.link || post.title
            ? <Card.Header>
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
            : undefined}
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
                      default: // web/cross-platform-ish
                        // <NativeText style={{ color: textColor }}>
                        //   <ReactMarkdown className="postMarkdown" children={cleanedContent!}
                        //     components={{
                        //       // li: ({ node, ordered, ...props }) => <li }} {...props} />,
                        //       p: ({ node, ...props }) => <p style={{ display: 'inline-block', marginBottom: 10 }} {...props} />,
                        //       a: ({ node, ...props }) => isPreview ? <span style={{ color: navColor }} children={props.children} /> : <a style={{ color: navColor }} target='_blank' {...props} />,
                        //     }}
                        //   />
                        // </NativeText>,
                        <TamaguiMarkdown text={post.content} disableLinks={isPreview} />,

                      // <ReactMarkdown children={cleanedContent!}
                      //   components={{
                      //     // li: ({ node, ordered, ...props }) => <li }} {...props} />,
                      //     h1: ({ children, id }) => <Heading size='$9' {...{ children, id }} />,
                      //     h2: ({ children, id }) => <Heading size='$8' {...{ children, id }} />,
                      //     h3: ({ children, id }) => <Heading size='$7' {...{ children, id }} />,
                      //     h4: ({ children, id }) => <Heading size='$6' {...{ children, id }} />,
                      //     h5: ({ children, id }) => <Heading size='$5' {...{ children, id }} />,
                      //     h6: ({ children, id }) => <Heading size='$4' {...{ children, id }} />,
                      //     li: ({ ordered, index, children }) => <XStack ml='$3'>
                      //       <Paragraph size='$3' mr='$4'>{ordered ? `${index}.` : '• '}</Paragraph>
                      //       <Paragraph size='$3' {...{ children }} />
                      //     </XStack>,
                      //     p: ({ children }) => <Paragraph size='$3' marginVertical='$2' {...{ children }} w='100%' />,
                      //     a: ({ children, href }) => <Anchor color={navColor} target='_blank' {...{ href, children }} />,
                      //   }} />,
                      //TODO: Find a way to render markdown on native that doesn't break web.
                      // default: post.content ? <NativeMarkdownShim>{cleanedContent}</NativeMarkdownShim> : undefined
                      // default: <Heading size='$1'>Native Markdown support pending!</Heading>
                    }) : undefined
                  }
                </YStack>
                <XStack pt={10} {...detailsProps}>
                  <YStack mr='auto' marginLeft={detailsMargins}>
                    <XStack>
                      <Heading size="$1" mr='$1' marginVertical='auto'>by</Heading>
                      {author && author.permissions.includes(Permission.ADMIN)
                        ? <Tooltip placement="bottom-start">
                          <Tooltip.Trigger>
                            <Shield />
                          </Tooltip.Trigger>
                          <Tooltip.Content>
                            <Heading size='$2'>User is an admin.</Heading>
                          </Tooltip.Content>
                        </Tooltip> : undefined}
                      {author && author.permissions.includes(Permission.RUN_BOTS)
                        ? <Tooltip placement="bottom-start">
                          <Tooltip.Trigger>
                            <Bot />
                          </Tooltip.Trigger>
                          <Tooltip.Content>
                            <Heading size='$2'>User may be (or run) a bot.</Heading>
                            <Heading size='$1'>Posts may be written by an algorithm rather than a human.</Heading>
                          </Tooltip.Content>
                        </Tooltip> : undefined}
                      <Heading size="$1" ml={author && author.permissions.includes(Permission.RUN_BOTS) ? '$2' : '$1'}
                        marginVertical='auto'>
                        {post.author
                          ? isPreview
                            ? `${post.author?.username}`
                            : <Anchor {...authorLinkProps}>{post.author?.username}</Anchor>
                          : 'anonymous'}
                      </Heading>
                    </XStack>
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
                  {(authorAvatar && authorAvatar != '') ?
                    isPreview
                      ? <FadeInView>
                        <Image
                          pos="absolute"
                          width={50}
                          ml='$3'
                          // opacity={0.25}
                          height={50}
                          borderRadius={25}
                          resizeMode="contain"
                          als="flex-start"
                          src={authorAvatar}
                          // blurRadius={1.5}
                          // borderRadius={5}
                          borderBottomRightRadius={5}
                        />
                      </FadeInView>
                      :
                      <FadeInView>
                        <Anchor {...authorLinkProps}
                          ml='$3'>
                          <XStack w={50} h={50}>
                            <Image
                              pos="absolute"
                              width={50}
                              // opacity={0.25}
                              height={50}
                              borderRadius={25}
                              resizeMode="contain"
                              als="flex-start"
                              src={authorAvatar}
                              // blurRadius={1.5}
                              // borderRadius={5}
                              borderBottomRightRadius={5}
                            />
                          </XStack>
                        </Anchor>
                      </FadeInView>
                    : undefined}
                  <XStack f={1} />
                  <YStack h='100%'>
                    <Button transparent
                      disabled={cannotToggleReplies || loadingReplies}
                      marginVertical='auto'
                      onPress={toggleReplies}>
                      <XStack>
                        <YStack marginVertical='auto'>
                          {!post.replyToPostId ? <Heading size="$1" ta='right'>
                            {post.responseCount} comment{post.responseCount == 1 ? '' : 's'}
                          </Heading> : undefined}
                          {(post.replyToPostId) && (post.responseCount != post.replyCount) ? <Heading size="$1" ta='right'>
                            {post.responseCount} response{post.responseCount == 1 ? '' : 's'}
                          </Heading> : undefined}
                          {isPreview || post.replyCount == 0 ? undefined : <Heading size="$1" ta='right'>
                            {post.replyCount} repl{post.replyCount == 1 ? 'y' : 'ies'}
                          </Heading>}
                        </YStack>
                        {!cannotToggleReplies ? <XStack marginVertical='auto'
                          animation='quick'
                          rotate={collapsed ? '0deg' : '90deg'}
                        >
                          <ChevronRight opacity={loadingReplies ? 0.5 : 1} />
                        </XStack> : undefined}
                      </XStack>
                    </Button>
                    {/* {replyPostIdPath
                    ? <Heading size="$1" marginRight='$3' marginTop='auto' marginBottom='auto'>
                      {post.responseCount} response{post.responseCount == 1 ? '' : 's'}
                    </Heading>
                    : <Heading size="$1" marginRight='$3' marginTop='auto' marginBottom='auto'>
                      {post.responseCount} response{post.responseCount == 1 ? '' : 's'}
                    </Heading>} */}
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
        </Card >
      </YStack>
      {
        isPreview ?
          <Anchor {...authorLinkProps
          } >
            <XStack w={180} h={70}
              // backgroundColor='#42424277' 
              position='absolute' bottom={15} />
          </Anchor >
          : undefined}
      {
        isPreview && post.link ?
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
          : undefined
      }
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
export type FadeInViewProps = PropsWithChildren<{ style?: ViewStyle }>;

export const FadeInView: React.FC<FadeInViewProps> = props => {
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

export type MarkdownProps = {
  text: string;
  disableLinks?: boolean;
}
export const TamaguiMarkdown = ({ text, disableLinks }: MarkdownProps) => {
  const { server, primaryColor, navColor } = useServerInfo();

  const cleanedText = (text ?? '').replace(
    /((?!  ).)\n([^\n*])/g,
    (_, b, c) => {
      if (b[1] != ' ') b = `${b} `
      return `${b}${c}`;
    }
  );

  return <ReactMarkdown children={cleanedText}
    components={{
      // li: ({ node, ordered, ...props }) => <li }} {...props} />,
      h1: ({ children, id }) => <Heading size='$9' {...{ children, id }} />,
      h2: ({ children, id }) => <Heading size='$8' {...{ children, id }} />,
      h3: ({ children, id }) => <Heading size='$7' {...{ children, id }} />,
      h4: ({ children, id }) => <Heading size='$6' {...{ children, id }} />,
      h5: ({ children, id }) => <Heading size='$5' {...{ children, id }} />,
      h6: ({ children, id }) => <Heading size='$4' {...{ children, id }} />,
      li: ({ ordered, index, children }) => <XStack ml='$3'>
        <Paragraph size='$3' mr='$4'>{ordered ? `${index}.` : '• '}</Paragraph>
        <Paragraph size='$3' {...{ children }} />
      </XStack>,
      p: ({ children }) => <Paragraph size='$3' marginVertical='$2' {...{ children }} w='100%' />,
      // a: ({ children, href }) => <Anchor color={navColor} target='_blank' {...{ href, children }} />,
      a: ({ children, href }) => disableLinks
        ? <Text fontFamily='$body' color={navColor} {...{ href, children }} />
        : <Anchor color={navColor} target='_blank' {...{ href, children }} />,
    }} />
}

export default PostCard;
