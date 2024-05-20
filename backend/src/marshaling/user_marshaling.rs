use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::get_federated_users;
use crate::rpcs::validations::PASSING_MODERATIONS;
use crate::schema::{follows, users};
use diesel::*;
use tonic::Code;
use tonic::Status;

use super::MediaLookup;

pub trait ToProtoUser {
    fn to_proto(
        &self,
        follow: &Option<&models::Follow>,
        target_follow: &Option<&models::Follow>,
        media_lookup: Option<&MediaLookup>,
        // If provided, marshaling will load federated user data from the DB.
        conn: Option<&mut PgPooledConnection>,
    ) -> User;

    fn to_author(&self) -> models::Author;
}
impl ToProtoUser for models::User {
    // fn to_proto(&self) -> User {
    //     return self.to_proto(&None, &None);
    // }
    fn to_proto(
        &self,
        follow: &Option<&models::Follow>,
        target_follow: &Option<&models::Follow>,
        media_lookup: Option<&MediaLookup>,
        // If provided, marshaling will load federated user data from the DB.
        conn: Option<&mut PgPooledConnection>,
    ) -> User {
        let email: Option<ContactMethod> = self
            .email
            .to_owned()
            .map(|cm| serde_json::from_value(cm).unwrap());
        let phone: Option<ContactMethod> = self
            .phone
            .to_owned()
            .map(|cm| serde_json::from_value(cm).unwrap());

        log::info!("user.avatar_media_id={:?}", &self.avatar_media_id);
        let user = User {
            id: self.id.to_proto_id().to_string(),
            username: self.username.to_owned(),
            real_name: self.real_name.to_owned(),
            email: email,
            phone: phone,
            permissions: self.permissions.to_i32_permissions(),
            bio: self.bio.to_owned(),
            // avatar_media_id: self.avatar_media_id.to_owned().map(|id| id.to_proto_id()),
            avatar: media_lookup
                .map(|ml| ml.get(&self.avatar_media_id.unwrap()).unwrap().to_proto()),
            visibility: self.visibility.to_proto_visibility().unwrap() as i32,
            moderation: self.moderation.to_proto_moderation().unwrap() as i32,
            follower_count: Some(self.follower_count),
            following_count: Some(self.following_count),
            group_count: Some(self.group_count),
            post_count: Some(self.post_count),
            response_count: Some(self.response_count),
            default_follow_moderation: self
                .default_follow_moderation
                .to_proto_moderation()
                .unwrap() as i32,
            has_advanced_data: conn.is_some(),
            federated_profiles: conn
                .map(|conn| get_federated_users(self.id, conn))
                .unwrap_or(vec![]),
            current_user_follow: follow.as_ref().map(|f| f.to_proto()),
            target_current_user_follow: target_follow.as_ref().map(|f| f.to_proto()),
            current_group_membership: None, // TODO
            created_at: Some(self.created_at.to_proto()),
            updated_at: Some(self.updated_at.to_proto()),
        };
        // log::info!("Converted user: {:?}", user);
        return user;
    }

    fn to_author(&self) -> models::Author {
        models::Author {
            id: self.id,
            username: self.username.clone(),
            avatar_media_id: self.avatar_media_id,
        }
    }
}

pub trait ToProtoAuthor {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> Author;
    fn to_proto_user_attendee(&self, media_lookup: Option<&MediaLookup>) -> UserAttendee;
}
impl ToProtoAuthor for models::Author {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> Author {
        Author {
            user_id: self.id.to_proto_id().to_string(),
            username: Some(self.username.to_owned()),
            avatar: self
                .avatar_media_id
                .to_owned()
                .map(|id| {
                    media_lookup
                        .find_media(id)
                        .map(|media_ref| media_ref.to_proto())
                })
                .flatten(),
        }
    }
    fn to_proto_user_attendee(&self, media_lookup: Option<&MediaLookup>) -> UserAttendee {
        UserAttendee {
            user_id: self.id.to_proto_id().to_string(),
            username: Some(self.username.to_owned()),
            avatar: self
                .avatar_media_id
                .to_owned()
                .map(|id| {
                    media_lookup
                        .find_media(id)
                        .map(|media_ref| media_ref.to_proto())
                })
                .flatten(),
        }
    }
}

pub trait ToProtoFollow {
    fn to_proto(&self) -> Follow;
    fn update_related_counts(&self, conn: &mut PgPooledConnection) -> Result<(), Status>;
}
impl ToProtoFollow for models::Follow {
    fn to_proto(&self) -> Follow {
        return Follow {
            user_id: self.user_id.to_proto_id().to_string(),
            target_user_id: self.target_user_id.to_proto_id().to_string(),
            target_user_moderation: self.target_user_moderation.to_proto_moderation().unwrap()
                as i32,
            created_at: Some(self.created_at.to_proto()),
            updated_at: Some(self.updated_at.to_proto()),
        };
    }

    fn update_related_counts(&self, conn: &mut PgPooledConnection) -> Result<(), Status> {
        let following_count = follows::table
            .count()
            .filter(follows::user_id.eq(self.user_id))
            .filter(follows::target_user_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap() as i32;

        diesel::update(users::table)
            .filter(users::id.eq(self.user_id))
            .set(users::following_count.eq(following_count))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_following_count"))?;

        let target_follower_count = follows::table
            .count()
            .filter(follows::target_user_id.eq(self.target_user_id))
            .filter(follows::target_user_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap() as i32;

        diesel::update(users::table)
            .filter(users::id.eq(self.target_user_id))
            .set(users::follower_count.eq(target_follower_count))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_follower_count"))?;
        Ok(())
    }
}
