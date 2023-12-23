import { Permission } from '@jonline/api';
import { Button, Heading, XStack, YStack, isWeb } from '@jonline/ui';
import { Send as SendIcon } from '@tamagui/lucide-icons';
import { useCredentialDispatch } from 'app/hooks';
import { FederatedGroup, useServerTheme } from 'app/store';
import React from 'react';
import StickyBox from 'react-sticky-box';
import { AddAccountSheet } from '../accounts/add_account_sheet';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import { CreateEventSheet } from '../event/create_event_sheet';
import { CreatePostSheet } from '../post/create_post_sheet';

interface StickyCreateButtonProps {
  selectedGroup?: FederatedGroup;
  showPosts?: boolean;
  showEvents?: boolean;
  // replyingToPath: string[];
}

export const StickyCreateButton: React.FC<StickyCreateButtonProps> = ({
  selectedGroup,
  showPosts,
  showEvents,
}: StickyCreateButtonProps) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();

  const canCreatePosts = accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS);
  const canCreateEvents = accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_EVENTS);

  const doShowPosts = showPosts && canCreatePosts;
  const doShowEvents = showEvents && canCreateEvents;

  return isWeb ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%' }}>
    {canCreatePosts
      ? <XStack w='100%' p='$2' space='$2' opacity={.92} /*backgroundColor='$background'*/ alignContent='center'>
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
  </StickyBox>
    : <Button mt='$3' circular icon={SendIcon} backgroundColor={primaryColor} onPress={() => { }} />

}
