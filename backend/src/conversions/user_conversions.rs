use crate::models;
use crate::protos::*;

pub fn proto_user(
    user_id: i32,
    username: String,
    email: Option<String>,
    phone: Option<String>,
) -> User {
    let id_bytes = (user_id + 10000).to_ne_bytes();
    User {
        id: bs58::encode(id_bytes).into_string(),
        username: username,
        email: email,
        phone: phone,
    }
}

// Converts a Protobuf User's id
pub fn proto_user_db_id(
    user: &User
) -> Result<i32, bs58::decode::Error> {
    proto_user_id_to_db_id(&user.id)
}

pub fn proto_user_id_to_db_id(
    id: &str
) -> Result<i32, bs58::decode::Error> {
    let id_bytes = bs58::decode(id).into_vec()?;
    let id = i32::from_ne_bytes(id_bytes.as_slice().try_into().unwrap_or([0; 4]));
    if id == 0 {
        return Err(bs58::decode::Error::InvalidCharacter { character: '0', index: 0 });
    }
    Ok(id - 10000)
}

pub trait ToProtoUser {
    fn to_proto_user(&self) -> User;
}
impl ToProtoUser for models::User {
    fn to_proto_user(&self) -> User {
        proto_user(
            self.id,
            self.username.to_owned(),
            self.email.to_owned(),
            self.phone.to_owned(),
        )
    }
}
