use super::*;
use crate::models::{self, NewServerConfiguration};
use crate::protos::*;
use std::mem::transmute;

pub trait ToDbServerConfiguration {
    fn to_db(&self) -> NewServerConfiguration;
}

impl ToDbServerConfiguration for ServerConfiguration {
    fn to_db(&self) -> NewServerConfiguration {
        NewServerConfiguration {
            server_info: serde_json::to_value(self.server_info.to_owned()).unwrap(),
            federation_info: serde_json::to_value(self.federation_info.to_owned()).unwrap(),
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
            web_push_config: self
                .web_push_config
                .as_ref()
                .map(|c| serde_json::to_value(c).unwrap()),
            custom_tabs: self
                .custom_tabs
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
        let server_info: ServerInfo = serde_json::from_value(self.server_info.to_owned()).unwrap();
        let mut federation_info: FederationInfo =
            serde_json::from_value(self.federation_info.to_owned()).unwrap();
        // `FacebookAuthConfig.app_secret` is write-only -- never send the real value to a
        // client. See `configure_server`'s merge logic for how a blank incoming value is kept
        // from clobbering the stored secret.
        federation_info.facebook_auth_config =
            federation_info
                .facebook_auth_config
                .map(|c| FacebookAuthConfig {
                    app_secret: String::new(),
                    ..c
                });
        // `XTwitterAuthConfig.client_secret` is write-only, same reasoning (and same
        // `configure_server` merge-on-blank counterpart) as `FacebookAuthConfig.app_secret` above.
        federation_info.x_twitter_auth_config =
            federation_info
                .x_twitter_auth_config
                .map(|c| XTwitterAuthConfig {
                    client_secret: String::new(),
                    ..c
                });
        let group_settings: FeatureSettings =
            serde_json::from_value(self.group_settings.to_owned()).unwrap();
        let people_settings: FeatureSettings =
            serde_json::from_value(self.people_settings.to_owned()).unwrap();
        let post_settings: PostSettings =
            serde_json::from_value(self.post_settings.to_owned()).unwrap();
        let event_settings: EventSettings =
            serde_json::from_value(self.event_settings.to_owned()).unwrap();
        let external_cdn_config: Option<ExternalCdnConfig> = self
            .external_cdn_config
            .to_owned()
            .map(|c| serde_json::from_value(c).unwrap_or_else(|_| ExternalCdnConfig::default()));
        // `WebPushConfig.private_vapid_key` is write-only -- never send the real value to a
        // client, same reasoning (and same `configure_server` merge-on-blank counterpart) as
        // `FacebookAuthConfig.app_secret` above.
        let web_push_config: Option<WebPushConfig> = self
            .web_push_config
            .to_owned()
            .map_or(Some(None), |c| serde_json::from_value(c).ok())
            .flatten()
            .map(|c| WebPushConfig {
                private_vapid_key: String::new(),
                ..c
            });
        // .map(|c| serde_json::from_value(c).unwrap_or_else(|_| None));
        let custom_tabs: Option<CustomNavigationTabSet> =
            self.custom_tabs.to_owned().and_then(deserialize_custom_tabs);

        ServerConfiguration {
            server_info: Some(server_info),
            federation_info: Some(federation_info),
            anonymous_user_permissions: self.anonymous_user_permissions.to_i32_permissions(),
            default_user_permissions: self.default_user_permissions.to_i32_permissions(),
            basic_user_permissions: self.basic_user_permissions.to_i32_permissions(),
            people_settings: Some(people_settings),
            group_settings: Some(group_settings),
            post_settings: Some(post_settings),
            event_settings: Some(event_settings),
            custom_tabs: custom_tabs,
            //TODO actually add media settings to the DB models...
            media_settings: Some(MediaSettings {
                visible: true,
                default_moderation: Moderation::Unmoderated as i32,
                default_visibility: Visibility::GlobalPublic as i32,
            }),
            private_user_strategy: self.private_user_strategy.to_i32_private_user_strategy(),
            authentication_features: self
                .authentication_features
                .to_i32_authentication_features(),
            external_cdn_config: external_cdn_config,
            web_push_config: web_push_config, // ..Default::default()
        }
    }
}

/// Backward-compatible deserialization for `ServerConfiguration.custom_tabs`, stored as plain JSON
/// (not protobuf wire bytes -- see `ToDbServerConfiguration::to_db` above), across the breaking
/// `CustomNavigationTabSet.home`/`tabs` shape change (`home` used to be a bare `CustomNavigationTab`
/// restricted by convention -- never by the type itself -- to Home/Events/Posts/a Post; it's now
/// its own dedicated `CustomHomePage`. `tabs` used to wrap each entry in a `CustomNavigationTabWithPath`;
/// `path` now lives on `CustomNavigationTab` itself). Three layers, each a real attempt rather than
/// a blind fallback, so a config actually gets migrated rather than silently reset whenever that's
/// at all possible:
///   1. Deserialize as the *current* shape -- succeeds for every config saved since this migration
///      shipped (including a freshly-initialized server), since `Serialize` always emits every
///      field and this is exactly what it wrote.
///   2. Otherwise, deserialize as the *legacy* shape (`legacy_custom_tabs`) and transform it into
///      the current one, preserving an admin's existing custom nav setup across the upgrade.
///   3. Otherwise -- neither shape fits, e.g. a config saved by some future, again-different
///      version -- fall back to `None` (no custom tabs) rather than ever failing the whole
///      `ServerConfiguration` fetch over it. Logged (unlike the old unconditional `.ok()` this
///      replaces) so a revert to defaults is at least diagnosable, never silent operationally.
fn deserialize_custom_tabs(value: serde_json::Value) -> Option<CustomNavigationTabSet> {
    match serde_json::from_value::<CustomNavigationTabSet>(value.clone()) {
        Ok(current) => Some(current),
        Err(current_err) => match serde_json::from_value::<legacy_custom_tabs::CustomNavigationTabSet>(value) {
            Ok(legacy) => Some(legacy.into_current()),
            Err(legacy_err) => {
                log::warn!(
                    "custom_tabs failed to deserialize as either the current or legacy shape (current: {}; legacy: {}) -- resetting to unset rather than failing the configuration fetch",
                    current_err,
                    legacy_err
                );
                None
            }
        },
    }
}

/// The pre-migration JSON shape of `CustomNavigationTabSet`/`CustomNavigationTab`, kept only so
/// `deserialize_custom_tabs` can recover an admin's existing setup -- see that function's own doc.
/// Field/variant names below must match exactly what the *old* generated prost types' own
/// `#[derive(serde::Serialize)]` actually produced; `custom_navigation_tab::Target`/`Icon`
/// themselves are reused directly from `crate::protos` since this migration didn't touch their own
/// shape at all (only which messages carry `path`, and what type `home` is), so their JSON
/// representation is identical whichever version wrote it. Can be deleted once every server still
/// running the old shape has saved a config at least once post-upgrade -- there's no way to know
/// that from here, so: in the distant future.
mod legacy_custom_tabs {
    use crate::protos::{
        custom_home_page, custom_navigation_tab, CalendarDisplayMode, CustomHomePage,
        CustomNavigationTab as CurrentTab, CustomNavigationTabSet as CurrentSet,
    };

