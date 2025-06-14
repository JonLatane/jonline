import { useAppSelector, useCurrentServer, useFederatedDispatch, useLocalConfiguration } from 'app/hooks';
import { FederatedGroup, FederatedPost, RootState, createGroupPost, deleteGroupPost, federateId, federatedId, loadPostGroupPosts, loadUser, markGroupVisit, useRootSelector, useServerTheme } from "app/store";
import React, { useCallback, useEffect, useState } from "react";

import { GroupPost, Permission, Post, PostContext } from "@jonline/api";
import { Button, Paragraph, Spinner, Text, XStack, YStack, useDebounceValue } from '@jonline/ui';


import { AccountOrServerContextProvider } from 'app/contexts';
import { useGroupContext } from "app/contexts/group_context";
import { themedButtonBackground } from "app/utils/themed_button_background";
import moment from 'moment';
import { useLink } from "solito/link";
import { hasAdminPermission, hasPermission } from '../../utils/permission_utils';
import { AuthorInfo } from "../post/author_info";

interface Props {
  post: FederatedPost;
  isVisible?: boolean;
  isDisabled?: boolean;
}

export function useMostRecentGroup(groups: FederatedGroup[]) {
  const recentGroupIds = useLocalConfiguration().recentGroups ?? [];

  for (const groupId of recentGroupIds) {
    const group = groups.find(g => federatedId(g) === groupId);
    if (group) return group;
  }

  return groups[0];
}
// type Selector<S> = (state: RootState) => S;

// const selectOrganizationName = (id: string): Selector<string | undefined> =>
//   createSelector(
//     [(state: RootState) => organizationSelectors.selectById(state, id)],
//     (organization) => organization?.name
//   );

export const GroupPostManager: React.FC<Props> = ({ post, isVisible = true, isDisabled }) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(post);
  const { server } = accountOrServer;
  const { navColor, navTextColor, primaryAnchorColor } = useServerTheme(server);
  const title = `Share ${post.context == PostContext.EVENT ? 'Event' : 'Post'}`;
  const { selectedGroup, sharingPostId, setSharingPostId } = useGroupContext();
  const [loading, setLoading] = useState(false);
  const groupPostData = useAppSelector(state => state.groups.postIdGroupPosts[federatedId(post)]);
  const groupPostDataLoadFailed = useAppSelector(state => state.groups.failedPostIdGroupPosts.includes(federatedId(post)));
  // console.log('groupPostData', groupPostData);
  // const knownGroupIds = useAppSelector(state => state.groups.ids);

  // const maxErrors = 1;
  // const [errorCount, setErrorCount] = useState(0);
  const isVisibleDebounced = useDebounceValue(isVisible, 1500);
  const [hasBeenVisible, setHasBeenVisible] = useState(isVisibleDebounced);
  useEffect(
    () => setHasBeenVisible(isVisibleDebounced || hasBeenVisible),
    [isVisibleDebounced]
  );
  useEffect(() => {
    // console.log('errorCount', errorCount);
    if (hasBeenVisible && !groupPostData && !loading && !groupPostDataLoadFailed) {
      setLoading(true);
      dispatch(loadPostGroupPosts({ ...accountOrServer, postId: post.id }))
        .then(() => setLoading(false));
    }
  }, [federatedId(post), hasBeenVisible, sharingPostId, loading, groupPostDataLoadFailed]);

  const [loadingGroups, setLoadingGroups] = useState([] as string[]);

  // This is undefined if data isn't loaded, true if shared, false if not shared.
  const sharedToSelectedGroup = selectedGroup
    ? groupPostData?.some(gp => gp.groupId == selectedGroup?.id)
    : undefined;
  const sharedToSingleGroup = groupPostData?.length == 1;
  const singleSharedGroupId = selectedGroup
    ? federatedId(selectedGroup)
    // ? federatedId(selectedGroup)
    // : undefined
    : sharedToSingleGroup
      ? federateId(groupPostData[0]!.groupId, server)
      : undefined;
  // console.log('singleSharedGroupId', singleSharedGroupId);
  const singleSharedGroup = useAppSelector((state) => singleSharedGroupId
    ? state.groups.entities[singleSharedGroupId]
    : undefined);
  // console.log('GroupPostManager singleSharedGroup', singleSharedGroupId, singleSharedGroup)
  const otherGroupCount = groupPostData
    ? Math.max(0,
      groupPostData/*.filter(g => knownGroupIds.includes(g.groupId))*/.length - (sharedToSelectedGroup ? 1 : 0))
    : undefined;
  // return <></>;


  //TODO revert this:
  const groupsUnavailable = false;//!groupPostData || (accountOrServer.account === undefined && groupPostData.length == 0);
  const showPeriod = selectedGroup && otherGroupCount && sharedToSelectedGroup === false;
  // console.log('groupPostManager')
  return <XStack flexWrap='wrap' maw='100%'>
    {/* {loading && !groupPostDataLoadFailed
      ? <Spinner my='auto' mx='$2' position='absolute' right={0}
        color={primaryAnchorColor} size='small' />
      : undefined} */}
    {!selectedGroup && !singleSharedGroup && otherGroupCount
      ?
      <Text my='auto' fontSize={'$1'} fontFamily='$body'>
        Shared to {otherGroupCount} group{(otherGroupCount ?? 0) !== 1 ? 's' : undefined}.
      </Text>
      : undefined}
    <Text my='auto' mr='$2' fontSize={'$1'} fontFamily='$body'>
      {sharedToSelectedGroup === true || (sharedToSelectedGroup === undefined && singleSharedGroup) ? 'In ' : undefined}
      {sharedToSelectedGroup === false ? 'Not shared to ' : undefined}
    </Text>
    <XStack py='$1'>
      {groupsUnavailable
        ? <Paragraph>Groups unavailable</Paragraph>
        : <Button size='$2' my='$1' onPress={() => setSharingPostId(federatedId(post))} {...themedButtonBackground(navColor, navTextColor)}
          disabled={isDisabled || loading} o={isDisabled || loading ? 0.5 : 1}>
          {singleSharedGroup?.name
            ?? (sharedToSelectedGroup ? selectedGroup?.name : undefined)
            ?? 'Share'}
        </Button>
      }
      {/* {showPeriod
        ? <Text my='auto' ml='$1' mr='$2' fontSize={'$1'} fontFamily='$body'>.</Text>
        : undefined} */}
    </XStack>
    <Spinner my='auto' mx='$2' color={primaryAnchorColor} animation='standard' size='small'
      pointerEvents='none'
      position='absolute'
      right={8} top={7}
      zi={1000}
      o={(!groupPostData || loading) && !groupPostDataLoadFailed ? 1 : 0}
    />
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
  // createViewHref?: (group: Group) => string;
}

