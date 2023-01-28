import { Button, formatError, Heading, Input, Paragraph, ServerConfiguration, TextArea, XStack, YStack } from '@jonline/ui'
import { Permission } from '@jonline/ui/src'
import { ChevronLeft } from '@tamagui/lucide-icons'
import { getCredentialClient } from 'app/store/modules/accounts'
import { JonlineServer, selectServerById, serverUrl, upsertServer } from 'app/store/modules/servers'
import { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from 'app/store/store'
import React, { useState } from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TabsNavigation } from '../tabs/tabs_navigation'
import ServerCard from './server_card'

const { useParam } = createParam<{ id: string }>()

export function ServerDetailsScreen() {
  const [requestedServerUrl] = useParam('id')
  // const linkProps = useLink({ href: '/' })
  const dispatch = useTypedDispatch();
  const server: JonlineServer | undefined = useTypedSelector((state: RootState) => selectServerById(state.servers, requestedServerUrl!));
  const account = useTypedSelector((state: RootState) => state.accounts.account);
  const [name, setName] = useState(server?.serverConfiguration?.serverInfo?.name || '');
  const [description, setDescription] = useState(server?.serverConfiguration?.serverInfo?.description || '');
  const [updating, setUpdating] = useState(false);
  const [updateError, setUpdateError] = useState('');

  const isAdmin = account && server && serverUrl(account.server) == serverUrl(server) &&
    account?.user?.permissions.includes(Permission.ADMIN);

  const { serviceVersion, serverConfiguration } = server || {};
  let primaryColorInt = server?.serverConfiguration?.serverInfo?.colors?.primary;
  let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;

  async function updateServer() {
    setUpdating(true);
    setUpdateError('');
    //TODO: get the latest config and merge our changes into it?
    let updatedConfiguration: ServerConfiguration = {
      ...serverConfiguration!,
      serverInfo: { ...serverConfiguration!.serverInfo, name, description }
    };
    let client = await getCredentialClient({account});
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

  return (
    <TabsNavigation onlyShowServer={server}>
      <YStack f={1} jc="center" ai="center" space w='100%'>
        {server ?
          <YStack w='100%' maw={800} space='$2' paddingHorizontal='$3'>
            <ServerCard server={server!} />
            <XStack mt='$4'>
              <Heading size='$3' f={1}>Service Version</Heading>
              <Paragraph>{serviceVersion?.version}</Paragraph>
            </XStack>
            <Heading size='$3'>Name</Heading>
            {isAdmin
              ? <Input value={name} placeholder='The name of your community.' onChangeText={t => setName(t)} />
              : <Heading opacity={name && name != '' ? 1 : 0.5}>{name || 'Not set'}</Heading>}
            <Heading size='$3'>Description</Heading>
            {isAdmin ?
              <TextArea value={description} onChangeText={t => setDescription(t)}
                placeholder='A description of the purpose of your community, any general guidelines, etc.' />
              : <Paragraph opacity={name && name != '' ? 1 : 0.5}>{description || 'Not set'}</Paragraph>}
            {isAdmin ?<>
              <Button backgroundColor={primaryColor} onPress={updateServer} disabled={updating} opacity={updating ? 0.5 : 1}>Update Server</Button>
              <Heading size='$1' color='red'>{}</Heading>
              </>
              : undefined}
          </YStack>
          : <>
            <Heading ta="center" fow="800">Server not configured. Add it through your Accounts screen first.</Heading>
            <Paragraph ta="center" fow="800">{`Server URL: ${requestedServerUrl}`}</Paragraph
            ></>}
        {/* <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button> */}
      </YStack>
    </TabsNavigation>
  )
}
