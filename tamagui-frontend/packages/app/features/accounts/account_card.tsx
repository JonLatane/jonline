import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store, { useTypedDispatch } from "../../store/store";
import { JonlineServer, selectServer } from "../../store/modules/Servers";
import { JonlineAccount, selectAccount } from "../../store/modules/Accounts";
import { Card, Heading, XStack, YStack } from "@jonline/ui";
import { Lock, Unlock } from "@tamagui/lucide-icons";

interface Props {
  account: JonlineAccount;
}

const AccountCard: React.FC<Props> = ({ account }) => {
  const dispatch = useTypedDispatch();
  let selected = store.getState().accounts.account?.id == account.id;

  return (
    <Card theme="dark" elevate size="$4" bordered

    animation="bouncy"
    // w={250}
    // h={50}
    scale={0.9}
    hoverStyle={{ scale: 0.925 }}
    pressStyle={{ scale: 0.875 }}
    onClick={() => dispatch(selectAccount(account))}>
      <Card.Header>
        <XStack>
          <YStack  style={{flex: 1}}>
            <Heading size="$1">{account.server.host}/</Heading>
            <Heading size="$7">{account.user.username}</Heading>
          </YStack>
          {account.server.secure ? <Lock/> : <Unlock/>}
        </XStack>
      </Card.Header>
      <Card.Footer>
        <XStack alignContent="flex-end">
          <Heading size="$1">{account.user.id}</Heading>
        </XStack>
      </Card.Footer>
      <Card.Background backgroundColor={selected ? '#424242' : undefined}/>
    </Card>
    // <a style={Styles.borderlessButton} onClick={() => dispatch(selectServer(server))}>
    // </a>
  );
};

export default AccountCard;
