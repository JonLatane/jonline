use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::schema::{groups, memberships};

pub fn get_group_and_membership(
    group_id: i64,
    user_id: Option<i64>,
    conn: &mut PgPooledConnection,
) -> Result<(Group, Option<Membership>), Status> {
    groups::table
        .left_join(memberships::table.on(memberships::group_id.eq(groups::id)))
        .select((groups::all_columns, memberships::all_columns.nullable()))
        .filter(memberships::user_id.nullable().eq(user_id))
        .filter(memberships::group_id.eq(group_id))
        .first::<(Group, Option<Membership>)>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_membership_data_not_found"))
}

pub fn get_group(group_id: i64, conn: &mut PgPooledConnection) -> Result<Group, Status> {
    groups::table
        .select(groups::all_columns)
        .filter(groups::id.eq(group_id))
        .first::<Group>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))
}

pub fn get_membership(
    group_id: i64,
    user_id: i64,
    conn: &mut PgPooledConnection,
) -> Result<Membership, Status> {
    memberships::table
        .select(memberships::all_columns)
        .filter(memberships::user_id.eq(user_id))
        .filter(memberships::group_id.eq(group_id))
        .first::<Membership>(conn)
        .map_err(|_| Status::new(Code::NotFound, "membership_not_found"))
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Group {
    pub id: i64,
    pub name: String,
    pub shortname: String,
    pub description: String,
    pub avatar_media_id: Option<i64>,
    pub visibility: String,
    pub non_member_permissions: serde_json::Value,
    pub default_membership_permissions: serde_json::Value,
    pub default_membership_moderation: String,
    pub default_post_moderation: String,
    pub default_event_moderation: String,
    pub moderation: String,
    pub member_count: i32,
    pub post_count: i32,
    pub event_count: i32,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = groups)]
pub struct NewGroup {
    pub name: String,
    pub shortname: String,
    pub description: String,
    pub avatar_media_id: Option<i64>,
    pub visibility: String,
    pub non_member_permissions: serde_json::Value,
    pub default_membership_permissions: serde_json::Value,
    pub default_membership_moderation: String,
    pub default_post_moderation: String,
    pub default_event_moderation: String,
    pub member_count: i32,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Membership {
    pub id: i64,
    pub user_id: i64,
    pub group_id: i64,
    pub permissions: serde_json::Value,
    pub group_moderation: String,
    pub user_moderation: String,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = memberships)]
pub struct NewMembership {
    pub user_id: i64,
    pub group_id: i64,
    pub permissions: serde_json::Value,
    pub group_moderation: String,
    pub user_moderation: String,
}
