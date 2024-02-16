import { deletePost, federateId, getServerTheme, loadPostReplies, updatePost } from "app/store";
import React, { useEffect, useState } from "react";
import { GestureResponderEvent, View } from "react-native";

import { Post, Visibility } from "@jonline/api";
import { Anchor, AnimatePresence, Button, Card, Dialog, Heading, Image, Paragraph, TamaguiMediaState, TextArea, Theme, XStack, YStack, reverseStandardAnimation, standardAnimation, useMedia, useTheme } from '@jonline/ui';
import { ChevronRight, Delete, Edit3 as Edit, Eye, Link, Reply, Save, X as XIcon } from "@tamagui/lucide-icons";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from 'react-social-media-embed';
import { useLink } from "solito/link";
import { TamaguiMarkdown } from "../../components/tamagui_markdown";
import { AuthorInfo } from "./author_info";

import { ShareableToggle, VisibilityPicker } from "app/components";
import { AccountOrServerContextProvider, useGroupContext } from "app/contexts";
import { useAccount, useAccountOrServer, useComponentKey, useCurrentAndPinnedServers, useIsVisible, useLocalConfiguration, useMediaUrl, usePostDispatch } from "app/hooks";
import { federatedEntity } from '../../store/federation';
import { GroupPostManager } from '../groups/group_post_manager';
import { ServerNameAndLogo } from "../navigation/server_name_and_logo";
import { postVisibilityDescription } from "./base_create_post_sheet";
import { PostMediaManager } from "./post_media_manager";
import { PostMediaRenderer } from "./post_media_renderer";

interface PostCardProps {
  // Note: Post may not be a FederatedPost if the Post is a reply. This could be better thought out...
  // it might be better to make a "ReplyCard" type.
  post: Post;
  isPreview?: boolean;
  // groupContext?: Group;
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
  // groupContext,
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
  const { dispatch, accountOrServer } = usePostDispatch(post);
  const server = accountOrServer.server;
  const isPrimaryServer = useAccountOrServer().server?.host === accountOrServer.server?.host;
  const currentAndPinnedServers = useCurrentAndPinnedServers();
  const showServerInfo = ('serverHost' in post) && (!isPrimaryServer || (isPreview && currentAndPinnedServers.length > 1));
  // console.log('PostCard', post.id, serverHost, accountOrServer?.server?.host);
  const mediaQuery = useMedia();
  const groupContext = useGroupContext();
  const isGroupPrimaryServer = useAccountOrServer().server?.host === groupContext?.serverHost;


  const currentUser = useAccount()?.user;
  const theme = useTheme();
  const { primaryColor, primaryBgColor, primaryAnchorColor, navAnchorColor } = getServerTheme(server, theme);
  // const postsStatus = useRootSelector((state: RootState) => state.posts.status);
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
  const [editedShareable, setEditedShareable] = useState(post.shareable);

  const content = editing ? editedContent : post.content;
  const media = editing ? editedMedia : post.media;
  const embedLink = editing ? editedEmbedLink : post.embedLink;
  const visibility = editing ? editedVisibility : post.visibility;
  const shareable = editing ? editedShareable : post.shareable;
  const { fancyPostBackgrounds, shrinkPreviews } = useLocalConfiguration();

