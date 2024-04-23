import { Button, Heading, Input, Sheet, standardAnimation, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronLeft } from '@tamagui/lucide-icons';
import { TamaguiMarkdown } from 'app/components';
import { useAppDispatch, useCreationServer, useCurrentServer } from 'app/hooks';
import { accountID, actionSucceeded, clearAccountAlerts, createAccount, useServerTheme, JonlineAccount, JonlineServer, login, RootState, selectAllAccounts, serverID, store, useRootSelector } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { TextInput } from 'react-native';
import AccountCard from './account_card';
import { CreationServerSelector } from './creation_server_selector';
import { useAuthSheetContext } from 'app/contexts/auth_sheet_context';

export type AuthSheetButtonProps = {
  server?: JonlineServer;
  operation?: string;
  button?: (onPress: () => void) => JSX.Element;
}

export function AuthSheetButton({ server: taggedServer, operation, button }: AuthSheetButtonProps) {
  const mediaQuery = useMedia();
  const { open: [_, setOpen] } = useAuthSheetContext();

  const { creationServer: creationServer, setCreationServer: setCreationServer } = useCreationServer();


  const specifiedServer = creationServer;



  const currentServer = useCurrentServer();
  const server = specifiedServer ?? currentServer;

  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme(server);

  const onPress = () => {
    if (taggedServer) setCreationServer(taggedServer);
    setOpen(true);
  };
  return button?.(onPress)
    ?? <Button {...themedButtonBackground(primaryColor, primaryTextColor)}
      disabled={server === undefined}
      px='$1'
      minWidth={80}
      onPress={onPress}>
      {mediaQuery.gtXs
        ? <Heading size='$2' ta='center' color={primaryTextColor}>
          Login/Sign Up<br />to {operation}
        </Heading>
        : <Heading size='$2' ta='center' color={primaryTextColor}>
          Login/<br />Sign Up
        </Heading>}
    </Button>
}
