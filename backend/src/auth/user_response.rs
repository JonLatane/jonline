use crate::models;
use crate::protos::*;

pub fn user_response(
    user_id: i32,
    username: String,
    email: Option<String>,
    phone: Option<String>,
) -> User {
    User {
        id: bs58::encode((user_id + 10000).to_string()).into_string(),
        username: username,
        email: email,
        phone: phone,
    }
}

pub trait ToUserResponse {
    fn to_user_response(&self) -> User;
}
impl ToUserResponse for models::User {
    fn to_user_response(&self) -> User {
        user_response(
            self.id,
            self.username.to_owned(),
            self.email.to_owned(),
            self.phone.to_owned(),
        )
    }
}
