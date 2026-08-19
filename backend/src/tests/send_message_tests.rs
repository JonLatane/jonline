//! Specs for `rpcs::messages::send_message`.

use diesel::Connection;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::send_message;
use crate::tests::factories::*;

#[test]
fn authenticated_send_sets_sender_and_group() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let sender = create_user(conn, "sm_sender");
        let recipient = create_user(conn, "sm_recipient");

        let message = send_message(
            SendMessageRequest {
                to_user_ids: vec![recipient.id.to_proto_id()],
                subject: Some("Hello".to_string()),
                body_text: Some("Hi there!".to_string()),
            },
            &Some(&sender),
            conn,
            test_pool(),
        )?;

        assert_eq!(message.subject, Some("Hello".to_string()));
        assert_eq!(message.body_text, "Hi there!".to_string());
        assert_eq!(
            message.sender.map(|a| a.user_id),
            Some(sender.id.to_proto_id())
        );
        let group = message.messaging_group.expect("messaging_group");
        let mut member_ids: Vec<String> = group.members.iter().map(|a| a.user_id.clone()).collect();
        member_ids.sort();
        let mut expected_ids = vec![sender.id.to_proto_id(), recipient.id.to_proto_id()];
        expected_ids.sort();
        assert_eq!(member_ids, expected_ids);
        Ok(())
    });
}

#[test]
fn anonymous_send_has_no_sender() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let recipient = create_user(conn, "sm_anon_recipient");

        let message = send_message(
            SendMessageRequest {
                to_user_ids: vec![recipient.id.to_proto_id()],
                subject: None,
                body_text: Some("Anonymous tip".to_string()),
            },
            &None,
            conn,
            test_pool(),
        )?;

        assert!(message.sender.is_none());
        assert_eq!(message.body_text, "Anonymous tip".to_string());
        let group = message.messaging_group.expect("messaging_group");
        assert_eq!(
            group
                .members
                .iter()
                .map(|a| a.user_id.clone())
                .collect::<Vec<_>>(),
            vec![recipient.id.to_proto_id()]
        );
        Ok(())
    });
}

#[test]
fn requires_at_least_one_recipient() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let sender = create_user(conn, "sm_no_recipients");

        let result = send_message(
            SendMessageRequest {
                to_user_ids: vec![],
                subject: None,
                body_text: Some("Hi".to_string()),
            },
            &Some(&sender),
            conn,
            test_pool(),
        );

        let err = result.unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "to_user_ids_required");
        Ok(())
    });
}

#[test]
fn rejects_nonexistent_recipient() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let sender = create_user(conn, "sm_bad_recipient");

        let result = send_message(
            SendMessageRequest {
                to_user_ids: vec![999_999_999i64.to_proto_id()],
                subject: None,
                body_text: Some("Hi".to_string()),
            },
            &Some(&sender),
            conn,
            test_pool(),
        );

        let err = result.unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "to_user_ids_invalid");
        Ok(())
    });
}

#[test]
fn requires_non_empty_body_text() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let sender = create_user(conn, "sm_empty_body_sender");
        let recipient = create_user(conn, "sm_empty_body_recipient");

        let result = send_message(
            SendMessageRequest {
                to_user_ids: vec![recipient.id.to_proto_id()],
                subject: Some("Subject only".to_string()),
                body_text: Some("   ".to_string()),
            },
            &Some(&sender),
            conn,
            test_pool(),
        );

        let err = result.unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "body_text_required");
        Ok(())
    });
}
