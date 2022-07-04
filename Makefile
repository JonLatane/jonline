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

release: build_backend_release push_release_local

create_deployment:
	kubectl create -f backend/k8s/jonline.yaml --save-config

update_deployment:
	kubectl apply -f backend/k8s/jonline.yaml

delete_deployment:
	kubectl delete -f backend/k8s/jonline.yaml

restart_deployment:
	kubectl rollout restart deployment jonline


create_db_deployment:
	kubectl create -f backend/k8s/k8s-postgres.yaml --save-config

update_db_deployment:
	kubectl apply -f backend/k8s/k8s-postgres.yaml

delete_db_deployment:
	kubectl delete -f backend/k8s/k8s-postgres.yaml

restart_db_deployment:
	kubectl rollout restart deployment jonline-postgres

get_deployment_pods:
	kubectl get pods --selector=app=jonline

push_builder_local:
	docker build . -t $(LOCAL_REGISTRY)/jonline-build -f backend/docker/build/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-build

push_builder_cloud:
	docker build . -t $(CLOUD_REGISTRY)/jonline-build -f backend/docker/build/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline-build

build_backend_release:
	docker run --rm -v $$(pwd):/opt -w /opt/backend/src $(LOCAL_REGISTRY)/jonline-build:latest /bin/bash -c "cargo build --release"

push_release_local: backend/target/release/jonline
	docker build . -t $(LOCAL_REGISTRY)/jonline -f backend/docker/server/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline

push_release_cloud: backend/target/release/jonline
	$(info "WARNING: Ensure you generated your release with 'make release' rather than 'cargo build --release'.")
	docker build . -t $(CLOUD_REGISTRY)/jonline:$(VERSION) -f backend/docker/server/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline:$(VERSION)

backend/target/release/jonline:
	$(error "Please run 'make release' first.")

lines_of_code:
	git ls-files | xargs cloc
