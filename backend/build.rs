use std::{env, fs, path::PathBuf};

fn main() {
    let proto_file = "../protos/jonline.proto";
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let _ = fs::create_dir("./target");
    let _ = fs::create_dir("./target/compiled_protos");
    tonic_build::configure()
        .build_server(true)
        .type_attribute("ServerInfo", "#[derive(serde::Serialize, serde::Deserialize)]")
        .type_attribute("FeatureSettings", "#[derive(serde::Serialize, serde::Deserialize)]")
        .type_attribute("ContactMethod", "#[derive(serde::Serialize, serde::Deserialize)]")
        .file_descriptor_set_path(out_dir.join("greeter_descriptor.bin"))
        .out_dir("./target/compiled_protos")
        .compile(&[proto_file], &["../protos"])
        .unwrap_or_else(|e| panic!("protobuf compile error: {}", e));

    println!("cargo:rerun-if-changed={}", proto_file);
}
