.NOTPARALLEL:
.DEFAULT_GOAL := release_be_local

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline

# Selects which provider-specific k8s/*-$(K8S_PROVIDER).yaml manifests to use for the
# DB/Minio/StorageClass targets below (e.g. "digitalocean"; "eks" or others as they're added).
K8S_PROVIDER ?= digitalocean

# Used when configuring the load balancer (deploy_lb_[un]link_service_account).
TARGET_NAMESPACE ?= jonline

TEST_GRPC_TARGET ?= $(shell $(MAKE) get_backend_external_ip):27707

# K8s server deployment targets
# Use "internal" when deploying with a separate load balancer, and 
# use deploy_be_link_lb_service_account to link the load balancer to the
# internal Jonline service.
create_external_backend: deploy_ensure_namespace
	kubectl create -f k8s/server_external.yaml --save-config -n $(NAMESPACE)
	kubectl create -f k8s/preview_generator.yaml --save-config -n $(NAMESPACE)
create_internal_backend: deploy_ensure_namespace
	kubectl create -f k8s/server_internal.yaml --save-config -n $(NAMESPACE)
	kubectl create -f k8s/preview_generator.yaml --save-config -n $(NAMESPACE)
deploy_be_internal_insecure_create: deploy_ensure_namespace
	kubectl create -f k8s/server_internal_insecure.yaml --save-config -n $(NAMESPACE)
	kubectl create -f k8s/preview_generator.yaml --save-config -n $(NAMESPACE)

update_external_backend:
	kubectl apply -f k8s/server_external.yaml -n $(NAMESPACE)
	kubectl apply -f k8s/preview_generator.yaml -n $(NAMESPACE)
	$(MAKE) monitor_backend_rollout
update_internal_backend:
	kubectl apply -f k8s/server_internal.yaml -n $(NAMESPACE)
	kubectl apply -f k8s/preview_generator.yaml -n $(NAMESPACE)
	$(MAKE) monitor_backend_rollout
deploy_be_internal_insecure_update:
	kubectl apply -f k8s/server_internal_insecure.yaml -n $(NAMESPACE)
	kubectl apply -f k8s/preview_generator.yaml -n $(NAMESPACE)
	$(MAKE) monitor_backend_rollout

delete_backend:
	kubectl delete -f k8s/server_external.yaml -n $(NAMESPACE)
	kubectl delete -f k8s/preview_generator.yaml -n $(NAMESPACE)

monitor_backend_rollout:
	kubectl rollout status deployment/jonline -n $(NAMESPACE) --timeout 2m

restart_backend:
	kubectl rollout restart deployment jonline -n $(NAMESPACE)

get_backend_external_ip:
# Suppress echoing this so 'make get_backend_external_ip` is easily composable. 
	@kubectl get service jonline -n $(NAMESPACE) | sed -n 2p | awk '{print $$4}'

get_backend_all:
	kubectl get all -n $(NAMESPACE)

deploy_be_get_pods:
	kubectl get pods --selector=app=jonline -n $(NAMESPACE)

backend_shell:
	kubectl exec -it $$(kubectl get pods --selector=app=jonline -n $(NAMESPACE) -o jsonpath='{.items[0].metadata.name}') -n $(NAMESPACE) -- /bin/bash

# K8s server deployment test targets
deploy_test_be:
	@echo 'Getting services on target server...'
	grpcurl $(TEST_GRPC_TARGET) list
	@echo "\nGetting Jonline service version..."
	grpcurl $(TEST_GRPC_TARGET) jonline.Jonline/GetServiceVersion
	@echo "\nGetting available Jonline RPCs..."
	grpcurl $(TEST_GRPC_TARGET) list jonline.Jonline

deploy_test_be_unsecured:
	@echo 'Getting services on target server...'
	grpcurl -plaintext $(TEST_GRPC_TARGET) list
	@echo "\nGetting Jonline service version..."
	grpcurl -plaintext $(TEST_GRPC_TARGET) jonline.Jonline/GetServiceVersion
	@echo "\nGetting available Jonline RPCs..."
	grpcurl -plaintext $(TEST_GRPC_TARGET) list jonline.Jonline

deploy_test_be_tls_openssl:
	openssl s_client -connect $(TEST_GRPC_TARGET) -CAfile generated_certs/ca.pem

create_backend_data: create_backend_postgres create_backend_minio
update_backend_data: update_backend_postgres update_backend_minio
delete_backend_data: delete_backend_postgres delete_backend_minio
restart_backend_data: restart_backend_postgres restart_backend_minio

