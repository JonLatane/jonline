import { UserListingType } from '@jonline/api';
import { Button, Heading, Input, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, useDebounceValue } from '@jonline/ui';
import { X as XIcon } from '@tamagui/lucide-icons';
import { useAppSelector, useCurrentServer, useMembersPage, usePaginatedRendering, useUsersPage } from 'app/hooks';
import { federatedId, getFederated } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useMemo, useState } from 'react';
import { createParam } from 'solito';
import { HomeScreenProps } from '../home/home_screen';
import { PageChooser } from '../home/page_chooser';
import { AppSection, AppSubsection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { UserCard } from '../user/user_card';
import { AutoAnimatedList } from '../post';

export function FollowRequestsScreen() {
  return <BasePeopleScreen listingType={UserListingType.FOLLOW_REQUESTS} />;
}

export function MainPeopleScreen() {
  return <BasePeopleScreen listingType={UserListingType.EVERYONE} />;
}

export type PeopleScreenProps = HomeScreenProps & {
  listingType?: UserListingType;
};

export function useParamState<T>(paramValue: T | undefined, defaultValue: T) {
  const [value, setValue] = useState(defaultValue);
  useEffect(() => {
    if (paramValue !== undefined) {
      setValue(paramValue as T);
    }
  }, [paramValue]);
  return [value, setValue] as const;
}

const { useParam, useUpdateParams } = createParam<{ search: string | undefined }>()
export const BasePeopleScreen: React.FC<PeopleScreenProps> = ({ listingType, selectedGroup }) => {
  const isForGroupMembers = listingType === undefined;

  const users = useUsersPage(listingType, 0);
  const groupMembers = useMembersPage(selectedGroup ? federatedId(selectedGroup!) : '', 0);
  const { results: allUsers, loading: loadingUsers, reload: reloadUsers, firstPageLoaded } = isForGroupMembers
    ? groupMembers
    // { results: [], loading: false, reload: () => { }, firstPageLoaded: true }
    : users

  // const [searchParamValue] = useParam('search');
  // const searchParam = useParamState(useParam('search')[0], '');// searchParamValue ?? '';
  const updateParams = useUpdateParams();
  // const [searchText, setSearchText] = useState(searchParam);
  const [searchParamValue] = useParam('search');
  const [searchText, setSearchText] = useParamState(searchParamValue, '');

  const debouncedSearchText = useDebounceValue(
    searchText.trim().toLowerCase(),
    300
  );
  useEffect(() => {
    requestAnimationFrame(
      () => {
        // debugger;
        if (searchParamValue ?? '' !== debouncedSearchText) {
          // debugger;
          updateParams(
            { search: debouncedSearchText || undefined },
            { web: { replace: true } }
          )
        }
      });
  }, [debouncedSearchText])

  const filteredUsers = useMemo(
    () => allUsers?.filter((user) => {
      return user.username.toLowerCase().includes(debouncedSearchText)
        || user.realName?.toLowerCase().includes(debouncedSearchText);
    }),
    [allUsers, debouncedSearchText]
  );

  const pagination = usePaginatedRendering(filteredUsers, 10);
  const paginatedUsers = pagination.results;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const server = useCurrentServer();

  const userPagesStatus = useAppSelector(state => getFederated(state.users.pagesStatus, server));

  useEffect(pagination.reset, [debouncedSearchText]);
  const documentTitle = (() => {
    let title = isForGroupMembers ? 'Members' :
      listingType == UserListingType.FOLLOW_REQUESTS ? 'Follow Requests' : 'People';
    title += ` | ${server?.serverConfiguration?.serverInfo?.name || '...'}`;
    return title;

  })();
  useEffect(() => {
    setDocumentTitle(documentTitle)
  }, [documentTitle, window.location.search]);

  useEffect(() => {
    if (firstPageLoaded && showScrollPreserver) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded, showScrollPreserver])

  return (
    <TabsNavigation appSection={selectedGroup ? AppSection.MEMBERS : AppSection.PEOPLE} selectedGroup={selectedGroup}
      appSubsection={listingType == UserListingType.FOLLOW_REQUESTS ? AppSubsection.FOLLOW_REQUESTS : undefined}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/members`}
      groupPageReverse='/people'
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
            <XStack position='absolute' right={55}
              pointerEvents="none"
              animation='standard'
              o={searchText !== debouncedSearchText ? 1 : 0}
            >
              <Spinner />
            </XStack>
            <Button circular disabled={searchText.length === 0} o={searchText.length === 0 ? 0.5 : 1} icon={XIcon} size='$2' onPress={() => setSearchText('')} mr='$2' />

          </XStack>
        </YStack>
      }
    >
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$2' mt='$2' pb='$3' maw={800} space>
        <AutoAnimatedList style={{ width: '100%' }}>
          <div key='pagest-top' id='pages-top' style={{ maxWidth: '100%' }}>
            <PageChooser {...pagination} />
          </div>
          {filteredUsers && filteredUsers.length == 0
            ? userPagesStatus != 'loading' && userPagesStatus != 'unloaded'
              ? <div key='no-people'>
                {listingType == UserListingType.FOLLOW_REQUESTS ?
                  <YStack mx='auto' width='100%' maw={600} jc="center" ai="center">
                    <Heading size='$3' o={0.5} mb='$3'>No follow requests found.</Heading>
                  </YStack> :
                  <YStack mx='auto' width='100%' maw={600} jc="center" ai="center">
                    <Heading size='$3' o={0.5} mb='$3'>No people found.</Heading>
                    {/* <Heading size='$2' o={0.5} ta='center'>The people you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                    {allUsers.length > 0 ? <Heading size='$3' o={0.5} ta='center'>Try searching for something else.</Heading> : undefined}
                  </YStack>}
              </div>
              : undefined
            : undefined}
          {paginatedUsers?.map((user) => {
            return <div style={{ width: '100%' }} key={`user-${federatedId(user)}`}>
              <YStack w='100%' my='$2'>
                <UserCard user={user} isPreview />
              </YStack>
            </div>;
          })}

          <div key='pages-bottom' id='pages-bottom' style={{ maxWidth: '100%' }}>
            <PageChooser {...pagination} pageTopId='pages-top' showResultCounts
              entityName={isForGroupMembers
                ? { singular: 'member', plural: 'members' } :
                { singular: 'person', plural: 'people' }}
            />
          </div>
          {showScrollPreserver ? <YStack h={100000} /> : undefined}
        </AutoAnimatedList>
      </YStack>
    </TabsNavigation>
  )
}
