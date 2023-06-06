import React from 'react'
import { BasePostsScreen } from '../home/posts_screen'
import { BaseGroupHomeScreen } from './group_home_screen'


export function GroupPostsScreen() {
  return <BaseGroupHomeScreen
    screenComponent={
      (group) => <BasePostsScreen key={group.id} selectedGroup={group} />
    } />;
}
