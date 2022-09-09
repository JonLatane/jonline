table! {
    federated_accounts (id) {
        id -> Int4,
        federated_server_id -> Nullable<Int4>,
        federated_user_id -> Varchar,
        user_id -> Nullable<Int4>,
    }
}

table! {
    federated_servers (id) {
        id -> Int4,
        server_location -> Varchar,
        ca_cert -> Nullable<Varchar>,
        tls_key -> Nullable<Varchar>,
    }
}

table! {
    follows (id) {
        id -> Int4,
        user_id -> Int4,
        local_user_id -> Nullable<Int4>,
        federated_account_id -> Nullable<Int4>,
    }
}

table! {
    posts (id) {
        id -> Int4,
        user_id -> Nullable<Int4>,
        parent_post_id -> Nullable<Int4>,
        title -> Varchar,
        link -> Nullable<Varchar>,
        content -> Nullable<Text>,
        published -> Bool,
        created_at -> Timestamp,
        updated_at -> Nullable<Timestamp>,
    }
}

table! {
    user_auth_tokens (id) {
        id -> Int4,
        user_id -> Int4,
        token -> Varchar,
        created_at -> Timestamp,
        expires_at -> Nullable<Timestamp>,
    }
}

table! {
    user_refresh_tokens (id) {
        id -> Int4,
        auth_token_id -> Int4,
        token -> Varchar,
        created_at -> Timestamp,
        expires_at -> Timestamp,
    }
}

table! {
    users (id) {
        id -> Int4,
        username -> Varchar,
        password_salted_hash -> Varchar,
        email -> Nullable<Varchar>,
        phone -> Nullable<Varchar>,
        created_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

joinable!(federated_accounts -> federated_servers (federated_server_id));
joinable!(federated_accounts -> users (user_id));
joinable!(user_auth_tokens -> users (user_id));
joinable!(user_refresh_tokens -> user_auth_tokens (auth_token_id));

allow_tables_to_appear_in_same_query!(
    federated_accounts,
    federated_servers,
    follows,
    posts,
    user_auth_tokens,
    user_refresh_tokens,
    users,
);
