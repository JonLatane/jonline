use lazy_static::lazy_static;
use regex::Regex;

use super::validate_regexp::validate_all_word_chars;
use super::validate_regexp::*;
use super::validate_strings::validate_length;
use tonic::{Code, Status};

lazy_static! {
    // A "standard" way to represent a federated Jonline user is federatedserver.com/username. But we also want
    // federatedserver.com/events and federatedserver.com/post/asdf123, etc. to be able to point to valid things.
    // Custom nav tab paths share this same top-level namespace, so they're checked against it too.
    static ref RESERVED_PATHS: Vec<&'static str> = vec![
        "app",
        "flutter",
        "tamagui",
        "elm",
        "elm_debug",
        "debug",
        "home",
        "web",
        "events",
        "event",
        "e",
        "posts",
        "post",
        "p",
        "groups",
        "group",
        "g",
        "people",
        "person",
        "author",
        "a",
        "member",
        "m",
        "server",
        "s",
        "servers",
        "about",
        "about_jonline",
        "u",
        "users",
        "user",
        "info",
        "info_shield",
        "robots.txt",
        "favicon.ico",
        "favicon.png",
        "sitemap.xml",
        "sitemap.xml.gz",
        "sitemap.xml.gz",
        "sitemap.xml.gz",
        "sitemap.xml.gz",
        "media",
        "backend_host",
        "frontend_host",
        "docs",
        "documentation",
        "event_ai",
        "third_party_auth",
        "third_party_auths",
        "auth",
        "auths",
        "calendar.ics",
    ];
    // Custom tab paths share the RESERVED_PATHS namespace, but these specific values are
    // allowed since they're used as top-level containers (e.g. federatedserver.com/events)
    // rather than single-resource routes.
    static ref CUSTOM_TAB_RESERVED_PATHS: Vec<&'static str> = RESERVED_PATHS
        .iter()
        .filter(|path| !["events", "people", "users", "posts"].contains(path))
        .cloned()
        .collect();
    static ref CUSTOM_TAB_PATH_RE: Regex = Regex::new(r"^[a-z_]+$").unwrap();
}

pub fn validate_username(value: &str) -> Result<(), Status> {
    validate_length(&value, "username", 1, 47)?;
    validate_all_word_chars(&value, "username")?;
    validate_reserved_values(&value, "username", &RESERVED_PATHS)
}

pub fn validate_custom_tab_path(path: &str, is_profile: bool) -> Result<(), Status> {
    // A profile tab's `path` *is* the username it links to (see the proto's own doc on
    // `is_profile`), so it's validated as a username instead (`validate_username`'s own
    // `[\w.-]+` word-char rule) -- not the stricter `[a-z_]+` below, which most real usernames
    // (mixed case, digits) would fail.
    if is_profile {
        return validate_username(path);
    }
    validate_reserved_values(path, "custom_tab_path", &CUSTOM_TAB_RESERVED_PATHS)?;
    if !CUSTOM_TAB_PATH_RE.is_match(path) {
        return Err(Status::new(
            Code::InvalidArgument,
            "custom_tab_path_must_match_[a-z_]",
        ));
    }
    Ok(())
}

pub fn validate_password(value: &str) -> Result<(), Status> {
    validate_length(&value, "password", 8, 128)
}

pub fn validate_email(value: &Option<String>) -> Result<(), Status> {
    match value {
        Some(value) => validate_length(&value, "email", 1, 255),
        None => Ok(()),
    }
}
pub fn validate_phone(value: &Option<String>) -> Result<(), Status> {
    match value {
        Some(value) => validate_length(&value, "phone", 1, 128),
        None => Ok(()),
    }
}
