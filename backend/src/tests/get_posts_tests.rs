//! Specs for `rpcs::posts::get_posts`, covering every branch of the `match` in
//! `get_posts()` plus the visibility/moderation rules baked into `query_visible_posts!`.
//!
//! Each test opens its own connection to `TEST_DATABASE_URL` and runs entirely inside a
//! `test_transaction`, so nothing here is ever committed - tests are free to create users,
//! posts, groups, etc. via `crate::tests::factories` without any cleanup step.

use diesel::Connection;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::get_posts;
use crate::tests::factories::*;

fn ids(response: &GetPostsResponse) -> Vec<String> {
    response.posts.iter().map(|p| p.id.clone()).collect()
}

mod get_by_post_id {
    use super::*;

    #[test]
    fn found_returns_public_post() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbpi_author1");
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![post.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn not_found_for_nonexistent_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_posts(
                GetPostsRequest {
                    post_id: Some(999_999_999i64.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "post_not_found");
            Ok(())
        });
    }

    #[test]
    fn invalid_id_format() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_posts(
                GetPostsRequest {
                    post_id: Some("not-valid-base58!!".to_string()),
                    ..Default::default()
                },
                &None,
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "post_id_invalid");
            Ok(())
        });
    }

    #[test]
    fn private_post_visible_to_author_only() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbpi_author2");
            let other = create_user(conn, "gbpi_other2");
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::Private,
                    ..Default::default()
                },
            );

            let response = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&author),
                conn,
            )?;
            assert_eq!(ids(&response), vec![post.id.to_proto_id()]);

            let hidden = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&other),
                conn,
            );
            assert_eq!(hidden.unwrap_err().code(), Code::NotFound);

            let anon = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            );
            assert_eq!(anon.unwrap_err().code(), Code::NotFound);
            Ok(())
        });
    }

    #[test]
    fn limited_post_visible_to_follower_only() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbpi_author3");
            let follower = create_user(conn, "gbpi_follower3");
            let stranger = create_user(conn, "gbpi_stranger3");
            create_follow(conn, &follower, &author);
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::Limited,
                    ..Default::default()
                },
            );

            let visible = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&follower),
                conn,
            )?;
            assert_eq!(ids(&visible), vec![post.id.to_proto_id()]);

            let hidden = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&stranger),
                conn,
            );
            assert_eq!(hidden.unwrap_err().code(), Code::NotFound);
            Ok(())
        });
    }

    #[test]
    fn limited_post_visible_via_passing_group_membership() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbpi_author4");
            let member = create_user(conn, "gbpi_member4");
            let pending_member = create_user(conn, "gbpi_pending4");
            let group = create_group(conn, "gbpi-group4", GroupOpts::default());
            create_membership(
                conn,
                &member,
                &group,
                Moderation::Approved,
                Moderation::Approved,
                vec![],
            );
            create_membership(
                conn,
                &pending_member,
                &group,
                Moderation::Pending,
                Moderation::Approved,
                vec![],
            );
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::Limited,
                    ..Default::default()
                },
            );
            create_group_post(conn, &post, &group, &author, Moderation::Approved);

            let visible = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&member),
                conn,
            )?;
            assert_eq!(ids(&visible), vec![post.id.to_proto_id()]);

            let hidden = get_posts(
                GetPostsRequest {
                    post_id: Some(post.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&pending_member),
                conn,
            );
            assert_eq!(hidden.unwrap_err().code(), Code::NotFound);
            Ok(())
        });
    }
}

mod replies {
    use super::*;

    struct Tree {
        root: crate::models::Post,
        reply1: crate::models::Post,
        reply2: crate::models::Post,
    }

    fn build_tree(conn: &mut crate::db_connection::PgPooledConnection) -> Tree {
        let author = create_user(conn, "replies_author");
        let root = create_post(
            conn,
            Some(&author),
            PostOpts {
                visibility: Visibility::GlobalPublic,
                ..Default::default()
            },
        );
        let reply1 = create_post(
            conn,
            Some(&author),
            PostOpts {
                visibility: Visibility::GlobalPublic,
                context: PostContext::Reply,
                parent_post_id: Some(root.id),
                ..Default::default()
            },
        );
        let reply2 = create_post(
            conn,
            Some(&author),
            PostOpts {
                visibility: Visibility::GlobalPublic,
                context: PostContext::Reply,
                parent_post_id: Some(reply1.id),
                ..Default::default()
            },
        );
        Tree { root, reply1, reply2 }
    }

