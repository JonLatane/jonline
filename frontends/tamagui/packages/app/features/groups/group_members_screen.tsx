import React from 'react';
import { BasePeopleScreen } from '../people/people_screen';
import { BaseGroupHomeScreen } from './group_home_screen';


export function GroupMembersScreen() {
  return <BaseGroupHomeScreen
    screenComponent={
      (group) => <BasePeopleScreen key={group.id} selectedGroup={group} />
    } />;
}
