use super::*;
use crate::models;
use crate::models::NewServerConfiguration;
use crate::protos::*;

pub trait ToDbServerConfiguration {
    fn to_db(&self) -> NewServerConfiguration;
}

impl ToDbServerConfiguration for ServerConfiguration {
    fn to_db(&self) -> NewServerConfiguration {
        NewServerConfiguration {
            server_info: serde_json::to_value(self.server_info.to_owned()).unwrap(),
            default_user_permissions: self.default_user_permissions.to_json_permissions(),
            people_settings: serde_json::to_value(self.people_settings.to_owned()).unwrap(),
            group_settings: serde_json::to_value(self.group_settings.to_owned()).unwrap(),
            post_settings: serde_json::to_value(self.post_settings.to_owned()).unwrap(),
            event_settings: serde_json::to_value(self.event_settings.to_owned()).unwrap(),
            private_user_strategy: self.private_user_strategy.to_string_private_user_strategy(),
            authentication_features: self
                .authentication_features
                .to_json_authentication_features(),
        }
    }
}

pub trait ToProtoServerConfiguration {
    fn to_proto(&self) -> ServerConfiguration;
}
impl ToProtoServerConfiguration for models::ServerConfiguration {
    fn to_proto(&self) -> ServerConfiguration {
        let server_info: ServerInfo = serde_json::from_value(self.server_info.to_owned()).unwrap();
        let group_settings: FeatureSettings =
            serde_json::from_value(self.group_settings.to_owned()).unwrap();
        let people_settings: FeatureSettings =
            serde_json::from_value(self.people_settings.to_owned()).unwrap();
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
            people_settings: Some(people_settings),
            group_settings: Some(group_settings),
            post_settings: Some(post_settings),
            event_settings: Some(event_settings),

            private_user_strategy: self.private_user_strategy.to_i32_private_user_strategy(),
            authentication_features: self
                .authentication_features
                .to_i32_authentication_features(), // ..Default::default()
        }
    }
}
