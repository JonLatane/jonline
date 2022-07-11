.DEFAULT_GOAL := release

LOCAL_REGISTRY := kubernetes.docker.internal:5000
LOCAL_REGISTRY_DIRECTORY := $(HOME)/Development/registry
CLOUD_REGISTRY := docker.io/jonlatane
VERSION := $$(cat Cargo.toml | grep 'version =' | sed -n 1p | awk '{print $$3;}' | sed 's/"//g')

# Local BE dev targets
build_local_be:
	cd backend && cargo build

rebuild_local_protos:
	cd backend && cargo clean -p prost-build
	cd backend && cargo build

release: build_backend_release push_release_local

# K8s server deployment targets
create_be_deployment:
	kubectl create -f backend/k8s/jonline.yaml --save-config

update_be_deployment:
	kubectl apply -f backend/k8s/jonline.yaml

delete_be_deployment:
	kubectl delete -f backend/k8s/jonline.yaml

restart_be_deployment:
	kubectl rollout restart deployment jonline

get_be_deployment_pods:
	kubectl get pods --selector=app=jonline

# K8s DB deployment targets (optional if using managed DB)
create_db_deployment:
	kubectl create -f backend/k8s/k8s-postgres.yaml --save-config

update_db_deployment:
	kubectl apply -f backend/k8s/k8s-postgres.yaml

delete_db_deployment:
	kubectl delete -f backend/k8s/k8s-postgres.yaml

restart_db_deployment:
	kubectl rollout restart deployment jonline-postgres

# Local registry targets for build
create_local_registry:
	docker start local-registry || docker run -d -p 5000:5000 --restart=always --name local-registry -v $(LOCAL_REGISTRY_DIRECTORY):/var/lib/registry registry:2

stop_local_registry:
	docker stop local-registry
	docker rm local-registry

destroy_local_registry: stop_local_registry
	rm -rf $(LOCAL_REGISTRY_DIRECTORY)/docker

# jonline-build image targets
push_builder_local: create_local_registry
	docker build . -t $(LOCAL_REGISTRY)/jonline-build -f backend/docker/build/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-build

push_builder_cloud:
	docker build . -t $(CLOUD_REGISTRY)/jonline-build -f backend/docker/build/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline-build

# Server image build targets
build_backend_release: backend/target/release/jonline-server-release

backend/target/release/jonline-server-release: push_builder_local
	docker run --rm -v $$(pwd):/opt -w /opt/backend/src $(LOCAL_REGISTRY)/jonline-build:latest /bin/bash -c "cargo build --release"
	mv backend/target/release/jonline backend/target/release/jonline-server-release

push_release_local: create_local_registry build_backend_release
	docker build . -t $(LOCAL_REGISTRY)/jonline -f backend/docker/server/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline

push_release_cloud: build_backend_release
	docker build . -t $(CLOUD_REGISTRY)/jonline:$(VERSION) -f backend/docker/server/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline:$(VERSION)

lines_of_code:
	git ls-files | xargs cloc
