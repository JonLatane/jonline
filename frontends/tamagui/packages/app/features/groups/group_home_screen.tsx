import { GetGroupsRequest, Group } from '@jonline/api'
import { Spinner, YStack, useWindowDimensions } from '@jonline/ui'
import { useCredentialDispatch, useFederatedDispatch, useServer } from 'app/hooks'
import { FederatedGroup, RootState, federateId, loadGroupsPage, parseFederatedId, selectGroupById, useRootSelector, useServerTheme } from 'app/store'
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

export const BaseGroupHomeScreen: React.FC<GroupHomeScreenProps> = ({ screenComponent }: GroupHomeScreenProps) => {
  const [inputShortname] = useParam('shortname');
  const currentServer = useServer();
  const { id: shortname, serverHost } = parseFederatedId(inputShortname ?? '', currentServer?.host);
  const federatedShortname = federateId(shortname, serverHost);
  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const shortnameIds = useRootSelector((state: RootState) => state.groups.shortnameIds);
  const groupId = shortnameIds[federatedShortname!];
  const group = useRootSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const [loadingGroups, setLoadingGroups] = useState(false);

  useEffect(() => {
    if (!group && !loadingGroups) {
      setLoadingGroups(true);
      reloadGroups();
    }
  }, [loadingGroups, group]);

  function reloadGroups() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(loadGroupsPage({ ...accountOrServer, ...GetGroupsRequest.create() }))
        .then(() => setLoadingGroups(false)), 1);
  }

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
