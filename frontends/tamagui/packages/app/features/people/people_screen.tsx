import { UserListingType } from '@jonline/api';
import { AnimatePresence, Button, Heading, Input, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { X as XIcon } from '@tamagui/lucide-icons';
import { useCredentialDispatch, useCurrentAndPinnedServers, usePaginatedRendering, useUsersPage } from 'app/hooks';
import { RootState, federatedId, getFederated, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { HomeScreenProps } from '../home/home_screen';
import { PaginationIndicator } from '../home/pagination_indicator';
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
  const { results: allUsers, loading: loadingUsers, reload: reloadUsers, firstPageLoaded } = isForGroupMembers
    ? { results: [], loading: false, reload: () => { }, firstPageLoaded: true }
    : useUsersPage(listingType, 0);

  const [searchText, setSearchText] = useState('');
  const filteredUsers = allUsers?.filter((user) => {
    return user.username.toLowerCase().includes(searchText.toLowerCase());
  });

  const pagination = usePaginatedRendering(filteredUsers, 10);
  const paginatedUsers = pagination.results;

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
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/members`}
      withServerPinning
      loading={loadingUsers}
      topChrome={
        <YStack w='100%' px='$2' py='$2' key='filter-toolbar'>

          <XStack w='100%' ai='center' space='$2' mx='$2'>
            <Input placeholder='Search'
              f={1}
              // textContentType='search'
              value={searchText}
              onChange={(e) => setSearchText(e.nativeEvent.text)} />
            {searchText.length > 0
              ? //<XStack position='absolute' right={0} top={0} bottom={0} my='auto' mr='$2'>
              <Button circular icon={XIcon} size='$2' onPress={() => setSearchText('')} mr='$2' />
              : undefined}
          </XStack>
        </YStack>
      }
    >
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$2' mt='$2' maw={800} space>
        {filteredUsers && filteredUsers.length == 0
          ? userPagesStatus != 'loading' && userPagesStatus != 'unloaded'
            ? listingType == UserListingType.FOLLOW_REQUESTS ?
              <YStack width='100%' maw={600} jc="center" ai="center">
                <Heading size='$5' mb='$3'>No follow requests found.</Heading>
                {/* <Heading size='$3' ta='center'>.</Heading> */}
              </YStack> :
              <YStack width='100%' maw={600} jc="center" ai="center">
                <Heading size='$5' mb='$3'>No people found.</Heading>
                <Heading size='$3' ta='center'>The people you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                {allUsers.length > 0 ? <Heading size='$3' ta='center'>Try searching for something else.</Heading> : undefined}
              </YStack>
            : undefined
          : <AnimatePresence>
            {paginatedUsers?.map((user) => {
              return <YStack w='100%' mb='$3' key={`user-${federatedId(user)}`}>
                <UserCard user={user} isPreview />
              </YStack>;
            })}
            <PaginationIndicator {...pagination} />
            {showScrollPreserver ? <YStack h={100000} /> : undefined}
          </AnimatePresence>}
      </YStack>
    </TabsNavigation>
  )
}
