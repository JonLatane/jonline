import { EventListingType, GetEventsResponse, GetGroupPostsRequest, GetGroupPostsResponse, GetGroupsRequest, GetGroupsResponse, GetPostsResponse, Group, PostListingType } from "@jonline/api";

import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer, getCredentialClient } from "..";

export type CreateGroup = AccountOrServer & Group;
export const createGroup: AsyncThunk<Group, CreateGroup, any> = createAsyncThunk<Group, CreateGroup>(
  "groups/create",
  async (createGroupRequest) => {
    let client = await getCredentialClient(createGroupRequest);
    return client.createGroup(createGroupRequest, client.credential);
  }
);

export type UpdateGroups = AccountOrServer & GetGroupsRequest;
export const updateGroups: AsyncThunk<GetGroupsResponse, UpdateGroups, any> = createAsyncThunk<GetGroupsResponse, UpdateGroups>(
  "groups/update",
  async (getGroupsRequest) => {
    let client = await getCredentialClient(getGroupsRequest);
    return await client.getGroups(getGroupsRequest, client.credential);
  }
);

export type LoadGroupPostsPage = AccountOrServer & { groupId: string, page?: number };
export const loadGroupPostsPage: AsyncThunk<GetPostsResponse, LoadGroupPostsPage, any> = createAsyncThunk<GetPostsResponse, LoadGroupPostsPage>(
  "groups/loadPostsPage",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getPosts({ groupId: request.groupId, listingType: PostListingType.GROUP_POSTS }, client.credential);
    return result;
  }
);

export type LoadGroupEventsPage = AccountOrServer & { groupId: string, page?: number };
export const loadGroupEventsPage: AsyncThunk<GetEventsResponse, LoadGroupEventsPage, any> = createAsyncThunk<GetEventsResponse, LoadGroupEventsPage>(
  "groups/loadEventsPage",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getEvents({ groupId: request.groupId, listingType: EventListingType.GROUP_EVENTS }, client.credential);
    return result;
  }
);

export type LoadGroup = { id: string } & AccountOrServer;
export const loadGroup: AsyncThunk<Group, LoadGroup, any> = createAsyncThunk<Group, LoadGroup>(
  "groups/loadOne",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getGroups(GetGroupsRequest.create({ groupId: request.id }), client.credential);
    let group = response.groups[0]!;
    return group;
  }
);

export type LoadGroupPostsForPostRequest = AccountOrServer & {
  postId: string,
};

export const loadGroupPostsForPost: AsyncThunk<GetGroupPostsResponse, LoadGroupPostsForPostRequest, any> = createAsyncThunk<GetGroupPostsResponse, LoadGroupPostsForPostRequest>(
  "groups/loadGroupPostsForPost",
  async (request) => {
    let client = await getCredentialClient(request);
    let apiRequest: GetGroupPostsRequest = { postId: request.postId };
    let result = await client.getGroupPosts(apiRequest, client.credential);
    return result;
  }
);
