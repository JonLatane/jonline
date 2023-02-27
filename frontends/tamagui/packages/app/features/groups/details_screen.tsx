import { Paragraph, YStack } from '@jonline/ui'
import { Anchor, Card, Group, GroupPost, Heading, Spinner, useWindowDimensions, XStack } from '@jonline/ui/src'
import { dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui/src/global'
import { loadPost, RootState, selectGroupById, selectPostById, loadGroupPosts, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store'
import React, { useState, useEffect } from 'react'
import ReactMarkdown from 'react-markdown'
import { FlatList } from 'react-native'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import PostCard from '../post/post_card'
import { TabsNavigation } from '../tabs/tabs_navigation'
import StickyBox from "react-sticky-box";

const { useParam } = createParam<{ shortname: string }>()

export function GroupDetailsScreen() {
  const [shortname] = useParam('shortname');
  // const [loadingPosts, setLoadingPosts] = React.useState(false);
  const linkProps = useLink({ href: '/' });
  const { server, primaryColor, navColor } = useServerTheme();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const groupsState = useTypedSelector((state: RootState) => state.groups);
  const groupId = useTypedSelector((state: RootState) => state.groups.shortnameIds[shortname!]);
  const group = useTypedSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const groupPosts = useTypedSelector((state: RootState) =>
    (groupId ? state.groups.idGroupPosts[groupId] : undefined));
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const dimensions = useWindowDimensions();
  const [loadingGroupPosts, setLoadingGroupPosts] = useState(false);
  useEffect(() => {
    if (groupId && !groupPosts && !loadingGroupPosts) {
      setLoadingGroupPosts(true);
      reloadPosts();
    } else if (groupPosts) {
      setLoadingGroupPosts(false);
      dismissScrollPreserver(setShowScrollPreserver);
    }
  });

  function reloadPosts() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(loadGroupPosts({ ...accountOrServer, groupId: groupId! })), 1);
  }
  const loading = groupsState.status == 'loading' || groupsState.status == 'unloaded'
    || postsState.status == 'loading';

  return (
    <TabsNavigation selectedGroup={group}>
      {loading ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} jc="center" ai="center" paddingHorizontal='$3' mt='$3' maw={800} w='100%' space>
        {/* <Paragraph ta="center" fow="800">{`Group Shortname: ${shortname}`}</Paragraph> */}
        {/* <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button> */}
        {(groupPosts || []).length > 0 ?
          <FlatList data={groupPosts} style={{ width: '100%' }}
            // onRefresh={reloadPosts}
            // refreshing={postsState.status == 'loading'}
            // Allow easy restoring of scroll position
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
            keyExtractor={(gp) => gp.postId}
            renderItem={({ item: groupPost }) => {
              return <GroupPostCard key={`${groupPost.groupId}=${groupPost.postId}`}
                group={group!} groupPost={groupPost} />;
            }} />
          : loading ? undefined : <Heading size='$1' ta='center'>No posts yet</Heading>}
      </YStack>
    </TabsNavigation>
  )
}

type GroupPostCardProps = {
  group: Group;
  groupPost: GroupPost;
}
function GroupPostCard({ group, groupPost }: GroupPostCardProps) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const post = useTypedSelector((state: RootState) => selectPostById(state.posts, groupPost.postId!));
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const { primaryColor } = useServerTheme();
  const [loadingPost, setLoadingPost] = useState(false);
  useEffect(() => {
    if (!post && !loadingPost) {
      setLoadingPost(true);
      setTimeout(() =>
        dispatch(loadPost({ ...accountOrServer, id: groupPost.postId! })), 1);
    } else if (postsState.status == 'loaded') {
      setLoadingPost(false);
    }
  });
  return post ? <PostCard post={post} groupContext={group} isPreview /> : <>
    <Card w='100%' h={200}
      theme="dark" elevate size="$4" bordered
      margin='$0'
      // marginBottom={replyPostIdPath ? '$0' : '$3'}
      mb='$3'
      mt='$3'
      // marginTop={replyPostIdPath ? '$0' : '$3'}
      padding='$0'
      f={1}
      // f={isPreview ? undefined : 1}
      animation="bouncy"
      pressStyle={{ scale: 0.990 }}
    // ref={ref!}
    >
      <Spinner f={1} size='large' color={primaryColor} mt={50} />
    </Card>
  </>;
}