    #[test]
    fn depth_zero_or_none_returns_only_the_post_itself() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let tree = build_tree(conn);

            let none_response = get_posts(
                GetPostsRequest {
                    post_id: Some(tree.root.id.to_proto_id()),
                    reply_depth: None,
                    ..Default::default()
                },
                &None,
                conn,
            )?;
            assert_eq!(ids(&none_response), vec![tree.root.id.to_proto_id()]);

            let zero_response = get_posts(
                GetPostsRequest {
                    post_id: Some(tree.root.id.to_proto_id()),
                    reply_depth: Some(0),
                    ..Default::default()
                },
                &None,
                conn,
            )?;
            assert_eq!(ids(&zero_response), vec![tree.root.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn depth_one_returns_only_direct_replies() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let tree = build_tree(conn);

            let response = get_posts(
                GetPostsRequest {
                    post_id: Some(tree.root.id.to_proto_id()),
                    reply_depth: Some(1),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![tree.reply1.id.to_proto_id()]);
            assert!(response.posts[0].replies.is_empty());
            Ok(())
        });
    }

    #[test]
    fn depth_two_returns_nested_replies() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let tree = build_tree(conn);

            let response = get_posts(
                GetPostsRequest {
                    post_id: Some(tree.root.id.to_proto_id()),
                    reply_depth: Some(2),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![tree.reply1.id.to_proto_id()]);
            let nested = &response.posts[0].replies;
            assert_eq!(
                nested.iter().map(|p| p.id.clone()).collect::<Vec<_>>(),
                vec![tree.reply2.id.to_proto_id()]
            );
            Ok(())
        });
    }

    #[test]
    fn invalid_id_format() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_posts(
                GetPostsRequest {
                    post_id: Some("not-valid-base58!!".to_string()),
                    reply_depth: Some(1),
                    ..Default::default()
                },
                &None,
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "replies_to_post_id_invalid");
            Ok(())
        });
    }

    #[test]
    fn excludes_replies_with_no_author_and_no_responses() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "replies_author_orphan");
            let root = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            // Simulates a reply left behind by a deleted user (user_id NULL) that never
            // itself received any responses - get_replies_to_post_ids filters these out.
            create_post(
                conn,
                None,
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    context: PostContext::Reply,
                    parent_post_id: Some(root.id),
                    ..Default::default()
                },
            );

            let response = get_posts(
                GetPostsRequest {
                    post_id: Some(root.id.to_proto_id()),
                    reply_depth: Some(1),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert!(response.posts.is_empty());
            Ok(())
        });
    }
}

mod text_search {
    use super::*;

    fn search(
        conn: &mut crate::db_connection::PgPooledConnection,
        search_text: Option<&str>,
        author_user_id: Option<String>,
        user: &Option<&crate::models::User>,
    ) -> Result<GetPostsResponse, Status> {
        get_posts(
            GetPostsRequest {
                listing_type: PostListingType::TextSearch as i32,
                search_text: search_text.map(str::to_string),
                author_user_id,
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
            let err = search(conn, None, None, &None).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }

    #[test]
    fn blank_search_text_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = search(conn, Some("   "), None, &None).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }

    #[test]
    fn matches_title() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_title_author");
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("A post about xylophones".to_string()),
                    ..Default::default()
                },
            );

            let response = search(conn, Some("xylophones"), None, &None)?;
            assert_eq!(ids(&response), vec![post.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn matches_author_username() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "zzyzxauthor");
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = search(conn, Some("zzyzxauthor"), None, &None)?;
            assert_eq!(ids(&response), vec![post.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn scoped_by_author_user_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author1 = create_user(conn, "search_scope_author1");
            let author2 = create_user(conn, "search_scope_author2");
            let post1 = create_post(
                conn,
                Some(&author1),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("wobblepost from author1".to_string()),
                    ..Default::default()
                },
            );
            create_post(
                conn,
                Some(&author2),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("wobblepost from author2".to_string()),
                    ..Default::default()
                },
            );

            let response = search(
                conn,
                Some("wobblepost"),
                Some(author1.id.to_proto_id()),
                &None,
            )?;
            assert_eq!(ids(&response), vec![post1.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn excludes_posts_not_visible_to_requester() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_private_author");
            create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::Private,
                    title: Some("a secret gizmo post".to_string()),
                    ..Default::default()
                },
            );

            let response = search(conn, Some("gizmo"), None, &None)?;
            assert!(response.posts.is_empty());
            Ok(())
        });
    }

    #[test]
    fn excludes_non_post_context() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_reply_author");
            let root = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    context: PostContext::Reply,
                    parent_post_id: Some(root.id),
                    title: None,
                    content: Some("flibbertigibbet".to_string()),
                    ..Default::default()
                },
            );

            let response = search(conn, Some("flibbertigibbet"), None, &None)?;
            assert!(response.posts.is_empty());
            Ok(())
        });
    }
}

