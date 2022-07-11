# Jonline Backend

The backend of Jonline is built with Rust, Tonic, Diesel, PostreSQL and Memcached.

## Building and running locally
Use `cargo build` and `cargo run` to run against your local database and memcached.

## Deploying
The quickest way to deploy is to simply run `make create_db_deployment create_be_deployment`. This will create a database and two `jonline` service replicas in your Kubernetes cluster.

### Deploying the Pre-Built Image
Pre-built images are available to deploy from `docker.io/jonlatane`. Once you've cloned this repo, even without Rust, you can simply `make create_be_deployment` to deploy a pre-built image. Other useful deployment commands include:
* `make update_be_deployment` to update to the latest version.
* `make delete_be_deployment` to remove your deployment.
* `make restart_be_deployment` to restart your deployment.
* `make get_be_deployment_pods` to get the pods from your deployment.

### Building and Deploying Your Own Image
If you're interested in building your own version of Jonline, you must fork this repo and have your own Docker registry. The registry can be private as long as your k8s cluster can talk to it. You must update the [`image` in `k8s/jonline.yaml`](https://github.com/JonLatane/jonline/blob/main/backend/k8s/jonline.yaml#L32) and the [`CLOUD_REGISTRY` in `Makefile`](https://github.com/JonLatane/jonline/blob/main/Makefile#L5) to point at your registry.

A Dockerfile for a build server (to build `jonline` Linux x86 server images on whatever desktop you use) lives in `docker/build`. We will use it throughout the following build steps.

#### Create a Local Registry to host Build Image
`make create_local_registry` will setup a local container registry, named `local-registry`. You only need to do this once, or if you delete the registry. Other local registry management commands include:
* `make stop_local_registry` to stop the registry container.
* `make destroy_local_registry` to delete the registry container.

#### Build the `jonline-build` Image
`make push_builder_local` will build the `jonline-build` image and upload it to your local registry, which we use to build the images we will deploy. This allows you to build imaes for Linux servers from you macOS or Windows laptop. You only need to do this once, or if `docker/build/Dockerfile` has been updated.
* If you want to modify `jonline-build` and use/share it, `make push_builder_cloud` will push it to your remote `CLOUD_REGISTRY` you set in the `Makefile`.

#### Build an Image to Deploy
1. First, update `CLOUD_REGISTRY` in the `Makefile` to point to your registry. You will not be able to push to `docker.io/jonlatane` 🚫.
2. `make release` will build your release (essentially, `backend/target/release/jonline`).
3. `make push_release_cloud` will build the image and upload it to your Docker registry. The version will match that in the `Cargo.toml`.
    * Be careful! If you built with `cargo build --release` and not `make release`, you could end up creating a useless Linux Docker image with a macOS or Windows `jonline` binary.
    * You can also `make push_release_local` and test running the image from your local repo before pushing it to your cloud repo.

#### Deploying your image
Make sure to update `k8s/jonline.yaml` and the `Makefile` to point at your docker registry. As with the local build, you can simply `make create_be_deployment` to launch your forked Jonline.