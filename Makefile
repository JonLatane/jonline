.NOTPARALLEL:
.PHONY: protos docs
.DEFAULT_GOAL := default


default: protos docs graphs

run_backend:
	$(MAKE) -C backend run
run_elm:
	$(MAKE) -C frontends/elm-spa run
run_tamagui:
	$(MAKE) -C frontends/tamagui run

test_backend:
	$(MAKE) -C backend test
test_elm:
	$(MAKE) -C frontends/elm-spa test
test_tamagui:
	$(MAKE) -C frontends/tamagui test


############################################################################
# DEPLOYMENT-RELATED TARGETS: More in deploys/Makefile
############################################################################
# Describe your BE deployment in the current namespace.
get_backend_all:
	cd deploys && $(MAKE) get_backend_all

# Targets for deploying Jonline to your K8s cluster.
# Internal or external refers to whether the service is exposed to the internet.
# External is the default, but internal is useful for testing, and could
# save lots of money if you want to host many servers from a single LoadBalancer/IP.
create_external_backend:
	cd deploys && $(MAKE) create_external_backend
create_internal_backend:
	cd deploys && $(MAKE) create_internal_backend
update_external_backend:
	cd deploys && $(MAKE) update_external_backend
update_internal_backend:
	cd deploys && $(MAKE) update_internal_backend
restart_backend:
	cd deploys && $(MAKE) restart_backend
delete_backend:
	cd deploys && $(MAKE) delete_backend
get_backend_version:
	@cd deploys/releases && $(MAKE) get_backend_version

# Targets for managing an existing deployment on your K8s cluster, so you can quickly setup DNS and setup an admin.
backend_shell:
	cd deploys && $(MAKE) backend_shell
get_backend_external_ip:
	cd deploys && $(MAKE) get_backend_external_ip
monitor_backend_rollout:
	cd deploys && $(MAKE) monitor_backend_rollout

# General targets for creating/deleting Postgres/MinIO for Jonline. For more granuar control, use deploys/Makefile directly.
create_backend_data:
	cd deploys && $(MAKE) create_backend_data
delete_backend_data:
	cd deploys && $(MAKE) delete_backend_data
update_backend_data:
	cd deploys && $(MAKE) update_backend_data


# Manage the shared Traefik ingress (lets many Jonline instances, each in
# their own namespace/domain, share a single LoadBalancer/external IP instead
# of one each). See deploys/ingress/README.md.
create_ingress:
	cd deploys/ingress && $(MAKE) create_ingress
remove_ingress:
	cd deploys/ingress && $(MAKE) remove_ingress
get_ingress_external_ip:
	cd deploys/ingress && $(MAKE) get_ingress_external_ip
deploy_ingress_restart:
	cd deploys/ingress && $(MAKE) deploy_ingress_restart
add_ingress_domain:
	cd deploys/ingress && $(MAKE) add_ingress_domain
remove_ingress_domain:
	cd deploys/ingress && $(MAKE) remove_ingress_domain
list_ingress_domains:
	cd deploys/ingress && $(MAKE) list_ingress_domains

# Manage the shared Stalwart mail server (lets Jonline instances receive mail at
# <username>@yourdomain without each one speaking SMTP itself). See deploys/email/README.md.
create_email_admin_secret:
	cd deploys/email && $(MAKE) create_email_admin_secret
create_email:
	cd deploys/email && $(MAKE) create_email
remove_email:
	cd deploys/email && $(MAKE) remove_email
restart_email:
	cd deploys/email && $(MAKE) restart_email
deploy_email_get_ip:
	cd deploys/email && $(MAKE) deploy_email_get_ip
deploy_email_restart:
	cd deploys/email && $(MAKE) deploy_email_restart
deploy_email_admin_port_forward:
	cd deploys/email && $(MAKE) deploy_email_admin_port_forward
add_email_domain:
	cd deploys/email && $(MAKE) add_email_domain
list_email_domains:
	cd deploys/email && $(MAKE) list_email_domains

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

# Update frontend protos and docs
protos:
	cd frontends/flutter && $(MAKE) protos
	cd frontends/tamagui && yarn protos
	cd frontends/elm-spa && $(MAKE) protos

# Full-Stack dev targets
# Excludes generated Dart and TypeScript Protobuf files we save in the repo.
lines_of_code:
	git ls-files | grep -v generated | xargs cloc

docs: documentation html_docs

documentation:
	docker run --rm -v $(PWD)/docs:/out -v $(PWD)/protos:/protos pseudomuto/protoc-gen-doc --doc_opt=markdown,protocol.md jonline.proto authentication.proto visibility_moderation.proto permissions.proto users.proto media.proto messages.proto groups.proto posts.proto events.proto server_configuration.proto federation.proto

html_docs: documentation
	npm i markdown-to-html-cli -g
	markdown-to-html --source docs/protocol.md --output docs/protocol.html --github-corners https://github.com/JonLatane/jonline --style 'markdown-style { padding-top: 40px!important; }' --title 'Jonline Protocol Documentation'
	node -e "const f='docs/protocol.html'; const js=require('fs').readFileSync('docs/toc-sidebar.js','utf8'); \
		require('fs').writeFileSync(f, require('fs').readFileSync(f,'utf8').replace('</body>', '<script>'+js+'</script></body>'));"

graphs:
	cd docs/architecture && dot -Tsvg Kubernetes_Deployment.dot -o Kubernetes_Deployment.svg
	cd docs/architecture && dot -Tsvg Traefik_Kubernetes_Deployment.dot -o Traefik_Kubernetes_Deployment.svg
	cd docs/architecture && dot -Tsvg Service_Architecture.dot -o Service_Architecture.svg
#	cd docs/architecture && neato -Tsvg Service_Architecture.dot -o Service_Architecture.svg

