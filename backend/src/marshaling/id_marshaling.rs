use tonic::{Status, Code};

pub trait ToProtoId {
    fn to_proto_id(&self) -> String;
}
impl ToProtoId for i64 {
    fn to_proto_id(&self) -> String {
        let id_bytes = (self + OFFSET).to_le_bytes();
        bs58::encode(id_bytes).into_string()
    }
}

pub trait ToDbId {
    fn to_db_id(&self) -> Result<i64, bs58::decode::Error>;
    fn to_db_id_or_err(&self, field_name: &str) -> Result<i64, Status>;
}
impl ToDbId for String {
    fn to_db_id(&self) -> Result<i64, bs58::decode::Error> {
        let id_bytes = bs58::decode(self).into_vec()?;
        let id = i64::from_le_bytes(id_bytes.as_slice().try_into().unwrap_or([0; 8]));
        if id == 0 {
            return Err(bs58::decode::Error::InvalidCharacter {
                character: '0',
                index: 0,
            });
        }
        Ok(id - OFFSET)
    }

    fn to_db_id_or_err(&self, field_name: &str) -> Result<i64, Status> {
        match self.to_db_id() {
            Ok(id) => Ok(id),
            Err(_) => Err(Status::new(Code::InvalidArgument, format!("invalid_id_{}", field_name))),
        }
    }

}

pub trait ToDbOptId {
    fn to_db_opt_id(&self) -> Result<Option<i64>, bs58::decode::Error>;
    fn to_db_opt_id_or_err(&self, field_name: &str) -> Result<Option<i64>, Status>;
}
impl ToDbOptId for Option<String> {
    fn to_db_opt_id(&self) -> Result<Option<i64>, bs58::decode::Error> {
        match self {
            None => Ok(None),
            Some(string) => Ok(Some(string.to_db_id()?))
        }
    }

    fn to_db_opt_id_or_err(&self, field_name: &str) -> Result<Option<i64>, Status> {
        match self {
            None => Ok(None),
            Some(string) => Ok(Some(string.to_db_id_or_err(field_name)?))
        }
    }
}

const OFFSET: i64 = 7;

#[cfg(test)]
mod tests {
    use crate::marshaling::ToDbId;
    use crate::marshaling::ToProtoId;

    #[test]
    fn id_conversions_work() {
        assert_eq!(10, 10.to_proto_id().to_db_id().unwrap());
        assert_eq!(10000000000000, 10000000000000.to_proto_id().to_db_id().unwrap());
    }
}
