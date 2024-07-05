import { FederatedAccount } from "@jonline/api";
import { Button, Heading, Paragraph, Popover, ScrollView, Tooltip, XStack, YStack } from "@jonline/ui";
import { AlertCircle, CheckCircle, X as XIcon } from '@tamagui/lucide-icons';
import { useAppDispatch, useAppSelector, useCurrentServer, useFederatedDispatch } from "app/hooks";
import { FederatedUser, JonlineAccount, accountID, defederateAccounts, federateAccounts, loadUser, selectAllAccounts, selectUserById, useServerTheme } from 'app/store';
import { themedButtonBackground } from "app/utils";
import { useEffect, useState } from "react";
import FlipMove from 'lumen5-react-flip-move';
import { useLink } from "solito/link";
import { useFederatedAccountOrServer } from '../../hooks/account_or_server/use_federated_account_or_server';
import { federateId } from '../../store/federation';
import { useJonlineServerInfo } from "../accounts/recommended_server";
import { AccountAvatarAndUsername } from "../navigation/pinned_server_selector";
import { ServerNameAndLogo } from "../navigation/server_name_and_logo";

interface Props {
  user: FederatedUser;
}

export const FederatedProfiles: React.FC<Props> = ({ user, }) => {
  const profiles = user.federatedProfiles;

  const accountOrServer = useFederatedAccountOrServer(user);
  const currentUser = accountOrServer.account?.user;
  const isCurrentUser = user.id === currentUser?.id
    && user.serverHost === accountOrServer.server?.host;

  const accounts = useAppSelector(state => selectAllAccounts(state.accounts));
  const federableAccounts = accounts.filter(account =>
    (account.user.id !== user.id || account.server.host !== user.serverHost) &&
    !profiles.some(profile => profile.host === account.server.host && profile.userId === account.user.id)
  );

  return <YStack mb={profiles.length > 0 || isCurrentUser ? '$2' : undefined}>
    {profiles.length > 0 ? <Heading size='$1'>Other Profiles</Heading> : undefined}
    <FlipMove style={{ display: 'flex', alignItems: 'center' }}>
      {profiles.map(profile =>
        <div key={`profile-${profile.userId}@${profile.host}`} style={{ marginRight: 3, marginLeft: 3 }}>
          <FederatedProfileSelector user={user} profile={profile} />
        </div>)}
      {isCurrentUser && federableAccounts.length > 0
        ? <div key='federate-profile' style={{ marginRight: 3, marginLeft: 3 }}>
          <Popover allowFlip>
            <Popover.Trigger>
              <Button>
                Link Profile...
              </Button>
            </Popover.Trigger>
            <Popover.Content>
              <ScrollView w='100%' h='100%'>
                {federableAccounts.map(account =>
                  <FederatedProfileCreator key={accountID(account)} user={user} account={account} />
                )}
              </ScrollView>
            </Popover.Content>
          </Popover>
        </div>
        : undefined}
    </FlipMove>
  </YStack >
}

