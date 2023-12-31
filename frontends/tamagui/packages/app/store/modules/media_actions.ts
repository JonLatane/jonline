import { Empty, GetMediaRequest, GetMediaResponse, Media } from "@jonline/api";
import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer, getCredentialClient } from "..";

// export type CreateMedia = AccountOrServer & Media;
// export const createMedia: AsyncThunk<Media, CreateMedia, any> = createAsyncThunk<Media, CreateMedia>(
//   "media/create",
//   async (request) => {
//     const client = await getCredentialClient(request);
//     return await client.createMedia(request, client.credential);
//   }
// );

// export type ReplyToMedia = AccountOrServer & { mediaIdPath: string[], content: string };
// export const replyToMedia: AsyncThunk<Media, ReplyToMedia, any> = createAsyncThunk<Media, ReplyToMedia>(
//   "media/reply",
//   async (request) => {
//     const client = await getCredentialClient(request);
//     const createMediaRequest: CreateMediaRequest = {
//       replyToMediaId: request.mediaIdPath[request.mediaIdPath.length - 1],
//       content: request.content,
//     };
//     // TODO: Why doesn't the BE return the correct created date? We "estimate" it here.
//     const result = await client.createMedia(createMediaRequest, client.credential);
//     return { ...result, createdAt: new Date().toISOString() }
//   }
// );

export type LoadMediaRequest = AccountOrServer & {
  userId?: string,
  page?: number
};
export const loadMediaPage: AsyncThunk<GetMediaResponse, LoadMediaRequest, any> = createAsyncThunk<GetMediaResponse, LoadMediaRequest>(
  "media/loadPage",
  async (request) => {
    let client = await getCredentialClient(request);
    let result = await client.getMedia({ ...request }, client.credential);
    return result;
  }
);


export type LoadMedia = { id: string } & AccountOrServer;
export const loadMedia: AsyncThunk<Media, LoadMedia, any> = createAsyncThunk<Media, LoadMedia>(
  "media/loadOne",
  async (request) => {
    const client = await getCredentialClient(request, { skipUpsert: true });
    const response = await client.getMedia(GetMediaRequest.create({ mediaId: request.id }), client.credential);
    if (response.media.length == 0) throw 'Media not found';
    return response.media[0]!;
  }
);

export type DeleteMedia = { id: string } & AccountOrServer;
export const deleteMedia: AsyncThunk<Empty, DeleteMedia, any> = createAsyncThunk<Empty, DeleteMedia>(
  "media/deleteOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.deleteMedia(Media.fromJSON(request), client.credential);
    return response;
  }
);
