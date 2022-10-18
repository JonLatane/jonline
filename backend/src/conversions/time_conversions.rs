use std::time::{SystemTime, UNIX_EPOCH};
use prost_wkt_types::Timestamp;

pub trait ToProtoTime {
    fn to_proto(&self) -> Timestamp;
}
impl ToProtoTime for SystemTime {
    fn to_proto(&self) -> Timestamp {
        Timestamp {
            seconds: self.duration_since(UNIX_EPOCH).unwrap().as_secs() as i64,
            nanos: 0,
        }
    }
}
