//! Specs for `EventSyncDestination.synced_event_instance_count` -- computed fresh via `COUNT` at
//! request time (see that proto field's own doc), not stored. Covers
//! `marshaling::attach_synced_event_instance_counts`/`get_event_sync_destinations` end to end.

use diesel::Connection;

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::get_event_sync_destinations;
use crate::tests::factories::*;

#[test]
fn reports_zero_when_nothing_has_been_synced() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdct_zero");
        create_event_sync_destination_row(conn, &owner, "123");

        let response =
            get_event_sync_destinations(User::default(), &owner, conn).expect("get should succeed");
        assert_eq!(response.destinations.len(), 1);
        assert_eq!(
            response.destinations[0].synced_event_instance_count,
            Some(0)
        );

        Ok(())
    });
}

#[test]
fn counts_synced_instances_for_the_right_destination_only() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdct_count");
        let destination_a = create_event_sync_destination_row(conn, &owner, "123");
        let destination_b = create_event_sync_destination_row(conn, &owner, "456");

        let (event, _) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance_1, _) = create_event_instance(conn, &event, Some(&owner), Default::default());
        let (instance_2, _) = create_event_instance(conn, &event, Some(&owner), Default::default());

        create_event_instance_sync_destination_row(conn, &instance_1, &destination_a);
        create_event_instance_sync_destination_row(conn, &instance_2, &destination_a);
        create_event_instance_sync_destination_row(conn, &instance_1, &destination_b);

        let response =
            get_event_sync_destinations(User::default(), &owner, conn).expect("get should succeed");

        let count_for = |db_id: i64| {
            let proto_id = db_id.to_proto_id();
            response
                .destinations
                .iter()
                .find(|d| d.id == proto_id)
                .and_then(|d| d.synced_event_instance_count)
        };
        assert_eq!(count_for(destination_a.id), Some(2));
        assert_eq!(count_for(destination_b.id), Some(1));

        Ok(())
    });
}
