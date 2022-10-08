use crate::conversions::*;
use crate::models;
use crate::protos::*;

pub trait ToProtoGroup {
    fn to_proto(&self, member_count: i32) -> Group;
}
impl ToProtoGroup for models::Group {
    fn to_proto(&self, member_count: i32) -> Group {
        let group = Group {
            id: self.id.to_proto_id().to_string(),
            name: self.name.to_owned(),
            description: self.description.to_owned(),
            avatar: self.avatar.to_owned(),
            default_membership_permissions: self.default_membership_permissions.to_i32_permissions(),
            default_membership_moderation: self.default_membership_moderation.to_i32_moderation(),
            visibility: self.visibility.to_i32_visibility(),
            member_count: member_count as u32
        };
        println!("Converted Group: {:?}", group);
        return group;
    }
}

pub trait ToProtoMembership {
    fn to_proto(&self) -> Membership;
}
