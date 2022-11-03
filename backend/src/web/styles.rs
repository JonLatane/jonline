use rocket::*;

use super::RocketState;
use crate::rpcs::*;
use rocket_dyn_templates::{context, Template};

#[rocket::get("/styles.css")]
pub async fn styles(state: &State<RocketState>) -> Template {
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration(&mut conn).unwrap();
    let server_info = configuration.server_info.unwrap();
    let colors = server_info.colors.unwrap();
    let primary_color = colors.primary.unwrap();
    let primary_rgb = format!("{:x}", primary_color)
        .chars()
        .skip(2)
        .take(6)
        .collect::<String>();
    let nav_color = colors.navigation.unwrap();
    let nav_rgb = format!("{:x}", nav_color)
        .chars()
        .skip(2)
        .take(6)
        .collect::<String>();

    Template::render(
        "styles",
        context! {
            primary_color: format!("#{}", primary_rgb),
            nav_color: format!("#{}", nav_rgb),
        },
    )
}
