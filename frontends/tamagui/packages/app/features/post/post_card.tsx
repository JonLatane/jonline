import { colorMeta, deletePost, loadPostReplies, loadUser, RootState, selectUserById, updatePost, useAccount, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { GestureResponderEvent, Platform, View } from "react-native";

import { Group, Post, Visibility } from "@jonline/api";
import { Anchor, Button, Card, Heading, Image, TamaguiMediaState, ScrollView, Spinner, Theme, useMedia, useTheme, XStack, YStack, TextArea, Dialog, Paragraph } from '@jonline/ui';
import { ChevronRight, Delete, Edit, Eye, Reply, Save, X as XIcon } from "@tamagui/lucide-icons";
import { useIsVisible } from 'app/hooks/use_is_visible';
import { useMediaUrl } from "app/hooks/use_media_url";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from 'react-social-media-embed';
import { useLink } from "solito/link";
import { AuthorInfo } from "./author_info";
import { TamaguiMarkdown } from "./tamagui_markdown";

import { MediaRenderer } from "../media/media_renderer";
import { FadeInView } from '../../components/fade_in_view';
import { GroupPostManager } from '../groups/group_post_manager';
import { PostMediaRenderer } from "./post_media_renderer";
import { PostMediaManager } from "./post_media_manager";
import { VisibilityPicker } from "../../components/visibility_picker";
import { postVisibilityDescription } from "./base_create_post_sheet";

interface PostCardProps {
  post: Post;
  isPreview?: boolean;
  groupContext?: Group;
  replyPostIdPath?: string[];
  collapseReplies?: boolean;
  toggleCollapseReplies?: () => void;
  onLoadReplies?: () => void;
  previewParent?: Post;
  onPress?: () => void;
  onPressParentPreview?: () => void;
  selectedPostId?: string;
  onPressReply?: () => void;
  onEditingChange?: (editing: boolean) => void;
}

export const postBackgroundSize = (media: TamaguiMediaState) =>
  media.gtLg ? 800 : media.gtMd ? 800 : media.gtSm ? 800 : media.gtXs ? 600 : 500;

export const PostCard: React.FC<PostCardProps> = ({
  post,
  isPreview,
  groupContext,
  replyPostIdPath,
  toggleCollapseReplies,
  onLoadReplies,
  collapseReplies,
  previewParent,
  onPress,
  onPressParentPreview,
  selectedPostId,
  onPressReply,
  onEditingChange
}) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const mediaQuery = useMedia();

  const theme = useTheme();
  const currentUser = useAccount()?.user;
  const textColor: string = theme.color?.val ?? '#000000';
  const themeBgColor = theme.background?.val ?? '#ffffff';
  const { luma: themeBgLuma } = colorMeta(themeBgColor);
  const { server, primaryColor, navAnchorColor: navColor, primaryAnchorColor, navAnchorColor } = useServerTheme();
  const postsStatus = useTypedSelector((state: RootState) => state.posts.status);
  const [editing, _setEditing] = useState(false);
  function setEditing(value: boolean) {
    _setEditing(value);
    onEditingChange?.(value);
  }
  const [previewingEdits, setPreviewingEdits] = useState(false);
  const [savingEdits, setSavingEdits] = useState(false);

  const [editedContent, setEditedContent] = useState(post.content);
  const [editedMedia, setEditedMedia] = useState(post.media);
  const [editedEmbedLink, setEditedEmbedLink] = useState(post.embedLink);
  const [editedVisibility, setEditedVisibility] = useState(post.visibility);
  const content = editing ? editedContent : post.content;
  const media = editing ? editedMedia : post.media;
  const embedLink = editing ? editedEmbedLink : post.embedLink;
  const visibility = editing ? editedVisibility : post.visibility;

  function saveEdits() {
    setSavingEdits(true);
    dispatch(updatePost({
      ...accountOrServer, ...post,
      content: editedContent,
      media: editedMedia,
      embedLink: editedEmbedLink,
      visibility: editedVisibility,
    })).then(() => {
      setEditing(false);
      setSavingEdits(false);
      setPreviewingEdits(false);
    });
  }

  const [deleted, setDeleted] = useState(post.author === undefined);
  const [deleting, setDeleting] = useState(false);
  function doDeletePost() {
    setDeleting(true);
    dispatch(deletePost({ ...accountOrServer, ...post })).then(() => {
      setDeleted(true);
      setDeleting(false);
    });
  }

  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const isVisible = useIsVisible(ref);
  const [hasBeenVisible, setHasBeenVisible] = useState(false);
  useEffect(() => {
    if (isVisible && !hasBeenVisible) {
      setHasBeenVisible(true);
    }
  }, [isVisible]);

  const authorId = post.author?.userId;
  const authorName = post.author?.username;

  const postHasWebLink = post.link && post.link.startsWith('http');
  const postLink = postHasWebLink ? useLink({
    href: post.link!,
  }) : {};
  const detailsLink = useLink({
    href: groupContext
      ? `/g/${groupContext.shortname}/p/${post.id}`
      : `/post/${post.id}`,
  });
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : `/user/${authorId}`
  });
  const authorLinkProps = post.author ? authorLink : undefined;
  const showDetailsShadow = isPreview && post.content && post.content.length > 700;
  const detailsMargins = showDetailsShadow ? 20 : 0;
  const footerProps = isPreview ? {
    // ml: -detailsMargins,
    mr: -detailsMargins,
  } : {};
  const contentProps = isPreview ? {
    // ml: detailsMargins,
    // mr: 2 * detailsMargins,
  } : {};
  const detailsProps = isPreview ? showDetailsShadow ? {
    ml: -detailsMargins,
    mr: -0.5 * detailsMargins,
    pr: 0,//1 * detailsMargins - 5,
    mb: -detailsMargins,
    pb: detailsMargins,
    shadowOpacity: 0.3,
    shadowOffset: { width: -5, height: -5 },
    shadowRadius: 10
  } : {
    mr: -10,
  } : {
    // mr: -2 * detailsMargins,
  };

  const author = post.author;
  const isAuthor = author && author.userId === currentUser?.id;
  const showEdit = isAuthor && !isPreview;

  const [loadingReplies, setLoadingReplies] = useState(false);
  useEffect(() => {
    if (loadingReplies && (post.replyCount == 0 || post.replies.length > 0 || postsStatus != 'loading')) {
      setLoadingReplies(false);
    }
  });
  function toggleReplies(e: GestureResponderEvent) {
    e.stopPropagation();
    setTimeout(() => {
      if (!loadingReplies && post.replies.length == 0) {
        setLoadingReplies(true);
        if (onLoadReplies) {
          onLoadReplies();
        }
        dispatch(loadPostReplies({ ...accountOrServer, postIdPath: replyPostIdPath! }));
      } else if (toggleCollapseReplies) {
        toggleCollapseReplies();
      }
    }, 1);
  }
  const cannotToggleReplies = !replyPostIdPath || post.replyCount == 0
    || (post.replies.length > 0 && !toggleCollapseReplies);
  const collapsed = collapseReplies || post.replies?.length == 0;

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

  const imagePreview = media?.find(m => m.contentType.startsWith('image'));
  const showScrollableMediaPreviews = (media?.filter(m => !m.generated).length ?? 0) >= 2;
  // const singleMediaPreview = showScrollableMediaPreviews
  //   ? undefined
  //   : post?.media?.find(m => m.contentType.startsWith('image') && (!m.generated /*|| !isPreview*/));
  const previewUrl = useMediaUrl( imagePreview?.id);

  const showBackgroundPreview = !!imagePreview;
  const backgroundSize = postBackgroundSize(mediaQuery);
  const foregroundSize = backgroundSize * 0.7;

  return (
    <>
      <YStack w='100%' ref={ref!} key={`post-card-${post.id}-${isPreview ? '-preview' : ''}`}>
        {previewParent && post.replyToPostId
          ? <XStack w='100%'>
            {mediaQuery.gtXs ? <Heading size='$5' ml='$3' mr='$0' marginVertical='auto' ta='center'>RE</Heading> : undefined}
            <XStack marginVertical='auto' marginHorizontal='$1'><ChevronRight /></XStack>

            <Theme inverse={selectedPostId == previewParent.id}>
              <Card f={1} theme="dark" elevate size="$1" bordered
                margin='$0'
                // marginBottom={replyPostIdPath ? '$0' : '$3'}
                // marginTop={replyPostIdPath ? '$0' : '$3'}
                // padding='$2'
                px='$2'
                py='$1'
                mb='$1'
                // f={isPreview ? undefined : 1}
                animation='standard'
                scale={0.92}
                opacity={1}
                y={0}
                // enterStyle={{ y: -50, opacity: 0, }}
                // exitStyle={{ opacity: 0, }}
                pressStyle={{ scale: 0.91 }}
                onPress={onPressParentPreview}
              >
                <Card.Footer>
                  <YStack w='100%'>
                    <XStack mah={200} w='100%'>
                      <TamaguiMarkdown text={previewParent.content} />
                    </XStack>

                    <XStack ml='$2'>
                      <AuthorInfo post={previewParent!} disableLink={false} isVisible={isVisible} />
                    </XStack>
                  </YStack>
                </Card.Footer>
              </Card>
            </Theme>
          </XStack>
          : undefined}
        <Theme inverse={selectedPostId == post.id}>
          <Card theme="dark" elevate size="$4" bordered
            margin='$0'
            marginBottom={replyPostIdPath ? '$0' : '$3'}
            marginTop={replyPostIdPath ? '$0' : '$3'}
            f={isPreview ? undefined : 1}
            animation='standard'
            pressStyle={previewUrl || post.replyToPostId ? { scale: 0.990 } : {}}
            scale={1}
            opacity={1}
            // w='100%'
            y={0}
          // enterStyle={{ y: -50, opacity: 0, }}
          // exitStyle={{ opacity: 0, }}
          // {...postLinkProps}
          >
            {!post.replyToPostId && (post.link != '' || post.title != '')
              ? <Card.Header>
                <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}), ...postLink, }} target={postHasWebLink ? '_blank' : undefined}>
                  <YStack w='100%'>
                    <Heading size="$7" marginRight='auto' color={post.link && post.link.startsWith('http') ? navColor : undefined}>{post.title && post.title != '' ? post.title : `Untitled Post ${post.id}`}</Heading>
                  </YStack>
                </Anchor>
              </Card.Header>
              : undefined}
            <Card.Footer p='$3' pr={mediaQuery.gtXs ? '$3' : '$1'} >
              {deleted
                ? <Paragraph size='$1'>This {post.replyToPostId ? 'comment' : 'post'} has been deleted.</Paragraph>
                : <YStack zi={1000} width='100%' {...footerProps}>

                  {editing && !previewingEdits
                    ? <PostMediaManager
                      link={post.link}
                      media={editedMedia}
                      setMedia={setEditedMedia}
                      embedLink={editedEmbedLink}
                      setEmbedLink={setEditedEmbedLink}
                      disableInputs={savingEdits}
                    />
                    : <PostMediaRenderer {...{
                      post: {
                        ...post,
                        media,
                        embedLink
                      }, isPreview, groupContext, hasBeenVisible
                    }} />}

                  <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                    <YStack maxHeight={isPreview
                      ? (showScrollableMediaPreviews) ? 150 : 300
                      : editing && !previewingEdits ? backgroundSize * (media.length > 0 ? 0.6 : 0.8) : undefined} overflow='hidden' 
                      {...contentProps}>
                      {
                        editing && !previewingEdits
                          ? <TextArea f={1} pt='$2' value={editedContent}
                            disabled={savingEdits} opacity={savingEdits || editedContent == '' ? 0.5 : 1}
                            h={(editedContent?.length ?? 0) > 300 ? window.innerHeight - 100 : undefined}
                            onChangeText={setEditedContent}
                            placeholder={`Text content (optional). Markdown is supported.`} />
                          : content && content != ''
                            ? <TamaguiMarkdown text={content} disableLinks={isPreview} />
                            : undefined
                      }
                    </YStack>
                  </Anchor>
                  <XStack space='$2' flexWrap="wrap">
                    {showEdit
                      ? editing
                        ? <>
                          <Button my='auto' size='$2' icon={Save} onPress={saveEdits} color={primaryAnchorColor} disabled={savingEdits} transparent>
                            Save
                          </Button>
                          <Button my='auto' size='$2' icon={XIcon} onPress={() => setEditing(false)} disabled={savingEdits} transparent>
                            Cancel
                          </Button>
                          {previewingEdits
                            ? <Button my='auto' size='$2' icon={Edit} onPress={() => setPreviewingEdits(false)} color={navAnchorColor} disabled={savingEdits} transparent>
                              Edit
                            </Button>
                            :
                            <Button my='auto' size='$2' icon={Eye} onPress={() => setPreviewingEdits(true)} color={navAnchorColor} disabled={savingEdits} transparent>
                              Preview
                            </Button>}
                        </>
                        : <>
                          <Button my='auto' size='$2' icon={Edit} onPress={() => setEditing(true)} disabled={deleting} transparent>
                            Edit
                          </Button>

                          <Dialog>
                            <Dialog.Trigger asChild>
                              <Button my='auto' size='$2' icon={Delete} disabled={deleting} transparent>
                                Delete
                              </Button>
                            </Dialog.Trigger>
                            <Dialog.Portal zi={1000011}>
                              <Dialog.Overlay
                                key="overlay"
                                animation="quick"
                                o={0.5}
                                enterStyle={{ o: 0 }}
                                exitStyle={{ o: 0 }}
                              />
                              <Dialog.Content
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
                                m='$3'
                                enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
                                exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
                                x={0}
                                scale={1}
                                opacity={1}
                                y={0}
                              >
                                <YStack space>
                                  <Dialog.Title>Delete {post.replyToPostId ? 'Reply' : 'Post'}</Dialog.Title>
                                  <Dialog.Description>
                                    Really delete {post.replyToPostId ? 'reply' : 'post'}?
                                    The content{post.replyToPostId ? '' : ' and title'} will be deleted, and your user account de-associated, but any replies (including quotes) will still be present.
                                  </Dialog.Description>

                                  <XStack space="$3" jc="flex-end">
                                    <Dialog.Close asChild>
                                      <Button>Cancel</Button>
                                    </Dialog.Close>
                                    {/* <Dialog.Action asChild> */}
                                    <Theme inverse>
                                      <Button onPress={doDeletePost}>Delete</Button>
                                    </Theme>
                                    {/* </Dialog.Action> */}
                                  </XStack>
                                </YStack>
                              </Dialog.Content>
                            </Dialog.Portal>
                          </Dialog>
                        </>
                      : undefined}

                    <XStack key='visibility-edit' mt='$2' ml='auto'>
                      <VisibilityPicker
                        id={`visibility-picker-${post.id}${isPreview ? '-preview' : ''}`}
                        label='Post Visibility'
                        visibility={visibility}
                        onChange={setEditedVisibility}
                        visibilityDescription={v => postVisibilityDescription(v, groupContext, server, 'post')}
                        readOnly={!editing || previewingEdits}
                      />
                    </XStack>
                    {/* {editing && !previewingEdits
                      ? <XStack mt='$2' ml='$2'>
                        <VisibilityPicker
                          id={`visibility-picker-${post.id}${isPreview ? '-preview' : ''}`}
                          label='Post Visibility'
                          visibility={visibility}
                          onChange={setEditedVisibility}
                          visibilityDescription={v => postVisibilityDescription(v, groupContext, server, 'post')} />
                      </XStack>
                      : visibility != Visibility.GLOBAL_PUBLIC
                        ? <Paragraph size='$1' my='auto' ml='$2'>
                          {postVisibilityDescription(visibility, groupContext, server, 'post')}
                        </Paragraph>
                        : undefined} */}
                    {post?.replyToPostId
                      ? undefined
                      : <XStack pt={10} pr='$2' maw='100%'>
                        <GroupPostManager post={post} isVisible={isVisible} />
                      </XStack>}
                  </XStack>

                  <XStack pt={post?.replyToPostId
                    ? 10
                    : undefined} {...detailsProps}>
                    <AuthorInfo {...{ post, detailsMargins, isVisible }} />
                    {onPressReply ? <Button onPress={onPressReply} circular icon={Reply}
                      my='auto' size='$2' mr='$2' /> : undefined}
                    <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                      <YStack h='100%' mr='$1'>
                        <Button opacity={isPreview ? 1 : 0.9} transparent={isPreview || !post?.replyToPostId || post.replyCount == 0}
                          borderColor={isPreview || cannotToggleReplies ? 'transparent' : undefined}
                          disabled={cannotToggleReplies || loadingReplies}
                          marginVertical='auto'
                          mr={isPreview ? '$2' : undefined}
                          size='$3'
                          onPress={toggleReplies} paddingRight={cannotToggleReplies || isPreview ? '$2' : '$0'} paddingLeft='$2'>
                          <XStack opacity={0.9}>
                            <YStack marginVertical='auto' scale={0.75}>
                              {!post.replyToPostId ? <Paragraph size="$1" ta='right'>
                                {post.responseCount} comment{post.responseCount == 1 ? '' : 's'}
                              </Paragraph> : undefined}
                              {(post.replyToPostId) && (post.responseCount != post.replyCount) ? <Paragraph size="$1" ta='right'>
                                {post.responseCount} response{post.responseCount == 1 ? '' : 's'}
                              </Paragraph> : undefined}
                              {isPreview || post.replyCount == 0 ? undefined : <Paragraph size="$1" ta='right'>
                                {post.replyCount} repl{post.replyCount == 1 ? 'y' : 'ies'}
                              </Paragraph>}
                            </YStack>
                            {!cannotToggleReplies ? <XStack marginVertical='auto'
                              animation='quick'
                              rotate={collapsed ? '0deg' : '90deg'}
                            >
                              <ChevronRight opacity={loadingReplies ? 0.5 : 1} />
                            </XStack> : undefined}
                          </XStack>
                        </Button>
                      </YStack>
                    </Anchor>
                  </XStack>
                </YStack>
              }
            </Card.Footer>
            <Card.Background>
              {(showBackgroundPreview) ?
                <FadeInView>
                  <Image
                    pos="absolute"
                    width={backgroundSize}
                    opacity={0.11}
                    height={backgroundSize}
                    resizeMode="cover"
                    als="flex-start"
                    source={{ uri: previewUrl!, height: backgroundSize, width: backgroundSize }}
                    blurRadius={1.5}
                    // borderRadius={5}
                    borderBottomRightRadius={5}
                  />
                </FadeInView>
                : undefined}
            </Card.Background>
          </Card >
        </Theme>
      </YStack>
    </>
  );
};

export default PostCard;
