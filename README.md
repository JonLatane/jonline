# Jonline

Federated, GPLv3 gRPC social network implemented with Rust/Tonic.

The goal of Jonline is to provide an open-source server+client for maintaining a small, localized social network. A central goal is to make Jonline dogshit easy for anyone else to fork and deploy to their own server. Assuming you can get a few boring, standard, inexpensive prerequisites set, you should be able to clone this repo and have Jonline up and running in a matter of minutes.

For the prerequisites, you only need setup on your end:

* A Kubernetes (k8s) cluster
* An empty PostgreSQL database
* (Optional) memcached instance (you can use one on k8s)
* (Optional for development) A Docker registry you can push images to

Why this goal for this project? See [Scaling via Federation](#scaling-via-federation).

## Motivations
Current social media and messaging solutions all kind of suck. In many ways, and in spite of his character issues, Richard Stallman was generally right about many of the problems social computing presents today. If we trust applications with closed source run on private Alphabet, Meta, Apple, etc. servers, *of course we're going to get the disinformation and effective-advertising-driven consumerism that plague the world today*. But of course, these models are great for building a profitable company that can return value to shareholders.

At the same time as the closed source/private server model has grown due to its profitability, software complexity has grown immensely, but largely unnecessarily, to handle scaling modern applications. MapReduce across a huge privately-owned cluster is absolutely useful for making the entire Internet searchable. But for communicating with a network of friends you know in real life, I don't really think it's necessary. Jonline is an attempt to prove this.

## Scaling via Federation

I (Jon 😊👋) run the Jonline server at https://jonline.io, but 


## Building and running locally
Use `cargo build` and `cargo run` to run against your local database and memcached.

## Deploying
A Dockerfile for a build server (to build for Linux server images) lives in `dockers/build`. You don't really need to know the technical details though. The `Makefile` may contain additional targets, though this list should be comprehensive for general usage.

### Deploying the Pre-Built Image
Pre-built images are available to deploy from `docker.io/jonlatane`. Once you've cloned this repo, even without Rust, you can simply `make create_deployment` to deploy a pre-built image. Other useful deployment commands include:
* `make update_deployment` to update to the latest version.
* `make delete_deployment` to remove your deployment.
* `make restart_deployment` to restart your deployment.
* `make get_deployment_pods` to get the pods from your deployment.

### Building and Deploying Your Own Image
If you're interested in building your own version of Jonline, you must fork this repo and have your own Docker registry. The registry can be private as long as your k8s cluster can talk to it. You must update `kubernetes.yaml` and the `Makefile` to point at your registry.

#### Create a Local Registry to host Build Image
`make create_local_registry` will setup a local container registry, named `local-registry`. You only need to do this once, or if you delete the registry. Other local registry management commands include:
* `make stop_local_registry` to stop the registry container
* `make destroy_local_registry` to delete the registry container.

#### Build the `jonline-build` Image
`make build_jonline_build` will build the `jonline-build` image and upload it to your, which we use to build the images we will deploy. This allows you to build imaes for Linux servers from you macOS or Windows laptop. You only need to do this once, or if `dockers/build/Dockerfile` has been updated.

#### Build an Image to Deploy
1. First, update `CLOUD_REGISTRY` in the `Makefile` to point to your registry. You will not be able to push to `docker.io/jonlatane` 🚫.
2. `make release` will build your release (essentially, `target/release/jonline_tonic`).
3. `make push_release_cloud` will build the image and upload it to your Docker registry. The version will match that in the `Cargo.toml`.
    * Be careful! If you built with `cargo build --release` and not `make release`, you could end up creating a useless Linux Docker image with a macOS or Windows `jonline-tonic` binary.

#### Deploying your image
Make sure to update `kubernetes.yaml` and the `Makefile` to point at your docker registry. As with the local build, you can simply `make create_deployment` to launch your forked Jonline.