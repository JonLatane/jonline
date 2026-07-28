.NOTPARALLEL:

# Namespace the shared Traefik controller itself runs in. There is normally
# only ever one of these per cluster.
INGRESS_NAMESPACE ?= traefik-ingress

# Pinned Traefik version. Keep in sync with the `image:` tag in
# k8s/traefik.yaml -- the CRDs and the controller version should always match.
TRAEFIK_VERSION ?= v3.7.9
TRAEFIK_CRDS_URL := https://raw.githubusercontent.com/traefik/traefik/$(TRAEFIK_VERSION)/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

# NAMESPACE/DOMAIN are intentionally NOT given defaults here: every
# add_ingress_domain/remove_ingress_domain call is specific to one of *your*
# domains, and should never silently fall back to a placeholder.

# create_ingress: the one command that sets up the shared ingress. Contains
# no domain-specific configuration whatsoever -- safe to run as-is on any
# cluster. Run this once per cluster; then use add_ingress_domain below, once
# per domain you want to route through it.
create_ingress: deploy_ingress_crds deploy_ingress_controller_create

deploy_ingress_ensure_namespace:
	- kubectl create namespace $(INGRESS_NAMESPACE)

# Traefik's CRDs (IngressRoute, IngressRouteTCP, etc.) are cluster-scoped and
# tied to TRAEFIK_VERSION, so we apply them straight from upstream rather than
# vendoring a copy that could drift.
deploy_ingress_crds:
	kubectl apply -f $(TRAEFIK_CRDS_URL)

deploy_ingress_controller_create: deploy_ingress_ensure_namespace
	kubectl create -f k8s/traefik.yaml --save-config -n $(INGRESS_NAMESPACE)
deploy_ingress_controller_update:
	kubectl apply -f k8s/traefik.yaml -n $(INGRESS_NAMESPACE)
	$(MAKE) deploy_ingress_monitor_rollout
deploy_ingress_controller_delete:
	kubectl delete -f k8s/traefik.yaml -n $(INGRESS_NAMESPACE)

deploy_ingress_monitor_rollout:
	kubectl rollout status deployment/traefik -n $(INGRESS_NAMESPACE) --timeout 2m
deploy_ingress_restart:
	kubectl rollout restart deployment traefik -n $(INGRESS_NAMESPACE)

deploy_ingress_get_ip:
# Suppress echoing this so `make deploy_ingress_get_ip` is easily composable.
	@kubectl get service traefik -n $(INGRESS_NAMESPACE) | sed -n 2p | awk '{print $$4}'

# Per-domain routes. NAMESPACE is the existing namespace your `jonline`
# backend/DB/certs already live in (see ../README.md); DOMAIN is that
# backend's public hostname. Both are required -- there are no defaults.
k8s/jonline-routes.$(NAMESPACE).generated.yaml: k8s/jonline-routes.template.yaml
	@test -n "$(NAMESPACE)" || (echo "NAMESPACE is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social.example.com make add_ingress_domain" && exit 1)
	@test -n "$(DOMAIN)" || (echo "DOMAIN is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social.example.com make add_ingress_domain" && exit 1)
	cat k8s/jonline-routes.template.yaml | \
	  sed 's/$${DOMAIN}/$(DOMAIN)/g' \
	  > k8s/jonline-routes.$(NAMESPACE).generated.yaml

add_ingress_domain: k8s/jonline-routes.$(NAMESPACE).generated.yaml
	kubectl apply -f k8s/jonline-routes.$(NAMESPACE).generated.yaml -n $(NAMESPACE)

remove_ingress_domain: k8s/jonline-routes.$(NAMESPACE).generated.yaml
	kubectl delete -f k8s/jonline-routes.$(NAMESPACE).generated.yaml -n $(NAMESPACE)
	rm k8s/jonline-routes.$(NAMESPACE).generated.yaml

# Lists every namespace currently wired up to the shared ingress, straight
# from the cluster (not from local *.generated.yaml files, which are
# per-machine and gitignored, so they're not a reliable inventory).
list_ingress_domains:
	@kubectl get ingressroute -A -o json | \
	  jq -r '.items[] | select(.metadata.name == "jonline-http") | "\(.metadata.namespace): \(.spec.routes[0].match)"' | \
	  sed -E 's/Host\(`(.*)`\)/\1/'
