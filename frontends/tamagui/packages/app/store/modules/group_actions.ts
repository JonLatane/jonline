import { Empty, EventListingType, GetEventsResponse, GetGroupPostsResponse, GetGroupsRequest, GetGroupsResponse, GetMembersRequest, GetMembersResponse, GetPostsResponse, Group, GroupListingType, GroupPost, Membership, Moderation, PostListingType, TimeFilter } from "@jonline/api";

import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer, getCredentialClient, parseFederatedId } from "app/store";

export const defaultGroupListingType = GroupListingType.ALL_GROUPS;

export type CreateGroup = AccountOrServer & Group;
export const createGroup: AsyncThunk<Group, CreateGroup, any> = createAsyncThunk<Group, CreateGroup>(
  "groups/create",
  async (createGroupRequest) => {
    const client = await getCredentialClient(createGroupRequest);
    return client.createGroup(createGroupRequest, client.credential);
  }
);

export type UpdateGroup = AccountOrServer & Group;
export const updateGroup: AsyncThunk<Group, UpdateGroup, any> = createAsyncThunk<Group, UpdateGroup>(
  "groups/update",
  async (updateGroupRequest) => {
    const client = await getCredentialClient(updateGroupRequest);
    return client.updateGroup(updateGroupRequest, client.credential);
  }
);
export type DeleteGroup = AccountOrServer & Group;
export const deleteGroup: AsyncThunk<Empty, DeleteGroup, any> = createAsyncThunk<Empty, DeleteGroup>(
  "groups/delete",
  async (deleteGroupRequest) => {
    const client = await getCredentialClient(deleteGroupRequest);
    return client.deleteGroup(deleteGroupRequest, client.credential);
  }
);

export type LoadGroupsPage = AccountOrServer & GetGroupsRequest;
export const loadGroupsPage: AsyncThunk<GetGroupsResponse, LoadGroupsPage, any> = createAsyncThunk<GetGroupsResponse, LoadGroupsPage>(
  "groups/loadPage",
  async (getGroupsRequest) => {
    const client = await getCredentialClient(getGroupsRequest);
    console.log('Loading groups page...')
    return await client.getGroups(getGroupsRequest, client.credential);
  }
);

export type LoadPostGroupPosts = AccountOrServer & { postId: string };
export const loadPostGroupPosts: AsyncThunk<GetGroupPostsResponse, LoadPostGroupPosts, any> = createAsyncThunk<GetGroupPostsResponse, LoadPostGroupPosts>(
  "groups/loadPostGroupPosts",
  async (request) => {
    const { postId } = request;
    const client = await getCredentialClient(request);
    const result = await client.getGroupPosts({
      postId: parseFederatedId(postId).id
    }, client.credential);
    return result;
  }
);

export type LoadGroupPostsPage = AccountOrServer & { groupId: string, page?: number };
export const loadGroupPostsPage: AsyncThunk<GetPostsResponse, LoadGroupPostsPage, any> = createAsyncThunk<GetPostsResponse, LoadGroupPostsPage>(
  "groups/loadPostsPage",
  async (request) => {
    const { groupId } = request;
    // debugger;
    const client = await getCredentialClient(request);
    // debugger;
    const result = await client.getPosts({
      groupId: parseFederatedId(groupId).id,
      listingType: PostListingType.GROUP_POSTS
    }, client.credential);
    // debugger;
    return result;
  }
);

export type LoadGroupEventsPage = AccountOrServer & { groupId: string, page?: number, filter?: TimeFilter };
export const loadGroupEventsPage: AsyncThunk<GetEventsResponse, LoadGroupEventsPage, any> = createAsyncThunk<GetEventsResponse, LoadGroupEventsPage>(
  "groups/loadEventsPage",
  async (request) => {
    const { groupId, filter } = request;
    const client = await getCredentialClient(request);
    const result = await client.getEvents({ groupId, listingType: EventListingType.GROUP_EVENTS, timeFilter: filter }, client.credential);
    return result;
  }
);

