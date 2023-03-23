.NOTPARALLEL:

# Configure these variables to deploy/test the official Jonline images on your own cluster.
NAMESPACE ?= jonline

# Set these variables when setting up cert generation
CERT_MANAGER_PROVIDER ?= digitalocean
CERT_MANAGER_DOMAIN ?= jonline.io
CERT_MANAGER_EMAIL ?= invalid_email
CERT_MANAGER_API_TOKEN ?= invalid_token

# Certificate-related targets
deploy_be_get_certs:
	kubectl get secret jonline-generated-tls -n $(NAMESPACE)
deploy_be_get_ca_certs:
	kubectl get configmap jonline-generated-ca -n $(NAMESPACE)

deploy_certmanager:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

# Cert-Manager targets: These all revolve around generating a (.gitignored)
# cert-manager.*.generated.yaml from a cert-manager.*.template.yaml
deploy_certmanager_credential:
	$(MAKE) deploy_certmanager_credential_$(CERT_MANAGER_PROVIDER)_store_apitoken
	$(MAKE) deploy_certmanager_credential_$(CERT_MANAGER_PROVIDER)_prepare
	$(MAKE) deploy_certmanager_credential_$(CERT_MANAGER_PROVIDER)_apply
deploy_certmanager_credential_apply:
	$(MAKE) deploy_certmanager_credential_$(CERT_MANAGER_PROVIDER)_apply
deploy_certmanager_credential_clean:
	$(MAKE) deploy_certmanager_credential_$(CERT_MANAGER_PROVIDER)_clean

# DigitalOcean Cert-Manager targets
deploy_certmanager_credential_digitalocean_clean:
	rm k8s/cert-manager.digitalocean.*.generated.yaml
deploy_certmanager_credential_digitalocean_store_apitoken:
	kubectl create secret generic digitalocean-dns --from-literal=access-token=$(CERT_MANAGER_API_TOKEN) -n $(NAMESPACE)
deploy_certmanager_credential_digitalocean_prepare: k8s/cert-manager.digitalocean.$(CERT_MANAGER_DOMAIN).generated.yaml
k8s/cert-manager.digitalocean.$(CERT_MANAGER_DOMAIN).generated.yaml:
	cat k8s/cert-manager.digitalocean.template.yaml | \
	  sed 's/$${CERT_MANAGER_EMAIL}/$(CERT_MANAGER_EMAIL)/g' | \
	  sed 's/$${CERT_MANAGER_DOMAIN}/$(CERT_MANAGER_DOMAIN)/g' \
	  > k8s/cert-manager.digitalocean.$(CERT_MANAGER_DOMAIN).generated.yaml
deploy_certmanager_credential_digitalocean_apply: deploy_ensure_namespace deploy_certmanager_digitalocean_prepare
	kubectl apply -f k8s/cert-manager.digitalocean.$(CERT_MANAGER_DOMAIN).generated.yaml -n $(NAMESPACE)


# Custom CA certificate generation targets
certs_generate: certs_ca_generate certs_server_generate

certs_ca_generate:
	openssl req -x509 \
	          -sha256 -days 365 \
	          -nodes \
	          -newkey rsa:2048 \
	          -subj '/CN=$(CERT_MANAGER_DOMAIN)/C=US/L=Durham' \
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
