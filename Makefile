.NOTPARALLEL:
.DEFAULT_GOAL := default
default: protos docs graphs

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline

############################################################################
# DEPLOYMENT-RELATED TARGETS: More in deploys/Makefile
############################################################################
# Describe your BE deployment in the current namespace.
deploy_get_all:
	cd deploys && $(MAKE) deploy_get_all

# Manage your Load Balancer (WIP)
deploy_lb_create_config:
	cd deploys/jbl && $(MAKE) deploy_lb_create_config
deploy_lb_delete_config:
	cd deploys/jbl && $(MAKE) deploy_lb_delete_config
deploy_lb_get_config:
	cd deploys/jbl && $(MAKE) deploy_lb_get_config
deploy_lb_link_service_account:
	cd deploys/jbl && $(MAKE) deploy_lb_link_service_account
deploy_lb_unlink_service_account:
	cd deploys/jbl && $(MAKE) deploy_lb_unlink_service_account
deploy_lb_create:
	cd deploys/jbl && $(MAKE) deploy_lb_create
deploy_lb_update:
	cd deploys/jbl && $(MAKE) deploy_lb_update

# Targets for deploying Jonline to your K8s cluster.
# Internal or external refers to whether the service is exposed to the internet.
# External is the default, but internal is useful for testing, and could
# save lots of money if you want to host many servers from a single LoadBalancer/IP.
deploy_be_external_create:
	cd deploys && $(MAKE) deploy_be_external_create
deploy_be_internal_create:
	cd deploys && $(MAKE) deploy_be_internal_create
deploy_be_external_update:
	cd deploys && $(MAKE) deploy_be_external_update
deploy_be_internal_update:
	cd deploys && $(MAKE) deploy_be_internal_update
deploy_be_restart:
	cd deploys && $(MAKE) deploy_be_restart
deploy_be_delete:
	cd deploys && $(MAKE) deploy_be_delete
get_be_version:
	@cd deploys/releases && $(MAKE) get_be_version

# Targets for managing an existing deployment on your K8s cluster, so you can quickly setup DNS and setup an admin.
deploy_be_shell:
	cd deploys && $(MAKE) deploy_be_shell
deploy_be_external_get_ip:
	cd deploys && $(MAKE) deploy_be_external_get_ip
deploy_be_monitor_rollout:
	cd deploys && $(MAKE) deploy_be_monitor_rollout

# General targets for creating/deleting Postgres/MinIO for Jonline. For more granuar control, use deploys/Makefile directly.
deploy_data_create:
	cd deploys && $(MAKE) deploy_data_create
deploy_data_delete:
	cd deploys && $(MAKE) deploy_data_delete
deploy_data_update:
	cd deploys && $(MAKE) deploy_data_update

############################################################################
# BE/LOCAL TESTING/DEVOPS RESEARCH TARGETS
############################################################################
local_db_create:
	cd backend && $(MAKE) local_db_create
local_db_drop:
	cd backend && $(MAKE) local_db_drop
local_db_reset:
	cd backend && $(MAKE) local_db_reset
local_db_connect:
	cd backend && $(MAKE) local_db_connect

local_minio_create:
	cd backend && $(MAKE) local_minio_create
local_minio_delete:
	cd backend && $(MAKE) local_minio_delete

############################################################################
# FULLSTACK DEV/RELEASE-RELATED TARGETS: More in deploys/releases/Makefile
############################################################################
.PHONY: protos docs

# Update frontend protos and docs
protos:
	cd frontends/flutter && $(MAKE) protos
	cd frontends/tamagui && yarn protos

# Core release targets (for general use, CI/CD, etc.)
release_ios:
	cd deploys/releases && $(MAKE) release_ios
release_be_cloud:
	cd deploys/releases && $(MAKE) release_be_cloud
_push_be_cloud_release:
	cd deploys/releases && $(MAKE) _push_be_cloud_release
# This target rebuilds the Flutter+React apps, but does not rebuild the Rust BE
# before pushing the new image. The server Docker image is structured so that this will
# result in a very small push of only it first layer. Useful for iteration (~55s to deploy
# to two namespaces in my cluster from my old MBP), but note that
# the BE GetServiceVersion call will not match the version of the Docker image.
release_be_fe_only_cloud:
	cd deploys/releases && $(MAKE) release_be_fe_only_cloud

# Full-Stack dev targets
# Excludes generated Dart and TypeScript Protobuf files we save in the repo.
lines_of_code:
	git ls-files | grep -v generated | xargs cloc

docs: documentation html_docs

documentation:
	docker run --rm -v $(PWD)/docs:/out -v $(PWD)/protos:/protos pseudomuto/protoc-gen-doc --doc_opt=markdown,protocol.md jonline.proto authentication.proto visibility_moderation.proto permissions.proto users.proto media.proto groups.proto posts.proto events.proto server_configuration.proto federation.proto

html_docs: documentation
	npm i markdown-to-html-cli -g
	markdown-to-html --source docs/protocol.md --output docs/protocol.html --github-corners https://github.com/JonLatane/jonline --style 'markdown-style { padding-top: 40px!important; }' --title 'Jonline Protocol Documentation'

graphs:
	cd docs/architecture && dot -Tsvg Kubernetes_Deployment.dot -o Kubernetes_Deployment.svg
	cd docs/architecture && dot -Tsvg JBL_Kubernetes_Deployment.dot -o JBL_Kubernetes_Deployment.svg
	cd docs/architecture && dot -Tsvg Service_Architecture.dot -o Service_Architecture.svg
#	cd docs/architecture && neato -Tsvg Service_Architecture.dot -o Service_Architecture.svg

