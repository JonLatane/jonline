use crate::protos::*;

pub trait ToProtoVisibility {
    fn to_proto_visibility(&self) -> Option<i32>;
}
impl ToProtoVisibility for String {
    fn to_proto_visibility(&self) -> Option<i32> {
        for visibility in [
            Visibility::Unknown,
            Visibility::Private,
            Visibility::Limited,
            Visibility::ServerPublic,
            Visibility::GlobalPublic,
        ] {
            if visibility.as_str_name().eq_ignore_ascii_case(self) {
                return Some(visibility as i32);
            }
        }
        return None;
    }
}
pub trait ToProtoModeration {
    fn to_proto_moderation(&self) -> Option<i32>;
}
impl ToProtoModeration for String {
    fn to_proto_moderation(&self) -> Option<i32> {
        for moderation in [
            Moderation::Unknown,
            Moderation::Unknown,
            Moderation::Pending,
            Moderation::Approved,
            Moderation::Rejected,
        ] {
            if moderation.as_str_name().eq_ignore_ascii_case(self) {
                return Some(moderation as i32);
            }
        }
        return None;
    }
}
