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