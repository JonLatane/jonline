use super::validate_regexp::validate_all_word_chars;
use super::validate_regexp::*;
use super::validate_strings::validate_length;
use tonic::Status;

pub fn validate_username(value: &str) -> Result<(), Status> {
    validate_length(&value, "username", 1, 47)?;
    validate_all_word_chars(&value, "username")?;
    // A "standard" way to represent a federated Jonline user is federatedserver.com/username. But we also want
    // federatedserver.com/events and federatedserver.com/post/asdf123, etc. to be able to point to valid things.
    validate_reserved_values(
        &value,
        "username",
        &[
            "app",
            "flutter",
            "tamagui",
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
        ],
    )
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
