.NOTPARALLEL:
.DEFAULT_GOAL := release_be_local

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline

# K8s server deployment targets
deploy_be_create:
	cd deploys && $(MAKE) deploy_be_create
# K8s server deployment targets
deploy_be_update:
	cd deploys && $(MAKE) deploy_be_update

deploy_data_create:
	cd deploys && $(MAKE) deploy_data_create

# DEVELOPMENT-RELATED TARGETS
# Core release targets (for general use, CI/CD, etc.)
release_ios:
	cd deploys/releases && $(MAKE) release_ios
release_be_cloud: release_be_push_cloud
	cd deploys/releases && $(MAKE) release_be_cloud
# This target rebuilds the Flutter+React apps, but does not rebuild the Rust BE
# before pushing the new image. The server Docker image is structured so that this will
# result in a very small push of only it first layer. Useful for iteration (~55s to deploy
# to two namespaces in my cluster from my old MBP), but note that
# the BE GetServiceVersion call will not match the version of the Docker image.
release_be_fe_only_cloud:
	cd deploys/releases && $(MAKE) release_be_fe_only_cloud

# Full-Stack dev targets
lines_of_code:
	git ls-files | xargs cloc

docs: documentation
documentation:
	docker run --rm -v $(PWD)/docs:/out -v $(PWD)/protos:/protos pseudomuto/protoc-gen-doc --doc_opt=markdown,protocol.md jonline.proto authentication.proto visibility_moderation.proto permissions.proto users.proto posts.proto server_configuration.proto
