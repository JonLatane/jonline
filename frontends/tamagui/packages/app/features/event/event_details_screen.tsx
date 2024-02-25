import { EventInstance } from '@jonline/api';
import { AnimatePresence, Button, Heading, Paragraph, ScrollView, Spinner, Tooltip, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, standardHorizontalAnimation, useMedia } from '@jonline/ui';
import { useAppSelector, useFederatedDispatch, useLocalConfiguration, useServer } from 'app/hooks';
import { RootState, federateId, federatedId, getServerTheme, loadEventByInstance, parseFederatedId, selectEventById, selectGroupById, selectPostById, serverID, useRootSelector } from 'app/store';
import { isPastInstance, setDocumentTitle, themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { createParam } from 'solito';
import EventCard from '../event/event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { ConversationContextProvider, ConversationManager, usePostInteractionType, useStatefulConversationContext } from '../post';
import { ReplyArea } from '../post/reply_area';
import { RsvpMode } from './event_rsvp_manager';
import { AccountOrServerContextProvider } from 'app/contexts';
import { ListEnd } from '@tamagui/lucide-icons';

const { useParam, useUpdateParams } = createParam<{ instanceId: string, shortname: string | undefined }>()

// In terms of the web app's URL structure, "/event" corresponds to
// EventInstances, not Events.
export function EventDetailsScreen() {
  const mediaQuery = useMedia();
  const [pathInstanceId] = useParam('instanceId');
  const [shortname] = useParam('shortname');
  const [interactionType, setInteractionType] = usePostInteractionType();
  const updateParams = useUpdateParams();

  const currentServer = useServer();

  const { serverHost, id: serverInstanceId } = parseFederatedId(pathInstanceId ?? '', currentServer?.host);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const server = accountOrServer.server;

  const instanceId = federateId(serverInstanceId, serverHost);

  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor, navAnchorColor } = getServerTheme(accountOrServer.server);
  const app = useLocalConfiguration();
  const groupId = useAppSelector((state) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useAppSelector((state) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const eventsState = useAppSelector((state) => state.events);
  const postsState = useAppSelector((state) => state.posts);

  const eventId = useAppSelector((state) => instanceId
    ? state.events.instanceEvents[instanceId]
    : undefined);
  const subjectEvent = useAppSelector(state => eventId
    ? selectEventById(state.events, eventId)
    : undefined);
  const subjectPost = useAppSelector((state) =>
    selectPostById(state.posts, federateId(subjectEvent?.post?.id ?? '', serverHost)));

  const subjectInstances = subjectEvent?.instances;
  const [subjectInstance, setSubjectInstance] = useState<EventInstance | undefined>(undefined);

  const instancePost = useAppSelector(state => subjectInstance
    ? selectPostById(state.posts, federateId(subjectInstance.post!.id, serverHost))
    : undefined);
  const instancePostId = instancePost?.id;

  // = subjectInstances?.find(i => i.id == instanceId);
  useEffect(() => {
    if (subjectInstances && subjectInstance?.id != instanceId) {
      setSubjectInstance(subjectInstances?.find(i => i.id == serverInstanceId));
    }
  }, [subjectInstances, instanceId]);
  // console.log("EventDetailsScreen.subjectInstance=", subjectInstance?.id, 'instanceId=', instanceId);
  // const postId = subjectPost?.id;
  const [newRsvpMode, setNewRsvpMode] = useState(undefined as RsvpMode);
  const [loadedEvent, setLoadedEvent] = useState(false);
  const [loadingEvent, setLoadingEvent] = useState(false);
  const conversationContext = useStatefulConversationContext();
  const { editingPosts, replyPostIdPath, setReplyPostIdPath, editHandler } = conversationContext;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const showReplyArea = subjectEvent != undefined && editingPosts.length == 0
    && (newRsvpMode === undefined);

  // const failedToLoadEvent = instanceId != undefined &&
  //   eventsState.failedInstanceIds.includes(instanceId!);
  const failedToLoadEvent = instanceId && eventsState.failedInstanceIds.includes(instanceId);

  // console.log("subjectEvent=", subjectEvent, 'failedToLoadEvent=', failedToLoadEvent);

  function onEventInstancesUpdated(instances: EventInstance[]) {
    if (!instances.some(i => i.id === serverInstanceId)) {
      updateParams({
        instanceId: `${instances.find(i => !isPastInstance(i))?.id
          ?? instances[0]!.id}${currentServer?.host === serverHost ? '' : `@${serverHost}`}`
      }, { web: { replace: true } });
    }
  }

  useEffect(() => {
    if (instanceId && serverInstanceId && server) {
      if ((!subjectEvent || !loadedEvent) && !loadingEvent) {
        setLoadingEvent(true);
        // console.log('loadEventByInstance', instanceId!)
        // setTimeout(() =>
        // console.log('loadEventByInstance', { ...accountOrServer, instanceId: serverInstanceId });
        dispatch(loadEventByInstance({ ...accountOrServer, instanceId: serverInstanceId }))
          .then((action) => {
            setTimeout(() => setLoadingEvent(false), 100);
            // setLoadedEvent(true);
          });
        // , 100);
      } else if (((subjectPost && subjectEvent) || failedToLoadEvent) && loadingEvent) {
        setLoadingEvent(false);
        setLoadedEvent(true);
      }
      if (subjectPost && (subjectPost.replyCount == 0 || subjectPost.replies.length > 0) && showScrollPreserver) {
        dismissScrollPreserver(setShowScrollPreserver);
      }
    }
  }, [server ? serverID(server) : undefined, instanceId, subjectPost, postsState, loadingEvent, loadedEvent, replyPostIdPath, showScrollPreserver]);

  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    let title = '';
    if (subjectPost) {
      if (subjectPost.title && subjectPost.title.length > 0) {
        title = subjectPost.title;
      } else {
        title = `Event Instance Details (#${instanceId})`;
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
    setDocumentTitle(title)
  }, [subjectPost?.id, group?.id, server ? serverID(server) : undefined])

  function scrollToBottom() {
    window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
  }
  function scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
  const chatUI = app?.discussionChatUI;

  return (
    <TabsNavigation appSection={AppSection.EVENT} selectedGroup={group}
      primaryEntity={subjectPost ?? { serverHost: serverHost ?? currentServer?.host }}

      topChrome={
        <XStack w='100%' maw={800} mx='auto' mt='$1' ai='center'>
          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'post' ? navColor : undefined)}
                transparent={interactionType !== 'post'} mr='$2'
                onPress={() => {
                  setInteractionType('post');
                  scrollToTop();
                }}>
                <Heading size='$4' color={interactionType == 'post' ? navTextColor : undefined}>Event</Heading>
              </Button>
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>Event Details</Heading>
            </Tooltip.Content>
          </Tooltip>

          {mediaQuery.gtSm
            ? <Paragraph size='$1' fontWeight='bold' my='auto' animation='standard' o={0.8} f={1}>
              {subjectPost?.title || 'Loading...'}
            </Paragraph>
            : <XStack f={1} />}

          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'discussion' ? navColor : undefined)}
                transparent={interactionType !== 'discussion'}
                onPress={() => setInteractionType('discussion')} mr='$2'>
                <Heading size='$4' color={interactionType == 'discussion' ? navTextColor : undefined}>Discussion</Heading>
              </Button>
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>Newest on top.</Heading>
              <Heading size='$1'>Grouped into threads.</Heading>
            </Tooltip.Content>
          </Tooltip>

          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'chat' ? navColor : undefined)}
                transparent={interactionType !== 'chat'}
                borderTopRightRadius={0} borderBottomRightRadius={0}
                onPress={() => setInteractionType('chat')}>
                <Heading size='$4' color={interactionType == 'chat' ? navTextColor : undefined}>Chat</Heading>
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
                opacity={!chatUI ? 0.5 : 1}
                onPress={() => {
                  if (chatUI) {
                    scrollToBottom();
                  } else {
                    setInteractionType('chat');
                    setTimeout(scrollToBottom, 1000);
                  }
                }} />
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>Go to newest.</Heading>
            </Tooltip.Content>
          </Tooltip>
        </XStack>
      }
      bottomChrome={<ReplyArea 
        replyingToPath={replyPostIdPath}
        onStopReplying={() => instancePostId && setReplyPostIdPath([instancePostId])}
        hidden={!showReplyArea} />}
    >
      {!subjectEvent || !subjectPost
        ? failedToLoadEvent
          ? <>
            <Heading size='$5'>Event not found.</Heading>
            <Heading size='$3' ta='center'>It may either not exist, not be visible to you, or be hidden by moderators.</Heading>
          </>
          : <Spinner size='large' color={navColor} scale={2} />
        :
        <AccountOrServerContextProvider value={accountOrServer}>

          <ConversationContextProvider value={conversationContext}>
            <YStack f={1} jc="center" ai="center" mt='$3' space w='100%' maw={800}>
              <ScrollView w='100%'>
                <AnimatePresence>
                  {interactionType === 'post'
                    ? <XStack w='100%' paddingHorizontal='$3'
                      animation='standard' {...standardHorizontalAnimation}>
                      <EventCard key={`event-card-loaded`}
                        event={subjectEvent}
                        onEditingChange={editHandler(subjectPost!.id)}
                        selectedInstance={subjectInstance}
                        onInstancesUpdated={onEventInstancesUpdated}
                        {...{ newRsvpMode, setNewRsvpMode }}
                      />
                    </XStack>
                    : undefined}
                </AnimatePresence>
                <ConversationManager post={instancePost} />
              </ScrollView>


            </YStack>
          </ConversationContextProvider>
        </AccountOrServerContextProvider>
      }
    </TabsNavigation >
  )
}
