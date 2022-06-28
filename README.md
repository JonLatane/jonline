# Jonline

*Note: though you can [build](#building-and-running-locally) and [deploy](#deploying) the skeleton service documented here, Jonline is nowhere near fully implemented as documented here.*

Federated GPLv3 gRPC social network implemented with Rust/Tonic.

The goal of Jonline is to provide an open-source server+client for maintaining a small, localized social network. A central goal is to make Jonline dogshit easy (🐕💩EZ) for anyone else to deploy to their own server (and to fork and modify). Assuming you can get a few boring, standard, inexpensive prerequisites set, you should be able to clone this repo and have Jonline up and running in a matter of minutes.

For the prerequisites, you only need setup on your end:

* A Kubernetes (k8s) cluster
* An empty PostgreSQL database

Optionally, Jonline will also integrate with:
* A `memcached` instance (you can use one on k8s)

And to use a fork, you might also want:
* A Docker registry you can push images to (your DockerHub account is fine)

Why this goal for this project? See [Scaling Social Software via Federation](#scaling-social-software-via-federation).

## Motivations
Current social media and messaging solutions all kind of suck. In many ways, and in spite of his character issues, Richard Stallman was generally right about many of the problems social computing presents today. If we trust applications with closed source run on private Alphabet, Meta, Apple, etc. servers, *of course we're going to get the disinformation and effective-advertising-driven consumerism that plague the world today*. But of course, these models are great for building a profitable company that can return value to shareholders.

At the same time as the closed source/private server model has grown due to its profitability, software complexity has grown immensely, but largely unnecessarily, to handle scaling modern applications. MapReduce across a huge privately-owned cluster is absolutely useful for making the entire Internet searchable. But for communicating with a network of friends you know in real life, I don't really think it's necessary. Jonline is an attempt to prove this.

## Scaling Social Software via Federation
Jonline is a federated social network. The general idea is that it should provide a functional network with a single server, but that you should be able to communicate with users on other servers from a single account. This is handled via sharing of OAuth2 auth tokens between servers.

### Single-server usage
The intended use case for Jonline is thus:

I (Jon 😊👋) will run the Jonline server at https://jonline.io. It's fully open to the web and I'm paying for the DB behind it and the k8s cluster on it. Friends who want to connect with me can register for an account and communicate with me and with each other.

#### Posts
To keep things straightforward, all Posts in Jonline have global visibility. Twitter is easily the closest comparison.

#### Messages
Messages are understood to be private between individuals and not visible to other users. Private messaging is, of course, where the federated approach to Jonline does have some limitations.

##### Caveats
Crucially, with this model, *all my friends have to trust that I won't abuse being able to read their communications with each other*. A top priority after initial development of Jonline is to add an optional E2E encryption layer.

Why is E2E not the first priority? First, we must implement our client. To have E2E, we need a client to store decryption keys. And generally, the user must be responsible for storing their encryption keys themselves.

Once a client is implemented, it should be fairly straightforward to add E2E to the Messages feature in Jonline. But at the same time, it could be that this isn't something that needs solving, say, if support for linking into SMS/iMessage/WhatsApp is really a better solution for P2P messaging.

### Multi-server usage
Suppose you have two accounts with friends, say, on `jonline.io` and `bobline.com`. To federate your accounts, you may simply pass an `auth_token` from your `bobline.com` account that you use to talk to Bob (who I don't know) into `jonline.io`. The general idea is that users can choose to keep their primary account with the person they trust the most. Maybe it's not me 😭 But that's fine; I won't even know!

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