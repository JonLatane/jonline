//! Specs for `rpcs::messages::get_messages`, covering every branch of the `match` in
//! `get_messages()` plus the personal-vs-system-listing access rules baked into its query helpers.
//!
//! Each test opens its own connection to `TEST_DATABASE_URL` and runs entirely inside a
//! `test_transaction`, so nothing here is ever committed - tests are free to create users,
//! messages, etc. via `crate::tests::factories` without any cleanup step.

use std::time::{Duration, SystemTime};

use diesel::Connection;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::get_messages;
use crate::tests::factories::*;

fn ids(response: &GetMessagesResponse) -> Vec<String> {
    response.messages.iter().map(|m| m.id.clone()).collect()
}

fn ago(seconds: u64) -> SystemTime {
    SystemTime::now() - Duration::from_secs(seconds)
}

mod personal_messages {
    use super::*;

    #[test]
    fn requires_login() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_messages(GetMessagesRequest::default(), &None, conn);

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "permission_READ_PERSONAL_MESSAGES_required");
            Ok(())
        });
    }

    #[test]
    fn requires_read_personal_messages_permission() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let user = create_user(conn, "gmpm_no_perm");

            let result = get_messages(GetMessagesRequest::default(), &Some(&user), conn);

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "permission_READ_PERSONAL_MESSAGES_required");
            Ok(())
        });
    }

    #[test]
    fn returns_sent_and_received_messages_only() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let me = create_user(conn, "gmpm_me");
            let me = grant_permissions(conn, &me, vec![Permission::ReadPersonalMessages]);
            let other = create_user(conn, "gmpm_other");
            let stranger = create_user(conn, "gmpm_stranger");

            let sent_to_me = create_message(
                conn,
                Some(&other),
                &[&me],
                MessageOpts {
                    created_at: Some(ago(1)),
                    ..Default::default()
                },
            );
            let sent_by_me = create_message(
                conn,
                Some(&me),
                &[&other],
                MessageOpts {
                    created_at: Some(ago(2)),
                    ..Default::default()
                },
            );
            let unrelated =
                create_message(conn, Some(&other), &[&stranger], MessageOpts::default());

            let response = get_messages(GetMessagesRequest::default(), &Some(&me), conn)?;

            let response_ids = ids(&response);
            assert_eq!(
                response_ids,
                vec![sent_to_me.id.to_proto_id(), sent_by_me.id.to_proto_id()]
            );
            assert!(!response_ids.contains(&unrelated.id.to_proto_id()));
            Ok(())
        });
    }

    #[test]
    fn text_search_matches_subject_and_body() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let me = create_user(conn, "gmpm_search_me");
            let me = grant_permissions(conn, &me, vec![Permission::ReadPersonalMessages]);
            let other = create_user(conn, "gmpm_search_other");

            let matching = create_message(
                conn,
                Some(&other),
                &[&me],
                MessageOpts {
                    subject: Some("Weekend Plans".to_string()),
                    body_text: Some("Are we still on for hiking?".to_string()),
                    ..Default::default()
                },
            );
            let non_matching = create_message(
                conn,
                Some(&other),
                &[&me],
                MessageOpts {
                    subject: Some("Invoice".to_string()),
                    body_text: Some("Please find attached.".to_string()),
                    ..Default::default()
                },
            );

            let response = get_messages(
                GetMessagesRequest {
                    listing_type: MessageListingType::PersonalMessagesTextSearch as i32,
                    search_text: Some("hiking".to_string()),
                    ..Default::default()
                },
                &Some(&me),
                conn,
            )?;

            let response_ids = ids(&response);
            assert_eq!(response_ids, vec![matching.id.to_proto_id()]);
            assert!(!response_ids.contains(&non_matching.id.to_proto_id()));
            Ok(())
        });
    }
}

mod by_message_id {
    use super::*;

    #[test]
    fn found_for_participant() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let me = create_user(conn, "gmid_me");
            let me = grant_permissions(conn, &me, vec![Permission::ReadPersonalMessages]);
            let other = create_user(conn, "gmid_other");
            let message = create_message(conn, Some(&other), &[&me], MessageOpts::default());

