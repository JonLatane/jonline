use prost_wkt_types::Timestamp;
use std::time::{SystemTime, UNIX_EPOCH};
use tonic::{Code, Status};

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

pub trait ToDbTime {
    fn to_db(&self) -> SystemTime;
}

impl ToDbTime for Timestamp {
    fn to_db(&self) -> SystemTime {
        UNIX_EPOCH + std::time::Duration::from_secs(self.seconds as u64)
    }
}

pub trait ToDbOptTime {
    fn to_db(&self) -> Result<SystemTime, Status>;
}

impl ToDbOptTime for Option<Timestamp> {
    fn to_db(&self) -> Result<SystemTime, Status> {
        let result = self
            .as_ref()
            .ok_or(Status::new(
                Code::InvalidArgument,
                format!("invalid_timestamp:_{:?}", self),
            ))?
            .to_db()
            .clone();
        Ok(result)
    }
}
