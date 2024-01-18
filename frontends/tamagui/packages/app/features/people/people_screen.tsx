import { UserListingType } from '@jonline/api';
import { AnimatePresence, Button, Heading, Input, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { useCredentialDispatch, useCurrentAndPinnedServers, usePaginatedRendering, useUsersPage } from 'app/hooks';
import { RootState, federatedId, getFederated, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { HomeScreenProps } from '../home/home_screen';
import { PaginationIndicator } from '../home/pagination_indicator';
import { AppSection, AppSubsection } from '../navigation/features_navigation';
import { TabsNavigation, tabNavBaseHeight } from '../navigation/tabs_navigation';
import { UserCard } from '../user/user_card';
import { NavigationContextConsumer } from 'app/contexts';
import { X as XIcon } from '@tamagui/lucide-icons';

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
    >
      <NavigationContextConsumer>
        {(navContext) => <StickyBox key='filters' offsetTop={tabNavBaseHeight + (navContext?.pinnedServersHeight ?? 0)} className='blur' style={{ width: '100%', zIndex: 10 }}>
          <YStack w='100%' px='$2' key='filter-toolbar'>

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
            {/* <Button size='$1' onPress={() => setShowMedia(!showMedia)}>
          <XStack animation='quick' rotate={showMedia ? '90deg' : '0deg'}>
            <ChevronRight size='$1' />
          </XStack>
          <Heading size='$1' f={1}>Media {media.length > 0 ? `(${media.length})` : undefined}</Heading>
        </Button> */}
              {/* <AnimatePresence>
            {displayMode === 'filtered' ?
              <XStack key='endsAfterFilter' w='100%' flexWrap='wrap' maw={800} px='$2' mx='auto' animation='standard' {...standardAnimation}>
                <Heading size='$5' mb='$3' my='auto'>Ends After</Heading>
                <Text ml='auto' my='auto' fontSize='$2' fontFamily='$body'>
                  <input type='datetime-local' min={supportDateInput(moment(0))} value={supportDateInput(moment(endsAfter))} onChange={(v) => setQueryEndsAfter(moment(v.target.value).toISOString(true))} style={{ padding: 10 }} />
                </Text>
              </XStack>
              : undefined}
          </AnimatePresence> */}
          </YStack>
        </StickyBox>}
      </NavigationContextConsumer>
      {loadingUsers ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
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
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
