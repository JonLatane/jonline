pub trait ToProtoId {
    fn to_proto_id(&self) -> String;
}
impl ToProtoId for i32 {
    fn to_proto_id(&self) -> String {
        let id_bytes = (self + 10000).to_ne_bytes();
        bs58::encode(id_bytes).into_string()
    }
}

pub trait ToDbId {
    fn to_db_id(&self) -> Result<i32, bs58::decode::Error>;
}
impl ToDbId for String {
    fn to_db_id(&self) -> Result<i32, bs58::decode::Error> {
        let id_bytes = bs58::decode(self).into_vec()?;
        let id = i32::from_ne_bytes(id_bytes.as_slice().try_into().unwrap_or([0; 4]));
        if id == 0 {
            return Err(bs58::decode::Error::InvalidCharacter {
                character: '0',
                index: 0,
            });
        }
        Ok(id - 10000)
    }
}
