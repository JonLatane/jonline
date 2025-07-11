import { Button, Heading, Paragraph, XStack, YStack } from "@jonline/ui";
import { ExternalLink } from "@tamagui/lucide-icons";
import { Selector, useAppDispatch, useAppSelector, useLocalConfiguration } from 'app/hooks';
import { JonlineServer, RootState, colorIntMeta, getServerClient, pinServer, serverID, serversAdapter, setAllowServerSelection, setBrowsingServers, store, upsertServer, useRootSelector } from 'app/store';
import React, { useEffect } from "react";
import { useLink } from "solito/link";
import { ServerNameAndLogo } from "../navigation/server_name_and_logo";
import { createSelector } from "@reduxjs/toolkit";

interface Props {
  host: string;
  tiny?: boolean;
  isPreview?: boolean;
  linkToServerInfo?: boolean;
  disableHeightLimit?: boolean;
  pinAfterAdding?: boolean;
}

const recommendedServerCache = new Map<string, any>();

export type JonlineServerInfo = {
  server: JonlineServer;
  existingServer: JonlineServer | undefined;
  pendingServer: JonlineServer | undefined;
  prototypeServer: JonlineServer;
}

const selectPinnedAccountsAndServers = (
  host: string
): Selector<JonlineServer | undefined> =>
  createSelector(
    [state => serversAdapter.getSelectors().selectAll(state.servers).find(server => server.host == host)],
    (data) => data
  );

export function useJonlineServerInfo(host: string): JonlineServerInfo {
  const existingServer: JonlineServer | undefined = useAppSelector(selectPinnedAccountsAndServers(host));
  const prototypeServer: JonlineServer = {
    host,
    secure: true,
  };

  const [pendingServer, setPendingServer] = React.useState(existingServer);
  const [loadingPendingServer, setLoadingPendingServer] = React.useState(false);
  const [loadedPendingServer, setLoadedPendingServer] = React.useState(false);
  useEffect(() => {
    if (!existingServer && !pendingServer && !loadingPendingServer && !loadedPendingServer) {
      setLoadingPendingServer(true);
      if (recommendedServerCache.has(host)) {
        setPendingServer(recommendedServerCache.get(host));
      } else {
        getServerClient(
          prototypeServer,
          {
            skipUpsert: true,
            onServerConfigured: (server) => {
              recommendedServerCache.set(host, server);
              setPendingServer(server);
            }
          }).then(_client => {
            setLoadedPendingServer(true);
            setLoadingPendingServer(false);
            // console.log("Got pending server", _client);
          });
      }
    }
  }, [existingServer === undefined, pendingServer === undefined, loadingPendingServer, loadedPendingServer]);

  return { existingServer, pendingServer, prototypeServer, server: existingServer ?? pendingServer ?? prototypeServer };
}
export const RecommendedServer: React.FC<Props> = ({ host, isPreview = false, disableHeightLimit = false, tiny = false, pinAfterAdding = false }) => {
  const dispatch = useAppDispatch();
  const [addingServer, setAddingServer] = React.useState(false);

  const { server, existingServer } = useJonlineServerInfo(host);

  const { allowServerSelection, browsingServers } = useLocalConfiguration();
  async function addServer() {
    if (addingServer) return;

    setAddingServer(true);
    if (!allowServerSelection) {
      dispatch(setAllowServerSelection(true));
    }
    if (!browsingServers) {
      dispatch(setBrowsingServers(true));
    }
    // dispatch(upsertServer(prototypeServer)).then(async () => {
    // debugger;
    await getServerClient(server, { skipUpsert: false }).then(_client => {
      console.log("Got server client", _client);
      // setTimeout(() => {
      store.dispatch(pinServer({ serverId: serverID(server), pinned: true }));
      setAddingServer(false);
      // }, 1500);
    });

    // });
  }

  const externalLink = useLink({ href: `https://${host}` });

  const { color: buttonBackgroundColor, textColor: buttonTextColor } = colorIntMeta(server?.serverConfiguration?.serverInfo?.colors?.primary ?? 0x424242);
  return <YStack px='$3' gap='$2'>
    {/* {tiny
      ? */}
    <XStack>
      <XStack f={1} overflow='hidden' mx='auto' my='auto'>
        <ServerNameAndLogo server={server} />
      </XStack>
      <Button icon={ExternalLink} target='_blank' circular my='auto' {...externalLink} />
    </XStack>
    {/* :
      <ServerCard server={existingServer ?? pendingServer ?? prototypeServer} isPreview={isPreview}
        disableHeightLimit={disableHeightLimit} disableFooter disablePress />
    } */}
    {existingServer ? undefined
      : <Button mt='$2' disabled={addingServer} o={addingServer ? 0.5 : 1}
        backgroundColor={buttonBackgroundColor} color={buttonTextColor}
        hoverStyle={{ backgroundColor: buttonBackgroundColor }}
        onPress={() => requestAnimationFrame(addServer)}>

        {tiny ? <YStack gap='$0' ai='center'>
          <Paragraph color={buttonTextColor} lineHeight='$1' size='$1' my='auto'>Add</Paragraph>
          <Heading color={buttonTextColor} lineHeight='$1' size='$2' my='auto'>{host}</Heading>
        </YStack> : <XStack gap='$2' ai='center'>
          <Paragraph color={buttonTextColor} size='$2' my='auto'>Add</Paragraph>
          <Heading color={buttonTextColor} size='$3' my='auto'>{host}</Heading>
        </XStack>}
      </Button>}
    {/* {existingServer
      ?
      tiny
        ? <ServerNameAndLogo server={existingServer} />
        : <>
          <ServerCard server={existingServer} isPreview={isPreview}
            disableHeightLimit={disableHeightLimit} linkToServerInfo disablePress />
        </>
      : <>
        {tiny
          ? <XStack overflow='hidden' mx='auto'> <ServerNameAndLogo server={pendingServer} />
          </XStack>
          :
          <ServerCard server={pendingServer ?? prototypeServer} isPreview={isPreview}
            disableHeightLimit={disableHeightLimit} disableFooter disablePress />
        }
        <Button mt='$2' disabled={loadingClient} o={loadingClient ? 0.5 : 1}
          backgroundColor={buttonBackgroundColor} color={buttonTextColor}
          hoverStyle={{ backgroundColor: buttonBackgroundColor }}
          onPress={addServer}>

          {tiny ? <YStack gap='$0' ai='center'>
            <Paragraph color={buttonTextColor} lineHeight='$1' size='$1' my='auto'>Add</Paragraph>
            <Heading color={buttonTextColor} lineHeight='$1' size='$2' my='auto'>{host}</Heading>
          </YStack> : <XStack gap='$2' ai='center'>
            <Paragraph color={buttonTextColor} size='$2' my='auto'>Add</Paragraph>
            <Heading color={buttonTextColor} size='$3' my='auto'>{host}</Heading>
          </XStack>}
        </Button>
      </>} */}
  </YStack>
};

export default RecommendedServer;
