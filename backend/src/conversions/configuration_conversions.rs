// use std::collections::HashMap;

// use serde_json::Value;

// use super::ToLink;
// use super::id_conversions::ToProtoId;
use crate::models;
use crate::protos::*;

pub trait ToDbServerConfiguration {
    fn to_proto(&self) -> models::NewServerConfiguration;
}

pub trait ToProtoServerConfiguration {
    fn to_proto(&self) -> ServerConfiguration;
}
pub trait ToProtoPermission {
    fn to_proto_permission(&self) -> Option<Permission>;
}
impl ToProtoPermission for String {
    fn to_proto_permission(&self) -> Option<Permission> {
        for permission in [
            Permission::ViewPosts,
            Permission::CreatePosts,
            Permission::GloballyPublishPosts,
            Permission::ModeratePosts,
            Permission::ViewEvents,
            Permission::CreateEvents,
            Permission::GloballyPublishEvents,
            Permission::ModerateEvents,
            Permission::Admin,
            Permission::ModerateUsers,
        ] {
            if permission.as_str_name() == *self {
                return Some(permission);
            }
        }
        return None;
    }
}

impl ToProtoServerConfiguration for models::ServerConfiguration {
    fn to_proto(&self) -> ServerConfiguration {
        let server_info: ServerInfo = serde_json::from_value(self.server_info.to_owned()).unwrap();
        let post_settings: FeatureSettings =
            serde_json::from_value(self.post_settings.to_owned()).unwrap();
        let event_settings: FeatureSettings =
            serde_json::from_value(self.event_settings.to_owned()).unwrap();
        let permissions: Vec<String> =
            serde_json::from_value(self.default_user_permissions.to_owned()).unwrap();
        let mapped_permissions: Vec<i32> = permissions
            .iter()
            .map(|permission| permission.to_proto_permission())
            .filter(|permission| permission.is_some())
            .map(|permission| permission.unwrap() as i32)
            .collect();
        ServerConfiguration {
            server_info: Some(server_info),
            default_user_permissions: mapped_permissions,
            post_settings: Some(post_settings),
            event_settings: Some(event_settings),
            ..Default::default()
        }
    }
}
