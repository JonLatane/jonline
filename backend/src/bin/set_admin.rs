extern crate diesel;
extern crate jonline;
extern crate serde_json;
use diesel::*;
use jonline::conversions::ToProtoId;
use jonline::db_connection;
// use jonline::schema::user_auth_tokens::dsl as user_auth_tokens;
// use jonline::schema::user_refresh_tokens::dsl as user_refresh_tokens;
use jonline::schema::*;
// use serde_json::Value::Array;
use std::env;

pub fn main() {
    let admin_permission = jonline::protos::Permission::Admin.as_str_name();
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        return println!("Usage: set_admin <username or db id> <on|off|true|false>");
    }
    let username = &args[1];
    let status = &args[2];
    println!(
        "Setting admin status to '{}' for user '{}'.",
        status, username
    );

    println!("Connecting to DB...");
    let conn = db_connection::establish_connection();
    let mut user = match users::table
        .select(users::all_columns)
        .filter(users::username.eq(username))
        .first::<jonline::models::User>(&conn)
    {
        Ok(user) => user,
        Err(_) => return println!("Could not find user."),
    };
    println!(
        "Found user {} with ID {}/{}.",
        username,
        user.id.to_proto_id(),
        user.id
    );

    let mut perms: Vec<String> = match serde_json::from_value(user.permissions.to_owned()) {
        Ok(it) => it,
        Err(_) => return println!("Could not deserialize permissions."),
    };
    println!("Initial permissions: {:?}", perms);
    match status.as_str() {
        "on" | "true" => {
            if !perms.contains(&admin_permission.to_owned()) {
                perms.push(admin_permission.to_owned());
            }
        }
        "off" | "false" => {
            if perms.contains(&admin_permission.to_owned()) {
                let index = perms.iter().position(|x| *x == admin_permission).unwrap();
                perms.remove(index);
                // perms.ind(admin_permission.to_owned());
            }
        }
        _ => return println!("Invalid status."),
    }
    println!("Updated permissions: {:?}", perms);
    user.permissions = perms.into();
    user.save_changes::<jonline::models::User>(&conn).unwrap();
    println!("Updated user {}.", username);
}
