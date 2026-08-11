.NOTPARALLEL:

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline

# K8S_PROVIDER, CERT_MANAGER_DOMAIN, CERT_MANAGER_EMAIL and CERT_MANAGER_API_TOKEN
# are no longer configured via environment variables. The targets below that need
# them prompt for them interactively instead.

# Certificate-related targets
get_backend_generated_certs:
	kubectl get secret jonline-generated-tls -n $(NAMESPACE)
get_backend_generated_ca_certs:
	kubectl get configmap jonline-generated-ca -n $(NAMESPACE)

deploy_certmanager:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

# Cert-Manager targets: These all revolve around generating a (.gitignored)
# cert-manager.*.generated.yaml from a cert-manager.*.template.yaml
deploy_certmanager_credential:
	@read -p "Enter your Kubernetes provider (default: digitalocean): " k8s_provider; \
	k8s_provider=$${k8s_provider:-digitalocean}; \
	$(MAKE) deploy_certmanager_credential_$${k8s_provider}_store_apitoken; \
	$(MAKE) deploy_certmanager_credential_$${k8s_provider}_prepare; \
	$(MAKE) deploy_certmanager_credential_$${k8s_provider}_apply
deploy_certmanager_credential_apply:
	@read -p "Enter your Kubernetes provider (default: digitalocean): " k8s_provider; \
	$(MAKE) deploy_certmanager_credential_$${k8s_provider:-digitalocean}_apply
deploy_certmanager_credential_clean:
	@read -p "Enter your Kubernetes provider (default: digitalocean): " k8s_provider; \
	$(MAKE) deploy_certmanager_credential_$${k8s_provider:-digitalocean}_clean

# DigitalOcean Cert-Manager targets
deploy_certmanager_credential_digitalocean_clean:
	rm -f k8s/cert-manager.digitalocean.generated.yaml
deploy_certmanager_credential_digitalocean_store_apitoken:
	@read -s -p "Enter your Cert-Manager API token (hidden): " cert_manager_api_token; \
	echo; \
	cert_manager_api_token=$$(echo "$$cert_manager_api_token" | xargs); \
	kubectl create secret generic digitalocean-dns --from-literal=access-token="$$cert_manager_api_token" -n $(NAMESPACE)
deploy_certmanager_credential_digitalocean_prepare:
	@read -p "Enter your Cert-Manager domain: " cert_manager_domain; \
	read -p "Enter an administrator email for Cert-Manager: " cert_manager_email; \
	cat k8s/cert-manager.digitalocean.template.yaml | \
	  sed "s/\$${CERT_MANAGER_EMAIL}/$$cert_manager_email/g" | \
	  sed "s/\$${CERT_MANAGER_DOMAIN}/$$cert_manager_domain/g" \
	  > k8s/cert-manager.digitalocean.generated.yaml
deploy_certmanager_credential_digitalocean_apply: deploy_ensure_namespace
	kubectl apply -f k8s/cert-manager.digitalocean.generated.yaml -n $(NAMESPACE)
deploy_certmanager_credential_digitalocean_delete: deploy_ensure_namespace
	kubectl delete -f k8s/cert-manager.digitalocean.generated.yaml -n $(NAMESPACE)


# Custom CA certificate generation targets
certs_generate: certs_ca_generate certs_server_generate

certs_ca_generate:
	@read -p "Enter your Cert-Manager domain: " cert_manager_domain; \
	openssl req -x509 \
	          -sha256 -days 365 \
	          -nodes \
	          -newkey rsa:2048 \
	          -subj "/CN=$$cert_manager_domain/C=US/L=Durham" \
	          -keyout ca.key -out ca.pem

certs_server_generate:
	openssl genpkey -out server.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
	openssl req -new -key server.key -config server.csr.conf -out server.csr
	openssl x509 -req \
	  -in server.csr \
	  -CA ca.pem -CAkey ca.key \
	  -CAcreateserial -out server.pem \
	  -days 365 \
	  -sha256 -extfile server.extfile.conf

certs_store_in_k8s: certs_server_store_in_k8s certs_ca_store_in_k8s
certs_delete_from_k8s:
	- $(MAKE) certs_server_delete_from_k8s
	- $(MAKE) certs_ca_delete_from_k8s

certs_server_store_in_k8s:
	kubectl create secret tls jonline-generated-tls --cert=server.pem --key=server.key -n $(NAMESPACE)
certs_server_delete_from_k8s:
	kubectl delete secret jonline-generated-tls -n $(NAMESPACE)
certs_ca_store_in_k8s:
	kubectl create configmap jonline-generated-ca --from-file ca.crt=ca.pem -n $(NAMESPACE)
certs_ca_delete_from_k8s:
	kubectl delete configmap jonline-generated-ca -n $(NAMESPACE)

# Custom CA cert testing targets
certs_gen_test: certs_gen_test_pass_openssl_verify
certs_gen_test_pass_openssl_verify:
	openssl verify -CAfile ca.pem server.pem

# Useful things
deploy_ensure_namespace:
	- kubectl create namespace $(NAMESPACE)
