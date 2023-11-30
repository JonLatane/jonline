import { EventInstance } from '@jonline/api'
import { Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui'
import { RootState, loadEventByInstance, selectEventById, selectGroupById, selectPostById, serverID, useCredentialDispatch, useLocalConfiguration, useServerTheme, useRootSelector } from 'app/store'
import { setDocumentTitle } from 'app/utils/set_title'
import React, { useEffect, useState } from 'react'
import { createParam } from 'solito'
import EventCard from '../event/event_card'
import { ConversationContextProvider, ConversationManager, useStatefulConversationContext } from '../post'
import { ReplyArea } from '../post/reply_area'
import { AppSection } from '../tabs/features_navigation'
import { TabsNavigation } from '../tabs/tabs_navigation'
import { RsvpMode } from './event_rsvp_manager'
import moment from 'moment'
import { isPastInstance } from 'app/utils/time'

const { useParam, useUpdateParams } = createParam<{ eventId: string, instanceId: string, shortname: string | undefined }>()

// Legacy parameter format (loading event by eventId):
// /event/:eventId/i/:instanceId
//
// Current parameter format (loading event by instanceId):
// /event/:instanceId
//
// Legacy parameter format is still supported for backwards compatibility, but
// the :eventId parameter is ignored.
//
// Legacy /event/:eventId format is no longer supported.
//  *There is no longer a way to access the event details screen by eventId alone.*
// This could prove confusing in some editing scenarios, but optimizations
// to the UpdateEvent RPC can mitigate this if it's ever actually a problem (preserving the last InstanceID).
//
// In terms of the web app's URL structure, "/event" corresponds to
// EventInstances, not Events.
export function EventDetailsScreen() {
  const [pathEventId] = useParam('eventId');
  const [pathInstanceId] = useParam('instanceId');
  const [shortname] = useParam('shortname');

  const updateParams = useUpdateParams();

  const instanceId = pathInstanceId && pathInstanceId.length > 0 ? pathInstanceId : pathEventId;

  const { server, primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor, navAnchorColor } = useServerTheme();
  const app = useLocalConfiguration();
  const groupId = useRootSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useRootSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const eventsState = useRootSelector((state: RootState) => state.events);
  const postsState = useRootSelector((state: RootState) => state.posts);

  const eventId = useRootSelector((state: RootState) => instanceId
    ? state.events.instanceEvents[instanceId]
    : undefined);
  const subjectEvent = useRootSelector((state: RootState) => eventId
    ? selectEventById(state.events, eventId)
    : undefined);
  const subjectPost = useRootSelector((state: RootState) =>
    selectPostById(state.posts, subjectEvent?.post?.id ?? '') ?? subjectEvent?.post);
  const postId = subjectPost?.id;

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
  const conversationContext = useStatefulConversationContext();
  const { editingPosts, replyPostIdPath, setReplyPostIdPath, editHandler } = conversationContext;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const showReplyArea = subjectEvent != undefined && editingPosts.length == 0
    && (newRsvpMode === undefined);

  const failedToLoadEvent = instanceId != undefined &&
    eventsState.failedInstanceIds.includes(instanceId!);
  console.log("subjectEvent=", subjectEvent, 'failedToLoadEvent=', failedToLoadEvent);

  function onEventInstancesUpdated(instances: EventInstance[]) {
    if (!instances.some(i => i.id == instanceId)) {
      updateParams({
        eventId: instances.find(i => !isPastInstance(i))?.id
          ?? instances[0]!.id
      }, { web: { replace: true } });
    }
  }

  useEffect(() => {
    if (instanceId) {
      if ((!subjectEvent || !loadedEvent) && !loadingEvent) {
        setLoadingEvent(true);
        console.log('loadEventByInstance', instanceId!)
        setTimeout(() =>
          dispatch(loadEventByInstance({ ...accountOrServer, instanceId: instanceId! }))
            .then((action) => {
              console.log('loadEventByInstance.then', action.payload)
              setLoadedEvent(true)
            }));
      } else if (subjectPost && loadingEvent) {
        setLoadingEvent(false);
      }
      if (subjectPost && (subjectPost.replyCount == 0 || subjectPost.replies.length > 0) && showScrollPreserver) {
        dismissScrollPreserver(setShowScrollPreserver);
      }
    }
  }, [instanceId, subjectPost, postsState, loadingEvent, loadedEvent, replyPostIdPath, showScrollPreserver]);

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
    <TabsNavigation appSection={AppSection.EVENT} selectedGroup={group}>
      {!subjectEvent
        ? failedToLoadEvent
          ? <>
            <Heading size='$5'>Event not found.</Heading>
            <Heading size='$3' ta='center'>It may either not exist, not be visible to you, or be hidden by moderators.</Heading>
          </>
          : <Spinner size='large' color={navColor} scale={2} />
        :
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
      }
    </TabsNavigation >
  )
}
