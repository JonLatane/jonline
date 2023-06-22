use std::time::SystemTime;

use crate::marshaling::ToJsonPermissions;
use crate::protos::*;
use crate::schema::server_configurations;

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct ServerConfiguration {
    pub id: i64,

    pub active: bool,

    pub server_info: serde_json::Value,

    pub anonymous_user_permissions: serde_json::Value,
    pub default_user_permissions: serde_json::Value,
    pub basic_user_permissions: serde_json::Value,

    pub people_settings: serde_json::Value,
    pub group_settings: serde_json::Value,
    pub post_settings: serde_json::Value,
    pub event_settings: serde_json::Value,

    pub external_cdn_config: Option<serde_json::Value>,

    pub private_user_strategy: String,
    pub authentication_features: serde_json::Value,

    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = server_configurations)]
pub struct NewServerConfiguration {
    pub server_info: serde_json::Value,
    pub anonymous_user_permissions: serde_json::Value,
    pub default_user_permissions: serde_json::Value,
    pub basic_user_permissions: serde_json::Value,
    pub people_settings: serde_json::Value,
    pub group_settings: serde_json::Value,
    pub post_settings: serde_json::Value,
    pub event_settings: serde_json::Value,
    pub external_cdn_config: Option<serde_json::Value>,
    pub private_user_strategy: String,
    pub authentication_features: serde_json::Value,
}

pub fn default_server_configuration() -> NewServerConfiguration {
    let basic_user_permissions = vec![
        Permission::ViewUsers,
        Permission::FollowUsers,
        Permission::PublishUsersLocally,
        Permission::PublishUsersGlobally,
        Permission::ViewMedia,
        Permission::CreateMedia,
        Permission::PublishMediaLocally,
        Permission::PublishMediaGlobally,
        Permission::ViewGroups,
        Permission::CreateGroups,
        Permission::PublishGroupsLocally,
        Permission::PublishGroupsGlobally,
        Permission::JoinGroups,
        Permission::ViewPosts,
        Permission::CreatePosts,
        Permission::ReplyToPosts,
        Permission::PublishPostsLocally,
        Permission::PublishPostsGlobally,
        Permission::ReplyToPosts,
        Permission::ViewEvents,
        Permission::CreateEvents,
        Permission::PublishEventsLocally,
        Permission::PublishEventsGlobally,
    ]
    .to_json_permissions();
    return NewServerConfiguration {
        server_info: serde_json::to_value(ServerInfo {
            name: None,
            short_name: None,
            description: Some("
Jonline is a new, DIY federated social network. It's designed to be run by local businesses,
community groups, and other organizations. It's open source (AGPLv3) and designed to be as easy
and cheap to deploy as possible. It's built atop a [well-documented, performant, RESTful open-source protocol](https://github.com/JonLatane/jonline/blob/main/docs/protocol.md)
that operates over gRPC (with configurable TLS) on port 27707. Multi-server interaction is managed via CORS.

***This is a demo server.*** Please create an account and post! But your account will be deleted at some point.
If you're interested in me running an instance for you, get in touch with me at [jonlatane@gmail.com](mailto:jonlatane@gmail.com).
If this is an instance you're running, feel free to replace this text with your own by logging in as an admin 🙃
            ".to_string()),
            privacy_policy_link: None,
            about_link: None,
            web_user_interface: Some(WebUserInterface::ReactTamagui as i32),
            colors: Some(ServerColors {
                primary: Some(0xFF2E86AB),
                navigation: Some(0xFFA23B72),
                ..Default::default()
            }),
            logo: None,
        })
        .unwrap(),
        anonymous_user_permissions: vec![
            Permission::ViewUsers,
            Permission::ViewGroups,
            Permission::ViewPosts,
            Permission::ViewEvents,
            Permission::ViewMedia,
        ].to_json_permissions(),
        default_user_permissions: basic_user_permissions.to_owned(),
        basic_user_permissions: basic_user_permissions,
        people_settings: serde_json::to_value(FeatureSettings {
            visible: true,
            default_moderation: Moderation::Unmoderated as i32,
            default_visibility: Visibility::GlobalPublic as i32,
            custom_title: None,
        })
        .unwrap(),
        group_settings: serde_json::to_value(FeatureSettings {
            visible: true,
            default_moderation: Moderation::Unmoderated as i32,
            default_visibility: Visibility::ServerPublic as i32,
            custom_title: None,
        }).unwrap(),
        post_settings: serde_json::to_value(PostSettings {
            visible: true,
            default_moderation: Moderation::Unmoderated as i32,
            default_visibility: Visibility::ServerPublic as i32,
            custom_title: None,
            enable_replies: true,
        })
        .unwrap(),
        event_settings: serde_json::to_value(FeatureSettings {
            visible: true,
            default_moderation: Moderation::Unmoderated as i32,
            default_visibility: Visibility::ServerPublic as i32,
            custom_title: None,
        })
        .unwrap(),
        external_cdn_config: None,
        private_user_strategy: PrivateUserStrategy::AccountIsFrozen
            .as_str_name()
            .to_string(),
        authentication_features: serde_json::to_value(
            [
                AuthenticationFeature::Login,
                AuthenticationFeature::CreateAccount,
            ]
            .iter()
            .map(|it| it.as_str_name())
            .collect::<Vec<&str>>(),
        )
        .unwrap(),
    };
}
