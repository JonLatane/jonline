extern crate jonline;

use jonline::*;
use std::env::args;

pub fn main() {
    init_crypto();
    init_bin_logging();
    let args: Vec<String> = args().collect();
    log::info!("{}", args[1].to_db_id().expect("Invalid Proto ID Format"));
}
