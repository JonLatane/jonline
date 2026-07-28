//! Specs for `rpcs::posts::update_post`'s `published_at` handling: it's set exactly once, the
//! first time a post's visibility becomes SERVER_PUBLIC/GLOBAL_PUBLIC, and never changes after
//! that - not on subsequent edits, not on further visibility changes, and not even if the post is
//! later made non-public again. See create_post_tests for the create-time half of the contract.

use diesel::Connection;
use tonic::Status;

use crate::protos::*;
use crate::rpcs::{create_post, update_post};
use crate::tests::factories::*;

fn update_visibility(id: &str, visibility: Visibility) -> Post {
    Post {
        id: id.to_string(),
        visibility: visibility as i32,
        ..Default::default()
    }
}

#[test]
fn self_update_publishing_a_private_post_sets_published_at() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uppt_author1");
        let author = grant_permissions(
            conn,
            &author,
            vec![Permission::CreatePosts, Permission::PublishPostsLocally],
        );
        let post = create_post(
            Post {
                title: Some("Test Post".to_string()),
                content: Some("Test content".to_string()),
                visibility: Visibility::Private as i32,
                ..Default::default()
            },
            &author,
            conn,
        )?;
        assert_eq!(post.published_at, None);

        let updated = update_post(
            update_visibility(&post.id, Visibility::ServerPublic),
            &author,
            conn,
        )?;

        assert_eq!(updated.published_at, updated.updated_at);
        assert_ne!(updated.published_at, None);
        Ok(())
    });
}

#[test]
fn published_at_is_immutable_across_further_edits() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uppt_author2");
        let author = grant_permissions(
            conn,
            &author,
            vec![Permission::CreatePosts, Permission::PublishPostsLocally],
        );
        let post = create_post(
            Post {
                title: Some("Test Post".to_string()),
                content: Some("Test content".to_string()),
                visibility: Visibility::ServerPublic as i32,
                ..Default::default()
            },
            &author,
            conn,
        )?;
        let original_published_at = post.published_at.clone();
        assert_ne!(original_published_at, None);

        let updated = update_post(
            Post {
                id: post.id.clone(),
                content: Some("Edited content".to_string()),
                visibility: Visibility::ServerPublic as i32,
                ..Default::default()
            },
            &author,
            conn,
        )?;

        assert_eq!(updated.content, Some("Edited content".to_string()));
        assert_eq!(updated.published_at, original_published_at);
        Ok(())
    });
}

#[test]
fn published_at_survives_a_visibility_upgrade() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uppt_author3");
        let author = grant_permissions(
            conn,
            &author,
            vec![
                Permission::CreatePosts,
                Permission::PublishPostsLocally,
                Permission::PublishPostsGlobally,
            ],
        );
        let post = create_post(
            Post {
                title: Some("Test Post".to_string()),
                content: Some("Test content".to_string()),
                visibility: Visibility::ServerPublic as i32,
                ..Default::default()
            },
            &author,
            conn,
        )?;
        let original_published_at = post.published_at.clone();

        let updated = update_post(
            update_visibility(&post.id, Visibility::GlobalPublic),
            &author,
            conn,
        )?;

        assert_eq!(updated.visibility(), Visibility::GlobalPublic);
        assert_eq!(updated.published_at, original_published_at);
        Ok(())
    });
}

#[test]
fn published_at_is_not_cleared_when_post_is_made_private_again() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uppt_author4");
        let author = grant_permissions(
            conn,
            &author,
            vec![Permission::CreatePosts, Permission::PublishPostsLocally],
        );
        let post = create_post(
            Post {
                title: Some("Test Post".to_string()),
                content: Some("Test content".to_string()),
                visibility: Visibility::ServerPublic as i32,
                ..Default::default()
            },
            &author,
            conn,
        )?;
        let original_published_at = post.published_at.clone();
        assert_ne!(original_published_at, None);

        let updated = update_post(
            update_visibility(&post.id, Visibility::Private),
            &author,
            conn,
        )?;

        assert_eq!(updated.visibility(), Visibility::Private);
        assert_eq!(updated.published_at, original_published_at);
        Ok(())
    });
}

#[test]
fn admin_publishing_someone_elses_post_sets_published_at() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uppt_author5");
        let admin = create_user(conn, "uppt_admin5");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);
        let post = create_post(
            Post {
                title: Some("Test Post".to_string()),
                content: Some("Test content".to_string()),
                visibility: Visibility::Private as i32,
                ..Default::default()
            },
            &author,
            conn,
        )?;

        let updated = update_post(
            update_visibility(&post.id, Visibility::ServerPublic),
            &admin,
            conn,
        )?;

        assert_eq!(updated.published_at, updated.updated_at);
        assert_ne!(updated.published_at, None);
        Ok(())
    });
}
