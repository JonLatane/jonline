import { UserListingType } from '@jonline/api';
import { AnimatePresence, Heading, Spinner, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { useCredentialDispatch, useCurrentAndPinnedServers, useUsersPage } from 'app/hooks';
import { FederatedUser, RootState, federatedId, getFederated, getUsersPage, loadUsersPage, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { HomeScreenProps } from '../home/home_screen';
import { AppSection, AppSubsection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { UserCard } from '../user/user_card';

export function FollowRequestsScreen() {
  return <BasePeopleScreen listingType={UserListingType.FOLLOW_REQUESTS} />;
}

export function MainPeopleScreen() {
  return <BasePeopleScreen listingType={UserListingType.EVERYONE} />;
}


export type PeopleScreenProps = HomeScreenProps & {
  listingType?: UserListingType;
};


export const BasePeopleScreen: React.FC<PeopleScreenProps> = ({ listingType, selectedGroup }) => {
  const isForGroupMembers = listingType === undefined;

  const servers = useCurrentAndPinnedServers();
  const { results: users, loading: loadingUsers, reload: reloadUsers, firstPageLoaded } = isForGroupMembers
    ? { results: [], loading: false, reload: () => { }, firstPageLoaded: true }
    : useUsersPage(listingType, 0);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  let { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();

  const dimensions = useWindowDimensions();

  const userPagesStatus = useRootSelector((state: RootState) => getFederated(state.users.pagesStatus, server));

  useEffect(() => {
    let title = isForGroupMembers ? 'Members' :
      listingType == UserListingType.FOLLOW_REQUESTS ? 'Follow Requests' : 'People';
    title += ` | ${server?.serverConfiguration?.serverInfo?.name || '...'}`;
    setDocumentTitle(title)
  }, [isForGroupMembers, listingType, server?.serverConfiguration?.serverInfo?.name]);



  useEffect(() => {
    if (firstPageLoaded && showScrollPreserver) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded, showScrollPreserver])

  return (
    <TabsNavigation appSection={selectedGroup ? AppSection.MEMBERS : AppSection.PEOPLE} selectedGroup={selectedGroup}
      appSubsection={listingType == UserListingType.FOLLOW_REQUESTS ? AppSubsection.FOLLOW_REQUESTS : undefined}
      groupPageForwarder={(group) => `/g/${group.shortname}/members`}
      withServerPinning
    >
      {loadingUsers ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$2' mt='$2' maw={800} space>
        {users && users.length == 0
          ? userPagesStatus != 'loading' && userPagesStatus != 'unloaded'
            ? listingType == UserListingType.FOLLOW_REQUESTS ?
              <YStack width='100%' maw={600} jc="center" ai="center">
                <Heading size='$5' mb='$3'>No follow requests found.</Heading>
                {/* <Heading size='$3' ta='center'>.</Heading> */}
              </YStack> :
              <YStack width='100%' maw={600} jc="center" ai="center">
                <Heading size='$5' mb='$3'>No people found.</Heading>
                <Heading size='$3' ta='center'>The people you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
              </YStack>
            : undefined
          : <AnimatePresence>
            {users?.map((user) => {
              return <YStack w='100%' mb='$3' key={`user-${federatedId(user)}`}>
                <UserCard user={user} isPreview />
              </YStack>;
            })}
            {showScrollPreserver ? <YStack h={100000} /> : undefined}
          </AnimatePresence>}
      </YStack>
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
