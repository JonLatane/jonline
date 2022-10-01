use crate::protos::*;

pub trait ToProtoPermission {
    fn to_proto_permission(&self) -> Option<Permission>;
}
impl ToProtoPermission for String {
    fn to_proto_permission(&self) -> Option<Permission> {
        for permission in ALL_PERMISSIONS {
            if permission.as_str_name().eq_ignore_ascii_case(self) {
                return Some(permission);
            }
        }
        return None;
    }
}

pub const ALL_PERMISSIONS: [Permission; 11] = [
    Permission::ViewPosts,
    Permission::CreatePosts,
    Permission::GloballyPublishPosts,
    Permission::ModeratePosts,
    Permission::ViewEvents,
    Permission::CreateEvents,
    Permission::GloballyPublishEvents,
    Permission::ModerateEvents,
    Permission::Admin,
    Permission::ModerateUsers,
    Permission::ViewPrivateContactMethods,
];

pub trait ToProtoPermissions {
    fn to_proto_permissions(&self) -> Vec<i32>;
}
impl ToProtoPermissions for serde_json::Value {
    fn to_proto_permissions(&self) -> Vec<i32> {
        match self {
            serde_json::Value::Array(permissions) => {
                let mut mapped_permissions: Vec<i32> = Vec::new();
                println!("Converting permissions: {:?}", permissions);
                for permission in permissions {
                    let mapped_permission = permission.as_str().map(|s| s.to_string().to_proto_permission()).flatten();

                    println!("Mapped permission {:?} to {:?}", permission, mapped_permission);
                    if mapped_permission.is_some() {
                        mapped_permissions.push(mapped_permission.unwrap() as i32);
                    }
                }
                return mapped_permissions;
            }
            _ => return Vec::new(),
        }
    }
}