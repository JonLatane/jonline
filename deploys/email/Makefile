.NOTPARALLEL:

# Namespace the shared Stalwart mail server runs in. There is normally only ever one of these
# per cluster, regardless of how many domains you onboard for mail (mirrors
# ../ingress/Makefile's INGRESS_NAMESPACE).
EMAIL_NAMESPACE ?= jonline-email

# create_email: boots the shared Stalwart controller (Namespace, PVC, Deployment, two ClusterIP
# Services, and an IngressRouteTCP on the shared Traefik ingress's `smtp` entrypoint -- see
# k8s/stalwart.yaml's comments). Requires deploys/ingress's shared controller to already be
# installed (`make create_ingress`) -- Stalwart has no external IP of its own; port 25 reaches
# it through Traefik, same LoadBalancer your other domains already share. Run once per cluster.
create_email:
	kubectl create -f k8s/stalwart.yaml --save-config
remove_email:
	kubectl delete -f k8s/stalwart.yaml

deploy_email_get_ip:
# Suppress echoing this so `make deploy_email_get_ip` is easily composable -- this is what your
# domains' MX records should point at (see ../README.md). Stalwart has no Service IP of its own
# any more -- this is just the shared ingress's IP, from ../ingress/Makefile.
	@cd ../ingress && $(MAKE) get_ingress_external_ip

deploy_email_restart:
	kubectl rollout restart deployment stalwart -n $(EMAIL_NAMESPACE)
deploy_email_monitor_rollout:
	kubectl rollout status deployment/stalwart -n $(EMAIL_NAMESPACE) --timeout 2m

# Reaches the setup wizard / admin UI at http://localhost:8080 -- this is *never* exposed
# publicly (see k8s/stalwart.yaml), so this is the only way in.
deploy_email_admin_port_forward:
	kubectl port-forward service/stalwart-admin -n $(EMAIL_NAMESPACE) 8080:8080

# add_email_domain: NOT a `kubectl apply` of generated YAML, unlike ../ingress's
# add_ingress_domain -- Stalwart keeps accepted domains and MTA hook definitions in its own
# database, configured through its admin UI/REST API rather than static files. This target
# can't safely do that for you sight-unseen (see ../README.md's "Onboarding a domain" section
# for what to actually click/POST), so it just prints the concrete values you need on hand.
add_email_domain:
	@test -n "$(NAMESPACE)" || (echo "NAMESPACE is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social make add_email_domain" && exit 1)
	@test -n "$(DOMAIN)" || (echo "DOMAIN is required, e.g. NAMESPACE=bullcitysocial DOMAIN=bullcity.social make add_email_domain" && exit 1)
	@echo "In the Stalwart admin UI (make deploy_email_admin_port_forward), under Settings:"
	@echo "  1. Add '$(DOMAIN)' as an accepted/local domain."
	@echo "  2. Add an MTA Hook (Settings > MTA > Filters > MTA Hooks) scoped to that domain, firing"
	@echo "     at the 'data' stage, posting to:"
	@echo "       http://jonline.$(NAMESPACE).svc.cluster.local:27705/email"
	@echo "     See ../README.md for the X-Jonline-Email-Recipients header contract this endpoint expects."
	@echo "  3. Point '$(DOMAIN)'s MX record at this cluster's mail IP (make deploy_email_get_ip)."

list_email_domains:
	@echo "Stalwart's accepted domains live in its own database, not this repo's files -- check"
	@echo "Settings > MTA in the admin UI (make deploy_email_admin_port_forward)."
