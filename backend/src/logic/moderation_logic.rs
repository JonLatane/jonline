use crate::{models, protos::*, conversions::*};

pub trait Moderated {
  fn passes(&self) -> bool;
  fn pending(&self) -> bool;
}
impl Moderated for Moderation {
    fn passes(&self) -> bool {
        match self {
            Moderation::Unmoderated | Moderation::Approved => true,
            _ => false,
        }
    }

    fn pending(&self) -> bool {
      match self {
          Moderation::Pending => true,
          _ => false,
      }
    }
}

impl Moderated for models::Membership {
  fn passes(&self) -> bool {
      self.to_proto().passes()
  }

  fn pending(&self) -> bool {
    self.to_proto().pending()
  }
}
impl Moderated for Membership {
  fn passes(&self) -> bool {
      self.group_moderation().passes() && self.user_moderation().passes()
  }

  fn pending(&self) -> bool {
    self.group_moderation().pending() || self.user_moderation().pending()
  }
}

impl Moderated for Follow {
  fn passes(&self) -> bool {
      self.target_user_moderation().passes()
  }

  fn pending(&self) -> bool {
    self.target_user_moderation().pending()
  }
}