export type LoadGroup = { id: string } & AccountOrServer;
export const loadGroup: AsyncThunk<Group, LoadGroup, any> = createAsyncThunk<Group, LoadGroup>(
  "groups/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.getGroups(GetGroupsRequest.create({ groupId: parseFederatedId(request.id).id }), client.credential);
    const group = response.groups[0]!;
    return group;
  }
);

export type LoadGroupMembers = { id: string, page?: number, groupModeration?: Moderation } & AccountOrServer;
export const loadGroupMembers: AsyncThunk<GetMembersResponse, LoadGroupMembers, any> = createAsyncThunk<GetMembersResponse, LoadGroupMembers>(
  "groups/loadMembers",
  async (request) => {
    try {
      // debugger;
      const client = await getCredentialClient(request);
      // debugger;
      const response = await client.getMembers(
        GetMembersRequest.create({
          groupId: parseFederatedId(request.id).id,
          page: request.page,
          groupModeration: request.groupModeration
        }),
        client.credential
      );
      return response;
    } catch (t) {
      console.error('error loading group members', t, request);
      throw t;
    }
    // debugger;
  }
);

export type LoadGroupPostsForPost = AccountOrServer & {
  postId: string,
};

export const loadGroupPostsForPost: AsyncThunk<GetGroupPostsResponse, LoadGroupPostsForPost, any> = createAsyncThunk<GetGroupPostsResponse, LoadGroupPostsForPost>(
  "groups/loadGroupPostsForPost",
  async (request) => {
    const { postId } = request;
    const client = await getCredentialClient(request);
    const result = await client.getGroupPosts({ postId }, client.credential);
    return result;
  }
);

export type CreateGroupPost = AccountOrServer & { groupId: string, postId: string };
export const createGroupPost: AsyncThunk<GroupPost, CreateGroupPost, any> = createAsyncThunk<GroupPost, CreateGroupPost>(
  'groups/createGroupPost',
  async (request) => {
    const { groupId, postId } = request;
    const client = await getCredentialClient(request);
    const result = await client.createGroupPost({ groupId, postId }, client.credential);
    return result;
  }
);

export type DeleteGroupPost = AccountOrServer & { groupId: string, postId: string };
export const deleteGroupPost: AsyncThunk<void, DeleteGroupPost, any> = createAsyncThunk<void, DeleteGroupPost>(
  'groups/deleteGroupPost',
  async (request) => {
    const { groupId, postId } = request;
    const client = await getCredentialClient(request);
    await client.deleteGroupPost({ groupId, postId }, client.credential);
  }
);


export type JoinLeaveGroup = { groupId: string, join: boolean } & AccountOrServer;
export const joinLeaveGroup: AsyncThunk<Membership | undefined, JoinLeaveGroup, any> = createAsyncThunk<Membership | undefined, JoinLeaveGroup>(
  "groups/joinLeave",
  async (request) => {
    const client = await getCredentialClient(request);
    const membership = { userId: request.account!.user.id, groupId: request.groupId };
    if (request.join) {
      return await client.createMembership(membership, client.credential);
    } else {
      await client.deleteMembership(membership, client.credential);
      return undefined;
    }
  });

export type RespondToMembershipRequest = { userId: string, groupId: string, accept: boolean } & AccountOrServer;
export const respondToMembershipRequest: AsyncThunk<Membership | undefined, RespondToMembershipRequest, any> = createAsyncThunk<Membership | undefined, RespondToMembershipRequest>(
  "groups/respondToMembershipRequest",
  async (request) => {
    const client = await getCredentialClient(request);
    const membership = { userId: request.userId, groupId: request.groupId, targetUserModeration: request.accept ? Moderation.APPROVED : Moderation.REJECTED };
    if (request.accept) {
      return await client.updateMembership(membership, client.credential);
    } else {
      await client.deleteMembership(membership, client.credential);
      return undefined;
    }
  });
