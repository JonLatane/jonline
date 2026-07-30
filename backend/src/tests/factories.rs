//! Test data builders for DB-backed specs. Each `#[test]` gets its own connection from
//! [`test_conn`] and should wrap its body in `conn.test_transaction(...)`, so nothing created
//! here is ever committed to `TEST_DATABASE_URL`.

use std::time::SystemTime;

use diesel::*;
use diesel_migrations::MigrationHarness;

use crate::db_connection::{establish_test_pool, PgPool, PgPooledConnection, MIGRATIONS};
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::{event_sync_sources, follows, group_posts, groups, memberships, posts, users};

/// Returns a pooled connection to `TEST_DATABASE_URL`, migrating it on first use (once per test
/// binary process, since `Once`/`lazy_static` state doesn't cross the parallel test threads
/// cargo spawns, but each of those threads shares this same process-wide pool/static).
pub fn test_conn() -> PgPooledConnection {
    lazy_static! {
        static ref POOL: PgPool = {
            let pool = establish_test_pool();
            pool.get()
                .expect("failed to connect to TEST_DATABASE_URL")
                .run_pending_migrations(MIGRATIONS)
                .expect("failed to run migrations against TEST_DATABASE_URL");
            pool
        };
    }
    POOL.get().expect("failed to check out a pooled test connection")
}

pub fn create_user(conn: &mut PgPooledConnection, username: &str) -> models::User {
    create_user_with(conn, username, Visibility::ServerPublic, Moderation::Unmoderated)
}

pub fn create_user_with(
    conn: &mut PgPooledConnection,
    username: &str,
    visibility: Visibility,
    moderation: Moderation,
) -> models::User {
    insert_into(users::table)
        .values((
            users::username.eq(username),
            users::password_salted_hash.eq("test_hash"),
            users::real_name.eq(username),
            users::permissions.eq(vec![
                Permission::ViewPosts,
                Permission::CreatePosts,
                Permission::ViewGroups,
                Permission::FollowUsers,
            ]
            .to_json_permissions()),
            users::visibility.eq(visibility.to_string_visibility()),
            users::moderation.eq(moderation.to_string_moderation()),
        ))
        // users::search_text has no corresponding field on `models::User` (see USER_COLUMNS'
        // doc comment), so a plain `RETURNING *` can't deserialize into it - the explicit
        // column list is required here, same as create_post's own `POST_COLUMNS`.
        .returning(models::USER_COLUMNS)
        .get_result::<models::User>(conn)
        .expect("failed to create test user")
}

/// Like `create_user_with`, but with distinct `real_name`/`bio` text (`create_user_with` always
/// sets `real_name` equal to `username`, and leaves `bio` at its DB default of `""`) - for
/// `get_users_tests`' `USERS_TEXT_SEARCH` specs, which need each of username/real_name/bio to be
/// independently distinguishable/matchable.
pub fn create_user_with_profile(
    conn: &mut PgPooledConnection,
    username: &str,
    real_name: &str,
    bio: &str,
) -> models::User {
    insert_into(users::table)
        .values((
            users::username.eq(username),
            users::password_salted_hash.eq("test_hash"),
            users::real_name.eq(real_name),
            users::bio.eq(bio),
            users::permissions.eq(vec![
                Permission::ViewPosts,
                Permission::CreatePosts,
                Permission::ViewGroups,
                Permission::FollowUsers,
            ]
            .to_json_permissions()),
            users::visibility.eq(Visibility::GlobalPublic.to_string_visibility()),
            users::moderation.eq(Moderation::Unmoderated.to_string_moderation()),
        ))
        .returning(models::USER_COLUMNS)
        .get_result::<models::User>(conn)
        .expect("failed to create test user")
}

/// Updates `user`'s `real_name`/`bio` - exercises `users.search_text`'s `GENERATED ALWAYS AS
/// ... STORED` recompute-on-update behavior (see
/// `2026-07-22-202628_add_search_text_to_users/up.sql`), for a spec confirming a changed
/// real_name/bio actually changes what that user matches on.
pub fn update_user_profile(
    conn: &mut PgPooledConnection,
    user: &models::User,
    real_name: &str,
    bio: &str,
) -> models::User {
    diesel::update(users::table.filter(users::id.eq(user.id)))
        .set((users::real_name.eq(real_name), users::bio.eq(bio)))
        .returning(models::USER_COLUMNS)
        .get_result::<models::User>(conn)
        .expect("failed to update test user")
}