# Cluster-scoped, so this is safe/idempotent to (re)apply from any namespace's create target.
deploy_ensure_storageclass_retain:
	kubectl apply -f k8s/storageclass-retain-$(K8S_PROVIDER).yaml

# K8s DB deployment targets (optional if using managed DB)
create_backend_postgres: deploy_ensure_namespace deploy_ensure_storageclass_retain
	kubectl create -f k8s/k8s-postgres-$(K8S_PROVIDER).yaml --save-config -n $(NAMESPACE)

update_backend_postgres:
	kubectl apply -f k8s/k8s-postgres-$(K8S_PROVIDER).yaml -n $(NAMESPACE)

delete_backend_postgres:
	- kubectl delete -f k8s/k8s-postgres-$(K8S_PROVIDER).yaml -n $(NAMESPACE)

restart_backend_postgres:
	kubectl rollout restart statefulset jonline-postgres -n $(NAMESPACE)

# K8s Minio deployment targets (optional if using managed S3/Minio)
create_backend_minio: deploy_ensure_namespace deploy_ensure_storageclass_retain
	kubectl create -f k8s/k8s-minio-$(K8S_PROVIDER).yaml --save-config -n $(NAMESPACE)

update_backend_minio:
	kubectl apply -f k8s/k8s-minio-$(K8S_PROVIDER).yaml -n $(NAMESPACE)

delete_backend_minio:
	- kubectl delete -f k8s/k8s-minio-$(K8S_PROVIDER).yaml -n $(NAMESPACE)

restart_backend_minio:
	kubectl rollout restart statefulset jonline-minio -n $(NAMESPACE)

# Useful things
deploy_ensure_namespace:
	- kubectl create namespace $(NAMESPACE)

# Certificate-related targets
get_backend_generated_certs:
	kubectl get secret jonline-generated-tls -n $(NAMESPACE)
get_backend_generated_ca_certs:
	kubectl get configmap jonline-generated-ca -n $(NAMESPACE)

# Facebook App credentials (FACEBOOK_APP_ID/FACEBOOK_APP_SECRET -- see
# backend/src/logic/facebook_sync.rs) used to cross-post Events to a connected Facebook Page.
# Kept in their own Secret (jonline-facebook-app), read by k8s/server_*.yaml's `optional: true`
# env entries -- skipping this target entirely is safe if a namespace doesn't need Facebook sync.
set_facebook_app_data:
	@read -p "Facebook App ID: " FACEBOOK_APP_ID; \
	read -s -p "Facebook App Secret: " FACEBOOK_APP_SECRET; echo; \
	test -n "$$FACEBOOK_APP_ID" || (echo "Facebook App ID is required" && exit 1); \
	test -n "$$FACEBOOK_APP_SECRET" || (echo "Facebook App Secret is required" && exit 1); \
	kubectl create secret generic jonline-facebook-app -n $(NAMESPACE) \
	  --from-literal=app-id="$$FACEBOOK_APP_ID" \
	  --from-literal=app-secret="$$FACEBOOK_APP_SECRET" \
	  --dry-run=client -o yaml | kubectl apply -f -

remove_facebook_app_data:
	- kubectl delete secret jonline-facebook-app -n $(NAMESPACE)

# Copies the jonline-facebook-app Secret from SOURCE_NAMESPACE into NAMESPACE (e.g. sharing one
# Facebook App's credentials across several instances) without re-prompting for them.
copy_facebook_app_data:
	@test -n "$(NAMESPACE)" || (echo "NAMESPACE is required, e.g. NAMESPACE=bullcitysocial SOURCE_NAMESPACE=jonline make copy_facebook_app_data" && exit 1)
	@test -n "$(SOURCE_NAMESPACE)" || (echo "SOURCE_NAMESPACE is required, e.g. NAMESPACE=bullcitysocial SOURCE_NAMESPACE=jonline make copy_facebook_app_data" && exit 1)
	@test "$(NAMESPACE)" != "$(SOURCE_NAMESPACE)" || (echo "NAMESPACE and SOURCE_NAMESPACE must be different" && exit 1)
	kubectl get secret jonline-facebook-app -n $(SOURCE_NAMESPACE) -o json \
	  | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.selfLink,.metadata.managedFields,.metadata.ownerReferences)' \
	  | kubectl apply -n $(NAMESPACE) -f -
