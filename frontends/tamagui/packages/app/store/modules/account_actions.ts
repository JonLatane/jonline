import { grpc } from "@improbable-eng/grpc-web";
import { CreateAccountRequest, LoginRequest } from "@jonline/api";
import {
  createAsyncThunk
} from "@reduxjs/toolkit";
import 'react-native-get-random-values';
import { v4 as uuidv4 } from 'uuid';
import { JonlineAccount, JonlineServer, getServerClient } from "..";
import { Metadata } from "nice-grpc-web";

export type CreateAccount = JonlineServer & CreateAccountRequest;
export const createAccount = createAsyncThunk<JonlineAccount, CreateAccount>(
  "accounts/create",
  async (createAccountRequest) => {
    let client = await getServerClient(createAccountRequest);
    let { refreshToken, accessToken, user } = await client.createAccount(createAccountRequest);
    // let metadata = new grpc.Metadata();
    // metadata.append('authorization', accessToken!.token)
    user = user || await client.getCurrentUser({}, {metadata: Metadata({authorization: accessToken!.token})});
    return {
      id: uuidv4(),
      user: user!,
      refreshToken: refreshToken!,
      accessToken: accessToken!,
      server: { ...createAccountRequest }
    };
  }
);

export type Login = JonlineServer & LoginRequest;
export const login = createAsyncThunk<JonlineAccount, Login>(
  "accounts/login",
  async (loginRequest) => {
    let client = await getServerClient(loginRequest);
    let { refreshToken, accessToken, user } = await client.login(loginRequest);
    // let metadata = new grpc.Metadata();
    // metadata.append('authorization', accessToken!.token)
    user = user || await client.getCurrentUser({}, {metadata: Metadata({authorization: accessToken!.token})});
    return {
      id: uuidv4(),
      user: user!,
      refreshToken: refreshToken!,
      accessToken: accessToken!,
      server: { ...loginRequest }
    };
  }
);
