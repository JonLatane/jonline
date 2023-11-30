import { User, UserListingType } from '@jonline/api';
import { Heading, Spinner, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { RootState, getUsersPage, loadUsersPage, useCredentialDispatch, useServerTheme, useRootSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { setDocumentTitle } from 'app/utils/set_title';
import { AppSection, AppSubsection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { UserCard } from '../user/user_card';
import { HomeScreenProps } from '../home/home_screen';

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

  // function BasePeopleScreen(listingType: UserListingType = UserListingType.EVERYONE) {
  const serversState = useRootSelector((state: RootState) => state.servers);
  const usersState = useRootSelector((state: RootState) => state.users);
  const app = useRootSelector((state: RootState) => state.app);

  const users: User[] | undefined = useRootSelector((state: RootState) =>
    isForGroupMembers
      ? []
      : getUsersPage(state.users, listingType, 0));

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  let { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();

  const dimensions = useWindowDimensions();

  const [loadingUsers, setLoadingUsers] = useState(false);
  useEffect(() => {
    if (users == undefined && !loadingUsers) {
      if (!accountOrServer.server) return;

      console.log("Loading users...");
      setLoadingUsers(true);
      reloadUsers();
    } else if (usersState.pagesStatus == 'loaded' && loadingUsers) {
      setLoadingUsers(false);
      dismissScrollPreserver(setShowScrollPreserver);
    }
    let title = isForGroupMembers ? 'Members' :
      listingType == UserListingType.FOLLOW_REQUESTS ? 'Follow Requests' : 'People';
    title += ` | ${server?.serverConfiguration?.serverInfo?.name || '...'}`;
    setDocumentTitle(title)
  });

  function reloadUsers() {
    dispatch(loadUsersPage({ listingType, ...accountOrServer }));
  }

  function onHomePressed() {
    if (isClient && window.scrollY > 0) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      reloadUsers();
    }
  }

  console.log('selectedGroup', selectedGroup)

  return (
    <TabsNavigation appSection={selectedGroup ? AppSection.MEMBERS : AppSection.PEOPLE} selectedGroup={selectedGroup}
      appSubsection={listingType == UserListingType.FOLLOW_REQUESTS ? AppSubsection.FOLLOW_REQUESTS : undefined}
      groupPageForwarder={(group) => `/g/${group.shortname}/members`}
    // customHomeAction={onHomePressed}
    >
      {usersState.pagesStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {users && users.length == 0
          ? usersState.pagesStatus != 'loading' && usersState.pagesStatus != 'unloaded'
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
          : <>
            {users?.map((user) => {
              return <YStack w='100%' mb='$3' key={`user-${user.id}`}><UserCard user={user} isPreview /></YStack>;
            })}
            {showScrollPreserver ? <YStack h={100000} /> : undefined}
          </>}
      </YStack>
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
