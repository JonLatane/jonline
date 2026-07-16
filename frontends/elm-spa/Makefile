.NOTPARALLEL:
# .DEFAULT_GOAL := default
# default: protos docs graphs

run: server

server:
	npx elm-spa server

stop_background_servers:
	lsof -ti:1234 | xargs -r kill; sleep 1; lsof -ti:1234 || echo "port 1234 free"

build:
	npx elm-spa build

setup_proto_build:
	yarn global add protoc-gen-elm

protos:
	protoc --elm_out=./src -I../../protos ../../protos/*.proto