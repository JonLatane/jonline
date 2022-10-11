use diesel::*;
use tonic::Code;
use tonic::Status;

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;

use crate::rpcs::PASSING_MODERATIONS;
use crate::schema::groups;
use crate::schema::memberships;

pub trait ToProtoGroup {
    fn to_proto_with(&self, member_count: i32, user_membership: Option<Membership>) -> Group;
    fn to_proto(&self, conn: &PgPooledConnection, user: &Option<models::User>) -> Group;
}
impl ToProtoGroup for models::Group {
    fn to_proto(&self, conn: &PgPooledConnection, user: &Option<models::User>) -> Group {
        let member_count = memberships::table
            .count()
            .filter(memberships::group_id.eq(self.id))
            .filter(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
            .filter(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap();
        println!("member count {}", member_count);
        let user_membership = match user {
            Some(user) => memberships::table
                .select(memberships::all_columns)
                .filter(memberships::group_id.eq(self.id))
                .filter(memberships::user_id.eq(user.id))
                .first::<models::Membership>(conn)
                .ok(),
            None => None,
        };
        self.to_proto_with(member_count as i32, user_membership.map(|m| m.to_proto()))
    }
    fn to_proto_with(&self, member_count: i32, user_membership: Option<Membership>) -> Group {
        let group = Group {
            id: self.id.to_proto_id().to_string(),
            name: self.name.to_owned(),
            description: self.description.to_owned(),
            avatar: self.avatar.to_owned(),
            default_membership_permissions: self
                .default_membership_permissions
                .to_i32_permissions(),
            default_membership_moderation: self.default_membership_moderation.to_i32_moderation(),
            visibility: self.visibility.to_i32_visibility(),
            member_count: member_count as u32,
            current_user_membership: user_membership,
            created_at: Some(self.created_at.to_proto()),
            updated_at: Some(self.updated_at.to_proto()),
        };
        // println!("Converted Group: {:?}", group);
        return group;
    }
}

pub trait ToProtoMembership {
    fn to_proto(&self) -> Membership;
    fn update_related_counts(&self, conn: &PgPooledConnection) -> Result<(), Status>;
}
impl ToProtoMembership for models::Membership {
    fn to_proto(&self) -> Membership {
        let membership = Membership {
            // id: self.id.to_proto_id(),
            user_id: self.user_id.to_proto_id(),
            group_id: self.group_id.to_proto_id(),
            permissions: self.permissions.to_i32_permissions(),
            group_moderation: self.group_moderation.to_i32_moderation(),
            user_moderation: self.user_moderation.to_i32_moderation(),
            created_at: Some(self.created_at.to_proto()),
            updated_at: Some(self.updated_at.to_proto()),
        };
        // println!("Converted Membership: {:?}", membership);
        return membership;
    }

    fn update_related_counts(&self, conn: &PgPooledConnection) -> Result<(), Status> {
        let member_count = memberships::table
            .count()
            .filter(memberships::group_id.eq(self.group_id))
            .filter(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
            .filter(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap() as i32;

        diesel::update(groups::table)
            .filter(groups::id.eq(self.group_id))
            .set(groups::member_count.eq(member_count))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_follower_count"))?;
        Ok(())
    }
}
