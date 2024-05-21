import { CreateAccountRequest, FederatedAccount, LoginRequest } from "@jonline/api";
import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import 'react-native-get-random-values';
import { AccountOrServer, JonlineAccount, JonlineServer, getCredentialClient, getServerClient } from "..";
export type SkipSelection = { skipSelection?: boolean; }
export type CreateAccount = JonlineServer & CreateAccountRequest & SkipSelection;
export const createAccount = createAsyncThunk<JonlineAccount, CreateAccount>(
  "accounts/create",
  async (createAccountRequest) => {
    const client = await getServerClient(createAccountRequest);
    const { refreshToken, accessToken, user } = await client.createAccount({
      ...createAccountRequest,
      deviceName: getDeviceName()
    });
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
    const { refreshToken, accessToken, user } = await client.login({
      ...loginRequest,
      deviceName: getDeviceName()
    });
    return {
      user: user!,
      refreshToken: refreshToken!,
      accessToken: accessToken!,
      server: { ...loginRequest }
    };
  }
);

const getDeviceName = () => {
  let device = "Unknown Device";
  const ua = {
    "Generic Linux": /Linux/i,
    "Android": /Android/i,
    "BlackBerry": /BlackBerry/i,
    "Bluebird": /EF500/i,
    "Chrome OS": /CrOS/i,
    "Datalogic": /DL-AXIS/i,
    "Honeywell": /CT50/i,
    "iPad": /iPad/i,
    "iPhone": /iPhone/i,
    "iPod": /iPod/i,
    "macOS": /Macintosh/i,
    "Windows": /IEMobile|Windows/i,
    "Zebra": /TC70|TC55/i,
  }
  Object.keys(ua).map(v => navigator.userAgent.match(ua[v]) && (device = v));
  return device;
};

export type FederateAccounts = { account1: AccountOrServer, account2: AccountOrServer };
export const federateAccounts: AsyncThunk<void, FederateAccounts, any> = createAsyncThunk<void, FederateAccounts>(
  "users/federateAccounts",
  async ({ account1, account2 }) => {
    // debugger;
    for (const accountOrServer of [account1, account2]) {
      const otherAccount = (accountOrServer === account1
        ? account2
        : account1
      ).account!;

      const client = await getCredentialClient(accountOrServer);
      try {
        await client.federateProfile({
          userId: otherAccount!.user.id,
          host: otherAccount.server!.host,
        }, client.credential);
      } catch (e) {
        console.error(e);
        throw e;
      }
    }
  });

export type DefederateAccounts = { account1: AccountOrServer, account2?: AccountOrServer, account2Profile: FederatedAccount };

export const defederateAccounts: AsyncThunk<void, DefederateAccounts, any> = createAsyncThunk<void, DefederateAccounts>(
  "users/defederateAccounts",
  async ({ account1, account2, account2Profile }) => {
    if (account2 && account2.account) {
      for (const accountOrServer of [account1, account2]) {
        const otherAccount = (accountOrServer === account1
          ? account2
          : account1
        ).account!;

        const client = await getCredentialClient(accountOrServer);
        await client.defederateProfile({
          userId: otherAccount!.user.id,
          host: otherAccount.server!.host,
        }, client.credential);
      }
    } else {
      const client = await getCredentialClient(account1);
      await client.defederateProfile({
        userId: account2Profile.userId,
        host: account2Profile.host,
      }, client.credential);
    }
  });
