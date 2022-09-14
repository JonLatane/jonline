.NOTPARALLEL:
.DEFAULT_GOAL := release_be_local

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline
TOP_LEVEL_CERT_DOMAIN ?= jonline.io
GENERATED_CERT_DOMAIN ?= *.$(TOP_LEVEL_CERT_DOMAIN)
TEST_GRPC_TARGET ?= $(shell $(MAKE) deploy_be_get_external_ip):27707
CERT_MANAGER_EMAIL ?= invalid_email

# Set these variables when setting up cert generation

# Configure these when building your own Jonline images. Note that you must update backend/k8s/jonline.yaml to
# point to your cloud registry rather than docker.io/jonlatane.
CLOUD_REGISTRY := docker.io/jonlatane
LOCAL_REGISTRY_DIRECTORY := $(HOME)/Development/registry

# You likely don't need to update this, but it's used when creating the local builder image.
LOCAL_REGISTRY := kubernetes.docker.internal:5000

# Versions are derived from TOML/YAML files, and should not be changed here.
BE_VERSION := $$(cat backend/Cargo.toml | grep 'version =' | sed -n 1p | awk '{print $$3;}' | sed 's/"//g')
FE_VERSION := $$(cat frontend/pubspec.yaml | grep 'version:' | sed -n 1p | awk '{print $$2;}' | sed 's/"//g')

show_be_version:
	@echo $(BE_VERSION)
show_fe_version:
	@echo $(FE_VERSION)

# Core release targets
release_be_local: build_be_release_binary push_be_release_local
release_be_cloud: build_be_release_binary push_be_release_cloud

# K8s server deployment targets
deploy_be_create: deploy_ensure_namespace
	kubectl create -f backend/k8s/jonline.yaml --save-config -n $(NAMESPACE)

deploy_be_update:
	kubectl apply -f backend/k8s/jonline.yaml -n $(NAMESPACE)

deploy_be_delete:
	kubectl delete -f backend/k8s/jonline.yaml -n $(NAMESPACE)

deploy_be_restart:
	kubectl rollout restart deployment jonline -n $(NAMESPACE)

deploy_be_get_external_ip:
# Suppress echoing this so 'make deploy_be_get_external_ip` is easily composable. 
	@kubectl get service jonline -n jonline | sed -n 2p | awk '{print $$4}'

deploy_be_get_all:
	kubectl get all -n $(NAMESPACE)

deploy_be_get_pods:
	kubectl get pods --selector=app=jonline -n $(NAMESPACE)

# K8s server deployment test targets
test_deploy_be:
	@echo 'Getting services on target server...'
	grpcurl $(TEST_GRPC_TARGET) list
	@echo "\nGetting Jonline service version..."
	grpcurl $(TEST_GRPC_TARGET) jonline.Jonline/GetServiceVersion
	@echo "\nGetting available Jonline RPCs..."
	grpcurl $(TEST_GRPC_TARGET) list jonline.Jonline

test_deploy_be_unsecured:
	@echo 'Getting services on target server...'
	grpcurl -plaintext $(TEST_GRPC_TARGET) list
	@echo "\nGetting Jonline service version..."
	grpcurl -plaintext $(TEST_GRPC_TARGET) jonline.Jonline/GetServiceVersion
	@echo "\nGetting available Jonline RPCs..."
	grpcurl -plaintext $(TEST_GRPC_TARGET) list jonline.Jonline

test_deploy_be_tls_openssl:
	openssl s_client -connect $(TEST_GRPC_TARGET) -CAfile generated_certs/ca.pem

# K8s DB deployment targets (optional if using managed DB)
deploy_db_create: deploy_ensure_namespace
	kubectl create -f backend/k8s/k8s-postgres.yaml --save-config -n $(NAMESPACE)

deploy_db_update:
	kubectl apply -f backend/k8s/k8s-postgres.yaml -n $(NAMESPACE)

deploy_db_delete:
	kubectl delete -f backend/k8s/k8s-postgres.yaml -n $(NAMESPACE)

deploy_db_restart:
	kubectl rollout restart deployment jonline-postgres -n $(NAMESPACE)

# Useful things
deploy_ensure_namespace:
	- kubectl create namespace $(NAMESPACE)

# Certificate-related targets
deploy_be_get_certs:
	kubectl get secret jonline-generated-tls -n $(NAMESPACE)
deploy_be_get_ca_certs:
	kubectl get configmap jonline-generated-ca -n $(NAMESPACE)

# Cert-Manager targets
deploy_certmanager_digitalocean_prepare: backend/k8s/cert-manager.digitalocean.generated.yaml
backend/k8s/cert-manager.digitalocean.generated.yaml:
	cat backend/k8s/cert-manager.digitalocean.template.yaml | \
	  sed 's/$${CERT_MANAGER_EMAIL}/$(CERT_MANAGER_EMAIL)/g' | \
	  sed 's/$${TOP_LEVEL_CERT_DOMAIN}/$(TOP_LEVEL_CERT_DOMAIN)/g' | \
	  sed 's/$${GENERATED_CERT_DOMAIN}/$(GENERATED_CERT_DOMAIN)/g' \
	  > backend/k8s/cert-manager.digitalocean.generated.yaml

