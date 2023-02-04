use std::path::PathBuf;

use rocket::get;
use rocket::request::FromRequest;
use rocket::request::Outcome;
use rocket::Request;
use rocket::response::Redirect;


#[get("/<path..>")]
pub fn redirect_to_secure(host: HostHeader, path: PathBuf) -> Redirect {
  let domain = host.0.split(":").next().unwrap();
  let redirect_url = format!("https://{}/{}", domain, path.to_string_lossy());
  // format!("Hello from {}. Redirecting to {}", domain, redirect_url)
  Redirect::to(redirect_url)
}

pub struct HostHeader<'a>(pub &'a str);

#[rocket::async_trait]
impl<'r> FromRequest<'r> for HostHeader<'r> {
    type Error = ();

    async fn from_request(req: &'r Request<'_>) -> Outcome<Self, Self::Error> {
        match req.headers().get_one("Host") {
            Some(h) => Outcome::Success(HostHeader(h)),
            None => Outcome::Forward(()),
        }
    }
}
