import { useAppSelector, useCredentialDispatch, useFederatedAccountOrServer, useFederatedDispatch, useLocalConfiguration, useServer } from 'app/hooks';
import { FederatedGroup, FederatedPost, RootState, createGroupPost, deleteGroupPost, federateId, federatedId, getServerTheme, loadPostGroupPosts, loadUser, markGroupVisit, serverID, useRootSelector, useServerTheme } from "app/store";
import React, { useEffect, useState } from "react";

import { Group, GroupPost, Permission, Post, PostContext } from "@jonline/api";
import { Button, Paragraph, Spinner, Text, XStack, YStack, useTheme } from '@jonline/ui';


import { themedButtonBackground } from "app/utils/themed_button_background";
import { useLink } from "solito/link";
import { useGroupContext } from "app/contexts/group_context";
import { hasAdminPermission, hasPermission } from '../../utils/permission_utils';
import { AuthorInfo } from "../post/author_info";
import { GroupsSheet } from './groups_sheet';
import { AccountOrServerContext, AccountOrServerContextProvider } from 'app/contexts';

interface Props {
  post: FederatedPost;
  createViewHref?: (group: Group) => string;
  isVisible?: boolean;
}

export function useMostRecentGroup(groups: FederatedGroup[]) {
  const recentGroupIds = useLocalConfiguration().recentGroups ?? [];

  for (const groupId of recentGroupIds) {
    const group = groups.find(g => federatedId(g) === groupId);
    if (group) return group;
  }

  return groups[0];
}

export const GroupPostManager: React.FC<Props> = ({ post, createViewHref, isVisible = true }) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(post);
  const { server } = accountOrServer;
  const { navColor, navTextColor, primaryAnchorColor } = getServerTheme(server, useTheme());
  const title = `Share ${post.context == PostContext.EVENT ? 'Event' : 'Post'}`;
  const selectedGroup = useGroupContext();
  const [loading, setLoading] = useState(false);
  const groupPostData = useAppSelector(state => state.groups.postIdGroupPosts[federatedId(post)]);
  console.log('groupPostData', groupPostData);
  const knownGroupIds = useAppSelector(state => state.groups.ids);

  const maxErrors = 1;
  const [errorCount, setErrorCount] = useState(0);
  useEffect(() => {
    // console.log('errorCount', errorCount);
    if (isVisible && !groupPostData && !loading && errorCount < maxErrors) {
      setLoading(true);
      dispatch(loadPostGroupPosts({ ...accountOrServer, postId: post.id }))
        .then(() => setLoading(false))
        .catch(() => { setLoading(false); setErrorCount(errorCount + 1); });
    }
  }, [post, isVisible, loading, errorCount]);

  const [loadingGroups, setLoadingGroups] = useState([] as string[]);

  // This is undefined if data isn't loaded, true if shared, false if not shared.
  const sharedToSelectedGroup = selectedGroup && groupPostData?.some(gp => gp.groupId == selectedGroup?.id);
  const sharedToSingleGroup = groupPostData?.length == 1;
  const singleSharedGroupId = sharedToSingleGroup
    ? groupPostData[0]!.groupId
    : undefined;
  const singleSharedGroup = useRootSelector((state: RootState) => singleSharedGroupId
    ? state.groups.entities[singleSharedGroupId]
    : undefined);
  const otherGroupCount = groupPostData
    ? Math.max(0,
      groupPostData.filter(g => knownGroupIds.includes(g.groupId)).length - (sharedToSelectedGroup ? 1 : 0))
    : undefined;
  // return <></>;

  //TODO revert this:
  const groupsUnavailable = false;//!groupPostData || (accountOrServer.account === undefined && groupPostData.length == 0);
  // console.log('groupPostManager')
  return <XStack flexWrap='wrap' maw='100%'>
    {!selectedGroup && !singleSharedGroup && otherGroupCount
      ?
      <Text my='auto' fontSize={'$1'} fontFamily='$body'>
        Shared to {otherGroupCount} group{otherGroupCount > 1 ? 's' : undefined}.
      </Text>
      : undefined}
    <Text my='auto' mr='$2' fontSize={'$1'} fontFamily='$body'>
      {sharedToSelectedGroup === true || singleSharedGroup ? 'In ' : undefined}
      {sharedToSelectedGroup === false ? 'Not shared to ' : undefined}
    </Text>
    {loading && errorCount < maxErrors ? <Spinner my='auto' mx='$2' color={primaryAnchorColor} size='small' /> : undefined}
    <XStack>
      {groupsUnavailable
        ? <Paragraph>Groups unavailable</Paragraph>
        : <GroupsSheet
          title={title}
          itemTitle={post.title}
          selectedGroup={selectedGroup ?? singleSharedGroup}
          // onGroupSelected={() => { }}
          disabled={!groupPostData || groupsUnavailable}
          topGroupIds={groupPostData?.map(
            gp => federateId(gp.groupId, server)) ?? []
          }
          serverHostFilter={server?.host}
          extraListItemChrome={(group) => {
            const groupPost = group.serverHost === server?.host
              ? groupPostData?.find(gp => gp.groupId == group.id)
              : undefined;

            return <GroupPostChrome group={group} groupPost={groupPost} post={post} createViewHref={createViewHref} />
          }}
          disableSelection
          hideInfoButtons
          // delayRenderingSheet
          // hideAdditionalGroups={accountOrServer.account === undefined}
          hideLeaveButtons
        />
      }
      {selectedGroup && otherGroupCount && sharedToSelectedGroup === false
        ? <Text my='auto' ml='$1' mr='$2' fontSize={'$1'} fontFamily='$body'>. </Text>
        : undefined}
    </XStack>
    {groupPostData && selectedGroup
      ? otherGroupCount
        ? <Text my='auto' ml={selectedGroup && otherGroupCount && sharedToSelectedGroup === false ? 0 : '$2'}
          fontSize={'$1'} fontFamily='$body'>
          {sharedToSelectedGroup === true ? ' + ' : undefined}
          {sharedToSelectedGroup === false ? 'Shared to ' : undefined}
          {otherGroupCount} group{otherGroupCount > 1 ? 's' : undefined}.
        </Text>
        : <Text my='auto' ml='$1' mr='$2' fontSize={'$1'} fontFamily='$body'>. </Text>
      : undefined}
    {/* {isVisible ? "hi!" : undefined} */}
  </XStack>;
}


