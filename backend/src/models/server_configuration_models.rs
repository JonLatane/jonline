use std::time::SystemTime;

use crate::protos::{FeatureSettings, Moderation, Permission, ServerInfo, Visibility};
use crate::schema::server_configurations;

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct ServerConfiguration {
    pub id: i32,

    pub active: bool,

    pub server_info: serde_json::Value,
    pub default_user_permissions: serde_json::Value,
    pub post_settings: serde_json::Value,
    pub event_settings: serde_json::Value,

    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}
#[derive(Debug, Insertable)]
#[table_name = "server_configurations"]
pub struct NewServerConfiguration {
    pub server_info: serde_json::Value,
    pub default_user_permissions: serde_json::Value,
    pub post_settings: serde_json::Value,
    pub event_settings: serde_json::Value,
}

pub fn default_server_configuration() -> NewServerConfiguration {
    return NewServerConfiguration {
        server_info: serde_json::to_value(ServerInfo {
            name: None,
            short_name: None,
            description: None,
            privacy_policy_link: None,
            about_link: None,
            logo: None,
        })
        .unwrap(),
        default_user_permissions: serde_json::to_value([
            Permission::ViewPosts,
            Permission::CreatePosts,
            Permission::GloballyPublishPosts,
            Permission::ViewEvents,
            Permission::CreateEvents,
            Permission::GloballyPublishEvents,
        ]
        .iter()
        .map(|it| it.as_str_name())
        .collect::<Vec<&str>>()).unwrap(),
        post_settings: serde_json::to_value(FeatureSettings {
            visible: true,
            default_moderation: Moderation::Unmoderated as i32,
            default_visibility: Visibility::GlobalPublic as i32,
            custom_title: None,
        })
        .unwrap(),
        event_settings: serde_json::to_value(FeatureSettings {
            visible: true,
            default_moderation: Moderation::Unmoderated as i32,
            default_visibility: Visibility::GlobalPublic as i32,
            custom_title: None,
        })
        .unwrap(),
    };
}
