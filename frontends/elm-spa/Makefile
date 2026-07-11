.NOTPARALLEL:
# .DEFAULT_GOAL := default
# default: protos docs graphs

run: server

server:
	npx elm-spa server

build:
	npx elm-spa build

setup_proto_build:
	yarn global add protoc-gen-elm

protos:
	protoc --elm_out=./src -I../../protos ../../protos/*.proto