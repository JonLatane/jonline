import 'package:flutter/foundation.dart';

import '../generated/posts.pb.dart';
import '../data_cache.dart';
import '../models/jonline_operations.dart';

class PostDataKey {
  final String? groupId;
  final PostListingType postListingType;
  PostDataKey(this.groupId, this.postListingType);
  @override
  int get hashCode => groupId.hashCode + postListingType.hashCode;
  @override
  bool operator ==(other) =>
      other is PostDataKey &&
      other.groupId == groupId &&
      other.postListingType == postListingType;
}

class PostCache
    extends DataCache<PostListingType, PostDataKey, GetPostsResponse> {
  PostCache() : super(ValueNotifier(PostListingType.PUBLIC_POSTS));

  @override
  GetPostsResponse get emptyResult => GetPostsResponse();

  @override
  PostDataKey get mainKey => PostDataKey(null, PostListingType.PUBLIC_POSTS);

  @override
  Future<GetPostsResponse?> getCurrentData() async {
    if (getCurrentKey == null) {
      return null;
    }
    GetPostsRequest? request;
    final key = getCurrentKey!();
    final listingType = key.postListingType;
    switch (listingType) {
      case PostListingType.PUBLIC_POSTS:
      case PostListingType.DIRECT_POSTS:
      case PostListingType.FOLLOWING_POSTS:
      case PostListingType.MY_GROUPS_POSTS:
      case PostListingType.POSTS_PENDING_MODERATION:
        request = GetPostsRequest(listingType: listingType);
        return await JonlineOperations.getPosts(
            request: GetPostsRequest(listingType: listingType));
      case PostListingType.GROUP_POSTS:
      case PostListingType.GROUP_POSTS_PENDING_MODERATION:
        request =
            GetPostsRequest(listingType: listingType, groupId: key.groupId);
    }
    if (request == null) {
      return null;
    }
    return await JonlineOperations.getPosts(request: request);
  }
}
