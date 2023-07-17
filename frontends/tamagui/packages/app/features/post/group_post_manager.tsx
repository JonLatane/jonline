import { loadPostGroupPosts, RootState, useCredentialDispatch, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Post } from "@jonline/api";
import { Text, XStack } from '@jonline/ui';


import { useIsVisible } from '../../hooks/use_is_visible';
import { useGroupContext } from "../groups/group_context";
import { GroupsSheet } from '../groups/groups_sheet';

interface Props {
  post: Post;
}

export const GroupPostManager: React.FC<Props> = ({ post }) => {
  // const disabled = false;
  function onValueSelected(v: string) {
    // const selectedVisibility = parseInt(v) as Visibility;
    // onChange(selectedVisibility)
  }
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const selectedGroup = useGroupContext();
  const [loading, setLoading] = useState(false);
  const groupPostData = useTypedSelector((state: RootState) => state.groups.postIdGroupPosts[post.id]);
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;

  const onScreen = useIsVisible(ref);

  useEffect(() => {
    if (onScreen && !groupPostData && !loading) {
      setLoading(true);
      dispatch(loadPostGroupPosts({ ...accountOrServer, postId: post.id }))
        .then(() => setLoading(false));
    }
  }, [post]);

  // This is undefined if data isn't loaded, true if shared, false if not shared.
  const sharedToSelectedGroup = selectedGroup && groupPostData?.some(gp => gp.groupId == selectedGroup?.id);
  const otherGroupCount = groupPostData
    ? groupPostData.length - (sharedToSelectedGroup ? 1 : 0)
    : undefined;

  return <XStack ref={ref}>
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
    <GroupsSheet
      title="Group Sharing"
      selectedGroup={selectedGroup}
      // onGroupSelected={() => { }}
      topGroupIds={groupPostData?.map(gp => gp.groupId) ?? []}
      disableSelection
      hideInfoButtons
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
  </XStack>;
}