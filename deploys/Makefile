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

# Used by the Postgres dump/restore targets below (e.g. during upgrade_backend_postgres).
PG_UPGRADE_LOCAL_PORT ?= 15432
PG_BACKUP_DIR ?= backups
PG_PASSWORD ?= secure_password1
# Replica count restored by start_backend after a stop_backend/start_backend maintenance window.
BACKEND_REPLICAS ?= 2

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

# Scales the app to 0 so it can't write to Postgres during maintenance (e.g. upgrade_backend_postgres).
stop_backend:
	kubectl scale deployment jonline --replicas=0 -n $(NAMESPACE)
	kubectl wait --for=delete pod -l app=jonline -n $(NAMESPACE) --timeout=60s || true

# Restores the app to BACKEND_REPLICAS after a stop_backend maintenance window.
start_backend:
	kubectl scale deployment jonline --replicas=$(BACKEND_REPLICAS) -n $(NAMESPACE)
	$(MAKE) monitor_backend_rollout

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
	kubectl create -f k8s/k8s-postgres-pvc-$(K8S_PROVIDER).yaml --save-config -n $(NAMESPACE)
	kubectl create -f k8s/k8s-postgres-$(K8S_PROVIDER).yaml --save-config -n $(NAMESPACE)

update_backend_postgres:
	kubectl apply -f k8s/k8s-postgres-$(K8S_PROVIDER).yaml -n $(NAMESPACE)

delete_backend_postgres:
	- kubectl delete -f k8s/k8s-postgres-$(K8S_PROVIDER).yaml -n $(NAMESPACE)

# Separate from delete_backend_postgres since it's rarely wanted: releases the PVC (data itself
# is safe either way, since the PV's reclaimPolicy is Retain -- see storageclass-retain-*.yaml --
# but this makes the volume unbound/orphaned from any PVC until manually reclaimed).
delete_backend_postgres_pvc:
	- kubectl delete -f k8s/k8s-postgres-pvc-$(K8S_PROVIDER).yaml -n $(NAMESPACE)

restart_backend_postgres:
	kubectl rollout restart statefulset jonline-postgres -n $(NAMESPACE)

# Scales Postgres to 0. Data is untouched (PV reclaimPolicy is Retain) -- this just stops the pod.
# Run dump_backend_postgres (or upgrade_backend_postgres, which does this for you) BEFORE this,
# since it needs Postgres running to connect to.
stop_backend_postgres:
	kubectl scale statefulset jonline-postgres --replicas=0 -n $(NAMESPACE)
	kubectl wait --for=delete pod/jonline-postgres-0 -n $(NAMESPACE) --timeout=60s || true

wait_backend_postgres_ready:
	kubectl wait --for=condition=ready pod/jonline-postgres-0 -n $(NAMESPACE) --timeout=2m

# Dumps the `jonline` database (schema + data) from the currently-running jonline-postgres-0 pod
# to a local file, via a temporary port-forward. Uses the local pg_dump (works against older *or*
# newer servers), so it doubles as a general-purpose backup target and as the first step of
# upgrade_backend_postgres. Override the output path with DUMP_FILE=path/to/file.sql.
DUMP_FILE ?= $(PG_BACKUP_DIR)/$(NAMESPACE)-$(shell date +%Y%m%d%H%M%S).sql
dump_backend_postgres:
	@mkdir -p $(PG_BACKUP_DIR)
	rm -f /tmp/pgpf-$(NAMESPACE).log; \
	kubectl port-forward -n $(NAMESPACE) jonline-postgres-0 $(PG_UPGRADE_LOCAL_PORT):5432 >/tmp/pgpf-$(NAMESPACE).log 2>&1 & \
	echo $$! > /tmp/pgpf-$(NAMESPACE).pid; \
	for i in 1 2 3 4 5 6 7 8 9 10; do grep -q "Forwarding from" /tmp/pgpf-$(NAMESPACE).log 2>/dev/null && break; sleep 1; done; \
	if ! grep -q "Forwarding from" /tmp/pgpf-$(NAMESPACE).log 2>/dev/null; then \
		echo "ERROR: port-forward to $(NAMESPACE)/jonline-postgres-0 on port $(PG_UPGRADE_LOCAL_PORT) never came up (port may already be in use by another tunnel -- check /tmp/pgpf-$(NAMESPACE).log, or override PG_UPGRADE_LOCAL_PORT)" >&2; \
		cat /tmp/pgpf-$(NAMESPACE).log >&2; \
		kill $$(cat /tmp/pgpf-$(NAMESPACE).pid) 2>/dev/null; \
		rm -f /tmp/pgpf-$(NAMESPACE).pid; \
		exit 1; \
	fi; \
	PGPASSWORD=$(PG_PASSWORD) pg_dump -h localhost -p $(PG_UPGRADE_LOCAL_PORT) -U admin -d jonline --clean --if-exists -f $(DUMP_FILE); \
	DUMP_STATUS=$$?; \
	kill $$(cat /tmp/pgpf-$(NAMESPACE).pid) 2>/dev/null; \
	rm -f /tmp/pgpf-$(NAMESPACE).pid; \
	exit $$DUMP_STATUS

