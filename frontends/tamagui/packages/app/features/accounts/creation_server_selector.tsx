import { Button, Paragraph, ScrollView, useMedia, XStack } from '@jonline/ui';
import { ChevronLeft, ExternalLink, SeparatorVertical } from '@tamagui/lucide-icons';
import { useAppDispatch, useCreationServer, usePinnedAccountsAndServers, useCurrentServer } from 'app/hooks';
import { JonlineServer, RootState, selectAllServers, serverID, useRootSelector } from 'app/store';
import React from 'react';
import FlipMove from 'react-flip-move';
import { useLink } from 'solito/link';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { Permission } from '@jonline/api';


export type CreationServerSelectorProps = {
  server?: JonlineServer;
  onPressBack?: () => void;
  requiredPermissions?: Permission[];
};

export function CreationServerSelector({
  server: taggedServer,
  onPressBack,
  requiredPermissions
}: CreationServerSelectorProps) {
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
        {server
          ? <div id='accounts-sheet-currently-adding-server'
            key={`serverCard-${serverID(server)}`}
            style={{ margin: 2 }}>
            {isCurrentServer
              ? <ServerNameAndLogo server={server} />
              : <Button maxWidth='100%' h='auto' ml='$1' p='$1' transparent iconAfter={ExternalLink} target='_blank' {...serverLink}>
                <XStack ai='center'>
                  <ServerNameAndLogo server={server} />
                </XStack>
              </Button>}
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
            .map((server, index) => <div key={`serverCard-${serverID(server)}`} style={{ margin: 2 }}>
              <Button onPress={() => dispatch(setCreationServer(server))}>
                <ServerNameAndLogo server={server} />
              </Button>
            </div>
            )}
      </FlipMove>
    </ScrollView>
    <XStack f={1} ai='center' o={isCurrentServer ? 0 : 0.5}>
      <Paragraph ml='auto' size='$1'> via</Paragraph>
      <XStack>
        <ServerNameAndLogo server={currentServer} />
      </XStack>
    </XStack>
  </XStack>;
}
export function useAvailableCreationServers(requiredPermissions: Permission[] | undefined) {
  const accountsAndServers = usePinnedAccountsAndServers();
  const servers = useRootSelector((state: RootState) => selectAllServers(state.servers)); //.servers.ids.map(id => state.servers.entities[id]));

  return requiredPermissions
    ? servers.filter(server => {
      const account = accountsAndServers.find(aos => aos.server?.host === server.host)?.account;

      return account &&
        !requiredPermissions.some(p => !account.user.permissions.includes(p));
    }) : servers;
}

