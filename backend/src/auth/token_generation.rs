use std::option::Option;
use std::time::SystemTime;

use diesel::*;
use prost_types::*;
use ring::rand::*;

use crate::db_connection::*;
use crate::protos::*;
use crate::schema::user_auth_tokens::dsl as user_auth_tokens;
use crate::schema::user_refresh_tokens::dsl as user_refresh_tokens;

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

pub fn generate_auth_and_refresh_token(
    user_id: i32,
    conn: &PgPooledConnection,
    expires_at: Option<Timestamp>,
) -> AuthTokenResponse {
    let auth_token = generate_token!(512);

    let requested_expiration: Option<SystemTime> = expires_at
        .map(SystemTime::try_from)
        .map(|x| x.ok())
        .flatten();
    let (auth_token_id, expires_at): (i32, Option<SystemTime>) =
        insert_into(user_auth_tokens::user_auth_tokens)
            .values((
                user_auth_tokens::user_id.eq(user_id),
                user_auth_tokens::token.eq(auth_token.to_owned()),
                user_auth_tokens::expires_at.eq(requested_expiration),
            ))
            .returning((user_auth_tokens::id, user_auth_tokens::expires_at))
            .get_result::<(i32, Option<SystemTime>)>(conn)
            .unwrap();
    let auth_exp_token = ExpirableToken {
        token: auth_token.to_owned(),
        expires_at: expires_at.map(Timestamp::from),
    };
    println!("Generated auth token for user_id={}", user_id);

    let refresh_exp_token = generate_refresh_token(auth_token_id, conn);
    AuthTokenResponse {
        auth_token: Some(auth_exp_token),
        refresh_token: Some(refresh_exp_token),
        user: None,
    }
}

pub fn generate_refresh_token(auth_token_id: i32, conn: &PgPooledConnection) -> ExpirableToken {
    let refresh_token = generate_token!(128);
    let expires_at: SystemTime = insert_into(user_refresh_tokens::user_refresh_tokens)
        .values((
            user_refresh_tokens::auth_token_id.eq(auth_token_id),
            user_refresh_tokens::token.eq(refresh_token.to_owned()),
        ))
        .returning(user_refresh_tokens::expires_at)
        .get_result::<SystemTime>(conn)
        .unwrap();
    println!("Generated refresh token for auth_token_id={}", auth_token_id);
    ExpirableToken {
        token: refresh_token.to_owned(),
        expires_at: Some(Timestamp::from(expires_at)),
    }
}
