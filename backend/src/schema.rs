table! {
    event_instances (id) {
        id -> Int8,
        event_id -> Int8,
        post_id -> Nullable<Int8>,
        info -> Jsonb,
        starts_at -> Timestamp,
        ends_at -> Timestamp,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

table! {
    events (id) {
        id -> Int8,
        post_id -> Int8,
        info -> Jsonb,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

table! {
    federated_accounts (id) {
        id -> Int8,
        federated_server_id -> Nullable<Int8>,
        federated_user_id -> Varchar,
        user_id -> Nullable<Int8>,
    }
}

table! {
    federated_servers (id) {
        id -> Int8,
        server_location -> Varchar,
    }
}

table! {
    follows (id) {
        id -> Int8,
        user_id -> Int8,
        target_user_id -> Int8,
        target_user_moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    group_posts (id) {
        id -> Int8,
        group_id -> Int8,
        post_id -> Int8,
        user_id -> Int8,
        group_moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

table! {
    groups (id) {
        id -> Int8,
        name -> Varchar,
        shortname -> Varchar,
        description -> Text,
        avatar -> Nullable<Bytea>,
        visibility -> Varchar,
        default_membership_permissions -> Jsonb,
        default_membership_moderation -> Varchar,
        default_post_moderation -> Varchar,
        default_event_moderation -> Varchar,
        moderation -> Varchar,
        member_count -> Int4,
        post_count -> Int4,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    media (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        minio_path -> Varchar,
        content_type -> Varchar,
        name -> Nullable<Varchar>,
        description -> Nullable<Text>,
        visibility -> Varchar,
        moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    memberships (id) {
        id -> Int8,
        user_id -> Int8,
        group_id -> Int8,
        permissions -> Jsonb,
        group_moderation -> Varchar,
        user_moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    post_media (post_id, media_id) {
        post_id -> Int8,
        media_id -> Int8,
        sort_order -> Int4,
    }
}

table! {
    posts (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        parent_post_id -> Nullable<Int8>,
        title -> Nullable<Varchar>,
        link -> Nullable<Varchar>,
        content -> Nullable<Text>,
        visibility -> Varchar,
        moderation -> Varchar,
        response_count -> Int4,
        reply_count -> Int4,
        group_count -> Int4,
        preview -> Nullable<Bytea>,
        context -> Varchar,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
        last_activity_at -> Timestamp,
    }
}

table! {
    server_configurations (id) {
        id -> Int8,
        active -> Bool,
        server_info -> Jsonb,
        anonymous_user_permissions -> Jsonb,
        default_user_permissions -> Jsonb,
        basic_user_permissions -> Jsonb,
        people_settings -> Jsonb,
        group_settings -> Jsonb,
        post_settings -> Jsonb,
        event_settings -> Jsonb,
        private_user_strategy -> Varchar,
        authentication_features -> Jsonb,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    user_access_tokens (id) {
        id -> Int8,
        refresh_token_id -> Int8,
        token -> Varchar,
        created_at -> Timestamp,
        expires_at -> Timestamp,
    }
}

table! {
    user_devices (id) {
        id -> Int8,
        user_id -> Int8,
        device_name -> Varchar,
    }
}

table! {
    user_posts (id) {
        id -> Int8,
        user_id -> Int8,
        post_id -> Int8,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

table! {
    user_refresh_tokens (id) {
        id -> Int8,
        user_id -> Int8,
        token -> Varchar,
        created_at -> Timestamp,
        expires_at -> Nullable<Timestamp>,
    }
}

table! {
    users (id) {
        id -> Int8,
        username -> Varchar,
        password_salted_hash -> Varchar,
        email -> Nullable<Jsonb>,
        phone -> Nullable<Jsonb>,
        permissions -> Jsonb,
        avatar -> Nullable<Bytea>,
        bio -> Text,
        visibility -> Varchar,
        moderation -> Varchar,
        default_follow_moderation -> Varchar,
        follower_count -> Int4,
        following_count -> Int4,
        group_count -> Int4,
        post_count -> Int4,
        event_count -> Int4,
        response_count -> Int4,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

joinable!(event_instances -> events (event_id));
joinable!(event_instances -> posts (post_id));
joinable!(events -> posts (post_id));
joinable!(federated_accounts -> federated_servers (federated_server_id));
joinable!(federated_accounts -> users (user_id));
joinable!(group_posts -> groups (group_id));
joinable!(group_posts -> posts (post_id));
joinable!(group_posts -> users (user_id));
joinable!(media -> users (user_id));
joinable!(memberships -> groups (group_id));
joinable!(memberships -> users (user_id));
joinable!(posts -> users (user_id));
joinable!(user_access_tokens -> user_refresh_tokens (refresh_token_id));
joinable!(user_devices -> users (user_id));
joinable!(user_posts -> posts (post_id));
joinable!(user_posts -> users (user_id));
joinable!(user_refresh_tokens -> users (user_id));

allow_tables_to_appear_in_same_query!(
    event_instances,
    events,
    federated_accounts,
    federated_servers,
    follows,
    group_posts,
    groups,
    media,
    memberships,
    post_media,
    posts,
    server_configurations,
    user_access_tokens,
    user_devices,
    user_posts,
    user_refresh_tokens,
    users,
);
