use rocket::*;
// use rocket::fs::*;

use rocket_dyn_templates::{context, Template};
// use rocket::{get, serde::json::Json, State};
use super::RocketState;
use crate::protos::*;
use crate::rpcs::get_posts;

// #[get("/web")]
// pub async fn home() -> std::io::Result<NamedFile> {
//     match NamedFile::open("opt/web/index.html").await {
//         Ok(file) => Ok(file),
//         Err(_) => match NamedFile::open("../web/index.html").await {
//             Ok(file) => Ok(file),
//             Err(e) => Err(e),
//         },
//     }
// }

#[get("/web")]
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
    Template::render(
        "index",
        context! {
            top_posts: top_posts.posts.into_iter().map(|p| Post {content: Some(markdown::to_html(p.content())), ..p}).collect::<Vec<Post>>(),
        },
    )
}
