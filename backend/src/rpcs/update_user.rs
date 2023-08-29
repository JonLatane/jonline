use std::time::SystemTime;

use diesel::result::DatabaseErrorKind::UniqueViolation;
use diesel::result::Error::DatabaseError;
use diesel::result::Error::RollbackTransaction;
use diesel::NotFound;
use diesel::*;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::rpcs;
use crate::schema::users;

use super::validations::*;

pub fn update_user(
    request: User,
    current_user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<User, Status> {
    validate_user(&request)?;

    let self_update = request.id == current_user.id.to_proto_id();
    let mut admin = false;
    let mut moderator = false;
    if !self_update {
        validate_any_permission(
            &current_user,
            vec![Permission::Admin, Permission::ModerateUsers],
        )?;
    }
    match validate_permission(&current_user, Permission::Admin) {
        Ok(_) => admin = true,
        Err(_) => {}
    };
    match validate_permission(&current_user, Permission::ModerateUsers) {
        Ok(_) => moderator = true,
        Err(_) => {}
    };
    log::info!(
        "self_update: {}, admin: {}, moderator: {}",
        self_update, admin, moderator
    );

    let transaction_result: Result<models::User, diesel::result::Error> = conn
        .transaction::<models::User, diesel::result::Error, _>(|conn| {
            let mut existing_user = users::table
                .select(users::all_columns)
                .filter(users::id.eq(request.id.to_db_id().unwrap()))
                .first::<models::User>(conn)?;
            if admin || self_update {
                existing_user.username = request.username.to_owned();
                existing_user.bio = request.bio.to_owned();
                existing_user.avatar_media_id = request.avatar.as_ref().map(|a| &a.id).to_db_opt_id().unwrap();
                if request.visibility == Visibility::GlobalPublic as i32
                    && existing_user.visibility.to_proto_visibility().unwrap()
                        != Visibility::GlobalPublic
                {
                    validate_permission(&current_user, Permission::PublishUsersGlobally)
                        .map_err(|_| RollbackTransaction)?;
                }
                existing_user.visibility = request.visibility.to_string_visibility();
                existing_user.default_follow_moderation = request.default_follow_moderation.to_string_moderation();
            }
            if admin {
                existing_user.permissions = request.permissions.to_json_permissions();
            }
            existing_user.updated_at = SystemTime::now().into();

            log::info!("Updating user: {:?}", existing_user);
            match diesel::update(users::table)
                .filter(users::id.eq(&existing_user.id))
                .set(&existing_user)
                .execute(conn)
            {
                Ok(_) => Ok(existing_user),
                Err(e) => Err(e),
            }
        });

    let result = match transaction_result {
        //TODO: properly marshal this stuff
        Ok(_user) => {
            rpcs::get_users(
                GetUsersRequest {
                    user_id: Some(request.id.clone()),
                    ..Default::default()
                },
                Some(current_user),
                conn,
            ).map(|u| u.users[0].to_owned())
            // Ok(result.to_proto(&None, &None, None))
        },
        Err(NotFound) => Err(Status::new(Code::NotFound, "user_not_found")),
        Err(RollbackTransaction) => Err(Status::new(
            Code::InvalidArgument,
            "cannot_publish_globally",
        )),
        Err(DatabaseError(UniqueViolation, _)) => {
            Err(Status::new(Code::NotFound, "duplicate_username"))
        }
        Err(e) => {
            log::error!("Error updating user: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    };
    log::info!("UpdateUser::request: {:?}, result: {:?}", &request, result);

    result
}
