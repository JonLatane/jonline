//! Specs for `logic::geocoding`, run against `factories::serve_nominatim_api` instead of the real
//! Nominatim API.

use crate::logic::resolve_timezone_at;
use crate::tests::factories::*;

#[test]
fn resolves_a_geocoded_address_to_its_timezone() {
    // Durham, NC, USA -- real coordinates from a live Nominatim lookup during development.
    let base_url = serve_nominatim_api(Some(("35.9826580", "-78.7591955")));

    let timezone = resolve_timezone_at(&base_url, "ZincHouse Winery & Brewery, Durham, NC, USA");
    assert_eq!(timezone, Some(chrono_tz::America::New_York));
}

#[test]
fn returns_none_when_geocoding_finds_no_results() {
    let base_url = serve_nominatim_api(None);

    let timezone = resolve_timezone_at(&base_url, "somewhere that doesn't exist");
    assert_eq!(timezone, None);
}

#[test]
fn returns_none_when_the_geocoding_request_fails() {
    let timezone = resolve_timezone_at("http://127.0.0.1:1", "unreachable");
    assert_eq!(timezone, None);
}
