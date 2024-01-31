
use crate::marshaling::ToDbId;
use crate::marshaling::ToProtoId;

#[test]
fn id_conversions_work() {
    assert_eq!(10, 10.to_proto_id().to_db_id().unwrap());
    assert_eq!(10000000000000, 10000000000000.to_proto_id().to_db_id().unwrap());
}
