//! Specs for `rpcs::users::get_users`'s `USERS_TEXT_SEARCH`/`FOLLOWERS_TEXT_SEARCH`/
//! `FOLLOWING_TEXT_SEARCH`/`FRIENDS_TEXT_SEARCH`/`FOLLOW_REQUESTS_TEXT_SEARCH` listing types --
//! mirrors `get_posts_tests`'s own `text_search` module in structure/rigor. `users_text_search`
//! covers the unscoped search itself (username/real_name/bio matching, visibility, the
//! search_text validation errors); the four `*_text_search` modules each cover the interaction
//! between that same search and the relationship scoping their non-search counterpart
//! (`get_following`/`get_followers`/`get_friends`/`get_follow_requests`) already applies - a user
//! must satisfy *both* to appear.
//!
//! Each test opens its own connection to `TEST_DATABASE_URL` and runs entirely inside a
//! `test_transaction`, so nothing here is ever committed.

use diesel::Connection;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::get_users;
use crate::tests::factories::*;

fn ids(response: &GetUsersResponse) -> Vec<String> {
    response.users.iter().map(|u| u.id.clone()).collect()
}

mod users_text_search {
    use super::*;

    fn search(
        conn: &mut crate::db_connection::PgPooledConnection,
        search_text: Option<&str>,
        user: &Option<&crate::models::User>,
    ) -> Result<GetUsersResponse, Status> {
        get_users(
            GetUsersRequest {
                listing_type: UserListingType::UsersTextSearch as i32,
                search_text: search_text.map(str::to_string),
                ..Default::default()
            },
            user,
            conn,
        )
    }

    #[test]
    fn missing_search_text_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = search(conn, None, &None).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }

    #[test]
    fn blank_search_text_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = search(conn, Some("   "), &None).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }

    #[test]
    fn matches_username() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            // `create_user` defaults to `ServerPublic` visibility (invisible to the anonymous
            // `search` requester here) - `create_user_with` makes this one `GlobalPublic` instead.
            let user = create_user_with(
                conn,
                "zzyzxfleck",
                Visibility::GlobalPublic,
                Moderation::Unmoderated,
            );

            let response = search(conn, Some("zzyzxfleck"), &None)?;
            assert_eq!(ids(&response), vec![user.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn matches_real_name() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let user = create_user_with_profile(conn, "utrn_user1", "Zorblatt Quixby", "");

            let response = search(conn, Some("Zorblatt"), &None)?;
            assert_eq!(ids(&response), vec![user.id.to_proto_id()]);
            Ok(())
        });
    }

    /// `search_text` matches by tsquery *prefix* (Postgres's `:*` operator - see
    /// `prefix_tsquery_text`), not just a whole/stemmed lexeme - "bob" should find "bobothy" too,
    /// not just a user literally named "bob".
    #[test]
    fn matches_username_prefix() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let user = create_user_with(
                conn,
                "zzyzxflecktarn",
                Visibility::GlobalPublic,
                Moderation::Unmoderated,
            );

            let response = search(conn, Some("zzyzxfleck"), &None)?;
            assert_eq!(ids(&response), vec![user.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn matches_bio() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let user =
                create_user_with_profile(conn, "utbio_user1", "", "Loves collecting xylophones");

            let response = search(conn, Some("xylophones"), &None)?;
            assert_eq!(ids(&response), vec![user.id.to_proto_id()]);
            Ok(())
        });
    }

    /// `users.search_text` is a `GENERATED ALWAYS AS ... STORED` column (see
    /// `2026-07-22-202628_add_search_text_to_users`) - Postgres recomputes it automatically
    /// whenever `real_name`/`bio` change, with no trigger of our own needed. Confirms that
    /// actually happens against a real connection, not just that the migration applies cleanly.
    #[test]
    fn updated_real_name_and_bio_are_searchable() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let user =
                create_user_with_profile(conn, "utupd_user1", "Original Name", "Original bio");
            assert!(search(conn, Some("Wibbledoo"), &None)?.users.is_empty());

            update_user_profile(
                conn,
                &user,
                "Wibbledoo Fenwick",
                "talks about wibbledoo constantly",
            );

            let response = search(conn, Some("Wibbledoo"), &None)?;
            assert_eq!(ids(&response), vec![user.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn excludes_users_not_visible_to_requester() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            create_user_with(
                conn,
                "utpriv_user1",
                Visibility::Private,
                Moderation::Unmoderated,
            );

            let response = search(conn, Some("utpriv_user1"), &None)?;
            assert!(response.users.is_empty());
            Ok(())
        });
    }

    #[test]
    fn anonymous_sees_only_global_public_authenticated_sees_server_public_too() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            // Deliberately doesn't share the "wobbzk" search term with `global`/`server` below --
            // otherwise the self-visibility clause (a user always sees itself, matching or not)
            // would put `viewer` in its own results too.
            let viewer = create_user(conn, "utvis_viewer1");
            let global = create_user_with(
                conn,
                "wobbzk_global1",
                Visibility::GlobalPublic,
                Moderation::Unmoderated,
            );
            let server = create_user_with(
                conn,
                "wobbzk_server1",
                Visibility::ServerPublic,
                Moderation::Unmoderated,
            );

            let anon_response = search(conn, Some("wobbzk"), &None)?;
            assert_eq!(ids(&anon_response), vec![global.id.to_proto_id()]);

            let auth_response = search(conn, Some("wobbzk"), &Some(&viewer))?;
            let mut actual = ids(&auth_response);
            actual.sort();
            let mut expected = vec![global.id.to_proto_id(), server.id.to_proto_id()];
            expected.sort();
            assert_eq!(actual, expected);
            Ok(())
        });
    }
}

