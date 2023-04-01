pub trait ToLink {
    fn to_link(&self) -> Option<String>;
}
impl ToLink for Option<String> {
    fn to_link(&self) -> Option<String> {
        match self {
            None => None,
            Some(l) => {
                if l.len() == 0 {
                    None
                } else if !l.starts_with("http") {
                    Some(format!("http://{}", &l))
                } else {
                    Some(l.to_owned())
                }
            }
        }
    }
}
