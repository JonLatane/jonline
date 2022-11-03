use rocket::*;

use super::RocketState;
use crate::group_context;
use crate::post_context;
use crate::home_page;
use crate::protos::*;
use crate::rpcs::*;
use rocket_dyn_templates::{context, Template};

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
            home: home_page!(&mut conn),
            groups: groups.groups.into_iter().map(|g| group_context!(g)).collect::<Vec<_>>(),
            top_posts: top_posts.posts.into_iter().map(|p| post_context!(p)).collect::<Vec<_>>(),
        },
    )
}
