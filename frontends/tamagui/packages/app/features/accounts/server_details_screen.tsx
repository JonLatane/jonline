import { Permission, ServerConfiguration } from '@jonline/api'
import { Button, Heading, Input, Paragraph, ScrollView, TextArea, XStack, YStack, formatError, isWeb, useWindowDimensions } from '@jonline/ui'
import { Info } from '@tamagui/lucide-icons'
import { JonlineServer, RootState, getCredentialClient, selectServer, selectServerById, serverID, setAllowServerSelection, upsertServer, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store'
import React, { useState } from 'react'
import { HexColorPicker } from "react-colorful"
import StickyBox from "react-sticky-box"
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { colorMeta } from '../../store'
import { TamaguiMarkdown } from '../post/tamagui_markdown'
import { AppSection } from '../tabs/features_navigation'
import { TabsNavigation } from '../tabs/tabs_navigation'
import { PermissionsEditor, PermissionsEditorProps } from '../user/permissions_editor'
import ServerCard from './server_card'

const { useParam } = createParam<{ id: string }>()

export function ServerDetailsScreen() {
  return BaseServerDetailsScreen();
}

export function BaseServerDetailsScreen(specificServer?: string) {
  const [requestedServerUrl] = specificServer ? [specificServer] : useParam('id');
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
    serverID(server) == serverID(selectedServer);
  const isAdmin = account && server && serverID(account.server) == serverID(server) &&
    account?.user?.permissions.includes(Permission.ADMIN);
  const [updating, setUpdating] = useState(false);
  const [updateError, setUpdateError] = useState('');
  const aboutJonlineLink = useLink({ href: '/about_jonline' })

  const { serviceVersion, serverConfiguration } = server || {};
  const [_, githubVersion] = serviceVersion?.version?.split('-') ?? [];
  const githubLink = useLink({ href: `https://github.com/JonLatane/jonline/commit/${githubVersion}`});

  const serverName = serverConfiguration?.serverInfo?.name;
  const [name, setName] = useState(serverName || undefined);
  if (serverName && name != serverName && name == undefined) {
    setName(serverName);
  }

  const serverDescription = serverConfiguration?.serverInfo?.description;
  const [description, setDescription] = useState(serverDescription || undefined);
  if (serverDescription && description != serverDescription && description == undefined) {
    setDescription(serverDescription);
  }

  const primaryColorInt = serverConfiguration?.serverInfo?.colors?.primary ?? 0x424242;
  const primaryColor = `#${primaryColorInt.toString(16).slice(-6)}`;
  const [primaryColorHex, setPrimaryColorHex] = useState(primaryColor);
  if (primaryColorHex != primaryColor && primaryColorHex == '#424242') {
    setPrimaryColorHex(primaryColor);
  }

  const navColorInt = serverConfiguration?.serverInfo?.colors?.navigation ?? 0xFFFFFF;
  const navColor = `#${navColorInt.toString(16).slice(-6)}`;
  const [navColorHex, setNavColorHex] = useState(navColor);
  if (navColorHex != navColor && navColorHex == '#FFFFFF') {
    setNavColorHex(navColor);
  }
  const { textColor: primaryTextColor } = colorMeta(primaryColor);
  const { textColor: navTextColor } = colorMeta(navColor);
  const { warningAnchorColor } = useServerTheme();

  const serverDefaultPermissions = serverConfiguration?.defaultUserPermissions;
  const [_defaultPermissions, setDefaultPermissions] = useState(serverDefaultPermissions);
  if (serverDefaultPermissions && _defaultPermissions == undefined) {
    setDefaultPermissions(serverDefaultPermissions);
  }
  const defaultPermissions = _defaultPermissions || [];
  function selectDefaultPermission(permission: Permission) {
    if (defaultPermissions.includes(permission)) {
      setDefaultPermissions(defaultPermissions.filter(p => p != permission));
    } else {
      setDefaultPermissions([...defaultPermissions, permission]);
    }
  }
  function deselectDefaultPermission(permission: Permission) {
    setDefaultPermissions(defaultPermissions.filter(p => p != permission));
  }
  const configurableUserPermissions = [
    Permission.VIEW_USERS,
    Permission.PUBLISH_USERS_LOCALLY,
    Permission.PUBLISH_USERS_GLOBALLY,
    Permission.VIEW_GROUPS,
    Permission.CREATE_GROUPS,
    Permission.VIEW_MEDIA,
    Permission.CREATE_MEDIA,
    Permission.PUBLISH_MEDIA_LOCALLY,
    Permission.PUBLISH_MEDIA_GLOBALLY,
    Permission.PUBLISH_GROUPS_LOCALLY,
    Permission.PUBLISH_GROUPS_GLOBALLY,
    Permission.JOIN_GROUPS,
    Permission.VIEW_POSTS,
    Permission.CREATE_POSTS,
    Permission.PUBLISH_POSTS_LOCALLY,
    Permission.PUBLISH_POSTS_GLOBALLY,
    Permission.VIEW_EVENTS,
    Permission.CREATE_EVENTS,
    Permission.PUBLISH_EVENTS_LOCALLY,
    Permission.PUBLISH_EVENTS_GLOBALLY,
  ];
  const defaultPermissionsEditorProps: PermissionsEditorProps = {
    selectablePermissions: configurableUserPermissions,
    selectedPermissions: defaultPermissions,
    selectPermission: selectDefaultPermission,
    deselectPermission: deselectDefaultPermission,
    editMode: isAdmin ?? false
  };

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
    <TabsNavigation appSection={AppSection.INFO} onlyShowServer={server}>
      <YStack f={1} jc="center" ai="center" space w='100%'>
        {server ?
          <YStack mb='$2' w='100%' jc="center" ai="center" >
            <ScrollView w='100%'>
              <YStack space='$2' w='100%' maw={800} paddingHorizontal='$3' als='center' marginHorizontal='auto'>
                {serverIsSelected ? undefined : <>
                  <Heading mt='$3' size='$3' als='center' color={warningAnchorColor} ta='center'>Currently browsing on a different server</Heading>

                  <Heading whiteSpace="nowrap" maw={200} overflow='hidden' als='center' color={warningAnchorColor} opacity={selectedServer?.serverConfiguration?.serverInfo?.name ? 1 : 0.5}>
                    {selectedServer?.serverConfiguration?.serverInfo?.name || 'Unnamed'}
                  </Heading>
                  <Heading size='$3' als='center' marginTop='$2' color={warningAnchorColor}>
                    {selectedServer?.host}
                  </Heading>
                  <Button onPress={() => dispatch(selectServer(server))} mt='$3' theme='active' size='$3'>
                    Switch to&nbsp;<Heading size='$3'>{server.host}</Heading>
                  </Button>
                </>}
                <Heading size='$10' als='center' mt='$3'>{specificServer ? 'Community' : 'Server'} Information</Heading>
                <ServerCard server={server!} />
                <XStack mt='$4'>
                  <Heading size='$3' f={1}>Service Version</Heading>
                  <Paragraph>{serviceVersion?.version}</Paragraph>
                </XStack>
                {githubVersion
                  ? <Button {...githubLink} mt='$3' backgroundColor={navColor} hoverStyle={{ backgroundColor: navColor }} pressStyle={{ backgroundColor: navColor }} color={navTextColor} size='$3' iconAfter={Info}>
                    <Heading size='$2' color={navTextColor}>View {githubVersion} on GitHub</Heading>
                  </Button>
                  : undefined}
                <Heading size='$3'>Name</Heading>
                {isAdmin
                  ? <Input value={name ?? ''} placeholder='The name of your community.' onChangeText={t => setName(t)} />
                  : <Heading opacity={name && name != '' ? 1 : 0.5}>{name || 'Unnamed'}</Heading>}
                <Heading size='$3'>Description</Heading>
                {isAdmin ?
                  <TextArea value={description ?? ''} onChangeText={t => setDescription(t)} h='$14'
                    placeholder='A description of the purpose of your community, any general guidelines, etc.' />
                  : description && description != ''
                    ? <TamaguiMarkdown text={description} />
                    : <Paragraph opacity={0.5}>No description set.</Paragraph>}

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
                {<PermissionsEditor label='Default Permissions'
                  {...defaultPermissionsEditorProps} />}


                <Button {...aboutJonlineLink} mt='$3' backgroundColor={navColor} hoverStyle={{ backgroundColor: navColor }} pressStyle={{ backgroundColor: navColor }} color={navTextColor} size='$3' iconAfter={Info}>
                  <Heading size='$2' color={navTextColor}>About Jonline...</Heading>
                </Button>

                {isWeb && isAdmin ? <YStack h={50} /> : undefined}
              </YStack>
            </ScrollView>

            {isAdmin ?
              isWeb ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%', zIndex: 10 }}>
                <YStack w='100%' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
                  <Button maw={600} als='center' backgroundColor={primaryColor} onPress={updateServer} disabled={updating} opacity={updating ? 0.5 : 1}>
                    <Heading size='$1' color={primaryTextColor}>Update Server</Heading>
                  </Button>
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
                <Heading color={warningAnchorColor} size='$3' ta={'center'}>Server URL is invalid.</Heading>
                <Heading color={warningAnchorColor} size='$3' ta={'center'}>Server URL format: [http|https]:valid_hostname</Heading>
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
