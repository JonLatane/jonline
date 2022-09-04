# Generated Certs for Jonline
This folder contains the CA cert (`ca.pem`) and server cert (`server.pem`) for Jon's official Jonline instance (be.jonline.io). To secure Jonline on your own domain, you can either use a wildcard cert from a legit CA (like LetsEncrypt), contact me to use my custom CA (i.e. ask me to use my `ca.key` to generate you a `server.pem` and `server.key`) or use your own CA (i.e. generate and use your own `ca.key`).

(Note that `*.key` files are `.gitignore`d in this repo.)

# Using Cert-Manager (recommended)
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
    * DigitalOcean: `EMAIL=my_email@example.com TOP_LEVEL_CERT_DOMAIN=my.domain.io make generate_cert_manager_digitalocean`
5. Wait for your cert secret to be generated. In the default setup, it will appear in `get secret jonline-generated-tls -n jonline` once it's generated.
6. `make restart_be_deployment` to use the cert-manager certificates.


## Use certs from an arbitrary "legit" CA or my own CA
If you contact me ([Jon Latané](mailto:jonlatane@gmail.com)) I'm happy to generate you a `server.pem` and `server.key` with my CA. You can also use LetsEncrypt, various ACME services, or whatever to generate your own cert/key pair (wildcard certs would be easiest to work with). Make sure to specify the domain name you want the certs for (it can be a wildcard). With a cert from me, the Jonline app (for Android and iOS) will work, secured, for your instance with no extra configuration.

1. Ensure this directory has a `server.key` and your updated `server.pem` from your CA.
2. From the root of the repo, `make store_[server_]certs_in_kubernetes restart_be_deployment` to use my certs.
    * If using a legit CA, just use `make store_server_certs_in_kubernetes` instead. If you accidentally messagegd up, just `make delete_ca_certs_from_kubernetes`.
    * You can `make delete_certs_from_kubernetes restart_be_deployment` to switch back to non-TLS mode.

## Using your own custom CA
To deploy with your own custom CA (i.e. generate your own `ca.key` and overwrite the existing `ca.pem` with your own here):

1. Update `server.csr.conf` and `server.extfile.conf` to point to your domain. (If you ask me for a cert, I do this temporarily.)
2. From the root of the repo, `make generate_certs`.
    * This generates `ca.key`, `ca.pem`, `server.key`, and `server.pem`.
    * You can `make generate_ca_certs` or `make generate_server_certs` to generate either set of public/private keys independently. (If you ask me for a cert, I do the latter and send you the `server.key` and `server.pem`.)
3. Finally, `make store_certs_in_kubernetes` to store them, and `make restart_be_deployment` to restart your instance.
    * You can `make store_ca_certs_in_kubernetes` or `make store_server_certs_in_kubernetes` similarly.
4. You will need to provide both your `ca.pem` to end users if they use the official Jonline app. Alternatively, you could ship your own Jonline app with your own `ca.pem`.