mod user_posts {
    use super::*;

    #[test]
    fn returns_only_that_authors_posts() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author1 = create_user(conn, "userposts_author1");
            let author2 = create_user(conn, "userposts_author2");
            let post1 = create_post(
                conn,
                Some(&author1),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_post(
                conn,
                Some(&author2),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_posts(
                GetPostsRequest {
                    author_user_id: Some(author1.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![post1.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn respects_visibility_of_other_users_posts() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "userposts_author3");
            let public_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            let private_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::Private,
                    ..Default::default()
                },
            );

            let anon_response = get_posts(
                GetPostsRequest {
                    author_user_id: Some(author.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;
            assert_eq!(ids(&anon_response), vec![public_post.id.to_proto_id()]);

            let self_response = get_posts(
                GetPostsRequest {
                    author_user_id: Some(author.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&author),
                conn,
            )?;
            let mut self_ids = ids(&self_response);
            self_ids.sort();
            let mut expected = vec![public_post.id.to_proto_id(), private_post.id.to_proto_id()];
            expected.sort();
            assert_eq!(self_ids, expected);
            Ok(())
        });
    }
}

mod my_groups_posts {
    use super::*;

    #[test]
    fn requires_login() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::MyGroupsPosts as i32,
                    ..Default::default()
                },
                &None,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::Unauthenticated);
            Ok(())
        });
    }

    #[test]
    fn returns_posts_from_my_groups_with_passing_group_post_moderation() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let member = create_user(conn, "mygroups_member1");
            let author = create_user(conn, "mygroups_author1");
            let group = create_group(conn, "mygroups-group1", GroupOpts::default());
            create_membership(
                conn,
                &member,
                &group,
                Moderation::Approved,
                Moderation::Approved,
                vec![],
            );
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::ServerPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &post, &group, &author, Moderation::Approved);

            let response = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::MyGroupsPosts as i32,
                    ..Default::default()
                },
                &Some(&member),
                conn,
            )?;

            assert_eq!(ids(&response), vec![post.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn excludes_group_posts_pending_moderation() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let member = create_user(conn, "mygroups_member2");
            let author = create_user(conn, "mygroups_author2");
            let group = create_group(conn, "mygroups-group2", GroupOpts::default());
            create_membership(
                conn,
                &member,
                &group,
                Moderation::Approved,
                Moderation::Approved,
                vec![],
            );
            let post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::ServerPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &post, &group, &author, Moderation::Pending);

            let response = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::MyGroupsPosts as i32,
                    ..Default::default()
                },
                &Some(&member),
                conn,
            )?;

            assert!(response.posts.is_empty());
            Ok(())
        });
    }
}

mod following_posts {
    use super::*;

    #[test]
    fn requires_login() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::FollowingPosts as i32,
                    ..Default::default()
                },
                &None,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::Unauthenticated);
            Ok(())
        });
    }

    #[test]
    fn returns_posts_from_followed_users_only() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let follower = create_user(conn, "following_follower1");
            let followed = create_user(conn, "following_followed1");
            let not_followed = create_user(conn, "following_notfollowed1");
            create_follow(conn, &follower, &followed);

            let followed_post = create_post(
                conn,
                Some(&followed),
                PostOpts {
                    visibility: Visibility::ServerPublic,
                    ..Default::default()
                },
            );
            create_post(
                conn,
                Some(&not_followed),
                PostOpts {
                    visibility: Visibility::ServerPublic,
                    ..Default::default()
                },
            );

            let response = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::FollowingPosts as i32,
                    ..Default::default()
                },
                &Some(&follower),
                conn,
            )?;

            assert_eq!(ids(&response), vec![followed_post.id.to_proto_id()]);
            Ok(())
        });
    }
}

