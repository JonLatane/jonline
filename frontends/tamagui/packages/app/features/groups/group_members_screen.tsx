import React from 'react'
import { BasePostsScreen } from '../home/posts_screen'
import { BaseGroupHomeScreen } from './group_home_screen'
import { BasePeopleScreen } from '../people/people_screen';
import { UserListingType } from '@jonline/api/index';


export function GroupMembersScreen() {
  return <BaseGroupHomeScreen
    screenComponent={
      (group) => <BasePeopleScreen key={group.id} selectedGroup={group} />
    } />;
}