deploy_certmanager_digitalocean_create: deploy_ensure_namespace
	kubectl create -f backend/k8s/cert-manager.digitalocean.generated.yaml --save-config -n $(NAMESPACE)

# Custom CA certificate generation targets
certs_generate: certs_ca_generate certs_server_generate

certs_ca_generate:
	mkdir -p generated_certs
	openssl req -x509 \
	          -sha256 -days 365 \
	          -nodes \
	          -newkey rsa:2048 \
	          -subj '/CN=$(GENERATED_CERT_DOMAIN)/C=US/L=Durham' \
	          -keyout generated_certs/ca.key -out generated_certs/ca.pem 

certs_server_generate:
	mkdir -p generated_certs
	openssl genpkey -out server.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
	openssl req -new -key generated_certs/server.key -config generated_certs/server.csr.conf -out generated_certs/server.csr
	openssl x509 -req \
	  -in generated_certs/server.csr \
	  -CA generated_certs/ca.pem -CAkey generated_certs/ca.key \
	  -CAcreateserial -out generated_certs/server.pem \
	  -days 365 \
	  -sha256 -extfile generated_certs/server.extfile.conf

certs_store_in_k8s: certs_server_store_in_k8s certs_ca_store_in_k8s
certs_delete_from_k8s:
	- $(MAKE) certs_server_delete_from_k8s
	- $(MAKE) certs_ca_delete_from_k8s

certs_server_store_in_k8s:
	cd generated_certs && kubectl create secret tls jonline-generated-tls --cert=server.pem --key=server.key -n $(NAMESPACE)
certs_server_delete_from_k8s:
	kubectl delete secret jonline-generated-tls -n $(NAMESPACE)
certs_ca_store_in_k8s:
	cd generated_certs && kubectl create configmap jonline-generated-ca --from-file ca.crt=ca.pem -n $(NAMESPACE)
certs_ca_delete_from_k8s:
	kubectl delete configmap jonline-generated-ca -n $(NAMESPACE)

# Custom CA cert testing targets
certs_gen_test: certs_gen_test_pass_openssl_verify
certs_gen_test_pass_openssl_verify:
	openssl verify -CAfile generated_certs/ca.pem generated_certs/server.pem

# DEVELOPMENT-RELATED TARGETS
# Local registry targets for build
local_registry_start:
	docker start local-registry

local_registry_stop:
	docker stop local-registry
	docker rm local-registry

local_registry_create:
	$(MAKE) local_registry_start || docker run -d -p 5000:5000 --restart=always --name local-registry -v $(LOCAL_REGISTRY_DIRECTORY):/var/lib/registry registry:2

local_registry_destroy:
	$(MAKE) local_registry_stop; rm -rf $(LOCAL_REGISTRY_DIRECTORY)/docker

# jonline-be-build image targets
push_builder_local: local_registry_create
	docker build . -t $(LOCAL_REGISTRY)/jonline-be-build -f backend/docker/build/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-be-build

push_builder_cloud:
	docker build . -t $(CLOUD_REGISTRY)/jonline-be-build -f backend/docker/build/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline-be-build

# Server image build targets
build_be_release_binary: backend/target/release/jonline__server_release

backend/target/release/jonline__server_release: push_builder_local
	docker run --rm -v $$(pwd):/opt -w /opt/backend/src $(LOCAL_REGISTRY)/jonline-be-build:latest /bin/bash -c "cargo build --release"
	mv backend/target/release/jonline backend/target/release/jonline__server_release
	mv backend/target/release/expired_token_cleanup backend/target/release/expired_token_cleanup__server_release

push_be_release_local: local_registry_create build_be_release_binary build_web_release
	docker build . -t $(LOCAL_REGISTRY)/jonline -f backend/docker/server/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline

push_be_release_cloud: #build_be_release_binary build_web_release
	docker build . -t $(CLOUD_REGISTRY)/jonline:$(BE_VERSION) -f backend/docker/server/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline:$(BE_VERSION)

build_web_release:
	cd frontend && ./build-release web

push_web_release_local: build_web_release
	docker build . -t $(LOCAL_REGISTRY)/jonline-web -f frontend/docker/web/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-web

push_ios_release:
	cd frontend && ./build-release ios

# Full-Stack dev targets
clean:
	cd backend && $(MAKE) clean

clean_protos:
	cd backend && $(MAKE) clean_protos

build_local:
	cd backend && $(MAKE) build

lines_of_code:
	git ls-files | xargs cloc
