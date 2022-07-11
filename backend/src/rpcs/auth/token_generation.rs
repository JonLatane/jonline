// use crate::db_connection::*;
use crate::protos::*;
// use crate::schema::users::dsl::*;
// use bcrypt::{hash, DEFAULT_COST};
// use diesel::*;
// use ring::aead::*;
// use ring::pbkdf2::*;
use ring::rand::*;
// use tonic::{Code, Request, Response, Status};

macro_rules! generate_token {
    ($length_u8:expr) => {{
        let mut randoms: [u8; $length_u8] = [0; $length_u8];
        let sr = SystemRandom::new();
        sr.fill(&mut randoms).unwrap();
        let mut token = String::new();
        for i in randoms.iter() {
            token.push_str(&format!("{:x}", i));
        }
        token
    }};
}

pub fn generate_auth_and_refresh_token(user: User) -> LoginResponse {
    let auth_token = generate_token!(512);
    let refresh_token = generate_token!(128);
    LoginResponse {
        auth_token: Some(ExpirableToken {
            token: auth_token.to_owned(),
            expires_at: None,
        }),
        refresh_token: Some(ExpirableToken {
            token: refresh_token.to_owned(),
            expires_at: None,
        }),
        user: Some(user),
    }
}

// fn generate_token(length_u8: u32) -> String {
//     let mut randoms: [u8; length_u8] = [0; length_u8];
//     let sr = SystemRandom::new();
//     sr.fill(&mut randoms);
//     let mut token = String::new();
//     for i in randoms.iter() {
//         token.push_str(&format!("{:x}", i));
//     }
//     token
// }
