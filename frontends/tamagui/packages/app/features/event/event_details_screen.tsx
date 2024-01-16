import { EventInstance } from '@jonline/api';
import { Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui';
import { useFederatedDispatch, useLocalConfiguration, useServer } from 'app/hooks';
import { RootState, federateId, getServerTheme, loadEventByInstance, parseFederatedId, selectEventById, selectGroupById, selectPostById, serverID, useRootSelector } from 'app/store';
import { isPastInstance, setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { createParam } from 'solito';
import EventCard from '../event/event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { ConversationContextProvider, ConversationManager, useStatefulConversationContext } from '../post';
import { ReplyArea } from '../post/reply_area';
import { RsvpMode } from './event_rsvp_manager';
import { AccountOrServerContextProvider } from 'app/contexts';

const { useParam, useUpdateParams } = createParam<{ instanceId: string, shortname: string | undefined }>()

// In terms of the web app's URL structure, "/event" corresponds to
// EventInstances, not Events.
export function EventDetailsScreen() {
  const [pathInstanceId] = useParam('instanceId');
  const [shortname] = useParam('shortname');
  const updateParams = useUpdateParams();

  const currentServer = useServer();

  const { serverHost, id: serverInstanceId } = parseFederatedId(pathInstanceId ?? '', currentServer?.host);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const server = accountOrServer.server;

  const instanceId = federateId(serverInstanceId, serverHost);

  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor, navAnchorColor } = getServerTheme(accountOrServer.server);
  const app = useLocalConfiguration();
  const groupId = useRootSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useRootSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const eventsState = useRootSelector((state: RootState) => state.events);
  const postsState = useRootSelector((state: RootState) => state.posts);

  const eventId = useRootSelector((state: RootState) => instanceId
    ? state.events.instanceEvents[instanceId]
    : undefined);
  const subjectEvent = useRootSelector((state: RootState) => eventId
    ? selectEventById(state.events, eventId)
    : undefined);
  const subjectPost = useRootSelector((state: RootState) =>
    selectPostById(state.posts, federateId(subjectEvent?.post?.id ?? '', serverHost)));

  const postId = subjectPost?.id;

  const subjectInstances = subjectEvent?.instances;
  const [subjectInstance, setSubjectInstance] = useState<EventInstance | undefined>(undefined);
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
    if (!instances.some(i => i.id == instanceId)) {
      updateParams({
        instanceId: instances.find(i => !isPastInstance(i))?.id
          ?? instances[0]!.id
      }, { web: { replace: true } });
    }
  }

  useEffect(() => {
    if (instanceId && serverInstanceId && server) {
      if ((!subjectEvent || !loadedEvent) && !loadingEvent) {
        setLoadingEvent(true);
        // console.log('loadEventByInstance', instanceId!)
        // setTimeout(() =>
        console.log('loadEventByInstance', { ...accountOrServer, instanceId: serverInstanceId });
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

  return (
    <TabsNavigation appSection={AppSection.EVENT} selectedGroup={group}
      primaryEntity={subjectPost ?? { serverHost: serverHost ?? currentServer?.host }}
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
                <XStack w='100%' paddingHorizontal='$3'>
                  <EventCard key={`event-card-loaded`}
                    event={subjectEvent}
                    onEditingChange={editHandler(subjectPost!.id)}
                    selectedInstance={subjectInstance}
                    onInstancesUpdated={onEventInstancesUpdated}
                    {...{ newRsvpMode, setNewRsvpMode }}
                  />
                </XStack>
                <ConversationManager post={subjectPost!} />
              </ScrollView>


              <ReplyArea replyingToPath={replyPostIdPath}
                onStopReplying={() => postId && setReplyPostIdPath([postId])}
                hidden={!showReplyArea} />
            </YStack>
          </ConversationContextProvider>
        </AccountOrServerContextProvider>
      }
    </TabsNavigation >
  )
}
