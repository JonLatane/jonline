import { Button, formatError, Heading, Input, Paragraph, ServerConfiguration, TextArea, XStack, YStack } from '@jonline/ui'
import { isWeb, Permission, ScrollView, useWindowDimensions } from '@jonline/ui/src'
import { getCredentialClient, JonlineServer, RootState, selectServer, selectServerById, serverUrl, setAllowServerSelection, upsertServer, useTypedDispatch, useTypedSelector } from 'app/store'
import React, { useState } from 'react'
import { HexColorPicker } from "react-colorful"
import { Dimensions } from 'react-native';
import { createParam } from 'solito'
import { TabsNavigation } from '../tabs/tabs_navigation'
import ServerCard from './server_card'
import StickyBox from "react-sticky-box";

const { useParam } = createParam<{ id: string }>()

export function ServerDetailsScreen() {
  const [requestedServerUrl] = useParam('id')
  const requestedServerUrlParts = requestedServerUrl?.split(':')
  const requestedServerUrlValid = requestedServerUrlParts?.length == 2
    && ['http', 'https'].includes(requestedServerUrlParts[0]!);
  // debugger
  // const linkProps = useLink({ href: '/' })
  const dispatch = useTypedDispatch();
  const app = useTypedSelector((state: RootState) => state.app);
  const server: JonlineServer | undefined = useTypedSelector((state: RootState) => selectServerById(state.servers, requestedServerUrl!));
  const selectedServer = useTypedSelector((state: RootState) => state.servers.server);
  const account = useTypedSelector((state: RootState) => state.accounts.account);
  const serverIsSelected = server && selectedServer &&
    serverUrl(server) == serverUrl(selectedServer);
  const isAdmin = account && server && serverUrl(account.server) == serverUrl(server) &&
    account?.user?.permissions.includes(Permission.ADMIN);
  const [updating, setUpdating] = useState(false);
  const [updateError, setUpdateError] = useState('');

  const { serviceVersion, serverConfiguration } = server || {};

  const serverName = serverConfiguration?.serverInfo?.name;
  const [name, setName] = useState(serverName || '');
  if (serverName && name != serverName && name == '') {
    setName(serverName);
  }

  const serverDescription = serverConfiguration?.serverInfo?.description;
  const [description, setDescription] = useState(serverDescription || '');
  if (serverDescription && description != serverDescription && description == '') {
    setDescription(serverDescription);
  }

  const primaryColorInt = serverConfiguration?.serverInfo?.colors?.primary;
  const primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  const [primaryColorHex, setPrimaryColorHex] = useState(primaryColor);
  if (primaryColorHex != primaryColor && primaryColorHex == '#424242') {
    setPrimaryColorHex(primaryColor);
  }

  const navColorInt = serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;
  const [navColorHex, setNavColorHex] = useState(navColor);
  if (navColorHex != navColor && navColorHex == '#FFFFFF') {
    setNavColorHex(navColor);
  }

  async function updateServer() {
    setUpdating(true);
    setUpdateError('');
    //TODO: get the latest config and merge our changes into it?

    let newPrimaryColorInt = parseInt(primaryColorHex.slice(1), 16) + 0xFF000000;
    let newNavColorInt = parseInt(navColorHex.slice(1), 16) + 0xFF000000;

    let updatedConfiguration: ServerConfiguration = {
      ...serverConfiguration!,
      serverInfo: {
        ...serverConfiguration!.serverInfo,
        name,
        description,
        colors: {
          ...serverConfiguration!.serverInfo!.colors,
          primary: newPrimaryColorInt, navigation: newNavColorInt
        }
      }
    };

    let client = await getCredentialClient({ account });
    try {
      let returnedConfiguration = await client.configureServer(updatedConfiguration, client.credential);
      dispatch(upsertServer({ ...server!, serverConfiguration: returnedConfiguration }));
    } catch (e) {
      console.log(e);
      setUpdateError(formatError(e.message));
    } finally {
      setUpdating(false);
    }
  }

  const windowHeight = useWindowDimensions().height;
  return (
    <TabsNavigation onlyShowServer={server}>
      <YStack f={1} jc="center" ai="center" space w='100%'>
        {server ?
          <YStack mb='$2' w='100%' jc="center" ai="center" >
            <ScrollView w='100%'>
              <YStack space='$2' w='100%' maw={800} paddingHorizontal='$3' als='center'>
                {serverIsSelected ? undefined : <>
                  <Heading mt='$3' size='$3' als='center' color='yellow' ta='center'>Currently browsing on a different server</Heading>

                  <Heading whiteSpace="nowrap" maw={200} overflow='hidden' als='center' color='yellow' opacity={selectedServer?.serverConfiguration?.serverInfo?.name ? 1 : 0.5}>
                    {selectedServer?.serverConfiguration?.serverInfo?.name || 'Unnamed'}
                  </Heading>
                  <Heading size='$3' als='center' marginTop='$2' color='yellow'>
                    {selectedServer?.host}
                  </Heading>
                  <Button onPress={() => dispatch(selectServer(server))} mt='$3' theme='active' size='$3'>
                    Switch to&nbsp;<Heading size='$3'>{server.host}</Heading>
                  </Button>
                </>}
                <Heading size='$10' als='center' mt='$3'>Server Info</Heading>
                <ServerCard server={server!} />
                <XStack mt='$4'>
                  <Heading size='$3' f={1}>Service Version</Heading>
                  <Paragraph>{serviceVersion?.version}</Paragraph>
                </XStack>
                <Heading size='$3'>Name</Heading>
                {isAdmin
                  ? <Input value={name} placeholder='The name of your community.' onChangeText={t => setName(t)} />
                  : <Heading opacity={name && name != '' ? 1 : 0.5}>{name || 'Unnamed'}</Heading>}
                <Heading size='$3'>Description</Heading>
                {isAdmin ?
                  <TextArea value={description} onChangeText={t => setDescription(t)}
                    placeholder='A description of the purpose of your community, any general guidelines, etc.' />
                  : <Paragraph opacity={name && name != '' ? 1 : 0.5}>{description || 'No description set.'}</Paragraph>}

                <XStack>
                  <Heading size='$3' f={1}>Primary Color</Heading>
                  <XStack w={50} h={30} backgroundColor={primaryColorHex} />
                </XStack>
                {isAdmin ? <XStack als='center'>
                  <HexColorPicker color={primaryColorHex} onChange={setPrimaryColorHex} />
                </XStack> : undefined}

                <XStack>
                  <Heading size='$3' f={1}>Navigation Color</Heading>
                  <XStack w={50} h={30} backgroundColor={navColorHex} />
                </XStack>
                {isAdmin ? <XStack als='center'>
                  <HexColorPicker color={navColorHex} onChange={setNavColorHex} />
                </XStack> : undefined}

                {isWeb && isAdmin ? <YStack h={50} /> : undefined}
              </YStack>
            </ScrollView>

            {isAdmin ?
              isWeb ? <StickyBox bottom offsetBottom={0} style={{ width: '100%' }}>
                <YStack w='100%' paddingVertical='$2' backgroundColor='$background' alignContent='center'>
                  <Button maw={600} als='center' backgroundColor={primaryColor} onPress={updateServer} disabled={updating} opacity={updating ? 0.5 : 1}>Update Server</Button>
                </YStack>
              </StickyBox>
                : <Button maw={600} mt='$3' als='center' backgroundColor={primaryColor} onPress={updateServer} disabled={updating} opacity={updating ? 0.5 : 1}>Update Server</Button>
              : undefined}

          </YStack>
          : app.allowServerSelection || serverIsSelected ? <>
            <Heading ta="center" fow="800">Server not configured. Add it through your Accounts screen, or autoconfigure it, first.</Heading>
            <Paragraph ta="center" fow="800">{`Server URL: ${requestedServerUrl}`}</Paragraph>
            {requestedServerUrlValid ? <Button theme='active' mt='$2' onPress={() => {
              let [newServerProtocol, newServerHost] = requestedServerUrlParts;
              let newServerSecure = newServerProtocol == 'https';
              dispatch(upsertServer({
                host: newServerHost!,
                secure: newServerSecure,
              }));
            }}>
              Autoconfigure Server <Heading size='$3'>{requestedServerUrl}</Heading>
            </Button>
              : <>
                <Heading color='yellow' size='$3' ta={'center'}>Server URL is invalid.</Heading>
                <Heading color='yellow' size='$3' ta={'center'}>Server URL format: [http|https]:valid_hostname</Heading>
              </>}
          </> :
            <>
              <Heading ta="center" fow="800">Enable "Allow Server Selection" in your settings to continue.</Heading>
              <Paragraph ta="center" fow="800">{`Server URL: ${requestedServerUrl}`}</Paragraph>
              <Button theme='active' mt='$2' onPress={() => dispatch(setAllowServerSelection(true))}>
                Enable "Allow Server Selection"
              </Button>
            </>}
        {/* <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button> */}
      </YStack>
    </TabsNavigation>
  )
}
