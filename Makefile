.DEFAULT_GOAL := all

LOCAL_REGISTRY := kubernetes.docker.internal:5000
LOCAL_REGISTRY_DIRECTORY := $(HOME)/Development/registry
CLOUD_REGISTRY := docker.io/jonlatane
VERSION := $$(cat Cargo.toml | grep 'version =' | sed -n 1p | awk '{print $$3;}' | sed 's/"//g')

local:
	cargo build

create_local_registry:
	docker run -d -p 5000:5000 --restart=always --name local-registry -v $(LOCAL_REGISTRY_DIRECTORY):/var/lib/registry registry:2

stop_local_registry:
	docker stop local-registry
	docker rm local-registry

destroy_local_registry: stop_local_registry
	rm -rf $(LOCAL_REGISTRY_DIRECTORY)/docker

release: build_release push_release_local

create_deployment:
	kubectl create -f kubernetes.yaml --save-config

update_deployment:
	kubectl apply -f kubernetes.yaml

delete_deployment:
	kubectl delete -f kubernetes.yaml

restart_deployment:
	kubectl rollout restart deployment jonline-tonic

get_deployment_pods:
	kubectl get pods --selector=app=jonline-tonic

push_builder_local:
	docker build . -t $(LOCAL_REGISTRY)/jonline-build -f dockers/build/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-build

push_builder_cloud:
	docker build . -t $(CLOUD_REGISTRY)/jonline-build -f dockers/build/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline-build

build_release:
	docker run --rm -v $$(pwd):/opt -w /opt/src $(LOCAL_REGISTRY)/jonline-build:latest /bin/bash -c "cargo build --release"

push_release_local: target/release/jonline_tonic
	docker build . -t $(LOCAL_REGISTRY)/jonline-tonic -f dockers/server/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-tonic

push_release_cloud: target/release/jonline_tonic
	$(info "WARNING: Ensure you generated your release with 'make release' rather than 'cargo build --release'.")
	docker build . -t $(CLOUD_REGISTRY)/jonline-tonic:$(VERSION) -f dockers/server/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline-tonic:$(VERSION)

target/release/jonline_tonic:
	$(error "Please run 'make release' first.")

lines_of_code:
	git ls-files | xargs cloc

setup_diesel_cli_macos_homebrew: export LDFLAGS := $(value LDFLAGS) -L/usr/local/opt/mysql-client/lib
setup_diesel_cli_macos_homebrew: export CPPFLAGS := $(value CPPFLAGS) -I/usr/local/opt/mysql-client/include
setup_diesel_cli_macos_homebrew:
	brew install sqlite3 mysql-connector-c
	cargo install diesel_cli
