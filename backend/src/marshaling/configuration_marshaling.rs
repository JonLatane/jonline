use super::*;
use crate::models::NewServerConfiguration;
use crate::models::{self, default_server_configuration};
use crate::protos::*;
use std::mem::transmute;

pub trait ToDbServerConfiguration {
    fn to_db(&self) -> NewServerConfiguration;
}

impl ToDbServerConfiguration for ServerConfiguration {
    fn to_db(&self) -> NewServerConfiguration {
        NewServerConfiguration {
            server_info: serde_json::to_value(self.server_info.to_owned()).unwrap(),
            anonymous_user_permissions: self.anonymous_user_permissions.to_json_permissions(),
            default_user_permissions: self.default_user_permissions.to_json_permissions(),
            basic_user_permissions: self.basic_user_permissions.to_json_permissions(),
            people_settings: serde_json::to_value(self.people_settings.to_owned()).unwrap(),
            group_settings: serde_json::to_value(self.group_settings.to_owned()).unwrap(),
            post_settings: serde_json::to_value(self.post_settings.to_owned()).unwrap(),
            event_settings: serde_json::to_value(self.event_settings.to_owned()).unwrap(),
            external_cdn_config: self
                .external_cdn_config
                .as_ref()
                .map(|c| serde_json::to_value(c).unwrap()),
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
        let server_info: ServerInfo = serde_json::from_value(self.server_info.to_owned())
            .unwrap_or(ServerInfo {
                name: self.server_info["name"].as_str().map(|s| s.to_string()),
                short_name: self.server_info["short_name"]
                    .as_str()
                    .map(|s| s.to_string()),
                description: self.server_info["description"]
                    .as_str()
                    .map(|s| s.to_string()),
                privacy_policy: self.server_info["privacy_policy"]
                    .as_str()
                    .map(|s| s.to_string()),
                logo: serde_json::from_value(self.server_info["logo"].clone()).ok(),
                web_user_interface: Some(WebUserInterface::ReactTamagui.into()), //serde_json::from_value(self.server_info["web_user_interface"]).unwrap_or(WebUserInterface::ReactTamagui),
                // serde_json::from_value(self.server_info["web_user_interface"])
                //     .map(|v: String| v.to_proto_web_ui())
                //     ,
                colors: Some(
                    serde_json::from_value(self.server_info["web_user_interface"].clone())
                        .unwrap_or(
                            serde_json::from_value(
                                default_server_configuration().server_info["colors"].clone(),
                            )
                            .unwrap_or(ServerColors::default()),
                        ),
                ),
                media_policy: self.server_info["media_policy"]
                    .as_str()
                    .map(|s| s.to_string()),
                recommended_server_hosts: serde_json::from_value(
                    self.server_info["recommended_server_hosts"].clone(),
                )
                .unwrap_or(vec![]),
            });
        //ServerInfo::try_from(self.server_info.to_owned()).unwrap();
        // serde_json::from_value(self.server_info.to_owned()).unwrap();
        let group_settings: FeatureSettings =
            serde_json::from_value(self.group_settings.to_owned()).unwrap();
        let people_settings: FeatureSettings =
            serde_json::from_value(self.people_settings.to_owned()).unwrap();
        let post_settings: PostSettings =
            serde_json::from_value(self.post_settings.to_owned()).unwrap();
        let event_settings: FeatureSettings =
            serde_json::from_value(self.event_settings.to_owned()).unwrap();
        let external_cdn_config: Option<ExternalCdnConfig> = self
            .external_cdn_config
            .to_owned()
            .map(|c| serde_json::from_value(c).unwrap_or_else(|_| ExternalCdnConfig::default()));

        ServerConfiguration {
            server_info: Some(server_info),
            anonymous_user_permissions: self.anonymous_user_permissions.to_i32_permissions(),
            default_user_permissions: self.default_user_permissions.to_i32_permissions(),
            basic_user_permissions: self.basic_user_permissions.to_i32_permissions(),
            people_settings: Some(people_settings),
            group_settings: Some(group_settings),
            post_settings: Some(post_settings),
            event_settings: Some(event_settings),
            //TODO actually add media settings to the DB models...
            media_settings: Some(FeatureSettings {
                visible: true,
                default_moderation: Moderation::Unmoderated as i32,
                default_visibility: Visibility::GlobalPublic as i32,
                custom_title: None,
            }),
            private_user_strategy: self.private_user_strategy.to_i32_private_user_strategy(),
            authentication_features: self
                .authentication_features
                .to_i32_authentication_features(),
            external_cdn_config: external_cdn_config,
            // ..Default::default()
        }
    }
}

pub const ALL_WEB_UIS: [WebUserInterface; 3] = [
    WebUserInterface::FlutterWeb,
    WebUserInterface::HandlebarsTemplates,
    WebUserInterface::ReactTamagui,
];

pub trait ToProtoWebUI {
    fn to_proto_web_ui(&self) -> Option<WebUserInterface>;
}
impl ToProtoWebUI for String {
    fn to_proto_web_ui(&self) -> Option<WebUserInterface> {
        for web_ui in ALL_WEB_UIS {
            if web_ui.as_str_name().eq_ignore_ascii_case(self) {
                return Some(web_ui);
            }
        }
        return None;
    }
}
impl ToProtoWebUI for i32 {
    fn to_proto_web_ui(&self) -> Option<WebUserInterface> {
        Some(unsafe { transmute::<i32, WebUserInterface>(*self) })
    }
}
pub trait ToStringWebUI {
    fn to_string_web_ui(&self) -> String;
}
impl ToStringWebUI for WebUserInterface {
    fn to_string_web_ui(&self) -> String {
        self.as_str_name().to_string()
    }
}
impl ToStringWebUI for i32 {
    fn to_string_web_ui(&self) -> String {
        self.to_proto_web_ui().unwrap().to_string_web_ui()
    }
}
