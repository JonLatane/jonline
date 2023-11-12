import { deleteEvent, deletePost, loadMedia, loadUser, RootState, selectMediaById, selectUserById, updateEvent, updatePost, useAccount, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { Platform, View } from "react-native";
import { useIsVisible } from 'app/hooks/use_is_visible';

import { Event, EventAttendance, EventInstance, Group, Media, Visibility } from "@jonline/api";
import { Anchor, Text, Button, Card, Heading, Image, Paragraph, ScrollView, createFadeAnimation, TamaguiElement, Theme, useMedia, XStack, YStack, Dialog, TextArea, Input, useWindowDimensions, Select, getFontSize, Sheet, Adapt } from "@jonline/ui";
import { useMediaUrl } from "app/hooks/use_media_url";
import moment from "moment";
import { useLink } from "solito/link";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { InstanceTime } from "./instance_time";
import { instanceTimeSort, isNotPastInstance, isPastInstance } from "app/utils/time";
import { Repeat, Delete, Edit, Eye, History, Save, CalendarPlus, X as XIcon, Link, Check, ChevronDown, ChevronUp } from "@tamagui/lucide-icons";
import icons from "@tamagui/lucide-icons";
import { GroupPostManager } from "../groups/group_post_manager";
import { FacebookEmbed, InstagramEmbed, LinkedInEmbed, PinterestEmbed, TikTokEmbed, TwitterEmbed, YouTubeEmbed } from "react-social-media-embed";
import { MediaRenderer } from "../media/media_renderer";
import { FadeInView } from "../../components/fade_in_view";
import { postBackgroundSize } from "../post/post_card";
import { defaultEventInstance, supportDateInput, toProtoISOString } from "./create_event_sheet";
import { LinearGradient } from '@tamagui/linear-gradient';
import { PostMediaManager } from "../post/post_media_manager";
import { PostMediaRenderer } from "../post/post_media_renderer";
import { VisibilityPicker } from "../../components/visibility_picker";
import { postVisibilityDescription } from "../post/base_create_post_sheet";
import { useEditableState, useStatefulEditingContext } from "app/components/save_button_group";

interface Props {
  event: Event;
  eventInstance: EventInstance;
  attendance: EventAttendance;
  onEditingChange?: (editing: boolean) => void;
}

let newEventId = 0;

export const RsvpCard: React.FC<Props> = ({
  event,
  eventInstance,
  attendance,
  onEditingChange,
}) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const mediaQuery = useMedia();
  const currentUser = useAccount()?.user;
  const post = event.post!;

  const editingContext = useStatefulEditingContext(false);

  const { server, textColor, primaryColor, navAnchorColor: navColor, backgroundColor: themeBgColor, primaryAnchorColor, navAnchorColor } = useServerTheme();

  const [anonName, editedAnonName, setEditedAnonName] = useEditableState(attendance.anonymousAttendee?.name ?? '', editingContext);
  const [publicNote, editedPublicNote, setEditedPublicNote] = useEditableState(attendance.publicNote ?? '', editingContext);
  const [privateNote, editedPrivateNote, setEditedPrivateNote] = useEditableState(attendance.privateNote ?? '', editingContext);
  const [numberOfGuests, editedNumberOfGuests, setEditedNumberOfGuests] = useEditableState(attendance.numberOfGuests ?? 1, editingContext);

  return <Card theme="dark" elevate size="$4" bordered
    key='event-card'
    margin='$0'
    marginBottom='$3'
    marginTop='$3'
    // f={isPreview ? undefined : 1}
    // ref={ref!}
    scale={1}
    opacity={1}
    y={0}
  >
    {post.link || post.title
      ? <Card.Header>

      </Card.Header>
      : undefined}
    <Card.Footer p='$3' pr={mediaQuery.gtXs ? '$3' : '$1'} >

    </Card.Footer>
  </Card >;
};

export default RsvpCard;
