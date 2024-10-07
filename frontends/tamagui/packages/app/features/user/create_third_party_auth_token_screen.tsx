import { Moderation, Permission, PostContext, TimeFilter, Visibility } from '@jonline/api';
import { AnimatePresence, Button, Dialog, Heading, Input, Label, Paragraph, ScrollView, Spinner, Switch, Text, TextArea, Theme, Tooltip, XStack, YStack, ZStack, dismissScrollPreserver, isClient, needsScrollPreservers, reverseHorizontalAnimation, standardHorizontalAnimation, toProtoISOString, useMedia, useToastController, useWindowDimensions } from '@jonline/ui';
import { AlertTriangle, Calendar as CalendarIcon, CheckCircle, ChevronRight, Edit3 as Edit, Eye, SquareAsterisk, Trash, XCircle } from '@tamagui/lucide-icons';
import { PermissionsEditor, PermissionsEditorProps, TamaguiMarkdown, ToggleRow, VisibilityPicker } from 'app/components';
import { useCurrentAccountOrServer, useEventPageParam, useFederatedDispatch, usePaginatedRendering } from 'app/hooks';
import { useBigCalendar, useShowEvents } from 'app/hooks/configuration_hooks';
import { FederatedEvent, FederatedPost, FederatedUser, RootState, actionSucceeded, deleteUser, federatedId, getFederated, loadUserEvents, loadUserPosts, loadUserReplies, loadUsername, resetPassword, selectUserById, serverID, updateUser, useRootSelector, useServerTheme } from 'app/store';
import { hasAdminPermission, highlightedButtonBackground, pending, setDocumentTitle, themedButtonBackground } from 'app/utils';
import moment from 'moment';
import React, { useCallback, useEffect, useState } from 'react';
import FlipMove from 'lumen5-react-flip-move';
import { createParam } from 'solito';
import { useLink } from 'solito/link';
import { useAppDispatch, useAppSelector } from '../../hooks/store_hooks';
import { EventCard } from '../event/event_card';
import { useGroupFromPath } from '../groups/group_home_screen';
import { DynamicCreateButton } from '../home/dynamic_create_button';
import { EventsFullCalendar } from '../event/events_full_calendar';
import { PageChooser } from '../home/page_chooser';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { PostCard } from '../post/post_card';
import { FederatedProfiles } from './federated_profiles';
import { EditableUserDetails, UserCard, useFullAvatarHeight } from './user_card';
import { AccountOrServerContextProvider } from 'app/contexts';
import { federatedEntity } from '../../store/federation';

const { useParam } = createParam<{ from?: string, to?: string, token?: string | undefined }>()
const { useParam: useShortnameParam } = createParam<{ from: string | undefined, to: string | undefined, token: string | undefined }>();

export function CreateThirdPartyAuthTokenScreen() {
  const mediaQuery = useMedia();
  const { group, pathShortname } = useGroupFromPath();

  const [fromHost] = useParam('from');
  const [toHost] = useParam('to');

  const theme = useServerTheme();
  const { primaryTextColor, primaryColor } = theme;
  const { account: currentServerAccount, server: currentServer } = useCurrentAccountOrServer();

  // const dispatch = useAppDispatch();

  const user = currentServerAccount ?
    federatedEntity(currentServerAccount.user, currentServer)
    : undefined;

  const createAuthToken = useCallback(() => {

  }, []);

  return (
    <TabsNavigation minimal
      appSection={AppSection.AUTH}
      primaryEntity={user}
      selectedGroup={group}
      // groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/m/${pathUsername}`}
      // groupPageReverse={`/${pathUsername}`}
      bottomChrome={!!user
        ? <YStack w='100%' paddingVertical='$2' alignContent='center'>
          <XStack mx='auto' px='$3' w='100%' maw={800}>
            <Button key={`save-color-${primaryColor}`} ml='auto' mr='$3'
              {...highlightedButtonBackground(theme)}
              // disabled={!dirtyData} opacity={dirtyData ? 1 : 0.5}
              als='center' onPress={createAuthToken}>
              <Heading size='$2' color={primaryTextColor}>Authenticate</Heading>
            </Button>
            {/* <XStack f={1} /> */}
          </XStack>
        </YStack> : undefined}
    >
      <YStack f={1} jc="center" ai="center" gap my='$2' w='100%'>
        {(toHost?.length ?? 0) > 0
          ? user
            ? <>
              <Heading size='$6'>Authenticating to {toHost} as:</Heading>
              <UserCard user={user} />
              <Paragraph size='$2'></Paragraph>
            </>
            : <Heading size='$1'>Login to integrate with {toHost}.</Heading>
          : (fromHost?.length ?? 0) > 0
            ? user
              ? <>
                <Heading size='$6'>Authenticating from {fromHost}</Heading>
                {/* <Heading size='$1'>Login on {fromHost}</Heading> */}
                {/* <UserCard user={user} /> */}
              </>
              : <Heading size='$1'>Login to integrate with {toHost}.</Heading>
            : <Paragraph size='$4'>To use third party auth, add <Text fontFamily='$mono'>?from=my.hostname.com</Text> or <Text fontFamily='$mono'>?to=my.hostname.com</Text> to this URL.</Paragraph>}

      </YStack>
    </TabsNavigation>
  )
}
