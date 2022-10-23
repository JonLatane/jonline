use rocket::*;
use rocket::fs::*;
use rocket::http::*;
use std::path::*;

use rocket_dyn_templates::{context, Template};
use super::RocketState;
use crate::protos::*;
use crate::rpcs::*;
use super::flutter_web::flutter_file;
use crate::db_connection::PgPooledConnection;

#[rocket::get("/home")]
pub async fn home(state: &State<RocketState>) -> Template {
    let mut conn = state.pool.get().unwrap();
    let top_posts = get_posts(
        GetPostsRequest {
            ..Default::default()
        },
        None,
        &mut conn,
    )
    .unwrap();
    let groups = get_groups(
        GetGroupsRequest {
            ..Default::default()
        },
        None,
        &mut conn,
    )
    .unwrap();
    Template::render(
        "home",
        context! {
            home: home_page(&mut conn),
            groups: groups.groups,
            top_posts: top_posts.posts.into_iter().map(|p| Post {content: Some(markdown::to_html(p.content())), ..p}).collect::<Vec<Post>>(),
        },
    )
}

#[rocket::get("/styles.css")]
pub async fn styles(state: &State<RocketState>) -> Template {
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration(&mut conn).unwrap();
    let server_info = configuration.server_info.unwrap();
    let colors = server_info.colors.unwrap();
    let primary_color = colors.primary.unwrap();
    let primary_rgb = format!("{:x}", primary_color).chars().skip(2).take(6).collect::<String>();
    let nav_color = colors.navigation.unwrap();
    let nav_rgb = format!("{:x}", nav_color).chars().skip(2).take(6).collect::<String>();

    Template::render(
        "styles",
        context! {
            primary_color: format!("#{}", primary_rgb),
            nav_color: format!("#{}", nav_rgb),
        }
    )
}

#[rocket::get("/assets/<file..>")]
pub async fn web_asset(file: PathBuf) -> Result<NamedFile, Status> {
    match NamedFile::open(Path::new("templates/assets/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../web/assets/").join(file.to_owned())).await {
            Ok(file) => Ok(file),
            Err(_) => flutter_file(Path::new("assets/").join(file).to_path_buf()).await,
        },
    }
}
#[rocket::get("/images/<file..>")]
pub async fn web_image(file: PathBuf) -> Result<NamedFile, Status> {
    match NamedFile::open(Path::new("templates/images/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../web/images/").join(file.to_owned())).await {
            Ok(file) => Ok(file),
            Err(_) => flutter_file(Path::new("images/").join(file).to_path_buf()).await,
        },
    }
}

fn home_page(conn: &mut PgPooledConnection) -> &str {
    match get_server_configuration(conn).unwrap().server_info.unwrap().web_user_interface() 
    {
        WebUserInterface::FlutterWeb => "/home",
        WebUserInterface::HandlebarsTemplates => "/",
    }

}
