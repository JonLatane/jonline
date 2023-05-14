use std::path::PathBuf;

use rocket::get;
use rocket::response::Redirect;

use super::headers::HostHeader;


#[get("/<path..>")]
pub fn redirect_to_secure(host: HostHeader, path: PathBuf) -> Redirect {
  let domain = host.0.split(":").next().unwrap();
  let redirect_url = format!("https://{}/{}", domain, path.to_string_lossy());
  // format!("Hello from {}. Redirecting to {}", domain, redirect_url)
  Redirect::to(redirect_url)
}