export const GroupPostChrome: React.FC<GroupPostChromeProps> = ({ group, groupPost, post, }) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(group);
  const { server } = accountOrServer;
  const currentServer = useCurrentServer();
  const isPrimaryServer = server?.host === currentServer?.host;
  const isSameServer = group.serverHost === post.serverHost;
  const shared = groupPost != undefined;
  const sharedBy = groupPost?.sharedBy;
  // const authorUser = useAppSelector(state => groupPost
  //   ? state.users.entities[groupPost?.userId ?? '']
  //   : undefined);
  // useEffect(() => {
  //   if (groupPost && !sharedBy) {
  //     dispatch(loadUser({ userId: groupPost.userId, ...accountOrServer }));
  //   }
  // }, [groupPost, authorUser]);
  const authorData = groupPost ? Post.fromPartial({
    createdAt: groupPost.createdAt,
    author: sharedBy
    // {
    //   userId: groupPost.userId,
    //   username: authorUser?.username,
    //   avatar: authorUser?.avatar,
    // }
  }) : undefined;
  // const accountOrServer = useAccountOrServer();
  const { navColor, navTextColor, primaryAnchorColor, textColor: themeTextColor } = useServerTheme(server);

  const canShare = !shared && hasPermission(group.currentUserMembership, Permission.CREATE_POSTS);
  const canUnshare = shared && (groupPost.userId === accountOrServer.account?.user?.id || hasAdminPermission(accountOrServer.account?.user) || hasAdminPermission(group.currentUserMembership));
  const [loadingGroup, setLoadingGroup] = useState(false);

  const detailsGroupShortname = !isPrimaryServer
    ? federateId(group.shortname, accountOrServer.server)
    : group.shortname;

  const detailsPostId = !isPrimaryServer
    ? federateId(post.id, accountOrServer.server)
    : post.id;

  const detailsEventId = useAppSelector(state => state.events.postEvents[federatedId(post)]);

  const detailsEventInstanceId = useAppSelector(state =>
    detailsEventId
      ? state.events.entities[detailsEventId]?.instances.filter(
        i => moment(i.endsAt).isAfter(moment())
      )[0]?.id
      : undefined);
  // useAppSelector(state => {
  //   const instanceId = state.events.postInstances[federatedId(post)];
  //   post.context === PostContext.EVENT_INSTANCE && instanceId
  //     ? !isPrimaryServer
  //       ? instanceId
  //       : parseFederatedId(instanceId)?.id
  //     : undefined
  // });

  // console.log('GroupPostChrome post.context', post.context, 'detailsEventInstanceId', detailsEventInstanceId)
  const viewLink = useLink({
    href: post.context === PostContext.EVENT && detailsEventInstanceId
      ? `/g/${detailsGroupShortname}/e/${detailsEventInstanceId}`
      : `/g/${detailsGroupShortname}/p/${detailsPostId}`
  });

  // const [loadingGroups, setLoadingGroups] = useState([] as string[]);
  const shareToGroup = useCallback((groupId: string) => {
    requestAnimationFrame(() => {
      dispatch(createGroupPost({ ...accountOrServer, postId: post.id, groupId }))
        .then(() => {
          setLoadingGroup(false);
          if (server) dispatch(markGroupVisit({ group }));
        });
      setLoadingGroup(true);
    });
  }, [server, federatedId(post)]);
  const unshareToGroup = useCallback((groupId: string) => {
    requestAnimationFrame(() => {
      dispatch(deleteGroupPost({ ...accountOrServer, postId: post.id, groupId }))
        .then(() => setLoadingGroup(false));
      setLoadingGroup(true);
    });
  }, [server, federatedId(post)]);

  const { selectedGroup } = useGroupContext();
  const groupPostData = useAppSelector(state => state.groups.postIdGroupPosts[federatedId(post)]);
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
      groupPostData/*.filter(g => knownGroupIds.includes(g.groupId))*/.length - (sharedToSelectedGroup ? 1 : 0))
    : undefined;

  const selected = groupPost?.groupId === group.id;
  const textColor = //selected ? navTextColor : 
    themeTextColor;
  // debugger;
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