mod group_posts {
    use super::*;

    #[test]
    fn missing_group_id_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::GroupPosts as i32,
                    ..Default::default()
                },
                &None,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "group_id_required");
            Ok(())
        });
    }

    #[test]
    fn nonexistent_group_is_not_found() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::GroupPosts as i32,
                    group_id: Some(999_999_999i64.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "group_not_found");
            Ok(())
        });
    }

    #[test]
    fn permission_denied_for_private_group_non_member() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            // No non_member_permissions granted, and requester isn't a member.
            let group = create_group(conn, "grouppost-private1", GroupOpts::default());
            let stranger = create_user(conn, "grouppost_stranger1");

            let err = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::GroupPosts as i32,
                    group_id: Some(group.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&stranger),
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            Ok(())
        });
    }

    #[test]
    fn anonymous_can_view_when_group_grants_view_posts_to_non_members() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "grouppost_author2");
            let group = create_group(
                conn,
                "grouppost-public2",
                GroupOpts {
                    non_member_permissions: vec![Permission::ViewPosts],
                },
            );
            let unmoderated_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &unmoderated_post, &group, &author, Moderation::Unmoderated);
            let approved_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &approved_post, &group, &author, Moderation::Approved);
            let pending_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &pending_post, &group, &author, Moderation::Pending);

            let response = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::GroupPosts as i32,
                    group_id: Some(group.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            let mut actual = ids(&response);
            actual.sort();
            let mut expected = vec![
                unmoderated_post.id.to_proto_id(),
                approved_post.id.to_proto_id(),
            ];
            expected.sort();
            assert_eq!(actual, expected);
            Ok(())
        });
    }
}

mod group_posts_pending_moderation {
    use super::*;

    #[test]
    fn requires_login() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let group = create_group(conn, "grouppending-anon1", GroupOpts::default());
            let err = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::GroupPostsPendingModeration as i32,
                    group_id: Some(group.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::Unauthenticated);
            Ok(())
        });
    }

    #[test]
    fn returns_only_pending_posts_for_an_authorized_member() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "grouppending_author1");
            let moderator = create_user(conn, "grouppending_mod1");
            let group = create_group(conn, "grouppending-group1", GroupOpts::default());
            create_membership(
                conn,
                &moderator,
                &group,
                Moderation::Approved,
                Moderation::Approved,
                vec![Permission::ViewPosts],
            );
            let pending_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::ServerPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &pending_post, &group, &author, Moderation::Pending);
            let approved_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::ServerPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &approved_post, &group, &author, Moderation::Approved);

            let response = get_posts(
                GetPostsRequest {
                    listing_type: PostListingType::GroupPostsPendingModeration as i32,
                    group_id: Some(group.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&moderator),
                conn,
            )?;

            assert_eq!(ids(&response), vec![pending_post.id.to_proto_id()]);
            Ok(())
        });
    }
}

mod default_listing {
    use super::*;

    #[test]
    fn excludes_replies_and_authorless_posts() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "default_listing_author1");
            let top_level = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    context: PostContext::Reply,
                    parent_post_id: Some(top_level.id),
                    ..Default::default()
                },
            );
            create_post(
                conn,
                None,
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_posts(GetPostsRequest::default(), &None, conn)?;

            assert_eq!(ids(&response), vec![top_level.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn anonymous_sees_only_global_public_authenticated_sees_server_public_too() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "default_listing_author2");
            let viewer = create_user(conn, "default_listing_viewer2");
            let global_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            let server_post = create_post(
                conn,
                Some(&author),
                PostOpts {
                    visibility: Visibility::ServerPublic,
                    ..Default::default()
                },
            );

            let anon_response = get_posts(GetPostsRequest::default(), &None, conn)?;
            assert_eq!(ids(&anon_response), vec![global_post.id.to_proto_id()]);

            let auth_response = get_posts(GetPostsRequest::default(), &Some(&viewer), conn)?;
            let mut actual = ids(&auth_response);
            actual.sort();
            let mut expected = vec![global_post.id.to_proto_id(), server_post.id.to_proto_id()];
            expected.sort();
            assert_eq!(actual, expected);
            Ok(())
        });
    }
}
