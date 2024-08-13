.NOTPARALLEL:
.DEFAULT_GOAL := release_be_local

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline

# Used when configuring the load balancer (deploy_lb_[un]link_service_account).
TARGET_NAMESPACE ?= jonline
TARGET_NAMESPACE_HOST ?= invalid.jonline.host

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

LB_CONFIG := jonline-lb-config
SERVICE_ACCOUNT := jonline-lb
SERVICE_LINK_ROLE := jonline-lb-$(TARGET_NAMESPACE)-to-$(NAMESPACE)

deploy_lb_create_config:
	kubectl create sa $(SERVICE_ACCOUNT) -n $(NAMESPACE)
	kubectl create configmap $(LB_CONFIG) --from-literal=servers=[] -n $(NAMESPACE)
deploy_lb_delete_config:
	kubectl delete sa $(SERVICE_ACCOUNT) -n $(NAMESPACE)
	kubectl delete configmap $(LB_CONFIG) -n $(NAMESPACE)

deploy_lb_get_config:
	$(eval CURRENT_CONFIG := $(shell kubectl get configmap $(LB_CONFIG) -o jsonpath="{.data.servers}" -n $(NAMESPACE)))
	@echo '$(CURRENT_CONFIG)'

deploy_lb_link_service_account:
	jq --version
	kubectl create clusterrole $(SERVICE_LINK_ROLE) --verb get,list --resource secret -n $(NAMESPACE)
	kubectl create rolebinding $(SERVICE_LINK_ROLE) -n $(TARGET_NAMESPACE) --serviceaccount $(NAMESPACE):$(SERVICE_ACCOUNT) --clusterrole $(SERVICE_LINK_ROLE)

	$(eval CURRENT_CONFIG := $(shell kubectl get configmap $(LB_CONFIG) -o jsonpath="{.data.servers}" -n $(NAMESPACE)))
	$(eval UPDATED_CONFIG := $(shell echo '$(CURRENT_CONFIG)' | jq -c -M '. += [{ "namespace": "$(TARGET_NAMESPACE)", "host": "$(TARGET_NAMESPACE_HOST)" }]'))
	$(eval UPDATED_CONFIG_WITH_ESCAPED_QUOTES := $(shell echo '$(UPDATED_CONFIG)' | sed 's/"/\\"/g'))
	kubectl patch configmap $(LB_CONFIG) -p '{"data":{"servers":"$(UPDATED_CONFIG_WITH_ESCAPED_QUOTES)"}}' -n $(NAMESPACE)

deploy_lb_unlink_service_account:
	jq --version
	kubectl delete rolebinding $(SERVICE_LINK_ROLE) -n $(TARGET_NAMESPACE)
	kubectl delete clusterrole $(SERVICE_LINK_ROLE) -n $(NAMESPACE)

	$(eval CURRENT_CONFIG := $(shell kubectl get configmap $(LB_CONFIG) -o jsonpath="{.data.servers}" -n $(NAMESPACE)))
	$(eval UPDATED_CONFIG := $(shell echo '$(CURRENT_CONFIG)' | jq -c -M 'del(.[] | select(.namespace == "$(TARGET_NAMESPACE)"))'))
	$(eval UPDATED_CONFIG_WITH_ESCAPED_QUOTES := $(shell echo '$(UPDATED_CONFIG)' | sed 's/"/\\"/g'))
	kubectl patch configmap $(LB_CONFIG) -p '{"data":{"servers":"$(UPDATED_CONFIG_WITH_ESCAPED_QUOTES)"}}' -n $(NAMESPACE)

deploy_lb_create:
	kubectl create -f ../k8s/load_balancer.yaml --save-config -n $(NAMESPACE)

deploy_lb_update:
	kubectl apply -f ../k8s/load_balancer.yaml --save-config -n $(NAMESPACE)

deploy_lb_delete:
	kubectl delete -f ../k8s/load_balancer.yaml -n $(NAMESPACE)

deploy_lb_monitor_rollout:
	kubectl rollout status deployment/jonline-lb -n $(NAMESPACE)

deploy_lb_restart:
	kubectl rollout restart deployment jonline-lb -n $(NAMESPACE)

deploy_lb_get_ip:
# Suppress echoing this so 'make deploy_lb_get_ip` is easily composable.
	@kubectl get service jonline-lb -n $(NAMESPACE) | sed -n 2p | awk '{print $$4}'

# Useful things
deploy_ensure_namespace:
	- kubectl create namespace $(NAMESPACE)
