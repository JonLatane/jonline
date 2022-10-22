use super::flutter_index;
use super::home;
use rocket::fs::*;
use rocket::*;
use rocket_dyn_templates::Template;

use super::RocketState;

use rocket::response::Responder;

use crate::protos::*;
use crate::rpcs::get_server_configuration;

#[rocket::get("/")]
pub async fn index(state: &State<RocketState>) -> MainIndex {
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration(&mut conn).unwrap();

    match configuration.server_info.unwrap().web_user_interface() {
        WebUserInterface::FlutterWeb => MainIndex {
            file: Some(flutter_index().await),
            template: None
        },
        WebUserInterface::HandlebarsTemplates => MainIndex {
            template: Some(home(state).await),
            file: None
        },
    }
}

pub struct MainIndex {
    file: Option<std::io::Result<NamedFile>>,
    template: Option<Template>,
}

impl<'r> Responder<'r, 'static> for MainIndex {
    fn respond_to(self, req: &rocket::Request<'_>) -> rocket::response::Result<'static> {
        match self.file {
            Some(file) => file.respond_to(req),
            None => self.template.unwrap().respond_to(req),
        }
    }
}