# Generated Certs for Jonline
This folder contains the CA cert (`ca.pem`) and server cert (`server.pem`) for Jon's official Jonline instance (be.jonline.io). To secure Jonline on your own domain, you can either use a wildcard cert from a legit CA (like LetsEncrypt), contact me to use my custom CA (i.e. ask me to use my `ca.key` to generate you a `server.pem` and `server.key`) or use your own CA (i.e. generate and use your own `ca.key`).

(Note that `*.key` files are `.gitignore`d in this repo.)

## Use Cert-Manager (recommended)
These instructions should at least get you a lazy wildcard setup for a domain managed by DigitalOcean.

1. Point your DNS host (for instance, I use `be.jonline.io`), at the IP for your deployed `jonline` LoadBalancer instance. For the default Quick Start deploy, get it with: `kubectl describe service jonline -n jonline | grep 'LoadBalancer Ingress'`.
2. [Install Cert-Manager](https://cert-manager.io/docs/installation/).
    * Currently their page says: `kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml`.
3. Securely store your DNS provider's credentials.
    1. Disable history in your shell.
        * For ZSH, `unset HISTFILE`.
    2. Generate and store your Cert-Manager-supported DNS provider's credentials.
        * DigitalOcean: [Get an access token here](https://cloud.digitalocean.com/account/api/tokens), then `kubectl create secret generic digitalocean-dns --from-literal=access-token=<your access token here> -n jonline`.
        * Other DNS providers: TBD. Google "`<your provider> cert-manager dns01 wildcard`" for a start!
            * Make a PR with your instructions here and a `backend/k8s/cert-manager.<your-provider>.template.yaml` for the next step!
4. Generate and apply your cert-manager authority and certificate.
    * DigitalOcean: `EMAIL=you@example.com TOP_LEVEL_CERT_DOMAIN=example.domain make generate_cert_manager_digitalocean create_certmanager_deployment_digitalocean`
5. Wait for your cert secret to be generated. In the default setup, it will appear in `get secret jonline-generated-tls -n jonline` once it's generated.
    * If something goes wrong, `kubectl describe certificate jonline-letsencrypt-cert -n jonline` to see details on what's going on with certificate generation.
6. `make deploy_be_restart` to use the cert-manager certificates.


## Use certs from an arbitrary legit CA
Perhaps you have a `server.pem` and `server.key` from your own CA. Make sure to specify the domain name you want the certs for (it can be a wildcard).

1. Ensure this directory has a `server.key` and your updated `server.pem` from your CA.
2. From the root of the repo, `make store_server_certs_in_kubernetes deploy_be_restart` to use my certs.
    * You can `make delete_certs_from_kubernetes deploy_be_restart` to switch back to non-TLS mode.

## Use your own custom CA
To deploy with your own custom CA (i.e. generate your own `ca.key` and overwrite the existing `ca.pem` with your own here):

1. Update `server.csr.conf` and `server.extfile.conf` to point to your domain. (If you ask me for a cert, I do this temporarily.)
2. From the root of the repo, `make generate_certs`.
    * This generates `ca.key`, `ca.pem`, `server.key`, and `server.pem`.
    * You can `make generate_ca_certs` or `make generate_server_certs` to generate either set of public/private keys independently. (If you ask me for a cert, I do the latter and send you the `server.key` and `server.pem`.)
3. Finally, `make store_certs_in_kubernetes` to store them, and `make deploy_be_restart` to restart your instance.
    * You can `make store_ca_certs_in_kubernetes` or `make store_server_certs_in_kubernetes` similarly.
4. You will need to provide both your `ca.pem` to end users if they use the official Jonline app. Alternatively, you could ship your own Jonline app with your own `ca.pem`.