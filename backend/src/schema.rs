table! {
    posts (id) {
        id -> Int4,
        shortcode -> Nullable<Text>,
        title -> Varchar,
        body -> Text,
        published -> Bool,
        user_id -> Nullable<Int4>,
        parent_post_id -> Nullable<Int4>,
    }
}

table! {
    user_auth_tokens (id) {
        id -> Int4,
        user_id -> Int4,
        token -> Text,
        created_at -> Timestamp,
        expires_at -> Timestamp,
    }
}

table! {
    user_refresh_tokens (id) {
        id -> Int4,
        auth_token_id -> Int4,
        token -> Text,
        created_at -> Timestamp,
        expires_at -> Timestamp,
    }
}

table! {
    users (id) {
        id -> Int4,
        username -> Varchar,
        password_salted_hash -> Text,
        email -> Nullable<Varchar>,
        phone -> Nullable<Varchar>,
    }
}

joinable!(user_auth_tokens -> users (user_id));
joinable!(user_refresh_tokens -> user_auth_tokens (auth_token_id));

allow_tables_to_appear_in_same_query!(
    posts,
    user_auth_tokens,
    user_refresh_tokens,
    users,
);