mod followers_text_search {
    use super::*;

    fn search(
        conn: &mut crate::db_connection::PgPooledConnection,
        target_user_id: String,
        search_text: Option<&str>,
    ) -> Result<GetUsersResponse, Status> {
        get_users(
            GetUsersRequest {
                listing_type: UserListingType::FollowersTextSearch as i32,
                user_id: Some(target_user_id),
                search_text: search_text.map(str::to_string),
                ..Default::default()
            },
            &None,
            conn,
        )
    }

    /// A user must both follow `target` *and* match `search_text` to show up - a matching
    /// follower of someone else, and a non-matching follower of `target`, are each excluded.
    #[test]
    fn matches_only_followers_whose_profile_matches_search_text() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let target = create_user(conn, "followerstx_target1");
            let matching_follower =
                create_user_with_profile(conn, "followerstx_match1", "Bramblewick Match", "");
            let other_follower = create_user(conn, "followerstx_other1");
            let non_follower_match =
                create_user_with_profile(conn, "followerstx_nonfollow1", "Bramblewick NoFollow", "");
            create_follow(conn, &matching_follower, &target);
            create_follow(conn, &other_follower, &target);

            let response = search(conn, target.id.to_proto_id(), Some("Bramblewick"))?;
            assert_eq!(ids(&response), vec![matching_follower.id.to_proto_id()]);
            assert!(!ids(&response).contains(&non_follower_match.id.to_proto_id()));
            Ok(())
        });
    }

    #[test]
    fn missing_search_text_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let target = create_user(conn, "followerstx_target2");
            let err = search(conn, target.id.to_proto_id(), None).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }
}

mod following_text_search {
    use super::*;

    fn search(
        conn: &mut crate::db_connection::PgPooledConnection,
        target_user_id: String,
        search_text: Option<&str>,
    ) -> Result<GetUsersResponse, Status> {
        get_users(
            GetUsersRequest {
                listing_type: UserListingType::FollowingTextSearch as i32,
                user_id: Some(target_user_id),
                search_text: search_text.map(str::to_string),
                ..Default::default()
            },
            &None,
            conn,
        )
    }

