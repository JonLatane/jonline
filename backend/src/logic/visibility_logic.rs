use crate::models;
use crate::protos::*;
use crate::marshaling::*;

pub fn public_visibilities(user: &Option<&models::User>) -> Vec<Visibility> {
  match user {
      Some(_) => vec![Visibility::GlobalPublic, Visibility::ServerPublic],
      None => vec![Visibility::GlobalPublic],
  }
}

pub fn public_string_visibilities(user: &Option<&models::User>) -> Vec<String> {
  public_visibilities(user).to_string_visibilities()
}
