use rocket::*;

use super::RocketState;
use crate::group_context;
use crate::home_page;
use crate::protos::*;
use crate::rpcs::*;
use rocket_dyn_templates::{context, Template};

#[rocket::get("/post/<id>/<_title>")]
pub async fn post_details(id: &str, _title: &str, state: &State<RocketState>) -> Template {
    let mut conn = state.pool.get().unwrap();
    let post = get_posts(
        GetPostsRequest {
            post_id: Some(id.to_string()),
            ..Default::default()
        },
        None,
        &mut conn,
    )
    .unwrap().posts.into_iter().next().unwrap();
    let groups = get_groups(
        GetGroupsRequest {
            ..Default::default()
        },
        None,
        &mut conn,
    )
    .unwrap();
    Template::render(
        "post",
        context! {
            home: home_page!(&mut conn),
            title: post.title,
            content: markdown::to_html(post.content.unwrap_or("".to_string()).as_str()),
            link: post.link,
            groups: groups.groups.into_iter().map(|g| group_context!(g)).collect::<Vec<_>>(),
        },
    )
}
