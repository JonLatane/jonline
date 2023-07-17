import { loadPostGroupPosts, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Post, PostContext } from "@jonline/api";
import { Spinner, Text, XStack } from '@jonline/ui';


import { useGroupContext } from "../groups/group_context";
import { GroupsSheet } from '../groups/groups_sheet';

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
  const { primaryAnchorColor } = useServerTheme();
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
      selectedGroup={selectedGroup}
      // onGroupSelected={() => { }}
      disabled={!groupPostData}
      topGroupIds={groupPostData?.map(gp => gp.groupId) ?? []}
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