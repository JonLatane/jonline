// @generated automatically by Diesel CLI.

pub mod sql_types {
    #[derive(diesel::query_builder::QueryId, diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "recipient_type"))]
    pub struct RecipientType;
}

diesel::table! {
    event_attendances (id) {
        id -> Int8,
        event_instance_id -> Int8,
        user_id -> Nullable<Int8>,
        anonymous_attendee -> Nullable<Jsonb>,
        number_of_guests -> Int4,
        status -> Varchar,
        inviting_user_id -> Nullable<Int8>,
        public_note -> Varchar,
        private_note -> Varchar,
        moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

diesel::table! {
    event_instance_sync_destinations (event_instance_id, event_sync_destination_id) {
        event_instance_id -> Int8,
        event_sync_destination_id -> Int8,
        destination_instance_id -> Nullable<Varchar>,
        destination_url -> Nullable<Varchar>,
        synced_at -> Nullable<Timestamp>,
        created_at -> Timestamp,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use diesel_full_text_search::TsVector;

    event_instances (id) {
        id -> Int8,
        event_id -> Int8,
        post_id -> Int8,
        info -> Jsonb,
        starts_at -> Timestamp,
        ends_at -> Timestamp,
        location -> Nullable<Jsonb>,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
        event_sync_source_instance_id -> Nullable<Varchar>,
        search_text -> TsVector,
        user_id -> Nullable<Int8>,
        sync_missing_since -> Nullable<Timestamp>,
    }
}

diesel::table! {
    event_sync_destinations (id) {
        id -> Int8,
        user_id -> Int8,
        configuration -> Jsonb,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

diesel::table! {
    event_sync_sources (id) {
        id -> Int8,
        user_id -> Int8,
        sync_interval_seconds -> Int8,
        configuration -> Jsonb,
        last_synced_at -> Nullable<Timestamp>,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
        event_count -> Int8,
        event_instance_count -> Int8,
    }
}

diesel::table! {
    events (id) {
        id -> Int8,
        post_id -> Int8,
        info -> Jsonb,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
        event_sync_source_id -> Nullable<Int8>,
    }
}

diesel::table! {
    federated_accounts (id) {
        id -> Int8,
        federated_server_id -> Nullable<Int8>,
        federated_user_id -> Varchar,
        user_id -> Nullable<Int8>,
    }
}

diesel::table! {
    federated_profiles (id) {
        id -> Int8,
        user_id -> Int8,
        federated_user_id -> Int8,
        created_at -> Timestamp,
    }
}

diesel::table! {
    federated_servers (id) {
        id -> Int8,
        server_location -> Varchar,
    }
}

diesel::table! {
    federated_users (id) {
        id -> Int8,
        remote_user_id -> Varchar,
        server_host -> Varchar,
        created_at -> Timestamp,
    }
}

diesel::table! {
    follows (id) {
        id -> Int8,
        user_id -> Int8,
        target_user_id -> Int8,
        target_user_moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

diesel::table! {
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

diesel::table! {
    groups (id) {
        id -> Int8,
        name -> Varchar,
        shortname -> Varchar,
        description -> Text,
        avatar_media_id -> Nullable<Int8>,
        visibility -> Varchar,
        non_member_permissions -> Jsonb,
        default_membership_permissions -> Jsonb,
        default_membership_moderation -> Varchar,
        default_post_moderation -> Varchar,
        default_event_moderation -> Varchar,
        moderation -> Varchar,
        member_count -> Int4,
        post_count -> Int4,
        event_count -> Int4,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

diesel::table! {
    media (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        minio_path -> Varchar,
        content_type -> Varchar,
        name -> Nullable<Varchar>,
        description -> Nullable<Text>,
        generated -> Bool,
        processed -> Bool,
        visibility -> Varchar,
        moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Timestamp,
        converted_sizes -> Jsonb,
        metadata -> Jsonb,
        aspect_ratio -> Nullable<Float4>,
    }
}

diesel::table! {
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

diesel::table! {
    message_reads (message_id, user_id) {
        message_id -> Int8,
        user_id -> Int8,
        read_at -> Timestamp,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::RecipientType;

    message_recipients (id) {
        id -> Int8,
        message_id -> Int8,
        user_id -> Int8,
        recipient_type -> RecipientType,
        created_at -> Timestamp,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use diesel_full_text_search::TsVector;

    messages (id) {
        id -> Int8,
        from_user_id -> Nullable<Int8>,
        subject -> Nullable<Varchar>,
        body_text -> Nullable<Text>,
        email_headers -> Nullable<Jsonb>,
        email_message_id -> Nullable<Varchar>,
        email_minio_path -> Nullable<Varchar>,
        created_at -> Timestamp,
        search_text -> TsVector,
        messaging_group_id -> Int8,
    }
}

diesel::table! {
    messaging_groups (id) {
        id -> Int8,
        sorted_user_ids -> Array<Nullable<Int8>>,
        created_at -> Timestamp,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use diesel_full_text_search::TsVector;

    posts (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        parent_post_id -> Nullable<Int8>,
        title -> Nullable<Varchar>,
        link -> Nullable<Varchar>,
        content -> Nullable<Text>,
        response_count -> Int4,
        reply_count -> Int4,
        group_count -> Int4,
        media -> Array<Nullable<Int8>>,
        media_generated -> Bool,
        embed_link -> Bool,
        shareable -> Bool,
        context -> Varchar,
        visibility -> Varchar,
        moderation -> Varchar,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
        published_at -> Nullable<Timestamp>,
        last_activity_at -> Timestamp,
        unauthenticated_star_count -> Int8,
        search_text -> TsVector,
        sort_published_at -> Timestamp,
    }
}

diesel::table! {
    push_subscriptions (id) {
        id -> Int8,
        user_id -> Int8,
        endpoint -> Varchar,
        p256dh_key -> Varchar,
        auth_key -> Varchar,
        created_at -> Timestamp,
    }
}

diesel::table! {
    push_token_posts (id) {
        id -> Int8,
        push_token_id -> Int8,
        post_id -> Int8,
        created_at -> Timestamp,
    }
}

diesel::table! {
    push_tokens (id) {
        id -> Int8,
        token -> Varchar,
        user_id -> Nullable<Int8>,
        created_at -> Timestamp,
    }
}

diesel::table! {
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
        external_cdn_config -> Nullable<Jsonb>,
        private_user_strategy -> Varchar,
        authentication_features -> Jsonb,
        created_at -> Timestamp,
        updated_at -> Timestamp,
        federation_info -> Jsonb,
        web_push_config -> Nullable<Jsonb>,
        custom_tabs -> Nullable<Jsonb>,
    }
}

diesel::table! {
    user_access_tokens (id) {
        id -> Int8,
        refresh_token_id -> Int8,
        token -> Varchar,
        created_at -> Timestamp,
        expires_at -> Timestamp,
    }
}

diesel::table! {
    user_devices (id) {
        id -> Int8,
        user_id -> Int8,
        device_name -> Varchar,
    }
}

diesel::table! {
    user_posts (id) {
        id -> Int8,
        user_id -> Int8,
        post_id -> Int8,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

diesel::table! {
    user_refresh_tokens (id) {
        id -> Int8,
        user_id -> Int8,
        token -> Varchar,
        created_at -> Timestamp,
        expires_at -> Nullable<Timestamp>,
        device_name -> Nullable<Varchar>,
        third_party -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use diesel_full_text_search::TsVector;

    users (id) {
        id -> Int8,
        username -> Varchar,
        password_salted_hash -> Varchar,
        real_name -> Varchar,
        email -> Nullable<Jsonb>,
        phone -> Nullable<Jsonb>,
        permissions -> Jsonb,
        avatar_media_id -> Nullable<Int8>,
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
        search_text -> TsVector,
        friend_count -> Int4,
        event_instance_count -> Int4,
    }
}

diesel::joinable!(event_attendances -> event_instances (event_instance_id));
diesel::joinable!(event_instance_sync_destinations -> event_instances (event_instance_id));
diesel::joinable!(event_instance_sync_destinations -> event_sync_destinations (event_sync_destination_id));
diesel::joinable!(event_instances -> events (event_id));
diesel::joinable!(event_instances -> posts (post_id));
diesel::joinable!(event_sync_destinations -> users (user_id));
diesel::joinable!(event_sync_sources -> users (user_id));
diesel::joinable!(events -> event_sync_sources (event_sync_source_id));
diesel::joinable!(events -> posts (post_id));
diesel::joinable!(federated_accounts -> federated_servers (federated_server_id));
diesel::joinable!(federated_accounts -> users (user_id));
diesel::joinable!(federated_profiles -> federated_users (federated_user_id));
diesel::joinable!(federated_profiles -> users (user_id));
diesel::joinable!(group_posts -> groups (group_id));
diesel::joinable!(group_posts -> posts (post_id));
diesel::joinable!(group_posts -> users (user_id));
diesel::joinable!(groups -> media (avatar_media_id));
diesel::joinable!(memberships -> groups (group_id));
diesel::joinable!(memberships -> users (user_id));
diesel::joinable!(message_reads -> messages (message_id));
diesel::joinable!(message_reads -> users (user_id));
diesel::joinable!(message_recipients -> messages (message_id));
diesel::joinable!(message_recipients -> users (user_id));
diesel::joinable!(messages -> messaging_groups (messaging_group_id));
diesel::joinable!(messages -> users (from_user_id));
diesel::joinable!(posts -> users (user_id));
diesel::joinable!(push_subscriptions -> users (user_id));
diesel::joinable!(push_token_posts -> posts (post_id));
diesel::joinable!(push_token_posts -> push_tokens (push_token_id));
diesel::joinable!(push_tokens -> users (user_id));
diesel::joinable!(user_access_tokens -> user_refresh_tokens (refresh_token_id));
diesel::joinable!(user_devices -> users (user_id));
diesel::joinable!(user_posts -> posts (post_id));
diesel::joinable!(user_posts -> users (user_id));
diesel::joinable!(user_refresh_tokens -> users (user_id));

diesel::allow_tables_to_appear_in_same_query!(
    event_attendances,
    event_instance_sync_destinations,
    event_instances,
    event_sync_destinations,
    event_sync_sources,
    events,
    federated_accounts,
    federated_profiles,
    federated_servers,
    federated_users,
    follows,
    group_posts,
    groups,
    media,
    memberships,
    message_reads,
    message_recipients,
    messages,
    messaging_groups,
    posts,
    push_subscriptions,
    push_token_posts,
    push_tokens,
    server_configurations,
    user_access_tokens,
    user_devices,
    user_posts,
    user_refresh_tokens,
    users,
);
