import { Spinner, YStack, useWindowDimensions } from '@jonline/ui'
import { useAppSelector, useCurrentServer, useFederatedDispatch } from 'app/hooks'
import { FederatedGroup, federateId, loadGroupByShortname, parseFederatedId, selectGroupById, useServerTheme } from 'app/store'
import React, { useEffect, useState } from 'react'
import { createParam } from 'solito'
import { BaseHomeScreen } from '../home/home_screen'

const { useParam } = createParam<{ shortname: string }>()

export type GroupHomeScreenProps = {
  screenComponent: (group: FederatedGroup) => React.JSX.Element;
}

export function GroupHomeScreen() {
  return <BaseGroupHomeScreen
    screenComponent={
      (group) => <BaseHomeScreen key={group.id} selectedGroup={group} />
    } />;
}

export function useGroupFromPath(inputShortname: string | undefined): FederatedGroup | undefined {
  const currentServer = useCurrentServer();
  const { id: shortname, serverHost } = parseFederatedId(inputShortname ?? '', currentServer?.host);
  const federatedShortname = federateId(shortname, serverHost);

  const shortnameIds = useAppSelector(state => state.groups.shortnameIds);
  const groupId = shortnameIds[federatedShortname!];
  const group = useAppSelector(state =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  // debugger;

  // console.log('useGroupFromPath', shortname, federatedShortname, shortnameIds, groupId, group);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const [loadingGroups, setLoadingGroups] = useState(false);

  useEffect(() => {
    if (shortname && !group && !loadingGroups) {
      // debugger;
      reloadGroups();
    }
  }, [shortname, loadingGroups, group]);

  function reloadGroups() {
    if (!accountOrServer.server) return;
    if (!shortname) return;

    setLoadingGroups(true);
    dispatch(loadGroupByShortname({ shortname, ...accountOrServer }))
      .then(() => setLoadingGroups(false));
  }

  return group;
}

export const BaseGroupHomeScreen: React.FC<GroupHomeScreenProps> = ({ screenComponent }: GroupHomeScreenProps) => {
  const [inputShortname] = useParam('shortname');
  const group = useGroupFromPath(inputShortname);
  const { dispatch, accountOrServer } = useFederatedDispatch(group);


  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();

  return group
    ? screenComponent(group) //<BaseHomeScreen selectedGroup={group} />
    : <YStack w='100%' h='100%' ai='center' jc='center'>
      <Spinner my='auto' size='large' color={navColor} scale={2}
        top={dimensions.height / 2 - 50}
      />
    </YStack>
};
