.NOTPARALLEL:
# .DEFAULT_GOAL := default
# default: protos docs graphs
.PHONY: server stop_background_servers build review review_fix setup_proto_build protos

run: server

server:
	npx elm-spa server

stop_background_servers:
	lsof -ti:1234 | xargs -r kill; sleep 1; lsof -ti:1234 || echo "port 1234 free"

build:
	npx elm-spa build

review:
	npx elm-review

review_fix:
	npx elm-review --fix-all

setup_proto_build:
	yarn global add protoc-gen-elm

protos:
	protoc --elm_out=./src -I../../protos ../../protos/*.proto