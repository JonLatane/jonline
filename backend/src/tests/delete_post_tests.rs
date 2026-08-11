//! Specs for `delete_post`: ownership/permission checks, and that a delete soft-deletes (scrubs
//! `user_id`/`title`/`content`/`link`/`media`, but keeps the row) rather than removing anything.
//! `delete_post_decrements_the_authors_counts` in `user_counts_tests` already covers the
//! author's own `post_count`; this file covers permissions plus the parent post's
//! `reply_count`/`response_count`, which `delete_post` also maintains.

use diesel::prelude::*;
use tonic::Code;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::delete_post;
use crate::schema::posts;
use crate::tests::factories::*;

#[test]
fn self_delete_scrubs_the_post_but_keeps_the_row() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let author = create_user(conn, "dpt_self");
        let post = create_post(conn, Some(&author), PostOpts::default());

        let result = delete_post(
            Post {
                id: post.id.to_proto_id(),
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("self delete should succeed");
        assert_eq!(result.id, post.id.to_proto_id());

        let after = models::get_post(post.id, conn).unwrap();
        assert_eq!(after.user_id, None);
        assert_eq!(after.title, None);
        assert_eq!(after.content, None);
        assert_eq!(after.link, None);
        assert!(after.media.is_empty());

        let remaining: i64 = posts::table
            .filter(posts::id.eq(post.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(
            remaining, 1,
            "delete_post should soft-delete, not remove the row"
        );

        Ok(())
    });
}

#[test]
fn delete_rejects_non_owner_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let author = create_user(conn, "dpt_owner");
        let post = create_post(conn, Some(&author), PostOpts::default());
        let other = create_user(conn, "dpt_other");

        let err = delete_post(
            Post {
                id: post.id.to_proto_id(),
                ..Default::default()
            },
            &other,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_ADMIN_required");

        let after = models::get_post(post.id, conn).unwrap();
        assert!(
            after.user_id.is_some(),
            "post should survive a rejected delete"
        );

        Ok(())
    });
}

#[test]
fn admin_can_delete_another_users_post() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let author = create_user(conn, "dpt_admin_author");
        let post = create_post(conn, Some(&author), PostOpts::default());
        let admin = create_user(conn, "dpt_admin");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        delete_post(
            Post {
                id: post.id.to_proto_id(),
                ..Default::default()
            },
            &admin,
            conn,
        )
        .expect("admin delete should succeed");

        let after = models::get_post(post.id, conn).unwrap();
        assert_eq!(after.user_id, None);

        Ok(())
    });
}

#[test]
fn delete_decrements_the_parents_reply_and_response_counts() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let author = create_user(conn, "dpt_reply_author");
        let parent = create_post(conn, Some(&author), PostOpts::default());
        let reply = create_post(
            conn,
            Some(&author),
            PostOpts {
                context: PostContext::Reply,
                parent_post_id: Some(parent.id),
                title: None,
                content: Some("A reply".to_string()),
                ..Default::default()
            },
        );
        // create_post (the factory) inserts directly and doesn't bump counters the way the
        // CreatePost RPC does -- seed them here so there's something meaningful to decrement.
        diesel::update(posts::table.filter(posts::id.eq(parent.id)))
            .set((posts::reply_count.eq(1), posts::response_count.eq(1)))
            .execute(conn)
            .unwrap();

        delete_post(
            Post {
                id: reply.id.to_proto_id(),
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("delete should succeed");

        let parent_after = models::get_post(parent.id, conn).unwrap();
        assert_eq!(parent_after.reply_count, 0);
        assert_eq!(parent_after.response_count, 0);

        Ok(())
    });
}
