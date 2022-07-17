.DEFAULT_GOAL := release_local_be

LOCAL_REGISTRY_DIRECTORY := $(HOME)/Development/registry
LOCAL_REGISTRY := kubernetes.docker.internal:5000
CLOUD_REGISTRY := docker.io/jonlatane
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

# Certificate Generation targets
generate_certs: generate_ca_certs generate_server_certs

generate_ca_certs:
	mkdir -p generated_certs
#	cd generated_certs && openssl genrsa -out ca.key 2048
	cd generated_certs && openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ca.key
	cd generated_certs && openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.pem

generate_server_certs:
	mkdir -p generated_certs
	echo "authorityKeyIdentifier=keyid,issuer\n\
	basicConstraints=CA:FALSE\n\
	keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\n\
	subjectAltName = @alt_names\n\
	\n\
	[alt_names]\n\
	DNS.1 = localhost\n\
	IP.1 = 0.0.0.0" > generated_certs/server.ext

#	cd generated_certs && openssl genrsa -out server.key 2048
	cd generated_certs && openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out server.key
	cd generated_certs && openssl req -new -sha256 -key server.key -out server.csr
	cd generated_certs && openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 1825 -sha256 -extfile server.ext -out server.pem

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
