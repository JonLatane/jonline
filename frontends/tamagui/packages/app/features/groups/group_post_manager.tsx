import { createGroupPost, deleteGroupPost, loadPostGroupPosts, markGroupVisit, RootState, useAccountOrServer, useCredentialDispatch, useServer, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Group, GroupPost, Permission, Post, PostContext } from "@jonline/api";
import { Button, Separator, Spinner, Text, XStack, YStack } from '@jonline/ui';


import { useGroupContext } from "./group_context";
import { GroupsSheet } from './groups_sheet';
import { AuthorInfo } from "../post/author_info";
import { hasAdminPermission, hasPermission } from '../../utils/permission_utils';
import { themedButtonBackground } from "app/utils/themed_button_background";
import { useLink } from "solito/link";

interface Props {
  post: Post;
  createViewHref?: (group: Group) => string;
  isVisible?: boolean;
}

export const GroupPostManager: React.FC<Props> = ({ post, createViewHref, isVisible = true }) => {
  // const disabled = false;
  function onValueSelected(v: string) {
    // const selectedVisibility = parseInt(v) as Visibility;
    // onChange(selectedVisibility)
  }
  const { navColor, navTextColor, primaryAnchorColor } = useServerTheme();
  const title = `Share ${post.context == PostContext.EVENT ? 'Event' : 'Post'}`;
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const selectedGroup = useGroupContext();
  const [loading, setLoading] = useState(false);
  const groupPostData = useTypedSelector((state: RootState) => state.groups.postIdGroupPosts[post.id]);
  const knownGroupIds = useTypedSelector((state: RootState) => state.groups.ids);

  const maxErrors = 3;
  const [errorCount, setErrorCount] = useState(0);
  useEffect(() => {
    // console.log('errorCount', errorCount);
    if (isVisible && !groupPostData && !loading && errorCount < maxErrors) {
      dispatch(loadPostGroupPosts({ ...accountOrServer, postId: post.id }))
        .then(() => setLoading(false))
        .catch(() => { setLoading(false); setErrorCount(errorCount + 1); });
      setLoading(true);
    }
  }, [post, isVisible, loading, errorCount]);

  const [loadingGroups, setLoadingGroups] = useState([] as string[]);

  // This is undefined if data isn't loaded, true if shared, false if not shared.
  const sharedToSelectedGroup = selectedGroup && groupPostData?.some(gp => gp.groupId == selectedGroup?.id);
  const sharedToSingleGroup = groupPostData?.length == 1;
  const singleSharedGroupId = sharedToSingleGroup
    ? groupPostData[0]!.groupId
    : undefined;
  const singleSharedGroup = useTypedSelector((state: RootState) => singleSharedGroupId
    ? state.groups.entities[singleSharedGroupId]
    : undefined);
  const otherGroupCount = groupPostData
    ? groupPostData.filter(g => knownGroupIds.includes(g.groupId)).length - (sharedToSelectedGroup ? 1 : 0)
    : undefined;
  // return <></>;

  //TODO revert this:
  const groupsUnavailable = false;//!groupPostData || (accountOrServer.account === undefined && groupPostData.length == 0);
  return <XStack flexWrap='wrap' maw='100%'>
    {!selectedGroup && !singleSharedGroup && otherGroupCount
      ?
      <Text my='auto' fontSize={'$1'} fontFamily='$body'>
        Shared to {otherGroupCount} group{otherGroupCount > 1 ? 's' : undefined}.
      </Text>
      : undefined}
    <Text my='auto' mr='$2' fontSize={'$1'} fontFamily='$body'>
      {sharedToSelectedGroup === true || singleSharedGroup? 'In ' : undefined}
      {sharedToSelectedGroup === false ? 'Not shared to ' : undefined}
    </Text>
    {loading && errorCount < maxErrors ? <Spinner my='auto' mx='$2' color={primaryAnchorColor} size='small' /> : undefined}
    <XStack>
      {groupsUnavailable ? undefined :
        <GroupsSheet
          title={title}
          itemTitle={post.title}
          selectedGroup={selectedGroup ?? singleSharedGroup}
          // onGroupSelected={() => { }}
          disabled={groupsUnavailable}
          topGroupIds={groupPostData?.map(gp => gp.groupId) ?? []}
          extraListItemChrome={(group) => {
            const groupPost = groupPostData?.find(gp => gp.groupId == group.id);

            return <GroupPostChrome group={group} groupPost={groupPost} post={post} createViewHref={createViewHref} />
          }}
          disableSelection
          hideInfoButtons
          delayRenderingSheet
          hideAdditionalGroups={accountOrServer.account === undefined}
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
  group: Group,
  groupPost: GroupPost | undefined;
  post: Post;
  createViewHref?: (group: Group) => string;
}

export const GroupPostChrome: React.FC<GroupPostChromeProps> = ({ group, groupPost, post, createViewHref, }) => {
  const server = useServer();
  const shared = groupPost != undefined;
  const authorData = groupPost ? Post.fromPartial({
    createdAt: groupPost.createdAt,
    author: {
      userId: groupPost.userId,
    }
  }) : undefined;
  // const accountOrServer = useAccountOrServer();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { navColor, navTextColor, primaryAnchorColor } = useServerTheme();

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
  return <YStack mx='auto' w='100%'>
    <XStack space='$1' my='$2' w='100%' flexWrap="wrap">
      <XStack f={1}>
        <XStack mx='auto'>
          <Text my='auto' mr='$2' fontSize={'$1'} fontFamily='$body'>
            {shared ? "Shared by" : 'Not yet shared.'}
          </Text>
          {shared ? <AuthorInfo post={authorData!} /> : undefined}
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