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
    const client = await getServerClient(createAccountRequest);
    const { refreshToken, accessToken, user } = await client.createAccount(createAccountRequest);
    return {
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
    const client = await getServerClient(loginRequest);
    const { refreshToken, accessToken, user } = await client.login(loginRequest);
    return {
      user: user!,
      refreshToken: refreshToken!,
      accessToken: accessToken!,
      server: { ...loginRequest }
    };
  }
);
