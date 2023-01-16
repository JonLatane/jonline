import React, { useState } from "react";
import { FlatList, StyleSheet, Text } from "react-native";
import * as Colors from "../styles/Colors";
import * as Spacing from "../styles/Spacing";
import FunFactCard from "../common/FunFactCard";
import { RootState, useTypedDispatch, useTypedSelector } from "../store/store";
import { selectAllFacts } from "../store/modules/Facts";
import { createServer, selectAllServers } from "../store/modules/Servers";
import ServerCard from "../common/ServerCard";
import { Button, Col, Container, Form, Row } from "react-bootstrap";
import { selectAllAccounts } from "../store/modules/Accounts";
import AccountCard from "../common/AccountCard";

const Styles = StyleSheet.create({
  trueBackground: {
    flex: 1,
    backgroundColor: Colors.DARK,
  },
  contentBackground: {
    ...Spacing.largePadding,
  },
  headerText: {
    color: Colors.PRIMARY,
    fontSize: 24,
    fontWeight: "bold",
  },
  headerButtonText: {
    color: Colors.PRIMARY,
    fontSize: 24,
    fontWeight: "bold",
  },
  label: {
    color: Colors.LIGHT,
    fontSize: 12,
    alignItems: "center",
    display: "flex",
    flexDirection: "column",
    marginTop: 'auto',
    marginBottom: 'auto',
    // fontWeight: "bold",
  },
});

const AccountsScreen: React.FC = () => {
  const [newServerHost, setNewServerHost] = useState('');

  const dispatch = useTypedDispatch();
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));

  const newServer = React.createRef<HTMLInputElement>();
  const newServerSecure = React.createRef<HTMLInputElement>();
  function addServer() {
    dispatch(createServer({
      host: newServer.current!.value,
      allowInsecure: !newServerSecure.current!.checked,
    }));
  }


  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));

  const serversLoading = serversState.status == 'loading';
  const newServerValid = newServerHost != '';

  // debugger;
  return (
    <>
      <FlatList
        data={servers}
        keyExtractor={(server) => server.host}
        ListHeaderComponent={
          <Row>
            <Col md="auto"><Text style={Styles.headerText}>Servers</Text></Col>
            <Col>
              <Form.Control ref={newServer} type="url" placeholder="Add Server..." disabled={serversLoading}
                onChange={() => { setNewServerHost(newServer.current!.value) }} />
            </Col>
            <Col md="auto">
              <Row>
                <Col>
                  <Form.Label style={Styles.label} htmlFor="newServerSecure" >
                    <Form.Check ref={newServerSecure} id="newServerSecure" aria-label='Secure' defaultChecked disabled={serversLoading} />
                    Secure
                  </Form.Label>
                </Col>
                <Col>
                  <Button onClick={addServer} disabled={serversLoading || !newServerValid}>
                    <Text style={Styles.headerText}>Add</Text>
                  </Button>
                </Col>
              </Row>
            </Col>
          </Row>
        }
        renderItem={({ item }) => {
          return <ServerCard server={item} />;
        }}
        style={Styles.trueBackground}
        contentContainerStyle={Styles.contentBackground}
      />
      <FlatList
        data={accounts}
        keyExtractor={(account) => account.id}
        ListHeaderComponent={<Text style={Styles.headerText}>Accounts</Text>}
        renderItem={({ item }) => {
          return <AccountCard account={item} />;
        }}
        style={Styles.trueBackground}
        contentContainerStyle={Styles.contentBackground}
      />
    </>
  );
};

export default AccountsScreen;
