import { UserListingType } from '@jonline/api';
import { Button, Heading, Input, XStack, YStack, dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui';
import { X as XIcon } from '@tamagui/lucide-icons';
import { usePaginatedRendering, useServer, useUsersPage } from 'app/hooks';
import { RootState, federatedId, getFederated, useRootSelector } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import FlipMove from 'react-flip-move';
import { createParam } from 'solito';
import { HomeScreenProps } from '../home/home_screen';
import { PaginationIndicator, PaginationResetIndicator } from '../home/pagination_indicator';
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

const { useParam, useUpdateParams } = createParam<{ search: string }>()
export const BasePeopleScreen: React.FC<PeopleScreenProps> = ({ listingType, selectedGroup }) => {
  const isForGroupMembers = listingType === undefined;

  const { results: allUsers, loading: loadingUsers, reload: reloadUsers, firstPageLoaded } = isForGroupMembers
    ? { results: [], loading: false, reload: () => { }, firstPageLoaded: true }
    : useUsersPage(listingType, 0);

  const [searchParam] = useParam('search');
  const updateParams = useUpdateParams();
  const [searchText, _setSearchText] = useState(searchParam ?? '');
  function setSearchText(text: string) {
    _setSearchText(text);
    updateParams({ search: text }, { web: { replace: true } });
  };

  const filteredUsers = allUsers?.filter((user) => {
    return user.username.toLowerCase().includes(searchText.toLowerCase());
  });

  const pagination = usePaginatedRendering(filteredUsers, 10);
  const paginatedUsers = pagination.results;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const server = useServer();

  const userPagesStatus = useRootSelector((state: RootState) => getFederated(state.users.pagesStatus, server));

  useEffect(pagination.reset, [searchText]);
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
      showShrinkPreviews
      loading={loadingUsers}
      topChrome={
        <YStack w='100%' px='$2' py='$2' key='filter-toolbar'>

          <XStack w='100%' ai='center' gap='$2' mx='$2'>
            <Input placeholder='Search'
              f={1}
              value={searchText}
              onChange={(e) => setSearchText(e.nativeEvent.text)} />
            <Button circular disabled={searchText.length === 0} o={searchText.length === 0 ? 0.5 : 1} icon={XIcon} size='$2' onPress={() => setSearchText('')} mr='$2' />

          </XStack>
        </YStack>
      }
    >
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$2' mt='$2' maw={800} space>
        {<>
          <PaginationResetIndicator {...pagination} />
          <FlipMove style={{ width: '100%', marginLeft: 5, marginRight: 5 }} >
            {filteredUsers && filteredUsers.length == 0
              ? userPagesStatus != 'loading' && userPagesStatus != 'unloaded'
                ? <div key='no-people'>
                  {listingType == UserListingType.FOLLOW_REQUESTS ?
                    <YStack width='100%' maw={600} jc="center" ai="center">
                      <Heading size='$5' mb='$3'>No follow requests found.</Heading>
                    </YStack> :
                    <YStack width='100%' maw={600} jc="center" ai="center">
                      <Heading size='$5' o={0.5} mb='$3'>No people found.</Heading>
                      {/* <Heading size='$2' o={0.5} ta='center'>The people you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                      {allUsers.length > 0 ? <Heading size='$3' o={0.5} ta='center'>Try searching for something else.</Heading> : undefined}
                    </YStack>}
                </div>
                : undefined
              : undefined}
            {paginatedUsers?.map((user) => {
              return <div style={{ width: '100%' }} key={`user-${federatedId(user)}`}>
                <YStack w='100%' mb='$3'>
                  <UserCard user={user} isPreview />
                </YStack>
              </div>;
            })}
          </FlipMove>
          <PaginationIndicator {...pagination} />
          {showScrollPreserver ? <YStack h={100000} /> : undefined}

        </>}
      </YStack>
    </TabsNavigation>
  )
}
