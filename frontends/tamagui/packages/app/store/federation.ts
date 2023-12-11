import { Dictionary, PayloadAction } from "@reduxjs/toolkit";
import { AccountOrServer, JonlineServer } from "./types";

/**
 * Federation support is essentially "bolted onto" the single-server Redux store designs through two mechanisms:
 * 1. The `Federated` type (along with `getFederated` and `setFederated`), which converts an arbitrary value (generally, a status like `'loaded' | 'loading'`) into a value keyed by server host.
 * 2. The `FederatedEntity` type, which converts a Jonline entity (anything with a string id - in our case, eventually  Media, Users, Groups, Posts, Events) 
 *    into a server-specific entity, again keyed by server host. This is used in the Redux/Thunk entity adapters. tl;dr: entity ID "a" becomes "jonline.io-a" or "localhost-a".
 */

export interface PinnedServer {
  serverId: string;
  accountId?: string;
  pinned: boolean;
}

export type FederatedIDPair = { serverId: string, federatedID: string };
export function federatedIDPair(serverId: string, server: HasServer): FederatedIDPair {
  const federatedID = federateId(serverId, server);
  return { serverId, federatedID };
}
export function optionalFederatedIDPair(serverId: string | undefined, server: HasServer): FederatedIDPair | undefined {
  if (!serverId) return undefined;

  return federatedIDPair(serverId, server);
}

/**
 * Fundamental type for Jonline multi-server support. Stores arbitrary data keyed by server host.
 */
export type Federated<T> = {
  values: Dictionary<T>,
  defaultValue: T,
};

export type HasIdFromServer = { id: string };

/**
 * Used to convert Jonline entities to server-specific entities for use in Redux/Thunk entity adapters.
 */
export type FederatedEntity<T extends HasIdFromServer> = T & {
  serverHost: string;
};

export type FederatedAction = PayloadAction<any, any, { arg: AccountOrServer }>;

export type HasServer = FederatedAction | JonlineServer | undefined;

/**
 * Make an entity server-/federation-aware.
 * @param entity Any entity with a string id (User, Media, Group, Post, Event, etc.)
 * @param action Any Redux action whose argument extends `AccountOrServer`.
 * @returns a server-aware copy of that entity with a `serverHost` field.
 */
export function federatedEntity<T extends HasIdFromServer>(entity: T, server: HasServer): FederatedEntity<T> {
  return { ...entity, serverHost: serverHost(server) };
}

/**
 * Make an entity server-/federation-aware.
 * @param entity Any entity with a string id (User, Media, Group, Post, Event, etc.)
 * @param action Any Redux action whose argument extends `AccountOrServer`.
 * @returns a server-aware copy of that entity with a `serverHost` field.
 */
export function federatedPayload<T extends HasIdFromServer>(action: FederatedAction & PayloadAction<T, any, any>): FederatedEntity<T> {
  return federatedEntity(action.payload, action);
}

/**
 * Get the server-aware ID of an entity.
 * @param entity Any ServerEntity
 * @returns a server-host-specific entity ID, e.g. "jonline.io@@a" or "localhost@@a"
 */
export function federatedId<T extends HasIdFromServer>(entity: FederatedEntity<T>): string {
  return _federatedId(entity.id, entity.serverHost);
}

/**
 * Get the server-aware ID of an entity.
 * @param id Any Jonline ID (i.e. should not contain '-' characters)
 * @returns a server-host-specific entity ID, e.g. "jonline.io-a" or "localhost-a"
 */
export function federateId(id: string, server: HasServer): string {
  return _federatedId(id, serverHost(server));
}

const _federatedId = (id: string, serverHost: string) => `${id}@${serverHost}`;

export type FederatedIDParsing = { id: string, serverHost: string };
export function parseFederatedId(federatedId: string, defaultServerHost?: string): FederatedIDParsing {
  const [id, serverHost] = (federatedId ?? '').split('@');

  return {
    id: id!,
    serverHost: serverHost ?? defaultServerHost ?? 'default',
  }
}

/**
 * Shortcut composing `federatedEntity` and `federatedId` (i.e. equivalent to `federatedId(federatedEntity(entity))`).
 * 
 * @param entity The entity whose federated ID to get.
 * @param server The server to use for the federated ID.
 * @returns A federated entity ID (see federateId)
 */
export function federatedEntityId<T extends HasIdFromServer>(entity: T, server: HasServer): string {
  return federatedId(federatedEntity(entity, server));
}

/**
 * Make an array of entities server-/federation-aware.
 * @param entities Any array of entities with string ids (User, Media, Group, Post, Event, etc.)
 * @param action Any Redux action whose argument extends `AccountOrServer`.
 * @returns an array of server-aware copies of those entities with a `serverHost` field.
 */
export function federatedEntities<T extends HasIdFromServer>(entities: T[], server: HasServer): FederatedEntity<T>[] {
  return entities.map(e => federatedEntity(e, server));
}

/**
 * Create a `FederatedValue` with a default value and no server-specific values.
 * @param defaultValue 
 * @returns 
 */
export function createFederated<T>(defaultValue: T): Federated<T> {
  return {
    values: {},
    defaultValue,
  };
}

export function getFederated<T>(federated: Federated<T>, server: HasServer): T {
  const defaultValue = typeof federated.defaultValue === 'string'
    ? `${federated.defaultValue}` as T
    : Array.isArray(federated.defaultValue)
      ? [...federated.defaultValue] as T
      : { ...federated.defaultValue } as T;
  // debugger;
  return federated.values[serverHost(server)] ?? defaultValue;
}

/**
 * Sets the value of a Federated type on a given server.
 * @param federated Any federation-aware type.
 * @param action Any Redux action whose argument extends `AccountOrServer`.
 * @param value The value to set.
 */
export function setFederated<T>(federated: Federated<T>, server: HasServer, value: T) {
  federated.values[serverHost(server)] = value;
}

/**
 * Determines whether the server is defined, whether it's an explicit server or action, and returns the host.
 * Used to create federated keys (the first part of them).
 * @param server 
 * @returns 
 */
function serverHost(server: HasServer): string {
  const jonlineServer = (server && 'meta' in server)
    ? (server as FederatedAction).meta.arg.server
    : server as JonlineServer | undefined;
  return federationKey(jonlineServer);
}

function federationKey(server: JonlineServer | undefined): string {
  return server?.host ?? 'default';
}