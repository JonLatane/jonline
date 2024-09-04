import { QueryStatus } from '@reduxjs/toolkit/query/react';
import { useSelector } from 'react-redux';
import { RootState } from '../store';

const isPostsQueryPending = (state: RootState) =>
  Object.values(state.postsApi.queries)
    .some(query => query?.status === QueryStatus.pending)

export const useIsPostsQueryPending = () => useSelector(isPostsQueryPending)

const isSomeQueryPending = (state: RootState) =>
  [
    ...Object.values(state.postsApi.queries),
  ].some(query => query?.status === QueryStatus.pending)

export const useIsSomeQueryPending = () => useSelector(isSomeQueryPending)

export * from './posts_api';
