.DEFAULT_GOAL := all

LOCAL_REGISTRY := kubernetes.docker.internal:5000
LOCAL_REGISTRY_DIRECTORY := $(HOME)/Development/registry
CLOUD_REGISTRY := registry.digitalocean.com/jonline
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

# start:
# 	docker-compose up -d

# stop:
# 	docker-compose down

release: build_release server_docker_local

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

build_jonline_build:
	docker build . -t $(LOCAL_REGISTRY)/jonline-build  -f dockers/build/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-build

build_release:
	docker run --rm -v $$(pwd):/opt -w /opt/src $(LOCAL_REGISTRY)/jonline-build:latest /bin/bash -c "cargo build --release"

server_docker_local:
	docker build . -t $(LOCAL_REGISTRY)/jonline-tonic -f dockers/server/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-tonic

server_docker_cloud: release
	docker build . -t $(CLOUD_REGISTRY)/jonline-tonic:$(VERSION) -f dockers/server/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline-tonic:$(VERSION)
