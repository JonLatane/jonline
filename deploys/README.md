## Jonline Deploys

Jonline is designed so you can simply create a fork of Jonline for your own deployment.
Jonline deploys are done from the `./deploys` directory from the root of the repo.

To deploy to your server:

* Clone this repo.
* `cd deploys && make deploy_data_create deploy_be_create` to create backing Postgres and MinIO/S3 instances and your BE instance. (You actually don't have to `cd deploys` because the main `Makefile` has some passthroughs!)
    * For "production-ready" performance you can (and should) configure external, managed Postgres and/or MinIO/S3 servers.

See [Generated Certs](./generated_certs/README.md) for more info on generating certs. At a high level, for a K8s deploy, `generated_certs/Makefile` will simply generate Cert-Manager K8s YAML to `deploys/generated_certs/k8s/cert-manager.\[digitalocean\].\[my-domain.com\].generated.yaml`. Applying that YAML (also doable through the `Makefile`) sets up K8s/Cert-Manager to auto-generate the certs for your Jonline instance in its namespace where it will look for them.