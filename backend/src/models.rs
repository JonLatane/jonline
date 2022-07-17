use std::time::SystemTime;

use crate::schema::users;
use crate::schema::posts;

#[derive(Queryable, Insertable)]
#[table_name = "users"]
pub struct User {
    pub id: i32,
    pub username: String,
    pub password_salted_hash: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Queryable, Insertable)]
#[table_name = "posts"]
pub struct Post {
    pub id: i32,
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub title: String,
    pub body: String,
    pub published: bool,
    pub created_at: SystemTime,
}
