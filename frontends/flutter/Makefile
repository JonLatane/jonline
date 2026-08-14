.NOTPARALLEL:


build_web:
	fvm flutter build web --web-renderer canvaskit --release --base-href /flutter/

test:
	fvm flutter test


# Local Flutter FE dev targets
protos: protos_prepare protos_generate
# Pinned to match this project's `protobuf`/`grpc` package majors (see pubspec.yaml)
# and the Dart SDK bundled with the locked Flutter version (see .fvmrc). Newer
# protoc_plugin releases (22.0.0+) generate code using the `$_setField`/`$_clearField`
# API, which only exists in protobuf >=4.1.0 - that needs Dart >=3.6, too new for
# this frozen frontend's pinned SDK. protoc_plugin must also be activated with
# `fvm dart` (not bare `dart`), or it builds against whatever Flutter happens to
# be ambient on PATH instead of the pinned SDK.
protos_prepare:
	fvm dart pub global activate protoc_plugin 21.1.2
protos_generate:
	mkdir -p lib/generated
	PATH="$(CURDIR)/.fvm/flutter_sdk/bin:$(HOME)/.pub-cache/bin:$$PATH" protoc --dart_out=grpc:lib/generated -I../../protos ../../protos/*.proto google/protobuf/timestamp.proto google/protobuf/field_mask.proto google/protobuf/empty.proto

routegen_watch:
	fvm flutter packages pub run build_runner watch
routegen_regenerate: routegen_delete routegen_generate
routegen_delete:
	- rm lib/router/router.gr.dart
routegen_generate:
	fvm flutter packages pub run build_runner build
