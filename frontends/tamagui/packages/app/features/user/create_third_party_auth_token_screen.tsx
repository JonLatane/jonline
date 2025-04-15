import { Button, Heading, Paragraph, Text, XStack, YStack, useMedia } from '@jonline/ui';
import { useCurrentAccountOrServer } from 'app/hooks';
import { useServerTheme } from 'app/store';
import { highlightedButtonBackground } from 'app/utils';
import React, { useCallback } from 'react';
import { createParam } from 'solito';
import { federatedEntity } from '../../store/federation';
import { useGroupFromPath } from '../groups/group_home_screen';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { UserCard } from './user_card';

const { useParam } = createParam<{ from?: string, to?: string, token?: string | undefined }>()
const { useParam: useShortnameParam } = createParam<{ from: string | undefined, to: string | undefined, token: string | undefined }>();

export function CreateThirdPartyAuthTokenScreen() {
  const mediaQuery = useMedia();
  const { group, pathShortname } = useGroupFromPath();

  const [fromHost] = useParam('from');
  const [toHost] = useParam('to');

  const theme = useServerTheme();
  const { primaryTextColor, primaryColor } = theme;
  const { account: currentServerAccount, server: currentServer } = useCurrentAccountOrServer();

  // const dispatch = useAppDispatch();

  const user = currentServerAccount ?
    federatedEntity(currentServerAccount.user, currentServer)
    : undefined;

  const createAuthToken = useCallback(() => {

  }, []);

  return (
    <TabsNavigation minimal
      appSection={AppSection.AUTH}
      primaryEntity={user}
      selectedGroup={group}
      // groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/m/${pathUsername}`}
      // groupPageReverse={`/${pathUsername}`}
      bottomChrome={!!user
        ? <YStack w='100%' paddingVertical='$2' alignContent='center'>
          <XStack mx='auto' px='$3' w='100%' maw={800}>
            <Button key={`save-color-${primaryColor}`} ml='auto' mr='$3'
              {...highlightedButtonBackground(theme)}
              // disabled={!dirtyData} opacity={dirtyData ? 1 : 0.5}
              als='center' onPress={createAuthToken}>
              <Heading size='$2' color={primaryTextColor}>Authenticate</Heading>
            </Button>
            {/* <XStack f={1} /> */}
          </XStack>
        </YStack> : undefined}
    >
      <YStack f={1} jc="center" ai="center" gap='$2' my='$2' w='100%'>
        {(toHost?.length ?? 0) > 0
          ? user
            ? <>
              <Heading size='$6'>Authenticating to {toHost} as:</Heading>
              <UserCard user={user} />
              <Paragraph size='$2'></Paragraph>
            </>
            : <Heading size='$1'>Login to integrate with {toHost}.</Heading>
          : (fromHost?.length ?? 0) > 0
            ? user
              ? <>
                <Heading size='$6'>Authenticating from {fromHost}</Heading>
                {/* <Heading size='$1'>Login on {fromHost}</Heading> */}
                {/* <UserCard user={user} /> */}
              </>
              : <Heading size='$1'>Login to integrate with {toHost}.</Heading>
            : <Paragraph size='$4'>To use third party auth, add <Text fontFamily='$mono'>?from=my.hostname.com</Text> or <Text fontFamily='$mono'>?to=my.hostname.com</Text> to this URL.</Paragraph>}

      </YStack>
    </TabsNavigation>
  )
}
