import { Post, PostListingType, User, UserListingType } from '@jonline/api';
import { dismissScrollPreserver, Heading, isClient, needsScrollPreservers, Spinner, useWindowDimensions, YStack } from '@jonline/ui';
import { getPostsPage, getUsersPage, loadPostsPage, loadUsersPage, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { FlatList } from 'react-native';
import StickyBox from "react-sticky-box";
// import { StickyCreateButton } from '../post/create_post_sheet';
import PostCard from '../post/post_card';
import { AppSection, AppSubsection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import {UserCard} from '../user/user_card';

export function FollowRequestsScreen() {
  return BasePeopleScreen(UserListingType.FOLLOW_REQUESTS);
}

export function MainPeopleScreen() {
  return BasePeopleScreen(UserListingType.EVERYONE);
}

function BasePeopleScreen(listingType: UserListingType = UserListingType.EVERYONE) {
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const usersState = useTypedSelector((state: RootState) => state.users);
  const app = useTypedSelector((state: RootState) => state.app);

  const users: User[] | undefined = useTypedSelector((state: RootState) =>
    getUsersPage(state.users, listingType, 0));
  // const posts = useTypedSelector((state: RootState) => selectAllPosts(state.posts));
  // const posts: Post[] = [];
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  let { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  // let primaryColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.primary;
  // let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  // let navColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.navigation;
  // let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
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
    let title = listingType == UserListingType.FOLLOW_REQUESTS ? 'Follow Requests' : 'People';
    title += ` - ${server?.serverConfiguration?.serverInfo?.name || 'Jonline'}`;
    document.title = title;
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

  return (
    <TabsNavigation appSection={AppSection.PEOPLE}
      appSubsection={listingType == UserListingType.FOLLOW_REQUESTS ? AppSubsection.FOLLOW_REQUESTS : undefined}
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
          {/* <FlatList data={users}
            // onRefresh={reloadUsers}
            // refreshing={usersState.pagesStatus == 'loading'}
            // Allow easy restoring of scroll position
            contentContainerStyle={{width:'100%'}}
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
            keyExtractor={(user) => user.id}
            renderItem={({ item: user }) => {
              return <YStack w='100%' mb='$3'><UserCard user={user} isPreview /></YStack>;
            }} /> */}
            {users?.map((user) => {
              return <YStack w='100%' mb='$3'><UserCard user={user} isPreview /></YStack>;
            })}
            {showScrollPreserver ? <YStack h={100000} /> : undefined}
          </>}
      </YStack>
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
