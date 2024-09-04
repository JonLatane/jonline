import { GetPostsRequest, GetPostsResponse } from '@jonline/api';
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
import { getCredentialClient } from '../credentialed_data';
import { AccountOrServer } from '../types';

export type WithServers = { servers: AccountOrServer[] };
export type GetPostsWithServers = GetPostsRequest & WithServers;

// Define our single API slice object
export const postsApi = createApi({
  // The cache reducer expects to be added at `state.api` (already default - this is optional)
  reducerPath: 'postsApi',
  // All of our requests will have URLs starting with '/fakeApi'
  baseQuery: fetchBaseQuery({ baseUrl: '/fakeApi' }),
  // The "endpoints" represent operations and requests for this server
  endpoints: builder => ({
    getPostsPage: builder.query<GetPostsResponse, GetPostsWithServers>({
      queryFn: async (request) => {
        const results = await Promise.all(request.servers.map(async server => {
          let client = await getCredentialClient(server);
          let data = await client.getPosts(request, client.credential);
          return { data };
        }));
        return results.reduce((acc, val) => {
          acc.data.posts.push(...val.data.posts);
          return acc;
        })
      }
    })
  })
})

export const { useGetPostsPageQuery } = postsApi;
