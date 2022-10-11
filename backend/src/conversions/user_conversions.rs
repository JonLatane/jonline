use crate::conversions::*;
use crate::models;
use crate::protos::*;

pub trait ToProtoUser {
    fn to_proto(&self) -> User;
}
impl ToProtoUser for models::User {
    fn to_proto(&self) -> User {
        let email: Option<ContactMethod> = self
            .email
            .to_owned()
            .map(|cm| serde_json::from_value(cm).unwrap());
        let phone: Option<ContactMethod> = self
            .phone
            .to_owned()
            .map(|cm| serde_json::from_value(cm).unwrap());

        let user = User {
            id: self.id.to_proto_id().to_string(),
            username: self.username.to_owned(),
            email: email,
            phone: phone,
            permissions: self.permissions.to_i32_permissions(),
            avatar: self.avatar.to_owned(),
            visibility: self.visibility.to_proto_visibility().unwrap() as i32,
            default_follow_moderation: self.default_follow_moderation.to_proto_moderation().unwrap() as i32,
            follow_relationship: None,
        };
        // println!("Converted user: {:?}", user);
        return user;
    }
}
