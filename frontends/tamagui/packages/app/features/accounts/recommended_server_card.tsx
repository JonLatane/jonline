import { Button, Card, Dialog, Heading, Paragraph, Theme, XStack, YStack } from "@jonline/ui";
import { Info, Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import { store, JonlineServer, removeAccount, removeServer, RootState, selectAccount, selectAllAccounts, selectServer, serverID, useTypedDispatch, useTypedSelector, accountId, serversAdapter, upsertServer, getServerClient, setAllowServerSelection, useLocalApp } from 'app/store';
import React, { useEffect } from "react";
import { useLink } from "solito/link";
import { ServerNameAndLogo } from "../tabs/server_name_and_logo";
import ServerCard from "./server_card";

interface Props {
  host: string;
  // server: JonlineServer;
  isPreview?: boolean;
  linkToServerInfo?: boolean;
  disableHeightLimit?: boolean;
}

export const RecommendedServerCard: React.FC<Props> = ({ host, isPreview = false, disableHeightLimit }) => {
  const dispatch = useTypedDispatch();
  const existingServer = useTypedSelector(
    (state: RootState) => serversAdapter.getSelectors().selectAll(state.servers)).find(server => server.host == host
    );
  const forceUpdate = React.useReducer(() => ({}), {})[1] as () => void

  const [loadingClient, setLoadingClient] = React.useState(false);

  const { allowServerSelection } = useLocalApp();
  const pendingServer = {
    host,
    secure: true,
  };
  async function addServer() {
    setLoadingClient(true);
    dispatch(upsertServer(pendingServer)).then(async () => {
      await getServerClient(pendingServer).then(_client => {
        console.log("Got server client", _client);
        setLoadingClient(false);
      });
    });
  }
  return <YStack px='$3' space='$2'>
    <XStack flexWrap="wrap">
      <Heading size='$1' mr='auto' pr='$3'>Recommended Server:</Heading>
      <Heading size='$1' ml='auto'>{host}</Heading>
    </XStack>
    {existingServer
      ? <>
        <ServerCard server={existingServer} isPreview={isPreview}
          disableHeightLimit={disableHeightLimit} linkToServerInfo />
        {/* <Paragraph size='$1' mt='$1' mb='$1'>
          This server is already in your server list.
        </Paragraph> */}
      </>
      : allowServerSelection
        ? <>
          <Button theme='active' mt='$2' disabled={loadingClient} o={loadingClient ? 0.5 : 1}
            onPress={addServer}>
            Add Server <Heading size='$3'>{host}</Heading>
          </Button>
          <Paragraph size='$1' mt='$1' mb='$1'>
            This server is not yet in your server list.
          </Paragraph>
        </>
        : <><Button theme='active' mt='$2' onPress={() => dispatch(setAllowServerSelection(true))}>
          Enable "Allow Server Selection"
        </Button>

          <Paragraph size='$1' mt='$1' mb='$1'>
            Server selection is not enabled. Enable it to add this server.
          </Paragraph>
        </>}
  </YStack>
  // return <ServerCard server={server} isPreview={isPreview} disableHeightLimit={disableHeightLimit} linkToServerInfo={true} />;
};

export default RecommendedServerCard;
