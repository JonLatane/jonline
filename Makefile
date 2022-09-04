.NOTPARALLEL:
.DEFAULT_GOAL := release_local_be

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline
TOP_LEVEL_CERT_DOMAIN ?= jonline.io
GENERATED_CERT_DOMAIN ?= *.$(TOP_LEVEL_CERT_DOMAIN)
TEST_GRPC_TARGET ?= $(shell $(MAKE) deploy_be_get_ip):27707
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

show_fe_version:
	echo $(FE_VERSION)

# Core release targets
release_local_be: build_backend_release push_release_local
release_cloud_be: build_backend_release push_release_cloud

# K8s server deployment targets
deploy_be_create: ensure_namespace
	kubectl create -f backend/k8s/jonline.yaml --save-config -n $(NAMESPACE)

deploy_be_update:
	kubectl apply -f backend/k8s/jonline.yaml -n $(NAMESPACE)

deploy_be_delete:
	kubectl delete -f backend/k8s/jonline.yaml -n $(NAMESPACE)

deploy_be_restart:
	kubectl rollout restart deployment jonline -n $(NAMESPACE)

deploy_be_get_ip:
# Suppress echoing this so 'make deploy_be_get_ip` is easily composable. 
	@kubectl get service jonline -n jonline | sed -n 2p | awk '{print $$4}'

deploy_be_get_namespace:
	kubectl get all -n $(NAMESPACE)

deploy_be_get_pods:
	kubectl get pods --selector=app=jonline -n $(NAMESPACE)

# K8s server deployment test targets
test_deploy_be_no_tls:
	grpc_cli ls $(TEST_GRPC_TARGET)

test_deploy_be_tls:
	grpc_cli ls $(TEST_GRPC_TARGET) --channel_creds_type=ssl

test_deploy_be_tls_openssl:
	openssl s_client -connect $(TEST_GRPC_TARGET) -CAfile generated_certs/ca.pem

# K8s DB deployment targets (optional if using managed DB)
deploy_db_create: ensure_namespace
	kubectl create -f backend/k8s/k8s-postgres.yaml --save-config -n $(NAMESPACE)

deploy_db_update:
	kubectl apply -f backend/k8s/k8s-postgres.yaml -n $(NAMESPACE)

deploy_db_delete:
	kubectl delete -f backend/k8s/k8s-postgres.yaml -n $(NAMESPACE)

deploy_db_restart:
	kubectl rollout restart deployment jonline-postgres -n $(NAMESPACE)

# Useful things
ensure_namespace:
	- kubectl create namespace $(NAMESPACE)

# Local registry targets for build
start_local_registry:
	docker start local-registry

stop_local_registry:
	docker stop local-registry
	docker rm local-registry

create_local_registry:
	$(MAKE) start_local_registry || docker run -d -p 5000:5000 --restart=always --name local-registry -v $(LOCAL_REGISTRY_DIRECTORY):/var/lib/registry registry:2

destroy_local_registry:
	$(MAKE) stop_local_registry; rm -rf $(LOCAL_REGISTRY_DIRECTORY)/docker

# jonline-be-build image targets
push_builder_local: create_local_registry
	docker build . -t $(LOCAL_REGISTRY)/jonline-be-build -f backend/docker/build/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline-be-build

push_builder_cloud:
	docker build . -t $(CLOUD_REGISTRY)/jonline-be-build -f backend/docker/build/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline-be-build

# Server image build targets
build_backend_release: backend/target/release/jonline__server_release

backend/target/release/jonline__server_release: push_builder_local
	docker run --rm -v $$(pwd):/opt -w /opt/backend/src $(LOCAL_REGISTRY)/jonline-be-build:latest /bin/bash -c "cargo build --release"
	mv backend/target/release/jonline backend/target/release/jonline__server_release
	mv backend/target/release/expired_token_cleanup backend/target/release/expired_token_cleanup__server_release

push_release_local: create_local_registry build_backend_release
	docker build . -t $(LOCAL_REGISTRY)/jonline -f backend/docker/server/Dockerfile
	docker push $(LOCAL_REGISTRY)/jonline

push_release_cloud: build_backend_release
	docker build . -t $(CLOUD_REGISTRY)/jonline:$(BE_VERSION) -f backend/docker/server/Dockerfile
	docker push $(CLOUD_REGISTRY)/jonline:$(BE_VERSION)

# Full-Stack dev targets
clean:
	cd backend && $(MAKE) clean

clean_protos:
	cd backend && $(MAKE) clean_protos

build_local:
	cd backend && $(MAKE) build

# Cert-Manager targets
create_certmanager_deployment_digitalocean: ensure_namespace
	kubectl create -f backend/k8s/cert-manager.digitalocean.generated.yaml --save-config -n $(NAMESPACE)

generate_cert_manager_digitalocean: backend/k8s/cert-manager.digitalocean.generated.yaml
backend/k8s/cert-manager.digitalocean.generated.yaml:
	cat backend/k8s/cert-manager.digitalocean.template.yaml | \
	  sed 's/$${CERT_MANAGER_EMAIL}/$(CERT_MANAGER_EMAIL)/g' | \
	  sed 's/$${TOP_LEVEL_CERT_DOMAIN}/$(TOP_LEVEL_CERT_DOMAIN)/g' | \
	  sed 's/$${GENERATED_CERT_DOMAIN}/$(GENERATED_CERT_DOMAIN)/g' \
	  > backend/k8s/cert-manager.digitalocean.generated.yaml

# Custom CA certificate generation targets
generate_certs: generate_ca_certs generate_server_certs

test_certs: test_certs_pass_openssl_verify

test_certs_pass_openssl_verify:
	openssl verify -CAfile generated_certs/ca.pem generated_certs/server.pem

generate_ca_certs:
	mkdir -p generated_certs
	openssl req -x509 \
	          -sha256 -days 365 \
	          -nodes \
	          -newkey rsa:2048 \
	          -subj '/CN=$(GENERATED_CERT_DOMAIN)/C=US/L=Durham' \
	          -keyout generated_certs/ca.key -out generated_certs/ca.pem 

generate_server_certs:
	mkdir -p generated_certs
	openssl genpkey -out server.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
	openssl req -new -key generated_certs/server.key -config generated_certs/server.csr.conf -out generated_certs/server.csr
	openssl x509 -req \
	  -in generated_certs/server.csr \
	  -CA generated_certs/ca.pem -CAkey generated_certs/ca.key \
	  -CAcreateserial -out generated_certs/server.pem \
	  -days 365 \
	  -sha256 -extfile generated_certs/server.extfile.conf

store_certs_in_kubernetes: store_server_certs_in_kubernetes store_ca_certs_in_kubernetes
delete_certs_from_kubernetes:
	- $(MAKE) delete_server_certs_from_kubernetes
	- $(MAKE) delete_ca_certs_from_kubernetes

store_server_certs_in_kubernetes:
	cd generated_certs && kubectl create secret tls jonline-generated-tls --cert=server.pem --key=server.key -n $(NAMESPACE)
delete_server_certs_from_kubernetes:
	kubectl delete secret jonline-generated-tls -n $(NAMESPACE)
store_ca_certs_in_kubernetes:
	cd generated_certs && kubectl create configmap jonline-generated-ca --from-file ca.crt=ca.pem -n $(NAMESPACE)
delete_ca_certs_from_kubernetes:
	kubectl delete configmap jonline-generated-ca -n $(NAMESPACE)

lines_of_code:
	git ls-files | xargs cloc
