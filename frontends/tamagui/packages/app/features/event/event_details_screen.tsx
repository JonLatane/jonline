import { EventInstance, Permission, Post } from '@jonline/api'
import { Button, Heading, ScrollView, Spinner, Tooltip, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, useWindowDimensions } from '@jonline/ui'
import { ListEnd, Plus } from '@tamagui/lucide-icons'
import { RootState, loadEvent, loadPostReplies, selectEventById, selectGroupById, selectPostById, setDiscussionChatUI, useCredentialDispatch, useLocalApp, useServerTheme, useTypedSelector } from 'app/store'
import moment, { Moment } from 'moment'
import React, { useEffect, useReducer, useState } from 'react'
import { createParam } from 'solito'
import EventCard from '../event/event_card'
import PostCard from '../post/post_card'
import { ReplyArea } from '../post/reply_area'
import { AppSection } from '../tabs/features_navigation'
import { TabsNavigation } from '../tabs/tabs_navigation'
import { hasPermission } from 'app/utils/permission_utils'
import { EventRsvpManager, RsvpMode } from './event_rsvp_manager'
import { themedButtonBackground } from 'app/utils/themed_button_background'

const { useParam } = createParam<{ eventId: string, instanceId: string, shortname: string | undefined }>()

let _nextChatReplyRefresh: Moment | undefined = undefined;
let _replyTextFocused = false;
let _viewportHeight = 0;
if (isClient) {
  visualViewport?.addEventListener('resize', (event) => {
    if (!event.target) return;

    const viewport: VisualViewport = event.target as VisualViewport;
    _viewportHeight = viewport.height ?? 0;
  });
}

