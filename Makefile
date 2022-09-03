.NOTPARALLEL:
.DEFAULT_GOAL := release_local_be

# Configure these variables to deploy/test the official Jonline images on your own cluster.
GENERATED_CERT_DOMAIN := *.jonline.io
TEST_GRPC_TARGET := be.jonline.io:27707

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

# K8s server deployment test targets
test_be_deployment_no_tls:
	grpc_cli ls $(TEST_GRPC_TARGET)

test_be_deployment_tls:
	GRPC_DEFAULT_SSL_ROOTS_FILE_PATH=generated_certs/ca.pem grpc_cli ls $(TEST_GRPC_TARGET) --channel_creds_type=ssl

test_be_deployment_tls_openssl:
	openssl s_client -connect $(TEST_GRPC_TARGET) -CAfile generated_certs/ca.pem

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

# K8s Cert-manager targets
install_k8s_nginx_ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/do/deploy.yaml
install_k8s_cert_manager:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml
show_k8s_ingress_details:
	kubectl get svc --namespace=ingress-nginx

# Certificate Generation targets
generate_certs: generate_ca_certs generate_server_certs

validate_certs:
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
#	openssl genrsa -out generated_certs/server.key 2048
	openssl req -new -key generated_certs/server.key -config generated_certs/server.csr.conf -out generated_certs/server.csr
	openssl x509 -req \
	  -in generated_certs/server.csr \
	  -CA generated_certs/ca.pem -CAkey generated_certs/ca.key \
	  -CAcreateserial -out generated_certs/server.pem \
	  -days 365 \
	  -sha256 -extfile generated_certs/server.extfile.conf

store_certs_in_kubernetes: store_server_certs_in_kubernetes store_ca_certs_in_kubernetes
delete_certs_from_kubernetes: delete_server_certs_from_kubernetes delete_ca_certs_from_kubernetes

store_server_certs_in_kubernetes:
	cd generated_certs && kubectl create secret tls jonline-generated-tls --cert=server.pem --key=server.key
delete_server_certs_from_kubernetes:
	kubectl delete secret jonline-generated-tls
store_ca_certs_in_kubernetes:
	cd generated_certs && kubectl create configmap jonline-generated-ca --from-file ca.crt=ca.pem
delete_ca_certs_from_kubernetes:
	kubectl delete configmap jonline-generated-ca

lines_of_code:
	git ls-files | xargs cloc
