use std::{env, fs, path::PathBuf};

fn main() {
    let proto_file = "../protos/jonline.proto";
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let _ = fs::create_dir("./target");
    let _ = fs::create_dir("./target/compiled_protos");
    tonic_prost_build::configure()
        .build_server(true)
        .type_attribute(".", "#[derive(serde::Serialize, serde::Deserialize)]")
        // Used for updating servers from 0.5.551 -> 0.5.553+. Can be removed
        // in the distant future.
        // Lets `event_settings` JSON stored before this field existed deserialize
        // instead of erroring, defaulting to CALENDAR_DISPLAY_WEEK (proto enum value 0).
        .field_attribute(
            "EventSettings.default_calendar_display_mode",
            "#[serde(default)]",
        )
        // Same as above, for `show_started_or_long_events_by_default` -- lets `event_settings`
        // JSON stored before this field existed deserialize instead of erroring, defaulting to
        // `false`.
        .field_attribute(
            "EventSettings.show_started_or_long_events_by_default",
            "#[serde(default)]",
        )
        // This is specifically for rust-analyzer in VSCode
        // .client_attribute(".", "#![allow(non_snake_case)]")
        .extern_path(".google.protobuf.Any", "::prost_wkt_types::Any")
        .extern_path(".google.protobuf.Timestamp", "::prost_wkt_types::Timestamp")
        .extern_path(".google.protobuf.Value", "::prost_wkt_types::Value")
        .file_descriptor_set_path(out_dir.join("greeter_descriptor.bin"))
        .out_dir("./src/protos")
        .compile_protos(&[proto_file], &["../protos"])
        .unwrap_or_else(|e| panic!("protobuf compile error: {}", e));

    // `jonline.proto` imports nearly every other file under `../protos` (sync.proto,
    // permissions.proto, ai_model_providers.proto, etc), but Cargo only reruns this script for
    // paths explicitly named here -- watching just `proto_file` meant editing an *imported* .proto
    // alone left the generated code stale until something else (e.g. `make rebuild_protos`) forced
    // a full recompile. Watch every .proto file in the directory instead.
    for entry in fs::read_dir("../protos").expect("failed to read ../protos") {
        let path = entry.expect("failed to read ../protos entry").path();
        if path.extension().and_then(|ext| ext.to_str()) == Some("proto") {
            println!("cargo:rerun-if-changed={}", path.display());
        }
    }
}
