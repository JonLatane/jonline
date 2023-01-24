# jonline

The Flutter client for Jonline. Built mostly with `provider` and `auto_router`.

## Building
tl;dr: `make routes_gen_regenerate protos_generate && flutter run`.

* To rebuild auto_router routes, use `make routes_gen_regenerate`. This will regenerate `lib/router/router.gr.dart` from `lib/router/router.dart`.
* To rebuild proto files (in BE/Rust/Tonic land Cargo does this for us), use `make protos_generate`. You need `protoc` setup for Dart. This will (re)generate `lib/generated/*.pb*.yaml` definitions of gRPC types.