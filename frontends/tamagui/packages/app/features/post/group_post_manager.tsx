import { createGroupPost, deleteGroupPost, loadPostGroupPosts, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Permission, Post, PostContext } from "@jonline/api";
import { Button, Separator, Spinner, Text, XStack, YStack } from '@jonline/ui';


import { useGroupContext } from "../groups/group_context";
import { GroupsSheet } from '../groups/groups_sheet';
import { AuthorInfo } from "./author_info";
import { hasAdminPermission, hasPermission } from '../../utils/permissions';
import { themedButtonBackground } from "app/utils/themed_button_background";

interface Props {
  post: Post;
  onScreen?: boolean;
}

export const GroupPostManager: React.FC<Props> = ({ post, onScreen = true }) => {
  // const disabled = false;
  function onValueSelected(v: string) {
    // const selectedVisibility = parseInt(v) as Visibility;
    // onChange(selectedVisibility)
  }
  const { navColor, navTextColor, primaryAnchorColor } = useServerTheme();
  const title = `Group ${post.context == PostContext.EVENT ? 'Event' : 'Post'} Sharing`;
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const selectedGroup = useGroupContext();
  const [loading, setLoading] = useState(false);
  const groupPostData = useTypedSelector((state: RootState) => state.groups.postIdGroupPosts[post.id]);

  const maxErrors = 3;
  const [errorCount, setErrorCount] = useState(0);
  useEffect(() => {
    if (onScreen && !groupPostData && !loading && errorCount < maxErrors) {
      dispatch(loadPostGroupPosts({ ...accountOrServer, postId: post.id }))
        .then(() => setLoading(false))
        .catch(() => { setLoading(false); setErrorCount(errorCount + 1); });
      setLoading(true);
    }
  }, [post, onScreen, loading, errorCount]);

  const [loadingGroups, setLoadingGroups] = useState([] as string[]);
  function shareToGroup(groupId: string) {
    dispatch(createGroupPost({ ...accountOrServer, postId: post.id, groupId }))
      .then(() => setLoadingGroups(loadingGroups.filter(g => g != groupId)));
    setLoadingGroups([...loadingGroups, groupId]);
  }
  function unshareToGroup(groupId: string) {
    dispatch(deleteGroupPost({ ...accountOrServer, postId: post.id, groupId }))
      .then(() => setLoadingGroups(loadingGroups.filter(g => g != groupId)));
    setLoadingGroups([...loadingGroups, groupId]);
  }

  // This is undefined if data isn't loaded, true if shared, false if not shared.
  const sharedToSelectedGroup = selectedGroup && groupPostData?.some(gp => gp.groupId == selectedGroup?.id);
  const otherGroupCount = groupPostData
    ? groupPostData.length - (sharedToSelectedGroup ? 1 : 0)
    : undefined;
  // return <></>;

  return <XStack>
    {!selectedGroup && otherGroupCount
      ?
      <Text my='auto' ml='$2' fontSize={'$1'} fontFamily='$body'>
        Shared to {otherGroupCount} group{otherGroupCount > 1 ? 's' : undefined}.
      </Text>
      : undefined}
    <Text my='auto' mr='$2' fontSize={'$1'} fontFamily='$body'>
      {sharedToSelectedGroup === true ? 'Shared to ' : undefined}
      {sharedToSelectedGroup === false ? 'Not yet shared to ' : undefined}
    </Text>
    {loading && errorCount < maxErrors ? <Spinner my='auto' mx='$2' color={primaryAnchorColor} size='small' /> : undefined}
    <GroupsSheet
      title={title}
      itemTitle={post.title}
      selectedGroup={selectedGroup}
      // onGroupSelected={() => { }}
      disabled={!groupPostData}
      topGroupIds={groupPostData?.map(gp => gp.groupId) ?? []}
      extraListComponents={(group) => {
        const groupPost = groupPostData?.find(gp => gp.groupId == group.id);
        const shared = groupPost != undefined;
        const authorData = groupPost ? Post.fromPartial({
          createdAt: groupPost.createdAt,
          author: {
            userId: groupPost.userId,
          }
        }) : undefined;
        const canShare = !shared && hasPermission(group.currentUserMembership, Permission.CREATE_POSTS);
        const canUnshare = shared && (groupPost.userId === accountOrServer.account?.user?.id || hasAdminPermission(accountOrServer.account?.user) || hasAdminPermission(group.currentUserMembership));
        return <YStack>
          <XStack space='$2' mb='$2'>
            <XStack f={1}>
              <XStack mx='auto'>
                <Text my='auto' mr='$2' fontSize={'$1'} fontFamily='$body'>
                  {shared ? "Shared by" : 'Not yet shared.'}
                </Text>
                {shared ? <AuthorInfo post={authorData!} /> : undefined}
              </XStack>
            </XStack>
            {accountOrServer.account && shared != undefined ?
              canShare
                ? <Button
                  {...themedButtonBackground(navColor, navTextColor)}
                  disabled={loadingGroups.includes(group.id)}
                  o={loadingGroups.includes(group.id) ? 0.5 : 1}
                  onPress={() => shareToGroup(group.id)}>
                  Share
                </Button>
                : canUnshare
                  ? <Button
                    disabled={loadingGroups.includes(group.id)}
                    o={loadingGroups.includes(group.id) ? 0.5 : 1}
                    onPress={() => unshareToGroup(group.id)}>
                    Unshare
                  </Button>
                  : undefined
              : undefined}
          </XStack>
          <Separator />
        </YStack>;
      }}
      disableSelection
      hideInfoButtons
      delayRenderingSheet
    />
    {selectedGroup
      ? otherGroupCount
        ? <Text my='auto' ml='$2' fontSize={'$1'} fontFamily='$body'>
          {sharedToSelectedGroup === true ? ' and ' : undefined}
          {sharedToSelectedGroup === false ? '. Shared to ' : undefined}
          {otherGroupCount} other group{otherGroupCount > 1 ? 's' : undefined}.
        </Text>
        : '.'
      : undefined}
    {/* {onScreen ? "hi!" : undefined} */}
  </XStack>;
}