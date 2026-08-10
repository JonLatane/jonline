//! Specs for `delete_follow`: either side of a Follow (the follower or the target) may delete it
//! without special permissions; anyone else needs Admin. `mutual_follow_sets_friend_follower_and_
//! following_counts_for_both_users` in `user_counts_tests` covers `create_follow`'s count side;
//! this covers `delete_follow`'s permission surface and that it also recomputes counts.

use diesel::prelude::*;
use tonic::Code;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::delete_follow;
use crate::schema::follows;
use crate::tests::factories::*;

fn follow_request(user: &models::User, target: &models::User) -> Follow {
    Follow {
        user_id: user.id.to_proto_id(),
        target_user_id: target.id.to_proto_id(),
        ..Default::default()
    }
}

#[test]
fn the_follower_can_unfollow() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let follower = create_user(conn, "dft_follower");
        let target = create_user(conn, "dft_target");
        create_follow(conn, &follower, &target);

        delete_follow(follow_request(&follower, &target), &follower, conn)
            .expect("follower unfollow should succeed");

        let remaining: i64 = follows::table
            .filter(follows::user_id.eq(follower.id))
            .filter(follows::target_user_id.eq(target.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        let target_after = models::get_user(target.id, conn).unwrap();
        assert_eq!(target_after.follower_count, 0);

        Ok(())
    });
}

#[test]
fn the_target_can_remove_a_follower() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let follower = create_user(conn, "dft_follower2");
        let target = create_user(conn, "dft_target2");
        create_follow(conn, &follower, &target);

        delete_follow(follow_request(&follower, &target), &target, conn)
            .expect("target-initiated removal should succeed");

        let remaining: i64 = follows::table
            .filter(follows::user_id.eq(follower.id))
            .filter(follows::target_user_id.eq(target.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn delete_rejects_an_unrelated_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let follower = create_user(conn, "dft_follower3");
        let target = create_user(conn, "dft_target3");
        create_follow(conn, &follower, &target);
        let bystander = create_user(conn, "dft_bystander");

        let err = delete_follow(follow_request(&follower, &target), &bystander, conn).unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_ADMIN_required");

        let remaining: i64 = follows::table
            .filter(follows::user_id.eq(follower.id))
            .filter(follows::target_user_id.eq(target.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 1, "follow should survive a rejected delete");

        Ok(())
    });
}

#[test]
fn admin_can_delete_an_unrelated_follow() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let follower = create_user(conn, "dft_follower4");
        let target = create_user(conn, "dft_target4");
        create_follow(conn, &follower, &target);
        let admin = create_user(conn, "dft_admin");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        delete_follow(follow_request(&follower, &target), &admin, conn)
            .expect("admin delete should succeed");

        let remaining: i64 = follows::table
            .filter(follows::user_id.eq(follower.id))
            .filter(follows::target_user_id.eq(target.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}