  function saveEdits() {
    setSavingEdits(true);
    dispatch(updatePost({
      ...accountOrServer, ...post,
      content: editedContent,
      media: editedMedia,
      embedLink: editedEmbedLink,
      visibility: editedVisibility,
      shareable: editedShareable,
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

  const postHasWebLink = !!post.link && post.link.startsWith('http');
  const postLink = postHasWebLink ? useLink({
    href: post.link!,
  }) : undefined;

  const postLinkView = postHasWebLink
    ? <Anchor key='post-link' textDecorationLine='none' {...postLink} target="_blank">
      <XStack>
        <YStack my='auto' mr='$1'>
          <Link size='$1' color={navAnchorColor} />
        </YStack>
        <YStack f={1} my='auto'>
          <Paragraph size="$2" color={navAnchorColor} overflow="hidden" whiteSpace="nowrap" textOverflow="ellipsis">
            {post.link}
          </Paragraph>
        </YStack>
      </XStack>
    </Anchor>
    : undefined;

  const detailsLinkId = !isPrimaryServer
    ? federateId(post.id, accountOrServer.server)
    : post.id;
  const detailsGroupId = groupContext
    ? (!isGroupPrimaryServer
      ? federateId(groupContext.shortname, accountOrServer.server)
      : groupContext.shortname)
    : undefined;
  const detailsLink = useLink({
    href: groupContext
      ? `/g/${detailsGroupId}/p/${detailsLinkId}`
      : `/post/${detailsLinkId}`,
  });
  const showDetailsShadow = isPreview && post.content && post.content.length > 700;

  const detailsShadowProps = showDetailsShadow ? {
    shadowOpacity: 0.3,
    shadowOffset: { width: -5, height: -5 },
    shadowRadius: 10
  } : {};

  const author = post.author;
  const isAuthor = author && author.userId === currentUser?.id;
  const showEdit = isAuthor && !isPreview;

  const [loadingReplies, setLoadingReplies] = useState(false);
  useEffect(() => {
    if (loadingReplies && (post.replyCount == 0 || post.replies.length > 0)) {
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
  const previewUrl = useMediaUrl(imagePreview?.id, accountOrServer);

  const showBackgroundPreview = !!imagePreview;


  const componentKey = useComponentKey('post-card');
  const backgroundSize = document.getElementById(componentKey)?.clientWidth ?? postBackgroundSize(mediaQuery);
  const foregroundSize = backgroundSize * 0.7;

  const contentArea = <YStack maxHeight={isPreview
    ? (showScrollableMediaPreviews) ? 150 : 300
    : editing && !previewingEdits ? backgroundSize * (media.length > 0 ? 0.6 : 0.8) : undefined} overflow='hidden'
  >
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
  </YStack>;

  const title = post.title && post.title != '' ? post.title : `Untitled Post ${post.id}`;
  const deleteDialog = <Dialog>
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

          <XStack gap="$3" jc="flex-end">
            <Dialog.Close asChild>
              <Button>Cancel</Button>
            </Dialog.Close>
            <Theme inverse>
              <Button onPress={doDeletePost}>Delete</Button>
            </Theme>
          </XStack>
        </YStack>
      </Dialog.Content>
    </Dialog.Portal>
  </Dialog>;
  return (
    <AccountOrServerContextProvider value={accountOrServer}>
      <YStack w='100%' ref={ref!}>
        {previewParent && post.replyToPostId
          ? <XStack w='100%'>
            {mediaQuery.gtXs ? <Heading size='$5' ml='$3' mr='$0' marginVertical='auto' ta='center'>RE</Heading> : undefined}
            <XStack marginVertical='auto' marginHorizontal='$1'><ChevronRight /></XStack>

            <Card f={1} theme="dark" size="$1" bordered id={componentKey}
              margin='$0'
              backgroundColor={selectedPostId == previewParent.id ? '$backgroundFocus' : undefined}
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
                    <TamaguiMarkdown text={previewParent.content} shrink />
                  </XStack>

                  <XStack ml='auto' mr='$2'>
                    <AuthorInfo post={previewParent!} disableLink={false} isVisible={isVisible} shrink />
                  </XStack>
                </YStack>
              </Card.Footer>
            </Card>
          </XStack>
          : undefined}
        {/* <Theme inverse={selectedPostId == post.id}> */}
        <Card size="$4" bordered
          // theme="dark"

          borderColor={showServerInfo ? primaryColor : undefined}
          margin='$1'
          backgroundColor={selectedPostId == post.id ? '$backgroundFocus' : undefined}
          marginBottom={replyPostIdPath ? '$0' : '$3'}
          marginTop={replyPostIdPath ? '$0' : '$3'}
          // marginRight={-10}
          f={isPreview ? undefined : 1}
          animation='standard'
          pressStyle={isPreview ? { scale: 0.990 } : {}}
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
              <XStack ai='center'>
                <YStack f={1}>
                  {isPreview
                    ? <Anchor textDecorationLine='none'
                      {...(isPreview ? detailsLink : {})}
                    >
                      <YStack w='100%'>
                        <Heading size="$7" marginRight='auto'>
                          {title}
                        </Heading>
                      </YStack>
                    </Anchor>
                    : <YStack w='100%'>
                      <Heading size="$7" marginRight='auto'>
                        {title}
                      </Heading>
                    </YStack>}

                  {postLinkView}
                </YStack>

                {showServerInfo
                  ? <XStack my='auto' w={mediaQuery.gtXxxs ? undefined : '$4'} h={mediaQuery.gtXxxs ? undefined : '$4'} jc={mediaQuery.gtXxxs ? undefined : 'center'}>
                    <ServerNameAndLogo server={server} shrinkToSquare={!mediaQuery.gtXxxs} />
                  </XStack>
                  : undefined}
              </XStack>
            </Card.Header>
            : undefined}
          <Card.Footer p={0} >
            {deleted
              ? <Paragraph size='$1'>This {post.replyToPostId ? 'comment' : 'post'} has been deleted.</Paragraph>
              : <YStack zi={1000} width='100%'>

                <YStack w='100%' px='$3' >
                  <AnimatePresence>
                    {shrinkPreviews && isPreview ? undefined : <YStack key='content' animation='standard' {...reverseStandardAnimation}>
                      <YStack mah={isPreview ? 300 : undefined} overflow='hidden'>
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
                      </YStack>
                      {isPreview
                        ? <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                          {contentArea}
                        </Anchor>
                        : contentArea}
                    </YStack>}
                  </AnimatePresence>
                </YStack>
                <AnimatePresence>
                  {shrinkPreviews && isPreview ? undefined
                    : <YStack animation='standard' {...standardAnimation}>
                      <XStack key='edit-buttons' px='$3' gap='$2' flexWrap="wrap" py='$2'>
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

                              {deleteDialog}
                            </>
                          : isAuthor ? <XStack o={0.5}>{deleteDialog}</XStack> : undefined}
                        <XStack gap='$2' flexWrap="wrap" ml='auto' my='auto' maw='100%'>
                          {post.replyToPostId && !editing && post.visibility === Visibility.GLOBAL_PUBLIC ? undefined : <XStack key='visibility-edit' my='auto' ml='auto' pl='$2'>
                            <VisibilityPicker
                              id={`visibility-picker-${post.id}${isPreview ? '-preview' : ''}`}
                              label='Post Visibility'
                              visibility={visibility}
                              onChange={setEditedVisibility}
                              visibilityDescription={v => postVisibilityDescription(v, groupContext, server, 'post')}
                              readOnly={!editing || previewingEdits}
                            />
                          </XStack>}
                          <XStack key='shareable-edit' my='auto' ml='auto' pb='$1'>
                            <ShareableToggle value={shareable}
                              setter={setEditedShareable}
                              readOnly={!editing || previewingEdits} />
                          </XStack>
                          {isPrimaryServer && !post?.replyToPostId
                            ? <XStack maw='100%' mr={0} my='auto' ml='auto'>
                              <GroupPostManager post={federatedEntity(post, server)} isVisible={isVisible} />
                            </XStack>
                            : undefined}

                        </XStack>
                      </XStack>
                      <XStack w='100%' p='$3' mt={showEdit ? -11 : -15} pt={post?.replyToPostId ? 10 : 0} {...detailsShadowProps}>
                        <AuthorInfo {...{ post, isVisible }} />
                        {onPressReply ? <Button onPress={onPressReply} circular icon={Reply}
                          my='auto' size='$2' mr='$2' /> : undefined}
                        <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                          <YStack h='100%' mr='$1'>
                            <Button opacity={isPreview ? 1 : 0.9} transparent={isPreview || !post?.replyToPostId || post.replyCount == 0}
                              borderColor={isPreview || cannotToggleReplies ? 'transparent' : undefined}
                              disabled={cannotToggleReplies || loadingReplies}
                              marginVertical='auto'
                              // mr={isPreview ? '$2' : undefined}
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
                    </YStack>}
                </AnimatePresence>
              </YStack>
            }
          </Card.Footer>
          {/* {fancyPostBackgrounds ? */}
          <Card.Background>
            {(showBackgroundPreview) ?
              <Image
                pos="absolute"
                width={backgroundSize}
                opacity={fancyPostBackgrounds ? 0.11 : 0.04}
                height={backgroundSize}
                resizeMode="cover"
                als="flex-start"
                source={{ uri: previewUrl!, height: backgroundSize, width: backgroundSize }}
                blurRadius={fancyPostBackgrounds ? 1.5 : undefined}
                // borderRadius={5}
                borderBottomRightRadius={5}
              />
              : undefined}
          </Card.Background>
          {/* : undefined} */}
        </Card >
        {/* </Theme> */}
      </YStack >
    </AccountOrServerContextProvider>
  );
};

export default PostCard;
