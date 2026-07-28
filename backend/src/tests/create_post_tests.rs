//! Specs for `rpcs::posts::create_post`, focused on the `published_at` contract: it's set to
//! exactly `created_at` when a post is created SERVER_PUBLIC/GLOBAL_PUBLIC, and left unset
//! otherwise (see 2026-07-27-215959_add_sort_published_at_to_posts, get_posts_tests's ordering
//! specs, and update_post_tests for the immutable-once-set half of the contract).

use diesel::Connection;
use tonic::Status;

use crate::protos::*;
use crate::rpcs::create_post;
use crate::tests::factories::*;

fn new_post(visibility: Visibility) -> Post {
    Post {
        title: Some("Test Post".to_string()),
        content: Some("Test content".to_string()),
        visibility: visibility as i32,
        ..Default::default()
    }
}

#[test]
fn global_public_post_gets_published_at_matching_created_at() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "cppt_author1");
        let author = grant_permissions(
            conn,
            &author,
            vec![Permission::CreatePosts, Permission::PublishPostsGlobally],
        );

        let post = create_post(new_post(Visibility::GlobalPublic), &author, conn)?;

        assert_eq!(post.published_at, post.created_at);
        Ok(())
    });
}

#[test]
fn server_public_post_gets_published_at_matching_created_at() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "cppt_author2");
        let author = grant_permissions(
            conn,
            &author,
            vec![Permission::CreatePosts, Permission::PublishPostsLocally],
        );

        let post = create_post(new_post(Visibility::ServerPublic), &author, conn)?;

        assert_eq!(post.published_at, post.created_at);
        Ok(())
    });
}

#[test]
fn private_post_has_no_published_at() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "cppt_author3");

        let post = create_post(new_post(Visibility::Private), &author, conn)?;

        assert_eq!(post.published_at, None);
        Ok(())
    });
}

#[test]
fn limited_post_has_no_published_at() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "cppt_author4");

        let post = create_post(new_post(Visibility::Limited), &author, conn)?;

        assert_eq!(post.published_at, None);
        Ok(())
    });
}

#[test]
fn unspecified_visibility_defaults_to_global_public_and_gets_published_at() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "cppt_author5");
        let author = grant_permissions(
            conn,
            &author,
            vec![Permission::CreatePosts, Permission::PublishPostsGlobally],
        );

        let post = create_post(
            Post {
                title: Some("Test Post".to_string()),
                content: Some("Test content".to_string()),
                ..Default::default()
            },
            &author,
            conn,
        )?;

        assert_eq!(post.visibility(), Visibility::GlobalPublic);
        assert_eq!(post.published_at, post.created_at);
        Ok(())
    });
}