const FederatedProfileSelector: React.FC<{
  user: FederatedUser; profile: FederatedAccount
}> = ({ user, profile }) => {

  const dispatch = useAppDispatch();

  const { accountOrServer: userAccountOrServer } = useFederatedDispatch(user.serverHost);
  const { accountOrServer: profileAccountOrServer } = useFederatedDispatch(profile.host);

  // const currentAccount = accountOrServer.account!;
  const userCurrentUser = userAccountOrServer.account?.user;
  const isCurrentUser = user.id === userCurrentUser?.id
    && user.serverHost === userAccountOrServer.server?.host;

  const profileAccount = useAppSelector(state => selectAllAccounts(state.accounts))
    .find(account => account.server.host === profile.host && account.user.id === profile.userId);

  const profileUser = useAppSelector(state => selectUserById(state.users, federateId(profile.userId, profile.host)));
  const loadFailed = useAppSelector(state => state.users.failedUserIds.includes(federateId(profile.userId, profile.host)));
  const [loadingUser, setLoadingUser] = useState(false);
  useEffect(() => {
    if (!profileUser?.hasAdvancedData && !loadFailed && !loadingUser && profileAccountOrServer.server) {
      setLoadingUser(true);
      dispatch(loadUser({ userId: profile.userId, ...profileAccountOrServer }))
        .then(() => setLoadingUser(false));
    }
  }, [profileUser, loadFailed, loadingUser, profileAccountOrServer.server]);
  const { server } = useJonlineServerInfo(profile.host);
  const { primaryColor, primaryTextColor } = useServerTheme(server);
  const isCurrentServer = useCurrentServer()?.host === profileUser?.serverHost;

  // console.log('link', `https://${profile.host}/${profileUser?.username}@${profileUser?.serverHost}`);
  const link = useLink({
    href: isCurrentServer
      ? `/${profileUser?.username}`
      : `/${profileUser?.username}@${profileUser?.serverHost}`
  });

  // console.log('FederatedProfileSelector', { profileUser, profileAccount, loadFailed })
  function defederateProfile() {
    dispatch(defederateAccounts({
      account1: userAccountOrServer,
      account2: profileAccountOrServer,
      account2Profile: profile
    }));
  }

  const validated = profileUser?.federatedProfiles
    .some(p => p.host === user.serverHost && p.userId === user.id);

  const { navAnchorColor: validatedColor } = useServerTheme(useCurrentServer());

  return <YStack ai='center' gap='$2'>
    <Button h='auto' {...(profileUser ? link : {})} {...themedButtonBackground(primaryColor, primaryTextColor)}>
      <YStack ai='center' gap='$1' py='$1'>
        <AccountAvatarAndUsername /*account={profileAccount}*/ user={profileUser} textColor={primaryTextColor} />
        <ServerNameAndLogo server={server} textColor={primaryTextColor} />
      </YStack>
    </Button>
    <XStack ai='center' gap='$3'>
      {validated
        ? <Tooltip>
          <Tooltip.Trigger>
            <CheckCircle color={validatedColor} />
          </Tooltip.Trigger>
          <Tooltip.Content>
            <Paragraph size='$1'>
              This profile link has been validated. {user?.username}@{user?.serverHost} and {profileUser?.username}@{profileUser?.serverHost} both link to each other.
            </Paragraph>
          </Tooltip.Content>
        </Tooltip>
        : <Tooltip>
          <Tooltip.Trigger>
            <AlertCircle />
          </Tooltip.Trigger>
          <Tooltip.Content>
            <Paragraph size='$1'>
              This profile link has not been validated. While {user?.username}@{user?.serverHost} has linked to {profileUser?.username}@{profileUser?.serverHost}, {profileUser?.username}@{profileUser?.serverHost} has not linked back to {user?.username}@{user?.serverHost}.
            </Paragraph>
          </Tooltip.Content>
        </Tooltip>}
      {isCurrentUser && profileAccount
        ? <Button mt='$1' circular size='$1' icon={XIcon} onPress={defederateProfile} />
        : undefined}
    </XStack>
  </YStack>;
}


const FederatedProfileCreator: React.FC<{
  user: FederatedUser; account: JonlineAccount
}> = ({ user, account }) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(user);
  const currentAccount = accountOrServer.account!;
  const { server } = useJonlineServerInfo(account.server?.host);

  function federateProfile() {
    dispatch(federateAccounts({
      account1: { account: currentAccount, server: currentAccount.server },
      account2: { account, server: account.server }
    }));
  }

  return <Button h='auto' w='100%' my='$1' py='$2' onPress={federateProfile}>
    <XStack w='100%'>
      <XStack f={1}>
        <AccountAvatarAndUsername account={account} />
      </XStack>
      <XStack>
        <ServerNameAndLogo server={server} />
      </XStack>
    </XStack>
  </Button>;
}