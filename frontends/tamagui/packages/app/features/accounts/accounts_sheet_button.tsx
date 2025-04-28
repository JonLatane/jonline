import { Button, ColorTokens, Image, Paragraph, SizeTokens, Tooltip, XStack, YStack } from '@jonline/ui';
import { AlertCircle, AlertTriangle, AtSign } from '@tamagui/lucide-icons';
import { useAccountsSheetContext } from 'app/contexts/accounts_sheet_context';
import { useCurrentAccount, useFederatedAccountOrServer } from 'app/hooks';
import { useMediaUrl } from 'app/hooks/use_media_url';
import { FederatedEntity, FederatedGroup, RootState, selectAllAccounts, useRootSelector, useServerTheme } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useCallback, useState } from 'react';
import { Platform } from 'react-native';

export type AccountsSheetButtonProps = {
  size?: SizeTokens;
  // Indicate to the AccountsSheet that we're
  // viewing server configuration for a server,
  // and should only show accounts for that server.
  // onlyShowServer?: JonlineServer;
  selectedGroup?: FederatedGroup;
  primaryEntity?: FederatedEntity<any>;
}
const doesPlatformPreferDarkMode = () =>
  window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

export function AccountsSheetButton({ size = '$5', selectedGroup, primaryEntity }: AccountsSheetButtonProps) {

  const [_open, setOpen] = useAccountsSheetContext().open;
  const primaryAccountOrServer = useFederatedAccountOrServer(primaryEntity);

  const { server: currentServer, navColor, navTextColor, warningAnchorColor } = useServerTheme();

  const account = useCurrentAccount();

  const browsingOn = Platform.OS == 'web' ? window.location.hostname : undefined
  const effectiveServer = primaryAccountOrServer.server ?? currentServer;

  const browsingOnDiffers = Platform.OS == 'web' &&
    effectiveServer?.host != browsingOn;


  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts));
  const serversDiffer = primaryEntity && currentServer && primaryEntity.serverHost != currentServer.host;

  const avatarUrl = useMediaUrl(account?.user.avatar?.id, { account, server: account?.server });

  const avatarSize = 22;
  const alertTriangle = useCallback(({ color }: { color?: string | ColorTokens } = {}) => <Tooltip>
    <Tooltip.Trigger>
      <AlertTriangle color={color} />
    </Tooltip.Trigger>
    <Tooltip.Content>
      <Paragraph size='$1'>You are seeing data as though you were on {currentServer?.host}, although you're on {browsingOn}.</Paragraph>
    </Tooltip.Content>
  </Tooltip>, [currentServer, browsingOn]);

  return <Button
    my='auto'
    size={size}
    {...themedButtonBackground(navColor, navTextColor)}
    // backgroundColor={navColor}
    h='auto'
    icon={serversDiffer || browsingOnDiffers
      ? alertTriangle({ color: navTextColor })
      : accounts.some(a => a.needsReauthentication)
        ? <AlertCircle color={navTextColor} />
        : undefined}
    borderBottomLeftRadius={0} borderBottomRightRadius={0}
    px='$2'
    py='$1'
    onPress={() => setOpen(true)}
  >
    {(avatarUrl && avatarUrl != '') ?
      <XStack w={avatarSize} h={avatarSize} ml={-3} mr={-3}>
        <Image
          pos="absolute"
          width={avatarSize}
          height={avatarSize}
          borderRadius={avatarSize / 2}
          resizeMode="cover"
          als="flex-start"
          source={{ uri: avatarUrl, width: avatarSize, height: avatarSize }}
        />
      </XStack>
      : undefined}
    <YStack f={1}>
      <Paragraph size='$1' color={navTextColor} o={account ? 1 : 0.5}
        whiteSpace='nowrap' overflow='hidden' textOverflow='ellipses'>
        {account?.user?.username ?? 'anonymous'}
      </Paragraph>
    </YStack>
    {selectedGroup ? undefined :
      <AtSign size='$1' color={navTextColor} />
    }

    {/* </XStack> */}
  </Button>;
}
