use rocket::{
    fs::*,
    http::Status,
    request::{FromRequest, Outcome},
    routes, Request, Route, State,
};
use rocket_cache_response::CacheResponse;
use std::path::*;

use crate::protos::*;
use crate::rpcs::get_server_configuration_proto;
use crate::web::RocketState;

lazy_static! {
    pub static ref ELM_PAGES: Vec<Route> = routes![
        elm_index,
        elm_file,
        elm_root_style,
        elm_root_dist,
        elm_root_vendor,
        elm_root_markdown_js,
    ];
}

#[rocket::get("/elm/<file..>")]
async fn elm_file(file: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    log::info!("elm_file: {:?}", file);
    let result = match elm_asset(&file).await {
        Ok(file) => Ok(file),
        // Not a real static asset -- treat it as a client-side route (e.g.
        // `/elm/about`, or `/elm` itself with a trailing slash) and fall back to
        // index.html, same as `elm_index`, so deep links/refreshes reach the Elm
        // router instead of 404ing before the app ever loads.
        Err(_) => open_elm_index().await,
    };
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/elm")]
pub async fn elm_index() -> CacheResponse<Result<NamedFile, Status>> {
    CacheResponse::Public {
        responder: open_elm_index().await.map_err(|e| {
            log::info!("elm: {:?}", e);
            e
        }),
        max_age: 60,
        must_revalidate: false,
    }
}

/// A server can serve the Elm SPA at its *root* too (`main_index.rs`'s
/// `WebUserInterface::ElmSpa` branch) -- but `index.html` there references its
/// assets at plain `/style.css`, `/dist/elm.js`, `/vendor/*`, and
/// `/markdown.js` (see `index.html`'s base-path bootstrap script), which would
/// otherwise only ever reach `tamagui_file_or_username`'s `/<file..>`
/// catch-all (there is no other root route for them). These routes claim
/// those paths first -- literal/mostly-literal routes outrank a bare
/// `/<file..>` wildcard under Rocket's default ranking, same as e.g.
/// `tamagui_web.rs`'s `/g/<_>/posts` already relies on -- but only when
/// `ElmSpaAtRoot` actually succeeds; otherwise they forward, and Rocket falls
/// through to that same catch-all, so this can't intercept these paths for
/// any other frontend.
#[rocket::get("/style.css")]
async fn elm_root_style(_gate: ElmSpaAtRoot) -> CacheResponse<Result<NamedFile, Status>> {
    let result = elm_asset(Path::new("style.css")).await;
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/dist/<file..>")]
async fn elm_root_dist(
    _gate: ElmSpaAtRoot,
    file: PathBuf,
) -> CacheResponse<Result<NamedFile, Status>> {
    let result = elm_asset(&Path::new("dist").join(file)).await;
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/vendor/<file..>")]
async fn elm_root_vendor(
    _gate: ElmSpaAtRoot,
    file: PathBuf,
) -> CacheResponse<Result<NamedFile, Status>> {
    let result = elm_asset(&Path::new("vendor").join(file)).await;
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/markdown.js")]
async fn elm_root_markdown_js(_gate: ElmSpaAtRoot) -> CacheResponse<Result<NamedFile, Status>> {
    let result = elm_asset(Path::new("markdown.js")).await;
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

/// Request guard for `elm_root_style`/`elm_root_dist`: succeeds only when this
/// server's configured `web_user_interface` is `ElmSpa`, forwarding (rather
/// than erroring) otherwise so Rocket tries the next matching route instead
/// of hard-404ing a path some other frontend might actually own.
struct ElmSpaAtRoot;

#[rocket::async_trait]
impl<'r> FromRequest<'r> for ElmSpaAtRoot {
    type Error = ();

    async fn from_request(req: &'r Request<'_>) -> Outcome<Self, Self::Error> {
        let is_elm_spa = req
            .guard::<&State<RocketState>>()
            .await
            .succeeded()
            .and_then(|state| state.pool.get().ok())
            .and_then(|mut conn| get_server_configuration_proto(&mut conn).ok())
            .and_then(|config| config.server_info)
            .map(|info| info.web_user_interface() == WebUserInterface::ElmSpa)
            .unwrap_or(false);

        if is_elm_spa {
            Outcome::Success(ElmSpaAtRoot)
        } else {
            Outcome::Forward(Status::NotFound)
        }
    }
}

async fn elm_asset(relative: &Path) -> Result<NamedFile, Status> {
    match NamedFile::open(Path::new("opt/elm_web/").join(relative)).await {
        Ok(file) => Ok(file),
        Err(_) => {
            match NamedFile::open(Path::new("../frontends/elm-spa/public/").join(relative)).await
            {
                Ok(file) => Ok(file),
                Err(_) => Err(Status::NotFound),
            }
        }
    }
}

async fn open_elm_index() -> Result<NamedFile, Status> {
    match NamedFile::open("opt/elm_web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../frontends/elm-spa/public/index.html").await {
            Ok(file) => Ok(file),
            Err(_) => Err(Status::NotFound),
        },
    }
}
