import React from 'react'
import { BaseEventsScreen } from '../home/events_screen'
import { BaseGroupHomeScreen } from './group_home_screen'


export function GroupEventsScreen() {
  return <BaseGroupHomeScreen
    screenComponent={
      (group) => <BaseEventsScreen key={group.id} selectedGroup={group} />
    } />;
}
