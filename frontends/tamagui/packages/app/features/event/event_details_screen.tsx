import { Permission, Event, Post, EventInstance } from '@jonline/api'
import { Button, dismissScrollPreserver, Heading, isClient, isWeb, needsScrollPreservers, ScrollView, Spinner, TextArea, Theme, Tooltip, useWindowDimensions, XStack, YStack, ZStack } from '@jonline/ui'
import { Clock, Edit, Eye, History, ListEnd, Send as SendIcon } from '@tamagui/lucide-icons'
import { confirmReplySent, loadEvent, loadPostReplies, replyToPost, RootState, selectGroupById, selectEventById, setDiscussionChatUI, useCredentialDispatch, useLocalApp, useServerTheme, useTypedSelector } from 'app/store'
import moment, { Moment } from 'moment'
import React, { useEffect, useReducer, useState } from 'react'
import { FlatList, View } from 'react-native'
import StickyBox from 'react-sticky-box'
import { createParam } from 'solito'
import { AddAccountSheet } from '../accounts/add_account_sheet'
import { TabsNavigation } from '../tabs/tabs_navigation'
import EventCard from '../event/event_card'
import { TamaguiMarkdown } from '../post/tamagui_markdown'
import { AppSection } from '../tabs/features_navigation'
import PostCard from '../post/post_card'
import { ReplyArea } from '../post/post_details_screen'
import { InstanceTime } from './instance_time'
import { instanceTimeSort, isNotPastInstance } from 'app/utils/time'

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

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const app = useLocalApp();
  const groupId = useTypedSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useTypedSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const eventsState = useTypedSelector((state: RootState) => state.events);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const subjectEvent = useTypedSelector((state: RootState) => selectEventById(state.events, eventId!));
  const subjectPost = subjectEvent?.post;
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
  const [loadingEvent, setLoadingEvent] = useState(false);
  const [loadingReplies, setLoadingReplies] = useState(false);
  const [collapsedReplies, setCollapsedReplies] = useState(new Set<string>());
  const [expandAnimation, setExpandAnimation] = useState(true);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const showReplyArea = subjectEvent != undefined;
  const [_, forceUpdate] = useReducer((x) => x + 1, 0);
  const { width, height: windowHeight } = useWindowDimensions();
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

  if (chatUI && (app?.autoRefreshDiscussions ?? true)) {
    if (!_nextChatReplyRefresh || moment().isAfter(_nextChatReplyRefresh)) {
      const intervalSeconds = app?.discussionRefreshIntervalSeconds || 6;
      _nextChatReplyRefresh = moment().add(intervalSeconds, 'second');
      const wasAtBottom = isClient && !showScrollPreserver &&
        document.body.scrollHeight - _viewportHeight - window.scrollY < 100;
      const scrollYAtBottom = window.scrollY;
      // console.log('wasAtBottom', wasAtBottom, document.body.scrollHeight, _viewportHeight, window.scrollY)
      setTimeout(() => {
        if (eventId) {
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
  const [replyPostIdPath, setReplyPostIdPath] = useState<string[]>(eventId ? [eventId] : []);

  const failedToLoadEvent = eventId != undefined &&
    eventsState.failedEventIds.includes(eventId!);


  useEffect(() => {
    if (eventId) {
      if ((!subjectEvent || postsState.status == 'unloaded') && postsState.status != 'loading' && !loadingEvent) {
        setLoadingEvent(true);
        // useEffect(() => {
        console.log('loadEvent', eventId!)
        setTimeout(() =>
          dispatch(loadEvent({ ...accountOrServer, id: eventId! })));
        // });
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
    const serverName = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
    let title = '';
    if (subjectPost) {
      if (subjectPost.title && subjectPost.title.length > 0) {
        title = subjectPost.title;
      } else {
        title = `Event Details (#${subjectEvent.id})`;
      }
    } else if (failedToLoadEvent) {
      title = 'Event Not Found';
    } else {
      title = 'Loading Event...';
    }
    title += ` - ${serverName}`;
    if (shortname && shortname.length > 0 && group && group.name.length > 0) {
      title += `- ${group.name}`;
    }
    document.title = title;
  }, [eventId, subjectPost, postsState, loadingEvent, loadingReplies, replyPostIdPath, showScrollPreserver]);

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
  useEffect(() => {
    if (subjectPost) {
      flattenReplies(subjectPost, [subjectEvent.id]);
    }
  }, [subjectPost]);

  useEffect(() => {
    if (chatUI) {
      flattenedReplies.sort((a, b) => a.reply.createdAt!.localeCompare(b.reply.createdAt!));
    }
  }, [chatUI]);

  const [showPastInstances, setShowPastInstances] = useState(false);
  const displayedInstances = subjectInstances
    ? (showPastInstances
      ? subjectInstances
      : subjectInstances
        .filter(isNotPastInstance)
    ).sort(instanceTimeSort)
    : undefined;

  let logicallyReplyingTo: Post | undefined = undefined;
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
              {subjectEvent ? <EventCard event={subjectEvent} selectedInstance={subjectInstance} /> : undefined}
            </XStack>
            <XStack w='100%' ml='$4' space>
              <Theme inverse={showPastInstances}>
                <Button mt='$2' mr={-7} size='$3' circular icon={History}
                  // backgroundColor={showPastInstances ? undefined : navColor} 
                  onPress={() => setShowPastInstances(!showPastInstances)} />
              </Theme>
              <ScrollView f={1} horizontal pb='$3'>
                <XStack mt='$1'>
                  {displayedInstances?.map((instance) =>
                    <InstanceTime key={instance.id} linkToInstance
                      event={subjectEvent} instance={instance}
                      highlight={instance.id == subjectInstance?.id}
                    />)}
                </XStack>

              </ScrollView>
            </XStack>
            <XStack>
              <XStack f={1} />
              <Tooltip placement="bottom">
                <Tooltip.Trigger>
                  <Button backgroundColor={chatUI ? undefined : navColor} transparent={chatUI} onPress={() => dispatch(setDiscussionChatUI(false))} mr='$2'>
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
                  <Button backgroundColor={!chatUI ? undefined : navColor}
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
            <XStack w='100%'>
              <YStack w='100%'>
                {flattenedReplies.map(({ reply, postIdPath, parentPost: parentEvent, lastReplyTo }) => {
                  let stripeColor = navColor;
                  const lastReplyToIndex = lastReplyTo ? postIdPath.indexOf(lastReplyTo!) : undefined;
                  const showParentPreview = chatUI && parentEvent?.id != subjectEvent?.id
                    && parentEvent?.id != logicallyReplyingTo?.id
                    && parentEvent?.id != logicallyReplyingTo?.replyToPostId;
                  const hideTopMargin = chatUI && parentEvent?.id != subjectEvent?.id && (parentEvent?.id == logicallyReplyingTo?.id || parentEvent?.id == logicallyReplyingTo?.replyToPostId);
                  const result = <XStack key={`reply-${reply.id}`} id={`reply-${reply.id}`}
                    // w='100%' f={1}
                    mt={(chatUI && !hideTopMargin) || (!chatUI && parentEvent?.id == subjectEvent?.id) ? '$3' : 0}
                    animation="bouncy"
                    opacity={1}
                    scale={1}
                    y={0}
                    enterStyle={{
                      // scale: 1.5,
                      y: expandAnimation ? -50 : 50,
                      opacity: 0,
                    }}
                    exitStyle={{
                      // scale: 1.5,
                      // y: 50,
                      opacity: 0,
                    }}
                  >
                    {postIdPath.slice(1).map(() => {
                      stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                      return <YStack w={7} bg={stripeColor} />
                    })}
                    {/* {lastReplyToIndex == undefined && lastReplyToIndex != 0 ?
                  postIdPath.slice(1).map(() => {
                    stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                    return <YStack w={7} bg={stripeColor} />
                  })
                  : postIdPath.slice(1, lastReplyToIndex).map(() => {
                    stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                    return <YStack w={7} bg={stripeColor} />
                  })} */}
                    <XStack f={1}
                    // mb={lastReplyToIndex != undefined ? '$3' : 0}
                    >
                      {/* {lastReplyToIndex != undefined
                    ? postIdPath.slice(Math.max(1,lastReplyToIndex)).map(() => {
                      stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                      return <YStack w={7} bg={stripeColor} />
                    })
                    : undefined} */}
                      <PostCard key={`comment-event-${reply.id}`} post={reply} replyPostIdPath={postIdPath}
                        selectedPostId={replyPostIdPath[replyPostIdPath.length - 1]}
                        collapseReplies={collapsedReplies.has(reply.id)}
                        previewParent={showParentPreview ? parentEvent : undefined}
                        onLoadReplies={() => setExpandAnimation(true)}
                        toggleCollapseReplies={() => {
                          setExpandAnimation(collapsedReplies.has(reply.id));
                          toggleCollapseReplies(reply.id);
                        }}
                        onPress={() => {
                          if (replyPostIdPath[replyPostIdPath.length - 1] == postIdPath[postIdPath.length - 1]) {
                            setReplyPostIdPath([eventId!]);
                          } else {
                            setReplyPostIdPath(postIdPath);
                          }
                        }}
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
                  logicallyReplyingTo = reply;
                  return result;
                })}
                <YStack h={showScrollPreserver ? 100000 : chatUI ? 0 : 150} ></YStack>
              </YStack>

            </XStack>
          </ScrollView>
          {showReplyArea ?
            <ReplyArea replyingToPath={replyPostIdPath} />
            : undefined}

        </YStack>
      }
    </TabsNavigation >
  )
}
