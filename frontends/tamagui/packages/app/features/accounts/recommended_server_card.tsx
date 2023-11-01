import { Button, Heading, Paragraph, XStack, YStack } from "@jonline/ui";
import { RootState, colorIntMeta, getServerClient, serversAdapter, setAllowServerSelection, upsertServer, useLocalApp, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
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

  const { color: buttonBackgroundColor, textColor: buttonTextColor } = colorIntMeta(pendingServer?.serverConfiguration?.serverInfo?.colors?.primary ?? 0x424242);
  return <YStack px='$3' space='$2'>
    {tiny
      ? <XStack overflow='hidden' mx='auto'> <ServerNameAndLogo server={existingServer ?? pendingServer ?? prototypeServer} />
      </XStack>
      :
      <ServerCard server={existingServer ?? pendingServer ?? prototypeServer} isPreview={isPreview}
        disableHeightLimit={disableHeightLimit} disableFooter disablePress />
    }
    {existingServer ? undefined
      : <Button mt='$2' disabled={loadingClient} o={loadingClient ? 0.5 : 1}
        backgroundColor={buttonBackgroundColor} color={buttonTextColor}
        hoverStyle={{ backgroundColor: buttonBackgroundColor }}
        onPress={addServer}>

        {tiny ? <YStack space='$0' ai='center'>
          <Paragraph color={buttonTextColor} lineHeight='$1' size='$1' my='auto'>Add</Paragraph>
          <Heading color={buttonTextColor} lineHeight='$1' size='$2' my='auto'>{host}</Heading>
        </YStack> : <XStack space='$2' ai='center'>
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

          {tiny ? <YStack space='$0' ai='center'>
            <Paragraph color={buttonTextColor} lineHeight='$1' size='$1' my='auto'>Add</Paragraph>
            <Heading color={buttonTextColor} lineHeight='$1' size='$2' my='auto'>{host}</Heading>
          </YStack> : <XStack space='$2' ai='center'>
            <Paragraph color={buttonTextColor} size='$2' my='auto'>Add</Paragraph>
            <Heading color={buttonTextColor} size='$3' my='auto'>{host}</Heading>
          </XStack>}
        </Button>
      </>} */}
  </YStack>
};

export default RecommendedServerCard;
