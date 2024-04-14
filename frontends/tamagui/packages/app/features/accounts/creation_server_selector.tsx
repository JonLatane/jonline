import { Button, Paragraph, reverseHorizontalAnimation, ScrollView, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronLeft, ExternalLink, SeparatorVertical } from '@tamagui/lucide-icons';
import { useAppDispatch, useCreationServer, usePinnedAccountsAndServers, useCurrentServer, useComponentKey, useAppSelector } from 'app/hooks';
import { JonlineServer, RootState, selectAllServers, serverID, useRootSelector } from 'app/store';
import React from 'react';
import FlipMove from 'react-flip-move';
import { useLink } from 'solito/link';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { Permission } from '@jonline/api';
import { ShortAccountSelectorButton } from '../navigation/pinned_server_selector';


export type CreationServerSelectorProps = {
  server?: JonlineServer;
  onPressBack?: () => void;
  requiredPermissions?: Permission[];
  showUser?: boolean;
};

export const CreationServerSelector: React.FC<CreationServerSelectorProps> = ({
  server: taggedServer,
  onPressBack,
  requiredPermissions,
  showUser
}) => {
  const dispatch = useAppDispatch();
  const mediaQuery = useMedia();

  const { creationServer: creationServer, setCreationServer: setCreationServer } = useCreationServer();

  const currentServer = useCurrentServer();
  const server = taggedServer ?? creationServer ?? currentServer;
  const isCurrentServer = server?.host == currentServer?.host;
  const serverLink = useLink({ href: server ? `http://${server.host}` : '' });

  const disabled = !!taggedServer;

  const availableServers = useAvailableCreationServers(requiredPermissions);
  const [pl, pr] = onPressBack
    ? [mediaQuery.gtXs ? '$2' : 0, mediaQuery.gtXs ? '$4' : '$1']
    : ['$2', '$2'];
  const selectorTopKey = useComponentKey('creation-server-selector-top');
  const onSelectServer = (otherServer: JonlineServer) => {
    dispatch(setCreationServer(otherServer));
    setTimeout(() => {
      document.getElementById(selectorTopKey)?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };
  const pinnedServer = useAppSelector(state => state.accounts.pinnedServers.find(s => server && s.serverId === serverID(server)));

  const serverNameAndLogo = <YStack>
    {showUser && creationServer
      ? <ShortAccountSelectorButton {...{ server: creationServer, pinnedServer }} />
      : undefined}
    <ServerNameAndLogo server={server} />
  </YStack>;
  const serverView = isCurrentServer
    ? serverNameAndLogo
    : <Button maxWidth='100%' h='auto' ml='$1' p='$1' transparent iconAfter={ExternalLink} target='_blank' {...serverLink}>
      <XStack ai='center'>
        {serverNameAndLogo}
      </XStack>
    </Button>;

  return <XStack ai='center'
    pl={pl}
    pr={pr}>
    {onPressBack
      ? <Button
        // alignSelf='center'
        // my='auto'
        size="$2"
        ml='$2'
        circular
        icon={ChevronLeft}
        // mb='$2'
        onPress={onPressBack} />
      : undefined}
    <ScrollView horizontal f={1}>
      <FlipMove style={{ display: 'flex', flexDirection: 'row', alignItems: 'center' }}>
        <div id={selectorTopKey} key={selectorTopKey} />
        {server
          ? <div id='accounts-sheet-currently-adding-server'
            key={`serverCard-${serverID(server)}`}
            style={{ margin: 2 }}>
            {serverView}
            {/* <ServerNameAndLogo server={addAccountServer} /> */}
          </div>
          : undefined}
        {availableServers && availableServers.length > 1 && !disabled
          ? <div key='separator' style={{ margin: 2 }}>
            <SeparatorVertical size='$1' />
          </div>
          : undefined}
        {disabled
          ? undefined
          : availableServers.filter(s => s.host != server?.host)
            .map((otherServer, index) => <div key={`serverCard-${serverID(otherServer)}`} style={{ margin: 2 }}>
              <Button onPress={() => onSelectServer(otherServer)}>
                <ServerNameAndLogo server={otherServer} />
              </Button>
            </div>
            )}
      </FlipMove>
    </ScrollView>
    {isCurrentServer
      ? undefined :
      <XStack ai='center' animation='standard' {...reverseHorizontalAnimation} o={0.5} >
        <Paragraph ml='$2' size='$1'> via</Paragraph>
        <XStack>
          <ServerNameAndLogo server={currentServer} />
        </XStack>
      </XStack>
    }
  </XStack>;
}

export function useAvailableCreationServers(requiredPermissions: Permission[] | undefined) {
  const accountsAndServers = usePinnedAccountsAndServers({ includeUnpinned: true });
  const servers = useRootSelector((state: RootState) => selectAllServers(state.servers)); //.servers.ids.map(id => state.servers.entities[id]));

  return requiredPermissions
    ? servers.filter(server => {
      const account = accountsAndServers.find(aos => aos.server?.host === server.host)?.account;

      return account &&
        !requiredPermissions.some(p => !account.user.permissions.includes(p));
    }) : servers;
}