interface GroupPostChromeProps {
  group: FederatedGroup,
  groupPost: GroupPost | undefined;
  post: FederatedPost;
  createViewHref?: (group: Group) => string;
}

export const GroupPostChrome: React.FC<GroupPostChromeProps> = ({ group, groupPost, post, createViewHref, }) => {
  const { server } = useFederatedAccountOrServer(group);
  const currentServer = useServer();
  const isPrimaryServer = server?.host === currentServer?.host;
  const isSameServer = group.serverHost === post.serverHost;
  const shared = groupPost != undefined;
  const authorUser = useAppSelector(state => groupPost
    ? state.users.entities[groupPost?.userId ?? '']
    : undefined);
  useEffect(() => {
    if (groupPost && !authorUser) {
      dispatch(loadUser({ userId: groupPost.userId, ...accountOrServer }));
    }
  }, [groupPost, authorUser]);
  const authorData = groupPost ? Post.fromPartial({
    createdAt: groupPost.createdAt,
    author: {
      userId: groupPost.userId,
      username: authorUser?.username,
      avatar: authorUser?.avatar,
    }
  }) : undefined;
  // const accountOrServer = useAccountOrServer();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { navColor, navTextColor, primaryAnchorColor } = getServerTheme(server, useTheme());

  const canShare = !shared && hasPermission(group.currentUserMembership, Permission.CREATE_POSTS);
  const canUnshare = shared && (groupPost.userId === accountOrServer.account?.user?.id || hasAdminPermission(accountOrServer.account?.user) || hasAdminPermission(group.currentUserMembership));
  const [loadingGroup, setLoadingGroup] = useState(false);

  const viewLink = useLink({ href: createViewHref?.(group) ?? `/g/${group.shortname}/p/${post.id}` });

  // const [loadingGroups, setLoadingGroups] = useState([] as string[]);
  function shareToGroup(groupId: string) {
    dispatch(createGroupPost({ ...accountOrServer, postId: post.id, groupId }))
      .then(() => {
        setLoadingGroup(false);
        if (server) dispatch(markGroupVisit({ group, server }));
      });
    setLoadingGroup(true);
  }
  function unshareToGroup(groupId: string) {
    dispatch(deleteGroupPost({ ...accountOrServer, postId: post.id, groupId }))
      .then(() => setLoadingGroup(false));
    setLoadingGroup(true);
  }
  const selected = groupPost?.groupId === group.id;
  const textColor = selected ? navTextColor : undefined;
  return <YStack mx='auto' w='100%'>
    <XStack gap='$1' my='$2' px='$2' w='100%' flexWrap="wrap">
      <XStack f={1}>
        <XStack mx='auto'>
          <Text my='auto' mr='$2' color={textColor}
            fontSize={'$1'} fontFamily='$body'>
            {shared ? "Shared by"
              : isSameServer ? 'Not yet shared.'
                : 'Not shareable to other servers.'}
          </Text>
          {shared ?
            <AccountOrServerContextProvider value={accountOrServer}>
              <AuthorInfo post={authorData!} textColor={textColor} />
            </AccountOrServerContextProvider> : undefined}
        </XStack>
      </XStack>
      <XStack mx='auto'>
        {shared === true ? <Button mx='$2' {...viewLink}>View</Button> : undefined}
        {accountOrServer.account && shared != undefined ?
          canShare
            ? <Button
              {...themedButtonBackground(navColor, navTextColor)}
              disabled={loadingGroup}
              o={loadingGroup ? 0.5 : 1}
              onPress={() => shareToGroup(group.id)}>
              Share
            </Button>
            : canUnshare
              ? <Button
                disabled={loadingGroup}
                o={loadingGroup ? 0.5 : 1}
                onPress={() => unshareToGroup(group.id)}>
                Unshare
              </Button>
              : undefined
          : undefined}
      </XStack>
    </XStack>
  </YStack>;
}