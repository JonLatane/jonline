extern crate jonline;

use jonline::*;
use std::env::args;

pub fn main() {
    init_bin_logging();
    let args: Vec<String> = args().collect();
    let arg = args[1].parse::<i64>().expect("Invalid BIGINT format");
    log::info!("{}", arg.to_proto_id());
}
