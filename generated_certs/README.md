# Generated Certs for Jonline
This folder contains the CA cert (`ca.pem`) and server cert (`server.pem`) for Jon's official Jonline instance (be.jonline.io). To secure Jonline on your own domain, you can either contact me to use my custom CA (i.e. ask me to use my `ca.key` to generate you a `server.pem` and `server.key`) or use your own CA (i.e. generate and use your own `ca.key`).

## Get certs from my own CA
If you contact me ([Jon Latané](mailto:jonlatane@gmail.com)) I'm happy to generate you a `server.pem` and `server.key` with my CA. Make sure to specify the domain name you want the certs for (it can be a wildcard). (Note `*.key` files are `.gitignore`d in this repo.) With a cert from me, the Jonline app (for Android and iOS) will work, secured, for your instance with no extra configuration.

1. Ensure this directory has a `server.key` and your updated `server.pem` from me.
2. From the root of the repo, `make store_certs_in_kubernetes restart_be_deployment` to use my certs.
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