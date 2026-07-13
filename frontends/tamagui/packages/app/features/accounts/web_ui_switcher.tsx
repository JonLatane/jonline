import { ServerConfiguration, ServerInfo, WebUserInterface } from '@jonline/api';
import { AnimatePresence, Button, Card, Heading, Image, Spinner, Text, XStack, formatError, standardAnimation, useToastController } from '@jonline/ui';
import { ChevronDown } from '@tamagui/lucide-icons';
import { useAppDispatch, useMediaUrl } from 'app/hooks';
import { JonlineAccount, accountID, getCredentialClient, upsertServer, useServerTheme } from 'app/store';
import { highlightedButtonBackground } from 'app/utils';
import React, { useState } from 'react';

function webUserInterfaceLabel(ui: WebUserInterface): string {
  switch (ui) {
    case WebUserInterface.FLUTTER_WEB: return 'Flutter';
    case WebUserInterface.ELM_SPA: return 'Elm';
    default: return 'React';
  }
}

type Props = {
  account: JonlineAccount;
  serverConfiguration?: ServerConfiguration;
};

// A collapsible panel, one per admin-capable signed-in account on a server, for
// setting which frontend (Flutter/React/Elm) that server serves at its root
// (ServerInfo.web_user_interface). Shown alongside that account's username/avatar
// since ConfigureServer is authenticated per-account, not as "whichever account is
// currently active" -- see server_details_screen.tsx.
export function WebUiSwitcher({ account, serverConfiguration }: Props) {
  const dispatch = useAppDispatch();
  const toast = useToastController();
  const [expanded, setExpanded] = useState(false);
  const [updating, setUpdating] = useState(false);

  const avatarUrl = useMediaUrl(account.user.avatar?.id, { account, server: account.server });
  const theme = useServerTheme(account.server);
  const currentUi = serverConfiguration?.serverInfo?.webUserInterface ?? WebUserInterface.REACT_TAMAGUI;

  async function setWebUserInterface(ui: WebUserInterface) {
    setUpdating(true);
    try {
      const client = await getCredentialClient({ account, server: account.server });
      const newConfiguration: ServerConfiguration = {
        ...serverConfiguration!,
        serverInfo: {
          ...ServerInfo.create(serverConfiguration?.serverInfo ?? {}),
          webUserInterface: ui,
        },
      };
      const returnedConfiguration = await client.configureServer(newConfiguration, client.credential);
      await dispatch(upsertServer({ ...account.server, serverConfiguration: returnedConfiguration }));
      toast.show(`Web UI set to ${webUserInterfaceLabel(ui)}.`);
    } catch (e) {
      toast.show(formatError(e.message));
    } finally {
      setUpdating(false);
    }
  }

  function uiButton(ui: WebUserInterface, label: string, disabled: boolean = false) {
    const selected = currentUi === ui;
    return <Button key={label} size='$2' f={1} disabled={disabled || updating}
      {...highlightedButtonBackground(theme, 'nav', selected)}
      opacity={disabled ? 0.5 : undefined}
      onPress={() => setWebUserInterface(ui)}>
      {label}
    </Button>;
  }

  return (
    <Card bordered p='$2'>
      <Button unstyled onPress={() => setExpanded(!expanded)}>
        <XStack ai='center' gap='$2'>
          {avatarUrl
            ? <Image source={{ uri: avatarUrl, width: 28, height: 28 }} w={28} h={28} borderRadius={14} />
            : <XStack w={28} h={28} borderRadius={14} backgroundColor='$color4' ai='center' jc='center'>
              <Text fontSize='$1'>{account.user.username.charAt(0).toUpperCase()}</Text>
            </XStack>}
          <Heading size='$2' f={1} numberOfLines={1}>{account.user.username}</Heading>
          {updating
            ? <Spinner size='small' />
            : <XStack animation='standard' rotate={expanded ? '180deg' : '0deg'}>
              <ChevronDown size='$1' />
            </XStack>}
        </XStack>
      </Button>
      <AnimatePresence>
        {expanded
          ? <XStack key={`web-ui-buttons-${accountID(account)}`} gap='$2' mt='$2'
            animation='standard' {...standardAnimation}>
            {uiButton(WebUserInterface.FLUTTER_WEB, 'Flutter', true)}
            {uiButton(WebUserInterface.REACT_TAMAGUI, 'React')}
            {uiButton(WebUserInterface.ELM_SPA, 'Elm')}
          </XStack>
          : undefined}
      </AnimatePresence>
    </Card>
  );
}
