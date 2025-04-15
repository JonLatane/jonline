use std::ops::Add;
use std::time::Duration;
use std::time::SystemTime;

use diesel::*;
use rand;
use rand::Rng;
use tonic::{Code, Status};

use crate::auth;
use crate::db_connection::*;
use crate::protos::*;
use crate::schema::user_refresh_tokens;

pub fn access_token(
    request: AccessTokenRequest,
    conn: &mut PgPooledConnection,
) -> Result<AccessTokenResponse, Status> {
    log::info!("AccessToken called.");
    let requested_token = &request.refresh_token;
    let token_user_expiry: Result<(i64, i64, Option<SystemTime>), _> = user_refresh_tokens::table
        .select((
            user_refresh_tokens::id,
            user_refresh_tokens::user_id,
            user_refresh_tokens::expires_at,
        ))
        .filter(user_refresh_tokens::token.eq(requested_token))
        .first::<(i64, i64, Option<SystemTime>)>(conn);

    const LIFETIME_DAYS: u64 = 7;
    const RENEWAL_PERIOD_DAYS: u64 = 1;
    match token_user_expiry {
        Err(_) => {
            log::warn!("Auth token {} not found.", requested_token);
            Err(Status::new(Code::Unauthenticated, "not_authorized"))
        }
        Ok((refresh_token_id, user_id, expires_at)) => match expires_at {
            Some(t) if t > SystemTime::now() => {
                log::warn!(
                    "Attempt to use expired refresh token. refresh_token_id={}, user_id={}",
                    refresh_token_id,
                    user_id
                );
                Err(Status::new(Code::Unauthenticated, "not_authorized"))
            }
            Some(t)
                if t.add(Duration::from_secs(60 * 60 * 24 * RENEWAL_PERIOD_DAYS))
                    > SystemTime::now() =>
            {
                log::info!(
                            "Generating both refresh token and access token for user_id={}, refresh_token_id={}...",
                            user_id, refresh_token_id
                        );
                let new_expiry =
                    SystemTime::now().add(Duration::from_secs(60 * 60 * 24 * LIFETIME_DAYS));
                let new_token_pair = auth::generate_refresh_and_access_token(
                    user_id,
                    conn,
                    &Some(new_expiry.into()),
                );
                Ok(AccessTokenResponse {
                    access_token: new_token_pair.access_token,
                    refresh_token: new_token_pair.refresh_token,
                })
            }
            Some(t) => {
                log::info!(
                    "Generating access token for user_id={}, refresh_token_id={}...",
                    user_id,
                    refresh_token_id
                );
                let access_token = auth::generate_access_token(refresh_token_id, conn);
                Ok(AccessTokenResponse {
                    access_token: Some(access_token),
                    refresh_token: None,
                })
            }
            None => {
                match rand::thread_rng().gen_range(0..=2) {
                    0 => {
                        log::info!("Randomly generating new refresh/access token pair for non-expiring refresh token for user_id={}; current token will expire in 60s.", user_id);
                        // log::warn!("Randomly failing to generate access token for user_id={}", user_id);

                        let new_expiry = SystemTime::now().add(Duration::from_secs(60));
                        diesel::update(user_refresh_tokens::table)
                            .set(user_refresh_tokens::expires_at.eq(new_expiry))
                            .filter(user_refresh_tokens::id.eq(refresh_token_id))
                            .execute(conn)
                            .map_err(|e| {
                                log::error!(
                                    "Failed to delete refresh token for user_id={}: {:?}",
                                    user_id,
                                    e
                                );
                                Status::new(Code::Internal, "internal_error")
                            })?;
                        let new_token_pair =
                            auth::generate_refresh_and_access_token(user_id, conn, &None);
                        Ok(AccessTokenResponse {
                            access_token: new_token_pair.access_token,
                            refresh_token: new_token_pair.refresh_token,
                        })
                    }
                    _ => {
                        log::debug!("Generating access token for user_id={}", user_id);
                        let access_token = auth::generate_access_token(refresh_token_id, conn);
                        Ok(AccessTokenResponse {
                            access_token: Some(access_token),
                            refresh_token: None,
                        })
                    }
                }
                // let num = rand::thread_rng().gen_range(0..=0);

                // let access_token = auth::generate_access_token(refresh_token_id, conn);
                // Ok(AccessTokenResponse {
                //     access_token: Some(access_token),
                //     refresh_token: None,
                // })
            } // _ => {
              //     log::debug!("Generating access token for user_id={}", user_id);
              //     let access_token = auth::generate_access_token(refresh_token_id, conn);
              //     Ok(AccessTokenResponse {
              //         access_token: Some(access_token),
              //         refresh_token: None,
              //     })
              // }
        },
    }
}
