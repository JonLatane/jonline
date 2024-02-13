use tonic::{Code, Status};

pub trait ToProtoId {
    // Converts an integer ID to a string that can be used in the proto file.
    // The ID is encoded as a base58 string either 4 or 8 bytes long,
    // depending on the size of the ID.
    fn to_proto_id(&self) -> String;
}

impl ToProtoId for i32 {
    fn to_proto_id(&self) -> String {
        let offset_value = self + OFFSET;
        let id_bytes = offset_value.to_le_bytes();
        bs58::encode(id_bytes).into_string()
    }
}

impl ToProtoId for i64 {
    fn to_proto_id(&self) -> String {
        let offset_value = self + (OFFSET as i64);
        if offset_value <= i32::MAX as i64 {
            (*self as i32).to_proto_id()
        } else {
            let id_bytes = (offset_value as i64).to_le_bytes();
            bs58::encode(id_bytes).into_string()
        }
    }
}

#[derive(Debug)]
pub enum IDDecodingError {
    // The ID couldn't be decoded because it's not a valid base58 string.
    Base58(bs58::decode::Error),
    // The ID couldn't be decoded because it has an invalid length. String/Proto IDs must be
    // base58-encoded 8 or 4 byte integers, which will be marshaled to i64 or to i32 (then cast as i64), respectively.
    InvalidLength(usize),
    // The ID couldn't be decoded because it's 0. 0 is not a valid ID.
    Id0,
}

pub trait ToDbId {
    fn to_db_id(&self) -> Result<i64, IDDecodingError>;
    fn to_db_id_or_err(&self, field_name: &str) -> Result<i64, Status>;
}
impl ToDbId for String {
    fn to_db_id(&self) -> Result<i64, IDDecodingError> {
        let id_bytes = bs58::decode(self)
            .into_vec()
            .map_err(|e| IDDecodingError::Base58(e))?;
        let id = match id_bytes.len() {
            4 => i32::from_le_bytes(id_bytes.as_slice().try_into().unwrap_or([0; 4])) as i64,
            8 => i64::from_le_bytes(id_bytes.as_slice().try_into().unwrap_or([0; 8])),
            _ => {
                print!("Invalid id: {}", self);
                return Err(IDDecodingError::InvalidLength(id_bytes.len()));
            }
        };
        // let id = i64::from_le_bytes(id_bytes.as_slice().try_into().unwrap_or([0; 8]));
        if id == 0 {
            print!("Invalid id: {}", self);
            return Err(IDDecodingError::Id0);
        }
        Ok(id - (OFFSET as i64))
    }

    fn to_db_id_or_err(&self, field_name: &str) -> Result<i64, Status> {
        match self.to_db_id() {
            Ok(id) => Ok(id),
            Err(_) => Err(Status::new(
                Code::InvalidArgument,
                format!("invalid_id:{}", field_name),
            )),
        }
    }
}

pub trait ToDbOptId {
    fn to_db_opt_id(&self) -> Result<Option<i64>, IDDecodingError>;
    fn to_db_opt_id_or_err(&self, field_name: &str) -> Result<Option<i64>, Status>;
}
impl ToDbOptId for Option<String> {
    fn to_db_opt_id(&self) -> Result<Option<i64>, IDDecodingError> {
        match self {
            None => Ok(None),
            Some(string) => Ok(Some(string.to_db_id()?)),
        }
    }

    fn to_db_opt_id_or_err(&self, field_name: &str) -> Result<Option<i64>, Status> {
        match self {
            None => Ok(None),
            Some(string) => Ok(Some(string.to_db_id_or_err(field_name)?)),
        }
    }
}
impl ToDbOptId for Option<&String> {
    fn to_db_opt_id(&self) -> Result<Option<i64>, IDDecodingError> {
        match self {
            None => Ok(None),
            Some(string) => Ok(Some(string.to_db_id()?)),
        }
    }

    fn to_db_opt_id_or_err(&self, field_name: &str) -> Result<Option<i64>, Status> {
        match self {
            None => Ok(None),
            Some(string) => Ok(Some(string.to_db_id_or_err(field_name)?)),
        }
    }
}

// TODO: Eventually this should come from the ServerConfiguration.
const OFFSET: i32 = 7;

#[cfg(test)]
mod tests {
    use crate::marshaling::ToDbId;
    use crate::marshaling::ToProtoId;

    #[test]
    fn id_conversions_work() {
        assert_eq!(
            10000000000000,
            (10000000000000 as i64).to_proto_id().to_db_id().unwrap()
        );
        assert_eq!(10, 10.to_proto_id().to_db_id().unwrap());
        assert_ne!(10, (967272945725 as i64).to_proto_id().to_db_id().unwrap());
        assert_eq!(
            967272945725,
            (967272945725 as i64).to_proto_id().to_db_id().unwrap()
        );
    }
}
