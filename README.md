# Jonline

Federated gRPC social network implemented with Rust/Tonic.

The goal of Jonline is to provide an open-source server+client for maintaining a small, localized social network. A central goal is to make Jonline dogshit easy for anyone else to fork and deploy to their own server. Assuming you can get a few boring, standard, inexpensive prerequisites set, you should be able to clone this repo and have Jonline up and running in a matter of minutes.

For the prerequisites, you should have setup on your end:

* A Kubernetes (k8s) cluster
* An empty PostgreSQL database
* (Optional) memcached instance (you can use one on k8s)
* (Optional for development) A Docker registry you can push images to

Why this goal for this project? See [Scaling via Federation](#scaling-via-federation).

## Building and running locally
Use `cargo build` and `cargo run` to run against your local database and memcached.

## Deploying
A Dockerfile for a build server (to build for Linux server images) lives in `dockers/build`. You don't really need to know the technical details though. The `Makefile` may contain additional targets, though this list should be comprehensive for general usage.

### Deploying the Pre-Built Image
Pre-built images are available to deploy from `registry.digitalocean.com/jonline`. Once you've cloned this repo, even without Rust, you can simply `make create_deployment` to deploy a pre-built image. Other useful deployment commands include:
* `make update_deployment` to update to the latest version.
* `make delete_deployment` to remove your deployment.
* `make restart_deployment` to restart your deployment.
* `make get_deployment_pods` to get the pods from your deployment.

### Building and Deploying Your Own Image
If you're interested in doing this, you should fork this repo. You must update `kubernetes.yaml` and the `Makefile` to point at your own Docker registry rather than

#### Create a Local Registry to host Build Image
`make create_local_registry` will setup a local container registry, named `local-registry`. You only need to set it up once, or if `dockers/build/Dockerfile` has been updated. Other local registry management commands include:
* `make stop_local_registry` to stop the registry container
* `make destroy_local_registry` to delete the registry container.

#### Build an Image to Deploy

1. First, update `CLOUD_REGISTRY` in the `Makefile` to point to your registry. You will not be able to push to `registry.digitalocean.com/jonline` 🚫.
2. `make server_docker_cloud` to build the image and upload it to your tag registry. The version will match that in the `Cargo.toml`.

#### Deploying your image
Make sure to update `kubernetes.yaml` and the `Makefile` to point at your docker registry. As with the local build, you can simply `make create_deployment`

### Deploy your imae

## Scaling via Federation

I (Jon 😊👋) run the Jonline server at https://jonline.io, but 
