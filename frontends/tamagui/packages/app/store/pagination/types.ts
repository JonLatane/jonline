import { Dictionary } from "@reduxjs/toolkit";
import { Federated, createFederated } from "../federation";

/**
 * Fundamental type for Jonline pagination. Stores IDs of paginated resources like Groups, People, Posts, Events, etc. used in the UI.
 * May be keyed by [Resource]ListingType or groupId.
 * Posts should be loaded from the adapter/slice's entities. An empty page indicates there is no more data to load.
 * Maps either: 
 *  * <code>PostListingType</code> -> <code>page</code> -> <code>postIds</code>, or
 *  * <code>groupId</code> -> <code>page</code> -> <code>postIds</code>
 * Access for page <code>0</code> looks like:
 *  * <code>postPages[PostListingType.ALL_ACCESSIBLE_POSTS][0]</code> -> <code>["postId1", "postId2"]</code>.
 *  * <code>groupPostPages['groupId1'][0]</code> -> <code>["postId1", "postId2"]</code>.
 */
export type PaginatedIds = string[][];
export type GroupedPages = Dictionary<PaginatedIds>;
