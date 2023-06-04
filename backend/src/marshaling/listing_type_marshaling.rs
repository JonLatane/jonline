use std::mem::transmute;

use crate::protos::*;

pub const ALL_GROUP_LISTING_TYPES: [GroupListingType; 4] = [
    GroupListingType::AllGroups,
    GroupListingType::MyGroups,
    GroupListingType::RequestedGroups,
    GroupListingType::InvitedGroups,
];

pub const ALL_USER_LISTING_TYPES: [UserListingType; 5] = [
  UserListingType::Everyone,
  UserListingType::Following,
  UserListingType::Friends,
  UserListingType::Followers,
  UserListingType::FollowRequests
];

pub const ALL_POST_LISTING_TYPES: [PostListingType; 4] = [
  PostListingType::PublicPosts,
  PostListingType::FollowingPosts,
  PostListingType::MyGroupsPosts,
  PostListingType::DirectPosts,
];

pub trait ToProtoGroupListingType {
    fn to_proto_group_listing_type(&self) -> Option<GroupListingType>;
}
impl ToProtoGroupListingType for String {
    fn to_proto_group_listing_type(&self) -> Option<GroupListingType> {
        for group_listing_type in ALL_GROUP_LISTING_TYPES {
            if group_listing_type.as_str_name().eq_ignore_ascii_case(self) {
                return Some(group_listing_type);
            }
        }
        return None;
    }
}
impl ToProtoGroupListingType for i32 {
    fn to_proto_group_listing_type(&self) -> Option<GroupListingType> {
        Some(unsafe { transmute::<i32, GroupListingType>(*self) })
    }
}

pub trait ToProtoUserListingType {
  fn to_proto_user_listing_type(&self) -> Option<UserListingType>;
}
impl ToProtoUserListingType for String {
  fn to_proto_user_listing_type(&self) -> Option<UserListingType> {
      for user_listing_type in ALL_USER_LISTING_TYPES {
          if user_listing_type.as_str_name().eq_ignore_ascii_case(self) {
              return Some(user_listing_type);
          }
      }
      return None;
  }
}
impl ToProtoUserListingType for i32 {
  fn to_proto_user_listing_type(&self) -> Option<UserListingType> {
      Some(unsafe { transmute::<i32, UserListingType>(*self) })
  }
}

pub trait ToProtoPostListingType {
  fn to_proto_post_listing_type(&self) -> Option<PostListingType>;
}
impl ToProtoPostListingType for String {
  fn to_proto_post_listing_type(&self) -> Option<PostListingType> {
      for post_listing_type in ALL_POST_LISTING_TYPES {
          if post_listing_type.as_str_name().eq_ignore_ascii_case(self) {
              return Some(post_listing_type);
          }
      }
      return None;
  }
}
impl ToProtoPostListingType for i32 {
  fn to_proto_post_listing_type(&self) -> Option<PostListingType> {
      Some(unsafe { transmute::<i32, PostListingType>(*self) })
  }
}