            let response = get_messages(
                GetMessagesRequest {
                    message_id: Some(message.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&me),
                conn,
            )?;

            assert_eq!(ids(&response), vec![message.id.to_proto_id()]);
            let proto_message = &response.messages[0];
            assert_eq!(proto_message.subject, message.subject);
            assert!(proto_message.messaging_group.is_some());
            Ok(())
        });
    }

    #[test]
    fn not_found_for_non_participant() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let me = create_user(conn, "gmid_outsider");
            let me = grant_permissions(conn, &me, vec![Permission::ReadPersonalMessages]);
            let sender = create_user(conn, "gmid_sender");
            let recipient = create_user(conn, "gmid_recipient");
            let message =
                create_message(conn, Some(&sender), &[&recipient], MessageOpts::default());

            let result = get_messages(
                GetMessagesRequest {
                    message_id: Some(message.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&me),
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "message_not_found");
            Ok(())
        });
    }

    #[test]
    fn not_found_for_nonexistent_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let me = create_user(conn, "gmid_none");
            let me = grant_permissions(conn, &me, vec![Permission::ReadPersonalMessages]);

            let result = get_messages(
                GetMessagesRequest {
                    message_id: Some(999_999_999i64.to_proto_id()),
                    ..Default::default()
                },
                &Some(&me),
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "message_not_found");
            Ok(())
        });
    }
}

mod by_message_group_id {
    use super::*;

    #[test]
    fn returns_group_messages_for_member() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let me = create_user(conn, "gmgid_me");
            let me = grant_permissions(conn, &me, vec![Permission::ReadPersonalMessages]);
            let other = create_user(conn, "gmgid_other");
            let first = create_message(
                conn,
                Some(&other),
                &[&me],
                MessageOpts {
                    created_at: Some(ago(2)),
                    ..Default::default()
                },
            );
            let second = create_message(
                conn,
                Some(&me),
                &[&other],
                MessageOpts {
                    created_at: Some(ago(1)),
                    ..Default::default()
                },
            );

            let response = get_messages(
                GetMessagesRequest {
                    message_group_id: Some(first.messaging_group_id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&me),
                conn,
            )?;

            assert_eq!(
                ids(&response),
                vec![second.id.to_proto_id(), first.id.to_proto_id()]
            );
            Ok(())
        });
    }

    #[test]
    fn not_found_for_non_member() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let me = create_user(conn, "gmgid_outsider");
            let me = grant_permissions(conn, &me, vec![Permission::ReadPersonalMessages]);
            let sender = create_user(conn, "gmgid_sender");
            let recipient = create_user(conn, "gmgid_recipient");
            let message =
                create_message(conn, Some(&sender), &[&recipient], MessageOpts::default());

            let result = get_messages(
                GetMessagesRequest {
                    message_group_id: Some(message.messaging_group_id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&me),
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "messaging_group_not_found");
            Ok(())
        });
    }
}

mod all_system_messages {
    use super::*;

    #[test]
    fn requires_read_all_system_messages_permission() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            // Has personal-message access, but not system-wide access.
            let admin = create_user(conn, "gasm_no_perm");
            let admin = grant_permissions(conn, &admin, vec![Permission::ReadPersonalMessages]);

            let result = get_messages(
                GetMessagesRequest {
                    listing_type: MessageListingType::AllSystemMessages as i32,
                    ..Default::default()
                },
                &Some(&admin),
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(
                err.message(),
                "permission_READ_ALL_SYSTEM_MESSAGES_required"
            );
            Ok(())
        });
    }

    #[test]
    fn returns_every_message_on_the_server() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let admin = create_user(conn, "gasm_admin");
            let admin = grant_permissions(conn, &admin, vec![Permission::ReadAllSystemMessages]);
            let sender = create_user(conn, "gasm_sender");
            let recipient = create_user(conn, "gasm_recipient");
            let message =
                create_message(conn, Some(&sender), &[&recipient], MessageOpts::default());

            let response = get_messages(
                GetMessagesRequest {
                    listing_type: MessageListingType::AllSystemMessages as i32,
                    ..Default::default()
                },
                &Some(&admin),
                conn,
            )?;

            let response_ids = ids(&response);
            assert!(response_ids.contains(&message.id.to_proto_id()));
            // An admin (not a participant) still sees the full messaging group.
            let proto_message = response
                .messages
                .iter()
                .find(|m| m.id == message.id.to_proto_id())
                .unwrap();
            assert!(proto_message.messaging_group.is_some());
            Ok(())
        });
    }
}
