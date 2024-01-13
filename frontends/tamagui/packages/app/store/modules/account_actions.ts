import { CreateAccountRequest, LoginRequest } from "@jonline/api";
import {
  createAsyncThunk
} from "@reduxjs/toolkit";
import 'react-native-get-random-values';
import { JonlineAccount, JonlineServer, getServerClient } from "..";

export type SkipSelection = { skipSelection?: boolean; }
export type CreateAccount = JonlineServer & CreateAccountRequest & SkipSelection;
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

export type Login = JonlineServer & LoginRequest & SkipSelection;
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