    // Deliberately *no* `#[serde(default)]` on either field here (unlike the sub-fields below) --
    // a real legacy blob always has both keys present (`Serialize` on the old type emitted every
    // field, same as the current one does), so requiring them is what keeps this from matching
    // arbitrary unrelated JSON (e.g. `{}`, or some future-again-different shape) and silently
    // "migrating" it into an empty `CustomNavigationTabSet` -- that should fall through to
    // `deserialize_custom_tabs`'s own logged `None` fallback instead.
    #[derive(serde::Deserialize)]
    pub struct CustomNavigationTabSet {
        home: Option<CustomNavigationTab>,
        tabs: Vec<CustomNavigationTabWithPath>,
    }

    #[derive(serde::Deserialize)]
    struct CustomNavigationTab {
        #[serde(default)]
        target: Option<custom_navigation_tab::Target>,
        #[serde(default)]
        icon: Option<custom_navigation_tab::Icon>,
        #[serde(default)]
        title: Option<String>,
    }

    #[derive(serde::Deserialize)]
    struct CustomNavigationTabWithPath {
        #[serde(default)]
        custom_tab: Option<CustomNavigationTab>,
        #[serde(default)]
        path: String,
    }

    impl CustomNavigationTabSet {
        pub fn into_current(self) -> CurrentSet {
            CurrentSet {
                home: self.home.and_then(CustomNavigationTab::into_current_home),
                tabs: self
                    .tabs
                    .into_iter()
                    .filter_map(CustomNavigationTabWithPath::into_current)
                    .collect(),
            }
        }
    }

