use std::mem::transmute;

use super::permission_conversions::ToProtoPermission;
use crate::models;
use crate::models::NewServerConfiguration;
use crate::protos::*;

pub trait ToDbServerConfiguration {
    fn to_db(&self) -> models::NewServerConfiguration;
}

impl ToDbServerConfiguration for ServerConfiguration {
    fn to_db(&self) -> models::NewServerConfiguration {
        NewServerConfiguration {
            server_info: serde_json::to_value(self.server_info.to_owned()).unwrap(),
            default_user_permissions: serde_json::to_value(
                self.default_user_permissions
                    .iter()
                    .map(|p| (unsafe { transmute::<i32, Permission>(*p) }).as_str_name().to_string())
                    .collect::<Vec<String>>(),
            )
            .unwrap(),
            post_settings: serde_json::to_value(self.post_settings.to_owned()).unwrap(),
            event_settings: serde_json::to_value(self.event_settings.to_owned()).unwrap(),
        }
    }
}

pub trait ToProtoServerConfiguration {
    fn to_proto(&self) -> ServerConfiguration;
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
