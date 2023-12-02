# Jonline Flutter FE

| CI Status                                                                                                            | Information                                                                                                 |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| ![Flutter Web Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_web.yml/badge.svg)         | [Flutter Web Build Results](https://github.com/jonlatane/jonline/actions/workflows/flutter_web.yml)         |
| ![Flutter iOS Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_ios.yml/badge.svg)         | [Flutter iOS Build Results](https://github.com/jonlatane/jonline/actions/workflows/flutter_ios.yml)         |
| ![Flutter Android Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_android.yml/badge.svg) | [Flutter Android Build Results](https://github.com/jonlatane/jonline/actions/workflows/flutter_android.yml) |

- [Jonline Flutter FE](#jonline-flutter-fe)
  - [gRPC implementation](#grpc-implementation)
  - [Routing](#routing)
  - [Building](#building)

The Flutter client for Jonline. Built mostly with `provider` and `auto_router`.

## gRPC implementation
Jonline's Flutter FE uses `protoc` and [`protoc_plugin`](https://pub.dev/packages/protoc_plugin) to generate its services into `lib/generated`. See `Makefile` for the implementation.

## Routing
The Flutter FE uses `auto_route` which means modifying path definitions gets a bit weird. I've tried to make the whole system a little easier to negotiate with the
`routegen_watch`, `routegen_regenerate`, `routegen_delete`, and `routegen_generate` targets in `Makefile`.

## Building
tl;dr: `make routegen_regenerate protos_generate && flutter run`.

* To rebuild auto_router routes, use `make routegen_regenerate`. This will regenerate `lib/router/router.gr.dart` from `lib/router/router.dart`.
* To rebuild proto files (in BE/Rust/Tonic land Cargo does this for us), use `make protos_generate`. You need `protoc` setup for Dart. This will (re)generate `lib/generated/*.pb*.yaml` definitions of gRPC types.