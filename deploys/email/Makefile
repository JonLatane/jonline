.NOTPARALLEL:

# create_email: boots the shared Stalwart controller (Namespace, PVC, Deployment, two ClusterIP
# Services, and an IngressRouteTCP on the shared Traefik ingress's `smtp` entrypoint -- see
# k8s/stalwart.yaml's comments). Requires deploys/ingress's shared controller to already be
# installed (`make create_ingress`) -- Stalwart has no external IP of its own; port 25 reaches
# it through Traefik, same LoadBalancer your other domains already share. Run once per cluster.
#
# Run create_email_admin_secret (below) FIRST if you want add_email_domain/etc. to work --
# Stalwart's Deployment picks up STALWART_RECOVERY_ADMIN from that Secret on first boot only.
create_email:
	kubectl create -f k8s/stalwart.yaml --save-config -n jonline-email
update_email:
	kubectl apply -f k8s/stalwart.yaml -n jonline-email
restart_email:
	kubectl rollout restart deployment stalwart -n jonline-email
remove_email:
	kubectl delete -f k8s/stalwart.yaml -n jonline-email

# create_email_admin_secret: pre-codes Stalwart's initial admin credentials into a Secret instead
# of hunting a random one-time password out of `kubectl logs` (see k8s/stalwart.yaml's
# STALWART_RECOVERY_ADMIN comment, `optional: true` so skipping this is still safe). Also doubles
# as the credential add_email_domain/remove_email_domain/list_email_domains authenticate with
# against Stalwart's Management API below -- same Secret, same "user:pass" value either way. Must
# run BEFORE create_email: Stalwart only reads STALWART_RECOVERY_ADMIN on a totally empty
# stalwart-data volume, not on every boot. No default ADMIN_PASSWORD on purpose (mirrors
# NAMESPACE/DOMAIN elsewhere in this repo not defaulting) -- pick your own, don't silently reuse a
# placeholder.
ADMIN_USER ?= admin
create_email_admin_secret:
	@test -n "$(ADMIN_PASSWORD)" || (echo "ADMIN_PASSWORD is required, e.g. ADMIN_USER=admin ADMIN_PASSWORD=correct-horse-battery-staple make create_email_admin_secret" && exit 1)
	kubectl create namespace jonline-email --dry-run=client -o yaml | kubectl apply -f -
	kubectl create secret generic stalwart-admin -n jonline-email \
	  --from-literal=credentials="$(ADMIN_USER):$(ADMIN_PASSWORD)" \
	  --dry-run=client -o yaml | kubectl apply -f -

deploy_email_get_ip:
# Suppress echoing this so `make deploy_email_get_ip` is easily composable -- this is what your
# domains' MX records should point at (see ../README.md). Stalwart has no Service IP of its own
# any more -- this is just the shared ingress's IP, from ../ingress/Makefile.
	@cd ../ingress && $(MAKE) get_ingress_external_ip

deploy_email_restart:
	kubectl rollout restart deployment stalwart -n jonline-email
deploy_email_monitor_rollout:
	kubectl rollout status deployment/stalwart -n jonline-email --timeout 2m

# Reaches the setup wizard / admin UI at http://localhost:8080 -- this is *never* exposed
# publicly (see k8s/stalwart.yaml), so this is the only way in.
deploy_email_admin_port_forward:
	kubectl port-forward service/stalwart-admin -n jonline-email 8080:8080

# add_email_domain / remove_email_domain / list_email_domains: unlike ../ingress's
# add_ingress_domain, these are NOT `kubectl apply` of generated YAML -- Stalwart keeps accepted
# domains and MTA hook definitions in its own database, so instead these script Stalwart's HTTP
# Management API (its JMAP-based `x:Domain`/`x:MtaHook` extension objects under `urn:stalwart:jmap`
# -- see https://stalw.art/docs/ref/object/domain/ and .../mta-hook), authenticated with the
# credentials from create_email_admin_secret above.
#
# CAVEAT: this talks to the same API the admin UI does, but has only been checked against
# Stalwart's documented API shape, NOT exercised against a live instance (verify the domain shows
# up correctly -- `make list_email_domains` or the admin UI -- before pointing real DNS at it, and
# recheck this against your Stalwart version if it starts failing; see ../README.md's original
# note on this API's syntax evolving between releases).
#
# Requires `make deploy_email_admin_port_forward` running in another terminal (Stalwart's admin
# API is ClusterIP-only, per k8s/stalwart.yaml).
STALWART_ADMIN_URL ?= http://localhost:8080/jmap
stalwart_admin_auth = $$(kubectl get secret stalwart-admin -n jonline-email -o jsonpath='{.data.credentials}' | base64 -d)

