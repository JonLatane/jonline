use super::id_conversions::ToProtoId;
use crate::models;
use crate::protos::*;

pub trait ToProtoUser {
    fn to_proto(&self) -> User;
}
impl ToProtoUser for models::User {
    fn to_proto(&self) -> User {
        User {
            id: self.id.to_proto_id().to_string(),
            username: self.username.to_owned(),
            email: self.email.to_owned(),
            phone: self.phone.to_owned(),
        }
    }
}
