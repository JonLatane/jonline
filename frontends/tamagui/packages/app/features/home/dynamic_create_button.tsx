import { Permission } from '@jonline/api';
import { Heading, XStack, YStack } from '@jonline/ui';
import { useAccountOrServer, useCredentialDispatch } from 'app/hooks';
import { FederatedGroup, useServerTheme } from 'app/store';
import React from 'react';
import { AddAccountSheet } from '../accounts/add_account_sheet';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import { CreateEventSheet } from '../event/create_event_sheet';
import { useHideNavigation } from '../navigation/use_hide_navigation';
import { CreatePostSheet } from '../post/create_post_sheet';

interface DynamicCreateButtonProps {
  selectedGroup?: FederatedGroup;
  showPosts?: boolean;
  showEvents?: boolean;
  // replyingToPath: string[];
}

export const DynamicCreateButton: React.FC<DynamicCreateButtonProps> = ({
  selectedGroup,
  showPosts,
  showEvents,
}: DynamicCreateButtonProps) => {
  const accountOrServer = useAccountOrServer();

  const canCreatePosts = accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS);
  const canCreateEvents = accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_EVENTS);

  const doShowPosts = showPosts && canCreatePosts;
  const doShowEvents = showEvents && canCreateEvents;

  const hide = useHideNavigation();

  return hide ? <></> :
    <>
      {canCreatePosts
        ? <XStack w='100%' p='$2' gap='$2' opacity={.92} /*backgroundColor='$background'*/ alignContent='center'>
          {doShowPosts ? <CreatePostSheet selectedGroup={selectedGroup} /> : undefined}
          {doShowEvents ? <CreateEventSheet selectedGroup={selectedGroup} /> : undefined}
        </XStack>
        : accountOrServer.account
          ? (showPosts || showEvents)
            ? <YStack w='100%' opacity={.92} paddingVertical='$2' /*backgroundColor='$background'*/ alignContent='center'>
              <Heading size='$1'>You do not have permission to create{
                showPosts && showEvents ? ' posts or events' : showPosts ? ' posts' : showEvents ? ' events' : ''
              }.</Heading>
            </YStack>
            : undefined
          : <YStack w='100%' opacity={.92} p='$3' /*backgroundColor='$background'*/ alignContent='center'>
            <AddAccountSheet operation='Post' />
          </YStack>}
    </>
    ;

}