/// `create_user`'s default permission set (`ViewPosts`/`CreatePosts`/`ViewGroups`/`FollowUsers`)
/// doesn't include `PublishPosts{Locally,Globally}` - specs exercising CreatePost/UpdatePost's
/// visibility handling grant those explicitly via this.
pub fn grant_permissions(
    conn: &mut PgPooledConnection,
    user: &models::User,
    permissions: Vec<Permission>,
) -> models::User {
    diesel::update(users::table.filter(users::id.eq(user.id)))
        .set(users::permissions.eq(permissions.to_json_permissions()))
        .returning(models::USER_COLUMNS)
        .get_result::<models::User>(conn)
        .expect("failed to update test user permissions")
}

#[derive(Clone)]
pub struct PostOpts {
    pub visibility: Visibility,
    pub moderation: Moderation,
    pub context: PostContext,
    pub parent_post_id: Option<i64>,
    pub title: Option<String>,
    pub content: Option<String>,
    /// Overrides `created_at`/`published_at`, which otherwise both default to `NOW()` - and
    /// since `NOW()` is frozen for the lifetime of a Postgres transaction, every post a test
    /// creates inside its `test_transaction` would otherwise get the *same* `created_at`. Specs
    /// asserting on `GetPosts`' `sort_published_at` ordering need distinct, explicit timestamps
    /// to have something meaningful to order by.
    pub created_at: Option<SystemTime>,
    pub published_at: Option<SystemTime>,
}

impl Default for PostOpts {
    fn default() -> Self {
        PostOpts {
            visibility: Visibility::ServerPublic,
            moderation: Moderation::Unmoderated,
            context: PostContext::Post,
            parent_post_id: None,
            title: Some("Test Post".to_string()),
            content: Some("Test content".to_string()),
            created_at: None,
            published_at: None,
        }
    }
}

/// `author: None` creates a post with no `user_id` (e.g. a reply left behind by a deleted user).
pub fn create_post(
    conn: &mut PgPooledConnection,
    author: Option<&models::User>,
    opts: PostOpts,
) -> models::Post {
    let post = insert_into(posts::table)
        .values(&models::NewPost {
            user_id: author.map(|u| u.id),
            parent_post_id: opts.parent_post_id,
            title: opts.title,
            link: None,
            content: opts.content,
            context: opts.context.to_string_post_context(),
            visibility: opts.visibility.to_string_visibility(),
            moderation: opts.moderation.to_string_moderation(),
            media: vec![],
            embed_link: false,
        })
        // posts::search_text has no corresponding field on `models::Post` (see POST_COLUMNS'
        // doc comment), so a plain `RETURNING *` can't deserialize into it - the explicit
        // column list is required here, same as in create_post.rs.
        .returning(models::POST_COLUMNS)
        .get_result::<models::Post>(conn)
        .expect("failed to create test post");

    if opts.created_at.is_none() && opts.published_at.is_none() {
        return post;
    }
    diesel::update(posts::table.filter(posts::id.eq(post.id)))
        .set((
            opts.created_at.map(|t| posts::created_at.eq(t)),
            opts.published_at.map(|t| posts::published_at.eq(t)),
        ))
        .returning(models::POST_COLUMNS)
        .get_result::<models::Post>(conn)
        .expect("failed to create test post")
}

pub struct GroupOpts {
    pub non_member_permissions: Vec<Permission>,
}

impl Default for GroupOpts {
    fn default() -> Self {
        GroupOpts {
            non_member_permissions: vec![],
        }
    }
}

pub fn create_group(conn: &mut PgPooledConnection, shortname: &str, opts: GroupOpts) -> models::Group {
    insert_into(groups::table)
        .values(&models::NewGroup {
            name: shortname.to_string(),
            shortname: shortname.to_string(),
            description: "".to_string(),
            avatar_media_id: None,
            visibility: Visibility::ServerPublic.to_string_visibility(),
            non_member_permissions: opts.non_member_permissions.to_json_permissions(),
            default_membership_permissions: vec![Permission::ViewPosts].to_json_permissions(),
            default_membership_moderation: Moderation::Unmoderated.to_string_moderation(),
            default_post_moderation: Moderation::Unmoderated.to_string_moderation(),
            default_event_moderation: Moderation::Unmoderated.to_string_moderation(),
            member_count: 0,
        })
        .get_result::<models::Group>(conn)
        .expect("failed to create test group")
}

