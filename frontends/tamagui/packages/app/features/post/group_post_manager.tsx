import { colorMeta, loadMedia, loadPostGroupPosts, loadPostReplies, loadUser, RootState, selectMediaById, selectUserById, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { GestureResponderEvent, Platform, View } from "react-native";

import { Group, GroupPost, Media, Post } from "@jonline/api";
import { Adapt, Anchor, Button, Card, Heading, Image, ScrollView, Select, Sheet, Text, Theme, useMedia, useTheme, XStack, YStack } from '@jonline/ui';
import { ChevronDown, ChevronRight, ChevronUp } from "@tamagui/lucide-icons";
import { LinearGradient } from "@tamagui/linear-gradient";

import { useMediaUrl } from "app/hooks/use_media_url";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from 'react-social-media-embed';
import { useLink } from "solito/link";
import { AuthorInfo } from "./author_info";
import { TamaguiMarkdown } from "./tamagui_markdown";

import { MediaRenderer } from "../media/media_renderer";
import { GroupsSheet } from '../groups/groups_sheet';
import { useGroupContext } from "../groups/group_context";

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

  useEffect(() => {
    if (!groupPostData && !loading) {
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