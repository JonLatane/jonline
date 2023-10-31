import { Button, Heading, YStack } from "@jonline/ui";
import { RootState, getServerClient, serversAdapter, setAllowServerSelection, upsertServer, useLocalApp, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useEffect } from "react";
import { ServerNameAndLogo } from "../tabs/server_name_and_logo";
import ServerCard from "./server_card";

interface Props {
  host: string;
  tiny?: boolean;
  isPreview?: boolean;
  linkToServerInfo?: boolean;
  disableHeightLimit?: boolean;
}

export const RecommendedServerCard: React.FC<Props> = ({ host, isPreview = false, disableHeightLimit, tiny = false }) => {
  const dispatch = useTypedDispatch();
  const existingServer = useTypedSelector(
    (state: RootState) => serversAdapter.getSelectors().selectAll(state.servers)).find(server => server.host == host
    );
  const prototypeServer = {
    host,
    secure: true,
  };
  const [pendingServer, setPendingServer] = React.useState(existingServer);
  const [loadingPendingServer, setLoadingPendingServer] = React.useState(false);
  const [loadedPendingServer, setLoadedPendingServer] = React.useState(false);
  useEffect(() => {
    if (!existingServer && !pendingServer && !loadingPendingServer && !loadedPendingServer) {
      setLoadingPendingServer(true);
      getServerClient(
        prototypeServer,
        {
          skipUpsert: true,
          onServerConfigured: setPendingServer
        }).then(_client => {
          console.log("Got pending server", _client);
          setLoadedPendingServer(true);
          setLoadingPendingServer(false);
        });
    }
  }, [existingServer === undefined, pendingServer === undefined, loadingPendingServer, loadedPendingServer]);

  const [loadingClient, setLoadingClient] = React.useState(false);

  const { allowServerSelection } = useLocalApp();
  async function addServer() {
    setLoadingClient(true);
    if (!allowServerSelection) {
      dispatch(setAllowServerSelection(true));
    }
    dispatch(upsertServer(prototypeServer)).then(async () => {
      await getServerClient(prototypeServer).then(_client => {
        console.log("Got server client", _client);
        setLoadingClient(false);
      });
    });
  }
  return <YStack px='$3' space='$2'>
    {existingServer
      ?
      tiny
        ? <ServerNameAndLogo server={existingServer} />
        : <>
          <ServerCard server={existingServer} isPreview={isPreview}
            disableHeightLimit={disableHeightLimit} linkToServerInfo disablePress />
        </>
      : <>
        <ServerCard server={pendingServer ?? prototypeServer} isPreview={isPreview}
          disableHeightLimit={disableHeightLimit} disableFooter linkToServerInfo disablePress />
        <Button theme='active' mt='$2' disabled={loadingClient} o={loadingClient ? 0.5 : 1}
          onPress={addServer}>
          Add <Heading size='$3'>{host}</Heading>
        </Button>
      </>}
  </YStack>
};

export default RecommendedServerCard;
