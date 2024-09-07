import { Permission } from '@jonline/api';
import { Heading, XStack, YStack } from '@jonline/ui';
import { useCurrentAccountOrServer, useCredentialDispatch, usePinnedAccountsAndServers, useCurrentAccount } from 'app/hooks';
import { FederatedGroup, useServerTheme } from 'app/store';
import React from 'react';
import { AuthSheet } from '../accounts/auth_sheet';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import { CreateEventSheet } from '../event/create_event_sheet';
import { useHideNavigation } from '../navigation/use_hide_navigation';
import { CreatePostSheet } from '../post/create_post_sheet';
import { AuthSheetButton } from '../accounts/auth_sheet_button';
import { useGroupContext } from 'app/contexts';

interface DynamicCreateButtonProps {
  // selectedGroup?: FederatedGroup;
  showPosts?: boolean;
  showEvents?: boolean;
  button?: (onPress: () => void) => JSX.Element;
  hideIfUnusable?: boolean;
}

export const DynamicCreateButton: React.FC<DynamicCreateButtonProps> = ({
  // selectedGroup,
  showPosts,
  showEvents,
  button,
  hideIfUnusable
}: DynamicCreateButtonProps) => {
  const currentAccount = useCurrentAccount();
  const accountsAndServers = usePinnedAccountsAndServers({ includeUnpinned: true });
  const { selectedGroup } = useGroupContext();

  const canCreatePosts = accountsAndServers.some(aos =>
    aos.account?.user?.permissions?.includes(Permission.CREATE_POSTS)
  );
  const canCreateEvents = accountsAndServers.some(aos =>
    aos.account?.user?.permissions?.includes(Permission.CREATE_EVENTS)
  );
  // console.log("DynamicCreateButton canCreatePosts", canCreatePosts, "canCreateEvents", canCreateEvents,
  //   accountsAndServers.map(aos => aos?.account?.user?.permissions));

  const doShowPosts = showPosts && canCreatePosts;
  const doShowEvents = showEvents && canCreateEvents;


  if (button) {
    return doShowPosts ? <CreatePostSheet {...{ selectedGroup, button }} />
      : doShowEvents ? <CreateEventSheet {...{ selectedGroup, button }} />
        : <AuthSheetButton operation='Post' button={button} />
  }

  // console.log("DynamicCreateButton hide", hide);
  return doShowPosts || doShowEvents
    ? <XStack gap='$2' opacity={.92} /*backgroundColor='$background'*/ alignContent='center'>
      {doShowPosts ? <CreatePostSheet {...{ selectedGroup, button }} /> : undefined}
      {doShowEvents ? <CreateEventSheet {...{ selectedGroup, button }} /> : undefined}
    </XStack>
    : hideIfUnusable
      ? undefined
      : currentAccount
        ? (showPosts || showEvents)
          ? <YStack opacity={.92} paddingVertical='$2' /*backgroundColor='$background'*/ alignContent='center'>
            <Heading size='$1'>You do not have permission to create{
              showPosts && showEvents ? ' posts or events' : showPosts ? ' posts' : showEvents ? ' events' : ''
            }.</Heading>
          </YStack>
          : undefined
        :
        <YStack opacity={.92} /*backgroundColor='$background'*/ alignContent='center'>
          <AuthSheetButton operation='Post' button={button} />
        </YStack>;

}
