extern crate diesel;
extern crate jonline;
extern crate serde_json;
use diesel::*;
use jonline::conversions::{ToProtoId, ToProtoPermission, ALL_PERMISSIONS};

use jonline::db_connection;
// use jonline::protos::Permission;
use jonline::schema::*;
// use serde_json::Value::Array;
use std::env;

pub fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 4 {
        return help("Invalid number of arguments.".to_string());
    }
    let username = &args[1];
    let permission = match args[2].to_proto_permission() {
        Some(permission) => permission,
        None => return help(format!("Invalid permission: {}.", args[2])),
    }
    .as_str_name();
    let status = &args[3];

    match status.as_str() {
        "on" | "true" | "off" | "false" => {}
        _ => return help(format!("Invalid status: {}.", status)),
    }
    println!(
        "Setting '{}' permission to '{}' for user '{}'.",
        permission, status, username
    );

    println!("Connecting to DB...");
    let mut conn = db_connection::establish_connection();
    let mut user = match users::table
        .select(users::all_columns)
        .filter(users::username.eq(username))
        .first::<jonline::models::User>(&mut conn)
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
            if !perms.contains(&permission.to_owned()) {
                perms.push(permission.to_owned());
            }
        }
        "off" | "false" => {
            if perms.contains(&permission.to_owned()) {
                let index = perms.iter().position(|x| *x == permission).unwrap();
                perms.remove(index);
                // perms.ind(admin_permission.to_owned());
            }
        }
        _ => return help(format!("Invalid status. Aborting.")),
    }
    println!("Updated permissions: {:?}", perms);
    user.permissions = perms.into();
    user.save_changes::<jonline::models::User>(&mut conn).unwrap();
    println!("Updated user {}.", username);
}

fn help(error: String) {
    if error.len() > 0 {
        println!("{}", error);
        println!("");
    }
    println!("This tool sets permissions for Jonline users.");
    println!("Usage:      set_permission <username> <permission> <status>");
    println!("Example:    set_permission jon admin off");
    println!("Statuses:   on|off|true|false");
    println!("Permissions (case insensitive): \n * {}", ALL_PERMISSIONS.map(|p| p.as_str_name().to_ascii_lowercase()).join("\n * "));
}
