import { Paragraph, YStack } from '@jonline/ui'
import { Anchor, Group, GroupPost, Heading } from '@jonline/ui/src'
import { loadPost, RootState, selectGroupById, selectPostById, updateGroupPosts, useCredentialDispatch, useTypedSelector } from 'app/store'
import React, { useState, useEffect } from 'react'
import ReactMarkdown from 'react-markdown'
import { FlatList } from 'react-native'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import PostCard from '../post/post_card'
import { TabsNavigation } from '../tabs/tabs_navigation'

const { useParam } = createParam<{ shortname: string }>()

export function GroupDetailsScreen() {
  const [shortname] = useParam('shortname');
  // const [loadingPosts, setLoadingPosts] = React.useState(false);
  const linkProps = useLink({ href: '/' });
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const groupId = useTypedSelector((state: RootState) => state.groups.shortnameIds[shortname!]);
  const group = useTypedSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const groupPosts = useTypedSelector((state: RootState) =>
    (groupId ? state.groups.idGroupPosts[groupId] : undefined));
  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  const [showScrollPreserver, setShowScrollPreserver] = useState(isSafari);


  // const [loadingPosts, setLoadingPosts] = useState(false);
  // useEffect(() => {
  //   if (postsState.status == 'unloaded' && !loadingPosts) {
  //     setLoadingPosts(true);
  //     reloadPosts();
  //   } else if (postsState.status == 'loaded') {//posts.length > 0) {
  //     setLoadingPosts(false);
  //     setTimeout(() => setShowScrollPreserver(false), 1500);
  //   }
  // });


  const [loadingGroupPosts, setLoadingGroupPosts] = useState(false);
  useEffect(() => {
    if (groupId && !groupPosts && !loadingGroupPosts) {
      setLoadingGroupPosts(true);
      reloadPosts();
    } else if (groupPosts) {
      setLoadingGroupPosts(false);
      setTimeout(() => setShowScrollPreserver(false), 1500);
    }
  });

  function reloadPosts() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(updateGroupPosts({ ...accountOrServer, groupId: groupId! })), 1);
  }

  return (
    <TabsNavigation selectedGroup={group}>
      <YStack f={1} jc="center" ai="center" paddingHorizontal='$3' mt='$3' maw={800} space>
        {/* <Paragraph ta="center" fow="800">{`Group Shortname: ${shortname}`}</Paragraph> */}
        {/* <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button> */}
        {(groupPosts || []).length > 0 ?
          <FlatList data={groupPosts}
            // onRefresh={reloadPosts}
            // refreshing={postsState.status == 'loading'}
            // Allow easy restoring of scroll position
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
            keyExtractor={(gp) => gp.postId}
            renderItem={({ item: groupPost }) => {
              return <GroupPostCard key={`${groupPost.groupId}=${groupPost.postId}`}
                group={group!} groupPost={groupPost} />;
            }} />
          : <Heading size='$1' ta='center'>No posts yet</Heading>}
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
  return post ? <PostCard post={post} groupContext={group} isPreview /> : <></>;
}
