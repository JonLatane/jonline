import { Paragraph, Spinner, XStack, YStack, useWindowDimensions } from '@jonline/ui'
import { useAppSelector, useCurrentServer, useFederatedDispatch } from 'app/hooks'
import { FederatedGroup, federateId, loadGroupByShortname, parseFederatedId, selectGroupById, useServerTheme } from 'app/store'
import React, { useEffect, useState } from 'react'
import { createParam } from 'solito'
import { BaseHomeScreen } from '../home/home_screen'
import { set } from 'immer/dist/internal'
import { useJonlineServerInfo } from '../accounts/recommended_server'
import { ServerNameAndLogo } from '../navigation/server_name_and_logo'

const { useParam, useUpdateParams } = createParam<{ shortname: string }>()

export type GroupHomeScreenProps = {
  screenComponent: (group: FederatedGroup) => React.JSX.Element;
}

export function GroupHomeScreen() {
  return <BaseGroupHomeScreen
    screenComponent={
      (group) => <BaseHomeScreen key={group.id} selectedGroup={group} />
    } />;
}

export type GroupFromPath = {
  group: FederatedGroup | undefined;
  loading: boolean;
  failedToLoad: boolean;
  // The shortname from the path, which should always case-insensitively match the group's shortname.
  pathShortname: string | undefined;
  serverHost: string | undefined;
};

export function useGroupFromPath(): GroupFromPath {
  const [inputShortname] = useParam('shortname');
  const updateParams = useUpdateParams();
  const result = useGroupFromShortname(inputShortname);
  const currentServer = useCurrentServer();
  const resultShortname = result.group
    ? result.group.serverHost === currentServer?.host
      ? result.group?.shortname
      : federateId(result.group?.shortname ?? '', result.serverHost)
    : undefined;
  console.log("resultShortname", resultShortname);
  useEffect(() => {
    if (resultShortname && resultShortname !== inputShortname) {
      setTimeout(
        () => updateParams({ shortname: resultShortname }, { web: { replace: true } }),
        1
      );
    }
  }, [inputShortname, resultShortname]);
  return result;
}

function useGroupFromShortname(inputShortname: string | undefined): GroupFromPath {
  const { id: shortname, serverHost } = parseFederatedId(inputShortname ?? '', useCurrentServer()?.host);
  const federatedShortname = federateId(shortname, serverHost);

  const shortnameIds = useAppSelector(state => state.groups.shortnameIds);
  const groupId = shortnameIds[federatedShortname!.toLowerCase()];
  const group = useAppSelector(state =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);

  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const [loading, setLoading] = useState(false);

  const [hasLoadedByShortname, setHasLoadedByShortname] = useState(false);
  useEffect(
    () => setHasLoadedByShortname(false),
    [shortname, serverHost, accountOrServer?.account?.user?.id]
  );
  useEffect(() => {
    if (shortname && !group && !loading && !hasLoadedByShortname && !!accountOrServer.server) {
      setLoading(true);
      // console.log("loading group data from server ", accountOrServer.server.host)
      dispatch(loadGroupByShortname({ shortname, ...accountOrServer }))
        .then(() => {
          setHasLoadedByShortname(true);
          setLoading(false);
        });
    }
  }, [shortname, loading, group, hasLoadedByShortname, !!accountOrServer.server]);

  return {
    group,
    loading,
    failedToLoad: !group && hasLoadedByShortname,
    pathShortname: inputShortname, serverHost
  };
}

export const BaseGroupHomeScreen: React.FC<GroupHomeScreenProps> = ({ screenComponent }: GroupHomeScreenProps) => {
  const currentServer = useCurrentServer();
  const { group, failedToLoad, pathShortname, serverHost } = useGroupFromPath();

  const { navColor, navAnchorColor } = useServerTheme();
  const dimensions = useWindowDimensions();


  const { existingServer, pendingServer, prototypeServer } = useJonlineServerInfo(serverHost ?? '');
  const groupServer = existingServer ?? pendingServer ?? prototypeServer;
  //<ServerNameAndLogo server={groupServer} />
  const showVia = groupServer && groupServer.host !== currentServer?.host;
  // const top = dimensions.height / 2 - 100 - (showVia ? 50 : 0);
  const serverStuff = <>
    <XStack mx='auto'>
      <ServerNameAndLogo server={groupServer} enlargeSmallText />
    </XStack>
    {showVia
      ? <XStack o={0.5} ai='center' gap='$2'>
        <Paragraph>via</Paragraph>
        <ServerNameAndLogo server={currentServer} />
      </XStack>
      : undefined}
  </>;
  // debugger;
  return group
    ? screenComponent(group!) //<BaseHomeScreen selectedGroup={group} />
    : <YStack my='auto' ai='center'>
      {serverStuff}
      {failedToLoad
        ? <Paragraph color={navAnchorColor}>
          Failed to load group "{pathShortname}."
          Please check the URL and try again.
        </Paragraph>
        : <>
          <XStack my='$5'>
            <Spinner my='auto' size='large' color={navColor} scale={2} />
          </XStack>
          <Paragraph color={navAnchorColor}>
            Loading group "{pathShortname}..."
          </Paragraph>
        </>}

    </YStack>
};
