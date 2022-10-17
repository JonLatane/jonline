use std::time::SystemTime;

use tonic::{Code, Status};
use diesel::*;

use crate::db_connection::PgPooledConnection;
use crate::schema::{groups, memberships};

pub fn get_group(group_id: i32, conn: &mut PgPooledConnection,) -> Result<Group, Status> {
    groups::table
        .select(groups::all_columns)
        .filter(groups::id.eq(group_id))
        .first::<Group>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))
}

pub fn get_membership(group_id: i32, user_id: i32, conn: &mut PgPooledConnection,) -> Result<Membership, Status> {
    memberships::table
        .select(memberships::all_columns)
        .filter(memberships::user_id.eq(user_id))
        .filter(memberships::group_id.eq(group_id))
        .first::<Membership>(conn)
        .map_err(|_| Status::new(Code::NotFound, "membership_not_found"))
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Group {
    pub id: i32,
    pub name: String,
    pub description: Option<String>,
    pub avatar: Option<Vec<u8>>,
    pub visibility: String,
    pub default_membership_permissions: serde_json::Value,
    pub default_membership_moderation: String,
    pub default_post_moderation: String,
    pub default_event_moderation: String,
    pub moderation: String,
    pub member_count: i32,
    pub post_count: i32,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = groups)]
pub struct NewGroup {
    pub name: String,
    pub description: Option<String>,
    pub avatar: Option<Vec<u8>>,
    pub visibility: String,
    pub default_membership_permissions: serde_json::Value,
    pub default_membership_moderation: String,
    pub default_post_moderation: String,
    pub default_event_moderation: String,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Membership {
    pub id: i32,
    pub user_id: i32,
    pub group_id: i32,
    pub permissions: serde_json::Value,
    pub group_moderation: String,
    pub user_moderation: String,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = memberships)]
pub struct NewMembership {
    pub user_id: i32,
    pub group_id: i32,
    pub permissions: serde_json::Value,
    pub group_moderation: String,
    pub user_moderation: String,
}