export function EventDetailsScreen() {
  const [eventId] = useParam('eventId');
  const [instanceId] = useParam('instanceId');
  const [shortname] = useParam('shortname');

  const { server, primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor, navAnchorColor } = useServerTheme();
  const app = useLocalApp();
  const groupId = useTypedSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useTypedSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const eventsState = useTypedSelector((state: RootState) => state.events);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const subjectEvent = useTypedSelector((state: RootState) => selectEventById(state.events, eventId!));
  const subjectPost = useTypedSelector((state: RootState) => selectPostById(state.posts, subjectEvent?.post?.id ?? ''));
  // const subjectPost = subjectEvent?.post;
  const subjectInstances = subjectEvent?.instances;
  const [subjectInstance, setSubjectInstance] = useState<EventInstance | undefined>(undefined);
  // = subjectInstances?.find(i => i.id == instanceId);
  useEffect(() => {
    if (subjectInstances && subjectInstance?.id != instanceId) {
      setSubjectInstance(subjectInstances?.find(i => i.id == instanceId));
    }
  }, [subjectInstances, instanceId]);
  // console.log("EventDetailsScreen.subjectInstance=", subjectInstance?.id, 'instanceId=', instanceId);
  // const postId = subjectPost?.id;
  const [newRsvpMode, setNewRsvpMode] = useState(undefined as RsvpMode);
  const [loadedEvent, setLoadedEvent] = useState(false);
  const [loadingEvent, setLoadingEvent] = useState(false);
  const [loadingReplies, setLoadingReplies] = useState(false);
  const [collapsedReplies, setCollapsedReplies] = useState(new Set<string>());
  const [expandAnimation, setExpandAnimation] = useState(true);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const [_, forceUpdate] = useReducer((x) => x + 1, 0);
  const { width, height: windowHeight } = useWindowDimensions();

  const [editingPosts, setEditingPosts] = useState([] as string[]);
  const editHandler = (postId: string) => ((editing: boolean) => {
    if (editing) {
      setEditingPosts([...editingPosts, postId]);
    } else {
      setEditingPosts(editingPosts.filter(p => p != postId));
    }
  });

  const showReplyArea = subjectEvent != undefined && editingPosts.length == 0
    && (newRsvpMode === undefined);

  function scrollToBottom() {
    if (!isClient) return;
    if (_replyTextFocused && windowHeight > 0) {
      window.scrollTo({ top: document.body.scrollHeight - _viewportHeight, behavior: 'smooth' });
    } else {
      window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
    }
  }
  function scrollToTop() {
    if (!isClient) return;

    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  const [hasLoadedReplies, setHasLoadedReplies] = useState(false);
  useEffect(() => {
    if (chatUI && (app?.autoRefreshDiscussions ?? true)) {
      if (!_nextChatReplyRefresh || moment().isAfter(_nextChatReplyRefresh)) {
        const intervalSeconds = app?.discussionRefreshIntervalSeconds ?? 6;
        if (!hasLoadedReplies) setHasLoadedReplies(true);
        _nextChatReplyRefresh = moment().add(intervalSeconds, 'second');
        const wasAtBottom = isClient && !showScrollPreserver &&
          document.body.scrollHeight - _viewportHeight - window.scrollY < 100;
        const scrollYAtBottom = window.scrollY;
        // console.log('wasAtBottom', wasAtBottom, document.body.scrollHeight, _viewportHeight, window.scrollY)
        setTimeout(() => {
          if (subjectPost) {
            dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [subjectPost!.id] })).then(() => {
              if (wasAtBottom && chatUI && (Math.abs(scrollYAtBottom - window.scrollY) < 10)) {
                scrollToBottom();
              }
              // forceUpdate();
              setTimeout(() => {
                forceUpdate();
              }, intervalSeconds * 1000);
            });
          } else {
            setTimeout(() => {
              forceUpdate();
            }, intervalSeconds * 1000);
          }
        }, 1);
        // if (wasAtBottom) {
        //   setTimeout(() => {
        //     if (chatUI && (Math.abs(scrollYAtBottom - window.scrollY) < 10)) {
        //       scrollToBottom();
        //     }
        //   }, 1000);
        // }
        // _nextChatReplyRefresh = moment().add(intervalSeconds, 'second');
        // setTimeout(() => {
        //   forceUpdate();
        // }, intervalSeconds * 1000);
      }
    }
  }, [chatUI && (app?.autoRefreshDiscussions ?? true), !_nextChatReplyRefresh || moment().isAfter(_nextChatReplyRefresh)]);
  const [replyPostIdPath, setReplyPostIdPath] = useState<string[]>(subjectPost ? [subjectPost.id] : []);

  const failedToLoadEvent = eventId != undefined &&
    eventsState.failedEventIds.includes(eventId!);


  useEffect(() => {
    if (eventId) {
      if ((!subjectEvent || !loadedEvent || postsState.status == 'unloaded') && postsState.status != 'loading' && !loadingEvent) {
        setLoadingEvent(true);
        // useEffect(() => {
        console.log('loadEvent', eventId!)
        setTimeout(() =>
          dispatch(loadEvent({ ...accountOrServer, id: eventId! }))
            .then(() => setLoadedEvent(true)));
      } else if (subjectPost && loadingEvent) {
        setLoadingEvent(false);
      }
      if (subjectPost && postsState.status != 'loading' && subjectPost.replyCount > 0 &&
        subjectPost.replies.length == 0 && !loadingReplies) {
        const postId = subjectPost.id;
        if (replyPostIdPath.length == 0) {
          setReplyPostIdPath([postId]);
        }
        setLoadingReplies(true);
        console.log('loadReplies', subjectPost.id, subjectPost.replyCount, subjectPost.replies.length, loadingReplies);
        setTimeout(() =>
          dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [postId!] })), 1);
      } else if (!subjectPost && loadingReplies) {
        setLoadingReplies(false);
      }
      if (subjectPost && (subjectPost.replyCount == 0 || subjectPost.replies.length > 0) && showScrollPreserver) {
        dismissScrollPreserver(setShowScrollPreserver);
      }
    }
  }, [eventId, subjectPost, postsState, loadingEvent, loadedEvent, loadingReplies, replyPostIdPath, showScrollPreserver]);

  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
    let title = '';
    if (subjectPost) {
      if (subjectPost.title && subjectPost.title.length > 0) {
        title = subjectPost.title;
      } else {
        title = `Event Details (#${subjectEvent!.id})`;
      }
    } else if (failedToLoadEvent) {
      title = 'Event Not Found';
    } else {
      title = 'Loading Event...';
    }
    title += ` - Event - ${serverName}`;
    if (shortname && shortname.length > 0 && group && group.name.length > 0) {
      title += `- ${group.name}`;
    }
    document.title = title;

  }, [subjectPost, group])

  function toggleCollapseReplies(eventId: string) {
    if (collapsedReplies.has(eventId)) {
      collapsedReplies.delete(eventId);
    } else {
      collapsedReplies.add(eventId);
    }
    setCollapsedReplies(new Set(collapsedReplies));
  }

  type FlattenedReply = {
    postIdPath: string[];
    reply: Post;
    parentPost?: Post;
    lastReplyTo?: string;
  }

  const flattenedReplies: FlattenedReply[] = [];
  function flattenReplies(reply: Post, postIdPath: string[], includeSelf: boolean = false, parentPost?: Post,
    lastReplyTo?: string, isLastReply?: boolean) {
    if (includeSelf) {
      flattenedReplies.push({
        reply, postIdPath, parentPost,
        lastReplyTo: isLastReply && (collapsedReplies.has(reply.id) || reply.replyCount == 0 || reply.replies.length == 0)
          ? lastReplyTo : undefined,
      });
    }
    if (collapsedReplies.has(reply.id)) return;

    for (const [index, child] of reply.replies.entries()) {
      const isChildLastReply = (index == reply.replies.length - 1 && includeSelf)
        || (!includeSelf && collapsedReplies.has(child.id) || child.replyCount == 0 || (child.replies ?? []).length == 0);
      const childIsLastReplyTo = isChildLastReply ? lastReplyTo ?? reply.id : undefined;
      flattenReplies(child, postIdPath.concat(child.id), true, reply, childIsLastReplyTo, isChildLastReply);
    }
  }
  // useEffect(() => {
  if (subjectPost && subjectEvent) {
    flattenReplies(subjectPost, [subjectPost!.id]);
  }
  // });
  if (chatUI) {
    flattenedReplies.sort((a, b) => a.reply.createdAt!.localeCompare(b.reply.createdAt!));
  }

  let replyAboveCurrent: Post | undefined = undefined;

  // const showRsvpSection = subjectEvent?.info?.allowsRsvps &&
  //   (subjectEvent?.info?.allowsAnonymousRsvps || hasPermission(accountOrServer?.account?.user, Permission.RSVP_TO_EVENTS));

  return (
    <TabsNavigation appSection={AppSection.EVENT} selectedGroup={group}>
      {!subjectEvent
        ? failedToLoadEvent
          ? <>
            <Heading size='$5'>Event not found.</Heading>
            <Heading size='$3' ta='center'>It may either not exist, not be visible to you, or be hidden by moderators.</Heading>
          </>
          : <Spinner size='large' color={navColor} scale={2} />
        : <YStack f={1} jc="center" ai="center" mt='$3' space w='100%' maw={800}>

          <ScrollView w='100%'>
            <XStack w='100%' paddingHorizontal='$3'>
              {subjectEvent
                ? <EventCard event={subjectEvent} key={`event-card-loaded-${loadedEvent}`}
                  onEditingChange={subjectPost ? editHandler(subjectPost.id) : undefined}
                  selectedInstance={subjectInstance} />
                : undefined}
            </XStack>

            <EventRsvpManager key={`rsvp-manager-${subjectInstance?.id}`}
              event={subjectEvent!} instance={subjectInstance!} {...{ newRsvpMode, setNewRsvpMode }} />

            <XStack>
              <XStack f={1} />
              <Tooltip placement="bottom">
                <Tooltip.Trigger>
                  <Button {...themedButtonBackground(chatUI ? undefined : navColor)} transparent={chatUI} onPress={() => dispatch(setDiscussionChatUI(false))} mr='$2'>
                    <Heading size='$4' color={chatUI ? undefined : navTextColor}>Discussion</Heading>
                  </Button>
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>Newest on top.</Heading>
                  <Heading size='$1'>Grouped into threads.</Heading>
                </Tooltip.Content>
              </Tooltip>

              <Tooltip placement="bottom">
                <Tooltip.Trigger>
                  <Button {...themedButtonBackground(!chatUI ? undefined : navColor)}
                    transparent={!chatUI}
                    borderTopRightRadius={0} borderBottomRightRadius={0}
                    onPress={() => dispatch(setDiscussionChatUI(true))}>
                    <Heading size='$4' color={!chatUI ? undefined : navTextColor}>Chat</Heading>
                  </Button>
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>Newest on bottom.</Heading>
                  <Heading size='$1'>Sorted by time.</Heading>
                </Tooltip.Content>
              </Tooltip>
              <Tooltip placement="bottom-end">
                <Tooltip.Trigger>
                  <Button transparent={!chatUI} icon={ListEnd}
                    borderTopLeftRadius={0} borderBottomLeftRadius={0}
                    opacity={!chatUI || showScrollPreserver ? 0.5 : 1}
                    onPress={() => {
                      if (chatUI) {
                        scrollToBottom();
                      } else {
                        dispatch(setDiscussionChatUI(true))
                      }
                    }} />
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>Go to newest.</Heading>
                </Tooltip.Content>
              </Tooltip>
              <XStack f={1} />
            </XStack>
            <YStack w='100%' key='comments'>
              {flattenedReplies.map(({ reply, postIdPath, parentPost, lastReplyTo }) => {
                let stripeColor = navColor;
                const lastReplyToIndex = lastReplyTo ? postIdPath.indexOf(lastReplyTo!) : undefined;
                const showParentPreview = chatUI && parentPost?.id != subjectEvent?.id
                  && parentPost?.id != replyAboveCurrent?.id
                  && parentPost?.id != replyAboveCurrent?.replyToPostId;
                const hideTopMargin = chatUI && parentPost?.id != subjectEvent?.id
                  && (parentPost?.id == replyAboveCurrent?.id
                    || parentPost?.id == replyAboveCurrent?.replyToPostId);
                const result = <XStack key={`reply-${reply.id}`} id={`reply-${reply.id}`}
                  // w='100%' f={1}
                  mt={(chatUI && !hideTopMargin) || (!chatUI && parentPost?.id == subjectEvent?.id) ? '$3' : 0}
                  animation='standard'
                  opacity={1}
                  scale={1}
                  y={0}
                  enterStyle={{
                    // scale: 1.5,
                    y: expandAnimation ? -50 : 50,
                    opacity: 0,
                  }}
                  exitStyle={{
                    opacity: 0,
                  }}
                >
                  {postIdPath.slice(1).map((_, index) => {
                    stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                    return <YStack key={`stripes-index-${index}`} w={7} bg={stripeColor} />
                  })}
                  <XStack key={`comment-postid-${reply.id}-container`} f={1}>
                    <PostCard key={`comment-postid-${reply.id}`} post={reply} replyPostIdPath={postIdPath}
                      selectedPostId={replyPostIdPath[replyPostIdPath.length - 1]}
                      collapseReplies={collapsedReplies.has(reply.id)}
                      previewParent={showParentPreview && parentPost?.id != subjectPost?.id ? parentPost : undefined}
                      onLoadReplies={() => setExpandAnimation(true)}
                      toggleCollapseReplies={() => {
                        setExpandAnimation(collapsedReplies.has(reply.id));
                        toggleCollapseReplies(reply.id);
                      }}
                      onPressReply={() => {
                        if (replyPostIdPath[replyPostIdPath.length - 1] == postIdPath[postIdPath.length - 1]) {
                          setReplyPostIdPath([eventId!]);
                        } else {
                          setReplyPostIdPath(postIdPath);
                        }
                      }}
                      onEditingChange={editHandler(reply.id)}
                      onPressParentPreview={() => {
                        const parentEventIdPath = postIdPath.slice(0, -1);
                        if (replyPostIdPath[replyPostIdPath.length - 1] == parentEventIdPath[parentEventIdPath.length - 1]) {
                          setReplyPostIdPath([eventId!]);
                        } else {
                          setReplyPostIdPath(parentEventIdPath);
                        }
                      }}
                    // onPressParentPreview={() => setReplyEventIdPath(postIdPath.slice(0, -1))}
                    />
                  </XStack>
                </XStack>;
                replyAboveCurrent = reply;
                return result;
              })}
              <YStack key='scroll-preserver' h={showScrollPreserver ? 100000 : chatUI ? 0 : 150} ></YStack>
            </YStack>
          </ScrollView>
          {showReplyArea ?
            <ReplyArea replyingToPath={replyPostIdPath} />
            : undefined}

        </YStack>
      }
    </TabsNavigation >
  )
}
