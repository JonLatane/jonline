use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::schema::{push_tokens, push_token_posts};

// pub fn get_push_token_and_push_token_post(
//     push_token_id: i64,
//     user_id: Option<i64>,
//     conn: &mut PgPooledConnection,
// ) -> Result<(PushToken, Option<PushTokenPost>), Status> {
//     push_tokens::table
//         .left_join(
//             push_token_posts::table.on(push_token_posts::push_token_id
//                 .eq(push_tokens::id)
//                 .and(push_token_posts::user_id.nullable().eq(user_id))),
//         )
//         .select((push_tokens::all_columns, push_token_posts::all_columns.nullable()))
//         .filter(push_tokens::id.eq(push_token_id))
//         .first::<(PushToken, Option<PushTokenPost>)>(conn)
//         .map_err(|_| Status::new(Code::NotFound, "push_token_push_token_post_data_not_found"))
// }

pub fn get_push_token(push_token_id: i64, conn: &mut PgPooledConnection) -> Result<PushToken, Status> {
    push_tokens::table
        .select(push_tokens::all_columns)
        .filter(push_tokens::id.eq(push_token_id))
        .first::<PushToken>(conn)
        .map_err(|_| Status::new(Code::NotFound, "push_token_not_found"))
}

pub fn get_push_tokens(post_id: i64, conn: &mut PgPooledConnection) -> Result<Vec<PushToken>, Status> {
    push_tokens::table
        .inner_join(push_token_posts::table.on(push_tokens::id.eq(push_token_posts::push_token_id)))
        .select(push_tokens::all_columns)
        .filter(push_token_posts::post_id.eq(post_id))
        .load::<PushToken>(conn)
        .map_err(|_| Status::new(Code::NotFound, "push_tokens_not_found"))
}

// pub fn get_push_token_post(
//     push_token_id: i64,
//     user_id: i64,
//     conn: &mut PgPooledConnection,
// ) -> Result<PushTokenPost, Status> {
//     push_token_posts::table
//         .select(push_token_posts::all_columns)
//         .filter(push_token_posts::user_id.eq(user_id))
//         .filter(push_token_posts::push_token_id.eq(push_token_id))
//         .first::<PushTokenPost>(conn)
//         .map_err(|_| Status::new(Code::NotFound, "push_token_post_not_found"))
// }

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct PushToken {
    pub id: i64,
    pub token: String,
    pub user_id: Option<i64>,
    pub created_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = push_tokens)]
pub struct NewPushToken {
    pub token: String,
    pub user_id: Option<i64>,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct PushTokenPost {
    pub id: i64,
    pub push_token_id: i64,
    pub post_id: i64,
    pub created_at: SystemTime,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = push_token_posts)]
pub struct NewPushTokenPost {
    pub push_token_id: i64,
    pub post_id: i64,
}