# Restores a dump produced by dump_backend_postgres into the currently-running jonline-postgres-0
# pod (must already have an empty/initialized `jonline` database -- i.e. run this after
# update_backend_postgres has brought up the new version). Usage: make restore_backend_postgres
# DUMP_FILE=backups/foo.sql
# Retries once on failure -- the dump's --clean --if-exists means a full re-run is idempotent even
# if a prior attempt got partway through (e.g. kubectl port-forward's SPDY tunnel dropping mid-COPY
# under a large transfer, which happens occasionally and isn't a sign of real DB corruption).
restore_backend_postgres:
	@test -n "$(DUMP_FILE)" || (echo "Usage: make restore_backend_postgres DUMP_FILE=path/to/dump.sql NAMESPACE=..." >&2 && exit 1)
	for attempt in 1 2; do \
		rm -f /tmp/pgpf-$(NAMESPACE).log; \
		kubectl port-forward -n $(NAMESPACE) jonline-postgres-0 $(PG_UPGRADE_LOCAL_PORT):5432 >/tmp/pgpf-$(NAMESPACE).log 2>&1 & \
		echo $$! > /tmp/pgpf-$(NAMESPACE).pid; \
		for i in 1 2 3 4 5 6 7 8 9 10; do grep -q "Forwarding from" /tmp/pgpf-$(NAMESPACE).log 2>/dev/null && break; sleep 1; done; \
		if ! grep -q "Forwarding from" /tmp/pgpf-$(NAMESPACE).log 2>/dev/null; then \
			echo "ERROR: port-forward to $(NAMESPACE)/jonline-postgres-0 on port $(PG_UPGRADE_LOCAL_PORT) never came up (port may already be in use by another tunnel -- check /tmp/pgpf-$(NAMESPACE).log, or override PG_UPGRADE_LOCAL_PORT)" >&2; \
			cat /tmp/pgpf-$(NAMESPACE).log >&2; \
			kill $$(cat /tmp/pgpf-$(NAMESPACE).pid) 2>/dev/null; \
			rm -f /tmp/pgpf-$(NAMESPACE).pid; \
			exit 1; \
		fi; \
		PGPASSWORD=$(PG_PASSWORD) psql -h localhost -p $(PG_UPGRADE_LOCAL_PORT) -U admin -d jonline -v ON_ERROR_STOP=1 -f $(DUMP_FILE); \
		RESTORE_STATUS=$$?; \
		kill $$(cat /tmp/pgpf-$(NAMESPACE).pid) 2>/dev/null; \
		rm -f /tmp/pgpf-$(NAMESPACE).pid; \
		if [ $$RESTORE_STATUS -eq 0 ]; then exit 0; fi; \
		echo "restore_backend_postgres: attempt $$attempt failed (status $$RESTORE_STATUS)$$([ $$attempt -eq 1 ] && echo ', retrying...' || echo '.')" >&2; \
	done; \
	exit 1

# Full Postgres major-version upgrade: dumps the live (old-version) database, stops the app and
# Postgres, applies the new k8s-postgres-$(K8S_PROVIDER).yaml (new image + new subPath, so the
# new version initdb's a fresh data directory alongside -- not over -- the old one), restores the
# dump into it, then brings the app back up. The old version's data directory is left in place on
# the same PVC as an instant rollback; once you've confirmed the app is healthy on the new
# version, clean it up by hand with delete_backend_postgres_old_data.
upgrade_backend_postgres:
	@echo "== Upgrading Postgres in namespace $(NAMESPACE) (see k8s/k8s-postgres-$(K8S_PROVIDER).yaml for target version) =="
	$(MAKE) dump_backend_postgres NAMESPACE=$(NAMESPACE) DUMP_FILE=$(PG_BACKUP_DIR)/$(NAMESPACE)-preupgrade.sql
	$(MAKE) stop_backend NAMESPACE=$(NAMESPACE)
	$(MAKE) stop_backend_postgres NAMESPACE=$(NAMESPACE)
	$(MAKE) update_backend_postgres NAMESPACE=$(NAMESPACE)
	$(MAKE) wait_backend_postgres_ready NAMESPACE=$(NAMESPACE)
	$(MAKE) restore_backend_postgres NAMESPACE=$(NAMESPACE) DUMP_FILE=$(PG_BACKUP_DIR)/$(NAMESPACE)-preupgrade.sql
	$(MAKE) start_backend NAMESPACE=$(NAMESPACE)
	@echo "== Done. Verify the app, then (once confident) run: make delete_backend_postgres_old_data NAMESPACE=$(NAMESPACE) =="

# DESTRUCTIVE, manual-only: permanently deletes the pre-upgrade Postgres data directory left
# behind (at PVC subPath "postgres") by upgrade_backend_postgres. Only run this per-namespace,
# once you've confirmed the app is healthy on the new version -- there is no undo.
delete_backend_postgres_old_data:
	@echo "This permanently deletes the pre-upgrade Postgres data at postgres-pv-claim:/postgres in namespace $(NAMESPACE)."
	kubectl exec -n $(NAMESPACE) jonline-postgres-0 -- rm -rf /var/lib/postgresql/data/postgres

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

# Web Push-related targets
# Generates a VAPID keypair for Web Push notifications (see `backend/src/web_push`) -- paste the
# printed Public/Private Key into a server's Web Push Configuration (FederationTab.elm, as an
# admin) or directly into that server's `server_configurations.web_push_config` JSONB column.
generate_vapid_push_key_pair:
	npx web-push generate-vapid-keys
