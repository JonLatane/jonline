.NOTPARALLEL:
.DEFAULT_GOAL := release_be_local

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline

# Used when configuring the load balancer (deploy_lb_[un]link_service_account).
TARGET_NAMESPACE ?= jonline
TARGET_NAMESPACE_DOMAIN ?= invalid.jonline.domain

TEST_GRPC_TARGET ?= $(shell $(MAKE) deploy_be_get_external_ip):27707

# K8s Load Balancer deployment targets (WIP)
# It should be possible to write a minimalist Rust LB that loads the TLS certs
# from various Jonline namespaces and routes traffic to the appropriate service.
# Both the LB and the internal service use the same TLS certs for their communication.
#
# See hudsucker, the library I should use for this:
# - https://github.com/omjadas/hudsucker/blob/main/examples/openssl.rs
# And this StackOverflow answer: https://stackoverflow.com/a/73419051
#
# The Rust code for the LB will basically just be "step 7 from the SA answer".
# Linking new service accounts will require restarting the LB

SERVICE_ACCOUNT := jonline-lb
SERVICE_LINK_ROLE := jonline-lb-$(TARGET_NAMESPACE)-to-$(NAMESPACE)
deploy_lb_create_service_account:
	kubectl create sa $(SERVICE_ACCOUNT) -n $(NAMESPACE)

deploy_lb_link_service_account:
	kubectl create clusterrole $(SERVICE_LINK_ROLE) --verb get,list --resource secret -n $(NAMESPACE)
	kubectl create rolebinding $(SERVICE_LINK_ROLE) -n $(TARGET_NAMESPACE) --serviceaccount $(NAMESPACE):$(SERVICE_ACCOUNT) --clusterrole $(SERVICE_LINK_ROLE)

deploy_lb_unlink_service_account:
	kubectl delete rolebinding $(SERVICE_LINK_ROLE) -n $(TARGET_NAMESPACE)
	kubectl delete clusterrole $(SERVICE_LINK_ROLE) -n $(NAMESPACE)

deploy_lb_create:
	kubectl create -f k8s/load_balancer.yaml --save-config -n $(NAMESPACE)

deploy_lb_update:
	kubectl apply -f k8s/load_balancer.yaml --save-config -n $(NAMESPACE)

deploy_lb_delete:
	kubectl delete -f k8s/load_balancer.yaml -n $(NAMESPACE)

deploy_lb_monitor_rollout:
	kubectl rollout status deployment/jonline-lb -n $(NAMESPACE)

deploy_lb_restart:
	kubectl rollout restart deployment jonline-lb -n $(NAMESPACE)

# K8s server deployment targets
# Use "internal" when deploying with a separate load balancer, and 
# use deploy_be_link_lb_service_account to link the load balancer to the
# internal Jonline service.
deploy_be_create_external: deploy_ensure_namespace
	kubectl create -f k8s/server_external.yaml --save-config -n $(NAMESPACE)
	kubectl create -f k8s/preview_generator.yaml --save-config -n $(NAMESPACE)
deploy_be_create_internal: deploy_ensure_namespace
	kubectl create -f k8s/server_internal.yaml --save-config -n $(NAMESPACE)
	kubectl create -f k8s/preview_generator.yaml --save-config -n $(NAMESPACE)

deploy_be_update_external:
	kubectl apply -f k8s/server_external.yaml -n $(NAMESPACE)
	kubectl apply -f k8s/preview_generator.yaml -n $(NAMESPACE)
	$(MAKE) deploy_be_monitor_rollout
deploy_be_update_internal:
	kubectl apply -f k8s/server_internal.yaml -n $(NAMESPACE)
	kubectl apply -f k8s/preview_generator.yaml -n $(NAMESPACE)
	$(MAKE) deploy_be_monitor_rollout

deploy_be_delete:
	kubectl delete -f k8s/server_external.yaml -n $(NAMESPACE)
	kubectl delete -f k8s/preview_generator.yaml -n $(NAMESPACE)

deploy_be_monitor_rollout:
	kubectl rollout status deployment/jonline -n $(NAMESPACE)

deploy_be_restart:
	kubectl rollout restart deployment jonline -n $(NAMESPACE)

deploy_be_get_external_ip:
# Suppress echoing this so 'make deploy_be_get_external_ip` is easily composable. 
	@kubectl get service jonline -n $(NAMESPACE) | sed -n 2p | awk '{print $$4}'

deploy_get_all:
	kubectl get all -n $(NAMESPACE)

deploy_be_get_pods:
	kubectl get pods --selector=app=jonline -n $(NAMESPACE)

deploy_be_shell:
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

deploy_data_create: deploy_db_create deploy_minio_create
deploy_data_update: deploy_db_update deploy_minio_update
deploy_data_delete: deploy_db_delete deploy_minio_delete
deploy_data_restart: deploy_ddbrestart deploy_dminiorestart

# K8s DB deployment targets (optional if using managed DB)
deploy_db_create: deploy_ensure_namespace
	kubectl create -f k8s/k8s-postgres.yaml --save-config -n $(NAMESPACE)

deploy_db_update:
	kubectl apply -f k8s/k8s-postgres.yaml -n $(NAMESPACE)

deploy_db_delete:
	- kubectl delete -f k8s/k8s-postgres.yaml -n $(NAMESPACE)

deploy_db_restart:
	kubectl rollout restart deployment jonline-postgres -n $(NAMESPACE)

# K8s Minio deployment targets (optional if using managed S3/Minio)
deploy_minio_create: deploy_ensure_namespace
	kubectl create -f k8s/k8s-minio.yaml --save-config -n $(NAMESPACE)

deploy_minio_update:
	kubectl apply -f k8s/k8s-minio.yaml -n $(NAMESPACE)

deploy_minio_delete:
	- kubectl delete -f k8s/k8s-minio.yaml -n $(NAMESPACE)

deploy_minio_restart:
	kubectl rollout restart deployment jonline-minio -n $(NAMESPACE)

# Useful things
deploy_ensure_namespace:
	- kubectl create namespace $(NAMESPACE)

# Certificate-related targets
deploy_be_get_certs:
	kubectl get secret jonline-generated-tls -n $(NAMESPACE)
deploy_be_get_ca_certs:
	kubectl get configmap jonline-generated-ca -n $(NAMESPACE)