pub fn create_membership(
    conn: &mut PgPooledConnection,
    user: &models::User,
    group: &models::Group,
    user_moderation: Moderation,
    group_moderation: Moderation,
    permissions: Vec<Permission>,
) -> models::Membership {
    insert_into(memberships::table)
        .values(&models::NewMembership {
            user_id: user.id,
            group_id: group.id,
            permissions: permissions.to_json_permissions(),
            group_moderation: group_moderation.to_string_moderation(),
            user_moderation: user_moderation.to_string_moderation(),
        })
        .get_result::<models::Membership>(conn)
        .expect("failed to create test membership")
}

pub fn create_group_post(
    conn: &mut PgPooledConnection,
    post: &models::Post,
    group: &models::Group,
    user: &models::User,
    group_moderation: Moderation,
) -> models::GroupPost {
    insert_into(group_posts::table)
        .values(&models::NewGroupPost {
            group_id: group.id,
            post_id: post.id,
            user_id: user.id,
            group_moderation: group_moderation.to_string_moderation(),
        })
        .get_result::<models::GroupPost>(conn)
        .expect("failed to create test group post")
}

/// `user` is the follower; `target` is the account being followed (matches `follows.user_id` /
/// `follows.target_user_id`). Always `Approved` - see `create_follow_with_moderation` for a
/// `Pending` one (e.g. for `get_users_tests`' `follow_requests_text_search` specs).
pub fn create_follow(
    conn: &mut PgPooledConnection,
    user: &models::User,
    target: &models::User,
) -> models::Follow {
    create_follow_with_moderation(conn, user, target, Moderation::Approved)
}

pub fn create_follow_with_moderation(
    conn: &mut PgPooledConnection,
    user: &models::User,
    target: &models::User,
    target_user_moderation: Moderation,
) -> models::Follow {
    insert_into(follows::table)
        .values(&models::NewFollow {
            user_id: user.id,
            target_user_id: target.id,
            target_user_moderation: target_user_moderation.to_string_moderation(),
        })
        .get_result::<models::Follow>(conn)
        .expect("failed to create test follow")
}

/// Inserts an `event_sync_sources` row directly (bypassing `rpcs::create_event_sync_source`, so
/// no sync/HTTP fetch happens) -- for specs that only care about ownership/permission handling,
/// not the actual sync. Specs exercising sync itself should go through the RPC/logic functions
/// against a `serve_ics`-backed URL instead.
pub fn create_event_sync_source_row(
    conn: &mut PgPooledConnection,
    user: &models::User,
    ics_subscription_url: &str,
) -> models::EventSyncSource {
    insert_into(event_sync_sources::table)
        .values(&models::NewEventSyncSource {
            user_id: user.id,
            sync_interval_seconds: 3600,
            configuration: serde_json::json!({ "ics_subscription_url": ics_subscription_url }),
        })
        .get_result::<models::EventSyncSource>(conn)
        .expect("failed to create test event sync source")
}

/// Starts a background thread serving `ics_text` as `text/calendar` for every HTTP request it
/// receives (looping for the life of the test process -- there's no teardown, same as any other
/// test-scoped leaked thread), and returns the `http://127.0.0.1:<port>/...` URL to fetch it
/// from. Keeps sync specs hermetic: real network calls in a test suite are flaky and slow, so
/// `sync_event_sync_source` (which always does a real HTTP fetch, unlike
/// `sync_event_sync_source_text`) is exercised against this instead of the public internet.
pub fn serve_ics(ics_text: &str) -> String {
    use std::io::{Read, Write};
    use std::net::TcpListener;

    let listener = TcpListener::bind("127.0.0.1:0").expect("failed to bind test ICS server");
    let port = listener.local_addr().expect("failed to read test ICS server port").port();
    let body = ics_text.to_string();
    std::thread::spawn(move || {
        for stream in listener.incoming() {
            let Ok(mut stream) = stream else { continue };
            let mut buf = [0u8; 2048];
            let _ = stream.read(&mut buf);
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: text/calendar\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                body.len(),
                body
            );
            let _ = stream.write_all(response.as_bytes());
        }
    });
    format!("http://127.0.0.1:{port}/test.ics")
}
