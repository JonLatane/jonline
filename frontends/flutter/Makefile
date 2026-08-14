.NOTPARALLEL:


build_web:
	fvm flutter build web --web-renderer canvaskit --release --base-href /flutter/


# Local Flutter FE dev targets
protos: protos_prepare protos_generate
# Pinned to match this project's `protobuf`/`grpc` package majors (see pubspec.yaml)
# and the Dart SDK bundled with the locked Flutter version (see .fvmrc). Newer
# protoc_plugin releases generate code for protobuf ^6.0.0, which needs Dart
# >=3.7 - too new for this frozen frontend.
protos_prepare:
	fvm dart pub global activate protoc_plugin 22.0.0
protos_generate:
	mkdir -p lib/generated
	protoc --dart_out=grpc:lib/generated -I../../protos ../../protos/*.proto google/protobuf/timestamp.proto google/protobuf/field_mask.proto google/protobuf/empty.proto

routegen_watch:
	fvm flutter packages pub run build_runner watch
routegen_regenerate: routegen_delete routegen_generate
routegen_delete:
	- rm lib/router/router.gr.dart
routegen_generate:
	fvm flutter packages pub run build_runner build
