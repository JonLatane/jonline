use crate::db_connection::*;
use crate::protos::*;

use crate::schema::user_auth_tokens::dsl as user_auth_tokens;
use crate::schema::user_refresh_tokens::dsl as user_refresh_tokens;

use diesel::*;
use ring::rand::*;

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
) -> AuthTokenResponse {
    let auth_token = generate_token!(512);

    let auth_token_id: i32 = insert_into(user_auth_tokens::user_auth_tokens)
        .values((
            user_auth_tokens::user_id.eq(user_id),
            user_auth_tokens::token.eq(auth_token.to_owned()),
        ))
        .returning(user_auth_tokens::id)
        .get_result::<i32>(conn)
        .unwrap();
    let auth_token_result = ExpirableToken {
        token: auth_token.to_owned(),
        expires_at: None,
    };
    let refresh_token_result = generate_refresh_token(auth_token_id, conn);

    AuthTokenResponse {
        auth_token: Some(auth_token_result),
        refresh_token: Some(refresh_token_result),
        user: None,
    }
}

pub fn generate_refresh_token(auth_token_id: i32, conn: &PgPooledConnection) -> ExpirableToken {
    let refresh_token = generate_token!(128);
    let _refresh_token_id: i32 = insert_into(user_refresh_tokens::user_refresh_tokens)
        .values((
            user_refresh_tokens::auth_token_id.eq(auth_token_id),
            user_refresh_tokens::token.eq(refresh_token.to_owned()),
        ))
        .returning(user_refresh_tokens::id)
        .get_result::<i32>(conn)
        .unwrap();
    ExpirableToken {
        token: refresh_token.to_owned(),
        expires_at: None,
    }
}
