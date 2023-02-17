import { loadPostPreview, loadPostReplies, loadUser, RootState, selectUserById, useCredentialDispatch, useServerInfo, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { Platform, View } from "react-native";

import { Anchor, Button, Card, Group, Heading, Image, Post, Tooltip, useMedia, useTheme, XStack, YStack } from "@jonline/ui";
import { Permission, Theme } from "@jonline/ui/src";
import { Bot, ChevronRight, Shield } from "@tamagui/lucide-icons";
import { useOnScreen } from "app/hooks/use_on_screen";
import moment from 'moment';
import { useLink } from "solito/link";
import { FadeInView } from "./fade_in_view";
import { TamaguiMarkdown } from "./tamagui_markdown";
import { AuthorInfo } from "./author_info";

interface Props {
  post: Post;
  isPreview?: boolean;
  groupContext?: Group;
  replyPostIdPath?: string[];
  collapseReplies?: boolean;
  toggleCollapseReplies?: () => void;
  previewParent?: Post;
  onPress?: () => void;
  onPressParentPreview?: () => void;
  selectedPostId?: string;
}

export const PostCard: React.FC<Props> = ({ post, isPreview, groupContext, replyPostIdPath, toggleCollapseReplies, collapseReplies, previewParent, onPress, onPressParentPreview, selectedPostId }) => {
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
  useEffect(() => {
    if (!preview && !loadingPreview && onScreen && post.previewImageExists != false) {
      post.content
      setLoadingPreview(true);
      setTimeout(() => dispatch(loadPostPreview({ ...post, ...accountOrServer })), 1);
    }
  });

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
  const postLinkProps = isPreview ? postLink : { onPress: onPress };
  const authorLinkProps = post.author ? authorLink : undefined;
  const showDetailsShadow = isPreview && post.content && post.content.length > 1000;
  const detailsMargins = showDetailsShadow ? media.gtXs && !isPreview ? 20 : 0 : 0;
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
      if (!loadingReplies && post.replies.length == 0) {
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
    <>
      <YStack w='100%'>
        {previewParent && post.replyToPostId
          ? <XStack w='100%'>
            {media.gtXs ? <Heading size='$5' ml='$3' mr='$0' marginVertical='auto' ta='center'>RE</Heading> : undefined}
            <XStack marginVertical='auto' marginHorizontal='$1'><ChevronRight /></XStack>

            <Theme inverse={selectedPostId == previewParent.id}>
              <Card f={1} theme="dark" elevate size="$1" bordered
                margin='$0'
                // marginBottom={replyPostIdPath ? '$0' : '$3'}
                // marginTop={replyPostIdPath ? '$0' : '$3'}
                // padding='$2'
                paddingHorizontal='$2'
                paddingVertical='$1'
                mb='$1'
                // f={isPreview ? undefined : 1}
                animation="bouncy"
                scale={0.92}
                pressStyle={{ scale: 0.91 }}
                onPress={onPressParentPreview}
              >
                <Card.Footer>
                  <YStack w='100%'>
                    <XStack mah={200} w='100%'>
                      <TamaguiMarkdown text={previewParent.content} />
                    </XStack>

                    <XStack ml='$2'>
                      <AuthorInfo post={previewParent!} isPreview={false} />
                    </XStack>
                  </YStack>
                </Card.Footer>
              </Card>
            </Theme>
          </XStack>
          : undefined}
        {/* // ? <XStack
            mt={media.gtXs ? '-5%' : '-12%'}
            ml={media.gtXs ? '-28%' : '-28%'}
            mb={media.gtXs ? '-5%' : '-14%'}
            scale={0.5}>
            <PostCard post={previewParent} isPreview={true} />
          </XStack> : undefined} */}
        {/* {previewParent ? <PostCard post={post.parent!} isPreview={true}  /> : undefined} */}

        <Theme inverse={selectedPostId == post.id}>
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
            <Card.Footer paddingRight={media.gtXs ? '$3' : '$1'} >
              <XStack width='100%' >
                {/* {...postLinkProps}> */}
                <YStack style={{ flex: 10 }} zi={1000}>
                  <YStack maxHeight={isPreview ? 300 : undefined} overflow='hidden'>
                    {(!isPreview && preview && preview != '') ?
                      <Image
                        mb='$3'
                        width={media.sm ? 300 : 400}
                        height={media.sm ? 300 : 400}
                        resizeMode="contain"
                        als="center"
                        src={preview}
                        borderRadius={10}
                      /> : undefined}
                    {
                      post.content && post.content != '' ? Platform.select({
                        default: <TamaguiMarkdown text={post.content} disableLinks={isPreview} />,
                        // default: post.content ? <NativeMarkdownShim>{cleanedContent}</NativeMarkdownShim> : undefined
                        // default: <Heading size='$1'>Native Markdown support pending!</Heading>
                      }) : undefined
                    }
                  </YStack>
                  <XStack pt={10} {...detailsProps}>
                    <AuthorInfo {...{ post, isPreview, detailsMargins }} />
                    {/* <XStack f={1} ml={media.gtXs ? 0 : -7} alignContent='flex-start'>
                    {(authorAvatar && authorAvatar != '') ?
                      <YStack marginVertical='auto'>
                        {isPreview
                          ? <FadeInView>
                            <Image
                              pos="absolute"
                              width={media.gtXs ? 50 : 26}
                              mr={media.gtXs ? '$3' : '$2'}
                              // opacity={0.25}
                              height={media.gtXs ? 50 : 26}
                              borderRadius={media.gtXs ? 25 : 13}
                              resizeMode="contain"
                              als="flex-start"
                              src={authorAvatar}
                            // blurRadius={1.5}
                            // borderRadius={5}
                            />
                          </FadeInView>
                          :
                          <FadeInView>
                            <Anchor {...authorLinkProps}
                              mr={media.gtXs ? '$3' : '$2'}>
                              <XStack w={media.gtXs ? 50 : 26} h={media.gtXs ? 50 : 26}>
                                <Image
                                  pos="absolute"
                                  width={media.gtXs ? 50 : 26}
                                  // opacity={0.25}
                                  height={media.gtXs ? 50 : 26}
                                  borderRadius={media.gtXs ? 25 : 13}
                                  resizeMode="contain"
                                  als="flex-start"
                                  src={authorAvatar}
                                // blurRadius={1.5}
                                // borderRadius={5}
                                />
                              </XStack>
                            </Anchor>
                          </FadeInView>}
                      </YStack>
                      : undefined}
                    <YStack marginLeft={detailsMargins}>
                      <XStack>

                        <Heading size="$1" ml='$1' mr='$2'
                          marginVertical='auto'>
                          {post.author
                            ? isPreview
                              ? `${post.author?.username}`
                              : <Anchor size='$1' {...authorLinkProps}>{post.author?.username}</Anchor>
                            : 'anonymous'}
                        </Heading>
                      </XStack>
                      <XStack>
                        <Tooltip placement="bottom-start">
                          <Tooltip.Trigger>
                            <Heading size="$1" marginVertical='auto' mr='$2'>
                              {moment.utc(post.createdAt).local().startOf('seconds').fromNow()}
                            </Heading>
                          </Tooltip.Trigger>
                          <Tooltip.Content>
                            <Heading size='$2'>{moment.utc(post.createdAt).local().format("ddd, MMM Do YYYY, h:mm:ss a")}</Heading>
                          </Tooltip.Content>
                        </Tooltip>
                        {author && author.permissions.includes(Permission.ADMIN)
                          ? <Tooltip placement="bottom">
                            <Tooltip.Trigger>
                              <Shield />
                            </Tooltip.Trigger>
                            <Tooltip.Content>
                              <Heading size='$2'>User is an admin.</Heading>
                            </Tooltip.Content>
                          </Tooltip> : undefined}
                        {author && author.permissions.includes(Permission.RUN_BOTS)
                          ? <Tooltip placement="bottom">
                            <Tooltip.Trigger>
                              <Bot />
                            </Tooltip.Trigger>
                            <Tooltip.Content>
                              <Heading size='$2' ta='center' als='center'>User may be (or run) a bot.</Heading>
                              <Heading size='$1' ta='center' als='center'>Posts may be written by an algorithm rather than a human.</Heading>
                            </Tooltip.Content>
                          </Tooltip> : undefined}
                      </XStack>
                    </YStack>
                  </XStack> */}

                    <YStack h='100%'>
                      <Button opacity={isPreview ? 1 : 0.9} transparent={isPreview || !post?.replyToPostId || post.replyCount == 0}
                        disabled={cannotToggleReplies || loadingReplies}
                        marginVertical='auto'
                        mr={media.gtXs || isPreview ? 0 : -10}
                        onPress={toggleReplies} paddingRight={cannotToggleReplies || isPreview ? '$2' : '$0'} paddingLeft='$2'>
                        <XStack opacity={0.9}>
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
        </Theme>
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
  );
};

export default PostCard;