add_email_domain:
	@test -n "$(NAMESPACE)" || (echo "NAMESPACE is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social make add_email_domain" && exit 1)
	@test -n "$(DOMAIN)" || (echo "DOMAIN is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social make add_email_domain" && exit 1)
	jq -n --arg domain "$(DOMAIN)" --arg url "http://jonline.$(NAMESPACE).svc.cluster.local:27705/email" --arg expr "rcpt_domain == '$(DOMAIN)'" '{using: ["urn:ietf:params:jmap:core", "urn:stalwart:jmap"], methodCalls: [["x:Domain/set", {create: {d1: {name: $$domain, allowRelaying: true}}}, "c1"], ["x:MtaHook/set", {create: {h1: {url: $$url, stages: {data: true}, httpAuth: {"@type": "Unauthenticated"}, enable: {match: {"0": {"if": $$expr, then: "true"}}, "else": "false"}}}}, "c2"]]}' | curl -sf -u "$(stalwart_admin_auth)" -H 'Content-Type: application/json' --data @- $(STALWART_ADMIN_URL) | jq .
	@echo "If that succeeded (check for \"notCreated\" errors above), point '$(DOMAIN)'s MX record at"
	@echo "this cluster's mail IP (make deploy_email_get_ip); see ../README.md's DNS table for SPF/DMARC."

remove_email_domain:
	@test -n "$(NAMESPACE)" || (echo "NAMESPACE is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social make remove_email_domain" && exit 1)
	@test -n "$(DOMAIN)" || (echo "DOMAIN is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social make remove_email_domain" && exit 1)
	@resp="$$(jq -n '{using: ["urn:ietf:params:jmap:core", "urn:stalwart:jmap"], methodCalls: [["x:Domain/get", {ids: null}, "c1"], ["x:MtaHook/get", {ids: null}, "c2"]]}' | curl -sf -u "$(stalwart_admin_auth)" -H 'Content-Type: application/json' --data @- $(STALWART_ADMIN_URL))"; \
	did="$$(echo "$$resp" | jq -r --arg d "$(DOMAIN)" '.methodResponses[0][1].list[] | select(.name==$$d) | .id')"; \
	hurl="http://jonline.$(NAMESPACE).svc.cluster.local:27705/email"; \
	hid="$$(echo "$$resp" | jq -r --arg u "$$hurl" '.methodResponses[1][1].list[] | select(.url==$$u) | .id')"; \
	test -n "$$did" || (echo "No domain named '$(DOMAIN)' found via the API." && exit 1); \
	jq -n --arg did "$$did" --arg hid "$$hid" '{using: ["urn:ietf:params:jmap:core", "urn:stalwart:jmap"], methodCalls: [["x:Domain/set", {destroy: [$$did]}, "c1"], ["x:MtaHook/set", {destroy: (if $$hid == "" then [] else [$$hid] end)}, "c2"]]}' | curl -sf -u "$(stalwart_admin_auth)" -H 'Content-Type: application/json' --data @- $(STALWART_ADMIN_URL) | jq .

list_email_domains:
	@jq -n '{using: ["urn:ietf:params:jmap:core", "urn:stalwart:jmap"], methodCalls: [["x:Domain/get", {ids: null}, "c1"]]}' | curl -sf -u "$(stalwart_admin_auth)" -H 'Content-Type: application/json' --data @- $(STALWART_ADMIN_URL) | jq -r '.methodResponses[0][1].list[] | .name'