    impl CustomNavigationTab {
        /// `home`'s own doc already restricted its `target` to `Tab(Home|Events|Posts)`/`PostId`
        /// (enforced by `validate_configuration`, never by the old type itself) -- an `IsProfile`
        /// here could only ever come from a hand-edited config, and has no `CustomHomePage.target`
        /// variant to become, so it's dropped (`None`, i.e. "no home override") same as an unset
        /// `target` (nothing meaningful to migrate either way).
        fn into_current_home(self) -> Option<CustomHomePage> {
            let target = match self.target? {
                custom_navigation_tab::Target::Tab(tab) => custom_home_page::Target::Tab(tab),
                custom_navigation_tab::Target::PostId(post_id) => {
                    custom_home_page::Target::PostId(post_id)
                }
                custom_navigation_tab::Target::IsProfile(_) => return None,
            };
            Some(CustomHomePage {
                target: Some(target),
                pinned_post_ids: Vec::new(),
                show_events_strip: false,
                default_events_strip_to_row: false,
                default_events_strip_calendar_display_mode: CalendarDisplayMode::CalendarDisplayWeek
                    as i32,
            })
        }

        fn into_current_tab(self, path: String) -> CurrentTab {
            CurrentTab {
                target: self.target,
                icon: self.icon,
                title: self.title,
                path,
            }
        }
    }

    impl CustomNavigationTabWithPath {
        fn into_current(self) -> Option<CurrentTab> {
            Some(self.custom_tab?.into_current_tab(self.path))
        }
    }
}

pub const ALL_WEB_UIS: [WebUserInterface; 4] = [
    WebUserInterface::FlutterWeb,
    WebUserInterface::HandlebarsTemplates,
    WebUserInterface::ReactTamagui,
    WebUserInterface::ElmSpa,
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

#[cfg(test)]
mod custom_tabs_migration_tests {
    use super::deserialize_custom_tabs;
    use crate::protos::*;

    /// A config saved by *this* version round-trips straight through the first (current-shape)
    /// deserialization attempt.
    #[test]
    fn current_shape_round_trips() {
        let set = CustomNavigationTabSet {
            home: Some(CustomHomePage {
                target: Some(custom_home_page::Target::PostId("post1".to_string())),
                pinned_post_ids: vec!["post2".to_string()],
                show_events_strip: true,
                default_events_strip_to_row: true,
                default_events_strip_calendar_display_mode: CalendarDisplayMode::CalendarDisplayMonth
                    as i32,
            }),
            tabs: vec![CustomNavigationTab {
                target: Some(custom_navigation_tab::Target::Tab(
                    NavigationTab::EventsTab as i32,
                )),
                icon: Some(custom_navigation_tab::Icon::EmojiIcon("📅".to_string())),
                title: None,
                path: "gigs".to_string(),
            }],
        };
        let value = serde_json::to_value(&set).unwrap();
        assert_eq!(deserialize_custom_tabs(value), Some(set));
    }

    /// A config saved by the *pre-migration* backend (`home: CustomNavigationTab`, `tabs:
    /// Vec<CustomNavigationTabWithPath>`) -- hand-built JSON matching exactly what that old
    /// generated `#[derive(serde::Serialize)]` produced -- migrates into the current shape rather
    /// than getting reset to unset.
    #[test]
    fn legacy_shape_migrates() {
        let legacy = serde_json::json!({
            "home": {
                "target": { "Tab": NavigationTab::EventsTab as i32 },
                "icon": null,
                "title": null
            },
            "tabs": [
                {
                    "custom_tab": {
                        "target": { "PostId": "weddings-post" },
                        "icon": { "EmojiIcon": "💍" },
                        "title": "Weddings"
                    },
                    "path": "weddings"
                },
                {
                    "custom_tab": {
                        "target": { "IsProfile": true },
                        "icon": { "EmojiIcon": "👤" },
                        "title": null
                    },
                    "path": "someuser"
                }
            ]
        });

        let migrated = deserialize_custom_tabs(legacy).expect("legacy shape should migrate");

        assert_eq!(
            migrated.home,
            Some(CustomHomePage {
                target: Some(custom_home_page::Target::Tab(NavigationTab::EventsTab as i32)),
                ..Default::default()
            })
        );
        assert_eq!(migrated.tabs.len(), 2);
        assert_eq!(migrated.tabs[0].path, "weddings");
        assert_eq!(
            migrated.tabs[0].target,
            Some(custom_navigation_tab::Target::PostId(
                "weddings-post".to_string()
            ))
        );
        assert_eq!(migrated.tabs[0].title, Some("Weddings".to_string()));
        assert_eq!(migrated.tabs[1].path, "someuser");
        assert_eq!(
            migrated.tabs[1].target,
            Some(custom_navigation_tab::Target::IsProfile(true))
        );
    }

    /// Neither shape fits -- falls back to `None` rather than panicking or propagating an error
    /// that would fail the whole `ServerConfiguration` fetch.
    #[test]
    fn unrecognized_shape_falls_back_to_none() {
        let garbage = serde_json::json!({ "totally": "unrecognized" });
        assert_eq!(deserialize_custom_tabs(garbage), None);
    }
}
