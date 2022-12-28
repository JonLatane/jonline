.NOTPARALLEL:
# Local FE dev targets
protos_generate:
	mkdir -p lib/generated
	protoc --dart_out=grpc:lib/generated -I../protos ../protos/*.proto google/protobuf/timestamp.proto google/protobuf/field_mask.proto google/protobuf/empty.proto

routes_gen_watch:
	flutter packages pub run build_runner watch
routes_gen_regenerate: routes_gen_delete routes_gen_generate
routes_gen_delete:
	- rm lib/router/router.gr.dart
routes_gen_generate:
	flutter packages pub run build_runner build