    /// A user must both be followed *by* `target` *and* match `search_text` - mirrors
    /// `followers_text_search`'s test, just with the follow direction reversed.
    #[test]
    fn matches_only_followed_users_whose_profile_matches_search_text() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let target = create_user(conn, "followingtx_target1");
            let matching_followed =
                create_user_with_profile(conn, "followingtx_match1", "Crumplehorn Match", "");
            let other_followed = create_user(conn, "followingtx_other1");
            create_follow(conn, &target, &matching_followed);
            create_follow(conn, &target, &other_followed);

            let response = search(conn, target.id.to_proto_id(), Some("Crumplehorn"))?;
            assert_eq!(ids(&response), vec![matching_followed.id.to_proto_id()]);
            Ok(())
        });
    }
}

mod friends_text_search {
    use super::*;

    fn search(
        conn: &mut crate::db_connection::PgPooledConnection,
        target_user_id: String,
        search_text: Option<&str>,
    ) -> Result<GetUsersResponse, Status> {
        get_users(
            GetUsersRequest {
                listing_type: UserListingType::FriendsTextSearch as i32,
                user_id: Some(target_user_id),
                search_text: search_text.map(str::to_string),
                ..Default::default()
            },
            &None,
            conn,
        )
    }

    /// Only a *mutual* follow that also matches `search_text` counts - a one-way relationship
    /// that matches the search text is excluded just like a mutual one that doesn't match.
    #[test]
    fn matches_only_mutual_follows_whose_profile_matches_search_text() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let target = create_user(conn, "friendstx_target1");
            let matching_friend =
                create_user_with_profile(conn, "friendstx_match1", "Snorbdunk Match", "");
            let other_friend = create_user(conn, "friendstx_other1");
            let one_way_match =
                create_user_with_profile(conn, "friendstx_oneway1", "Snorbdunk OneWay", "");
            create_follow(conn, &target, &matching_friend);
            create_follow(conn, &matching_friend, &target);
            create_follow(conn, &target, &other_friend);
            create_follow(conn, &other_friend, &target);
            create_follow(conn, &target, &one_way_match);

            let response = search(conn, target.id.to_proto_id(), Some("Snorbdunk"))?;
            assert_eq!(ids(&response), vec![matching_friend.id.to_proto_id()]);
            Ok(())
        });
    }
}

mod follow_requests_text_search {
    use super::*;

    fn search(
        conn: &mut crate::db_connection::PgPooledConnection,
        search_text: Option<&str>,
        user: &Option<&crate::models::User>,
    ) -> Result<GetUsersResponse, Status> {
        get_users(
            GetUsersRequest {
                listing_type: UserListingType::FollowRequestsTextSearch as i32,
                search_text: search_text.map(str::to_string),
                ..Default::default()
            },
            user,
            conn,
        )
    }

    #[test]
    fn anonymous_gets_empty_response_not_an_error() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let response = search(conn, Some("anything"), &None)?;
            assert!(response.users.is_empty());
            Ok(())
        });
    }

    #[test]
    fn missing_search_text_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let current_user = create_user(conn, "frtx_current1");
            let err = search(conn, None, &Some(&current_user)).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }

    /// Only a *pending* follow request targeting the signed-in caller, whose requester's profile
    /// also matches `search_text`, shows up - an approved follow (not a pending request) and a
    /// matching-but-non-pending requester are both excluded.
    #[test]
    fn matches_only_pending_requesters_whose_profile_matches_search_text() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let current_user = create_user(conn, "frtx_current2");
            let matching_requester =
                create_user_with_profile(conn, "frtx_match2", "Puddlejump Match", "");
            let other_requester = create_user(conn, "frtx_other2");
            let approved_match =
                create_user_with_profile(conn, "frtx_approved2", "Puddlejump Approved", "");
            create_follow_with_moderation(
                conn,
                &matching_requester,
                &current_user,
                Moderation::Pending,
            );
            create_follow_with_moderation(conn, &other_requester, &current_user, Moderation::Pending);
            create_follow_with_moderation(conn, &approved_match, &current_user, Moderation::Approved);

            let response = search(conn, Some("Puddlejump"), &Some(&current_user))?;
            assert_eq!(ids(&response), vec![matching_requester.id.to_proto_id()]);
            Ok(())
        });
    }
}
