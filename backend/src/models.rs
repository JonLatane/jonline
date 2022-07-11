
use crate::schema::users;
use crate::schema::user_auth_tokens;
use crate::schema::user_refresh_tokens;
use crate::schema::posts;

#[derive(Queryable,Insertable)]
#[table_name="users"]
pub struct User<'a> {
    pub id: i32,
    pub username: &'a str,
    pub password_salted_hash: &'a str,
    pub email: Option<&'a str>,
    pub phone: Option<&'a str>
}

#[derive(Queryable,Insertable)]
#[table_name="posts"]
pub struct Post<'a> {
    pub id: i32,
    pub title: &'a str,
    pub body: &'a str,
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub shortcode: Option<&'a str>,
    pub published: bool,
}