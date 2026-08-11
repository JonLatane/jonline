//! Specs for the group-domain delete RPCs: `delete_group`, `delete_membership`,
//! `delete_group_post`. All three share the same permission shape (self/owner, or a group-Admin
//! membership, or a site-wide Admin/ModerateGroups permission) via `validate_group_admin`/
//! `validate_group_permission`; these specs cover each RPC's variant of it plus the row-level
//! effect (removed row, recomputed group counters).

use diesel::prelude::*;
use tonic::Code;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::{delete_group, delete_group_post, delete_membership};
use crate::schema::{group_posts, groups, memberships};
use crate::tests::factories::*;

// ---- delete_group ----

#[test]
fn group_admin_member_can_delete_the_group() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dgt_owned", GroupOpts::default());
        let owner = create_user(conn, "dgt_owner");
        create_membership(
            conn,
            &owner,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![Permission::Admin],
        );

        delete_group(group.to_proto(conn, &None), &owner, conn).expect("delete should succeed");

        let remaining: i64 = groups::table
            .filter(groups::id.eq(group.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn delete_rejects_non_admin_member() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dgt_member_only", GroupOpts::default());
        let member = create_user(conn, "dgt_member");
        create_membership(
            conn,
            &member,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![Permission::ViewPosts],
        );

        let err = delete_group(group.to_proto(conn, &None), &member, conn).unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "group_permission_ADMIN_required");

        let remaining: i64 = groups::table
            .filter(groups::id.eq(group.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 1, "group should survive a rejected delete");

        Ok(())
    });
}

#[test]
fn site_admin_can_delete_any_group_without_membership() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dgt_site_admin", GroupOpts::default());
        let admin = create_user(conn, "dgt_site_admin_user");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        delete_group(group.to_proto(conn, &None), &admin, conn)
            .expect("admin delete should succeed");

        let remaining: i64 = groups::table
            .filter(groups::id.eq(group.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

// ---- delete_membership ----

fn membership_request(user: &models::User, group: &models::Group) -> Membership {
    Membership {
        user_id: user.id.to_proto_id(),
        group_id: group.id.to_proto_id(),
        ..Default::default()
    }
}

#[test]
fn self_delete_leaves_the_group_and_recomputes_member_count() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dmt_self_leave", GroupOpts::default());
        let leaver = create_user(conn, "dmt_leaver");
        create_membership(
            conn,
            &leaver,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![],
        );
        let staying = create_user(conn, "dmt_staying");
        create_membership(
            conn,
            &staying,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![],
        );

        delete_membership(membership_request(&leaver, &group), &leaver, conn)
            .expect("self leave should succeed");

        let remaining: i64 = memberships::table
            .filter(memberships::group_id.eq(group.id))
            .filter(memberships::user_id.eq(leaver.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        let group_after: models::Group = groups::table.find(group.id).first(conn).unwrap();
        assert_eq!(group_after.member_count, 1, "only `staying` should remain");

        Ok(())
    });
}

#[test]
fn self_delete_rejects_a_rejected_membership() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dmt_rejected", GroupOpts::default());
        let user = create_user(conn, "dmt_rejected_user");
        create_membership(
            conn,
            &user,
            &group,
            Moderation::Approved,
            Moderation::Rejected,
            vec![],
        );

        let err = delete_membership(membership_request(&user, &group), &user, conn).unwrap_err();
        assert_eq!(err.code(), Code::FailedPrecondition);
        assert_eq!(err.message(), "cannot_delete_rejected_membership");

        Ok(())
    });
}

#[test]
fn delete_rejects_non_admin_non_self() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dmt_kick_reject", GroupOpts::default());
        let target = create_user(conn, "dmt_kick_target");
        create_membership(
            conn,
            &target,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![],
        );
        let bystander = create_user(conn, "dmt_bystander");

        let err =
            delete_membership(membership_request(&target, &group), &bystander, conn).unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "group_permission_ADMIN_required");

        Ok(())
    });
}

#[test]
fn group_admin_can_remove_another_members_membership() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dmt_kick_ok", GroupOpts::default());
        let target = create_user(conn, "dmt_kick_target2");
        create_membership(
            conn,
            &target,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![],
        );
        let group_admin = create_user(conn, "dmt_group_admin");
        create_membership(
            conn,
            &group_admin,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![Permission::Admin],
        );

        delete_membership(membership_request(&target, &group), &group_admin, conn)
            .expect("group admin kick should succeed");

        let remaining: i64 = memberships::table
            .filter(memberships::group_id.eq(group.id))
            .filter(memberships::user_id.eq(target.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

// ---- delete_group_post ----

fn group_post_request(group: &models::Group, post: &models::Post) -> GroupPost {
    GroupPost {
        group_id: group.id.to_proto_id(),
        post_id: post.id.to_proto_id(),
        ..Default::default()
    }
}

#[test]
fn sharer_can_delete_their_own_share() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dgpt_sharer", GroupOpts::default());
        let author = create_user(conn, "dgpt_author");
        let post = create_post(conn, Some(&author), PostOpts::default());
        create_group_post(conn, &post, &group, &author, Moderation::Approved);

        delete_group_post(group_post_request(&group, &post), &author, conn)
            .expect("sharer delete should succeed");

        let remaining: i64 = group_posts::table
            .filter(group_posts::group_id.eq(group.id))
            .filter(group_posts::post_id.eq(post.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn delete_rejects_non_sharer_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dgpt_reject", GroupOpts::default());
        let author = create_user(conn, "dgpt_author2");
        let post = create_post(conn, Some(&author), PostOpts::default());
        create_group_post(conn, &post, &group, &author, Moderation::Approved);
        let bystander = create_user(conn, "dgpt_bystander");

        let err =
            delete_group_post(group_post_request(&group, &post), &bystander, conn).unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "group_permission_ADMIN_required");

        Ok(())
    });
}

#[test]
fn group_admin_can_delete_anyones_share_and_post_count_is_recomputed() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let group = create_group(conn, "dgpt_admin", GroupOpts::default());
        let author = create_user(conn, "dgpt_author3");
        let post = create_post(conn, Some(&author), PostOpts::default());
        create_group_post(conn, &post, &group, &author, Moderation::Approved);
        let group_admin = create_user(conn, "dgpt_group_admin");
        create_membership(
            conn,
            &group_admin,
            &group,
            Moderation::Approved,
            Moderation::Approved,
            vec![Permission::Admin],
        );

        delete_group_post(group_post_request(&group, &post), &group_admin, conn)
            .expect("group admin delete should succeed");

        let group_after: models::Group = groups::table.find(group.id).first(conn).unwrap();
        assert_eq!(group_after.post_count, 0);

        Ok(())
    });
}
