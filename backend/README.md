# Jonline Backend

| CI Status | Information |
|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ![Rust Build Badge](https://github.com/jonlatane/jonline/actions/workflows/backend.yml/badge.svg)    | [Rust Build Results](https://github.com/jonlatane/jonline/actions/workflows/backend.yml)    |

- [Jonline Backend](#jonline-backend)
  - [gRPC implementation](#grpc-implementation)
  - [Build and release management](#build-and-release-management)
  - [Architecture \& Data](#architecture--data)
    - [Marshaling Data](#marshaling-data)
      - [Media Data](#media-data)
  - [Building and running locally](#building-and-running-locally)
    - [Unit testing](#unit-testing)
    - [Local integration testing](#local-integration-testing)
  - [Deploying](#deploying)
    - [Deploying with TLS support](#deploying-with-tls-support)
    - [Testing your (or any) deployment](#testing-your-or-any-deployment)
  - [Building and Deploying Your Own Image](#building-and-deploying-your-own-image)
      - [Create a Local Registry to host Build Image](#create-a-local-registry-to-host-build-image)
      - [Build the `jonline-be-build` Image](#build-the-jonline-be-build-image)
      - [Build an Image to Deploy](#build-an-image-to-deploy)
      - [Deploying your image](#deploying-your-image)


The backend of Jonline is built in Rust, with [Tonic](https://github.com/hyperium/tonic), [Rocket](http://rocket.rs), and [Diesel](https://diesel.rs), atop PostreSQL. A Tonic thread serves up the Jonline gRPC backend on port 27707, while Rocket threads serve up the Flutter Web frontend on ports 80, 8000, and 443 if TLS is configured.

## gRPC implementation
Jonline's BE uses [Tonic](https://github.com/hyperium/tonic), which uses [Prost](https://github.com/tokio-rs/prost) for Protobuf codegen. The BE implementation is unique from the FE implementations in that the BE codebase does *not* include the generated client/structs/traits/etc. Instead, the `.proto` files themselves integrate into the Cargo build system to essentially function as `.rs` source files to the build system. (In contrast, Flutter/Dart client code is generated into `frontends/flutter/lib/generated`, while TypeScript client code is generated into `frontends/tamagui/packages/api/generated`.)

## Build and release management
Most of the high-level Jonline backend build management lives in `../Makefile`.
For instance, for me, after incremention the version in `Cargo.toml`, I generally run the following to build/push a release to Dockerhub and deploy to both [jonline.io](https://jonline.io) and [get.jonline](https://getj.online):

```bash
make release_be_cloud deploy_be_external_update && NAMESPACE=getjonline make deploy_be_external_update && say 'deploy complete'
```

As an end user, once you've set up per the quick setup, you can simply run this to apply updates:

```bash
git pull && make deploy_be_external_update
```

Until Jonline is fairly complete, I'm not bothering with migrations. Be prepared to reset data until then. To reset your database/minio (if you're using the K8s one and not a managed DB):

```bash
make deploy_db_delete deploy_db_create deploy_minio_delete deploy_minio_create deploy_be_restart
```

or, more succinctly:

```bash
make deploy_data_delete deploy_data_create deploy_be_restart
```

## Architecture & Data

Jonline BE is, fundamentally, mostly a dumb Diesel-DB-model to Prost-gRPC-interface translator that respects permissions¹. The two fundamental modules to understand are [`models`](https://github.com/JonLatane/jonline/tree/main/backend/src/models) (the Diesel ORM models and related access methods) and [`protos`](https://github.com/JonLatane/jonline/tree/main/backend/src/protos) (the generated gRPC models/server trait/client interface [unused in the BE for now]). Most of Jonline's BE code is a matter of transforming between `models::DieselType` (say, `models::Post`) and `protos::GrpcType` (say, `protos::Post`).

In many cases, like server configuration, Jonline BE uses [serde](https://serde.rs) (Rust JSON) along with [prost](https://github.com/tokio-rs/prost) (Rust Protobuf, the core/encoding layer for [Tonic](https://github.com/hyperium/tonic)) and [diesel](https://diesel.rs) (Rust DB) to transform data between Postgres JSONB columns and gRPC models.

Though it's only been started on, Jonline's API-model mappings are designed to be pretty deeply metaprogrammable with Rust. This could be a great contribution opportunity for other devs!

¹ *(**Mostly** respects permissions, except not on Media at all yet 😬😅. PRs for tests and/or fixes for permissions issues would make wonderful contributions!)*

### Marshaling Data

Just to differentiate from the "serializers" we're used to, and because it has fewer syllables, Jonline's serialization module is named [`marshaling`](https://github.com/JonLatane/jonline/tree/main/backend/src/marshaling). A keen observer may notice that the Protos have types that are derived from numerous DB sources. To keep things sane, Jonline uses the `Marshalable` prefix to denote types derived from multiple Diesel sources to straightforwardly convert them.

The basic things to know are:

* [`MarshalablePost`](https://github.com/JonLatane/jonline/tree/main/backend/src/marshaling/post_marshaling.rs) and [`MarshalableEvent`](https://github.com/JonLatane/jonline/tree/main/backend/src/marshaling/event_marshaling.rs) contain exactly the data from `models::Post`, `models::Author` (a subset of `models::User`), and `models::Event`.
* `MarshalablePost` has a vector of replies and is designed to facilitate multi-layer reply loading.
* A `MarshalableEvent` contains a `MarshalablePost`.

#### Media Data

Media data is designed to be loosely coupled from the rest of the system. There is a `media` table, but the `posts` table does not have a foreign key relationship with `media` (though `users` and `groups` do). To facilitate access, when using `Marshalable` types that may contain media, the `MediaLookup` type is provided.

Another way of thinking about this: the primary function of any Jonline RPC is to load Post, Event, and User data. After that, it loads `MediaReference`s in a separate pass for the entire result set, at marshaling time. So, conversion of any Jonline type to a


## Building and running locally
Use `cargo build` and `cargo run` from here (`backend/`) to run against your local database. `make build` and `make run` simply mirror these to avoid confusion. Make targets assume you have a fairly "normal" local Postgres setup with `createdb` and `dropdb` commands in your `PATH`.

### Unit testing
TBD. Should be a matter of doing a `cargo test`. Ideally there shoouldn't be so much logic that we *need* a lot of unit tests. This is kinda the point.

### Local integration testing
Some really dumb integration tests are provided in `backend/Makefile`. You need `grpc_cli` installed (`brew install grpc_cli`). `make test_list_services` and `make test_authentication` will test Jonline's gRPC reflection and the actual authentication locally with `grpc_cli`.

## Deploying
The quickest way to deploy is to simply run `make deploy_db_create deploy_be_create` from the root of this repo. This will create a database and two `jonline` service replicas in your Kubernetes cluster. No compilation required. Note that by default, Jonline will run without TLS, so passwords, tokens, and everything goes back and forth as plain text!

### Deploying with TLS support
1. Initial TLS Setup
    1. Generate a 100-char CA Cert password and two 20-char Challenge Passwords. Save these.
    2. `make certs_generate`
        * You need to answer at least one question; really, you should just answer everything fully here. But you do you.
        * Use the cert password and challenge passwords you saved above when prompted.
    3. `make certs_store_in_k8s`
        * The certs you generated will be stored in `secret tls jonline-generated-tls` and `configmap jonline-generated-ca` in your k8s.
2. `make deploy_db_create` to create a Postgres instance named `jonline-postgres` with credentials `admin:secure_password1`.
    * `make [update,restart,delete]_db_deployment` are all valid targets, too.
3. `make deploy_be_create` to deploy the Jonline backend.
    * `make [update,restart,delete]_be_deployment` and `make deploy_be_get_pods` are all valid targets, too.
4. Optional: Validate TLS setup
    1. `kubectl get pods` and get the ID of your first pod, say `jonline-646c9f8699-kthkr`.
        * Make sure the pods are freshly created from your deploy and Running.
    2. `kubectl logs <pod-id>` to view the logs. You should see the text `TLS successfully configured.`. If not, um... figure it out and make a PR! 😉
        * You can also [install `kail`](https://github.com/boz/kail#installing) and just `kail -d jonline` 🚀

### Testing your (or any) deployment
Once you've deployed, get the EXTERNAL-IP of your instance/community:

```sh
$ kubectl get services     
NAME               TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)           AGE
jonline            LoadBalancer   10.245.181.122   178.128.143.154   27707:31509/TCP   5d7h
jonline-postgres   ClusterIP      10.245.56.115    <none>            5432/TCP          38m
kubernetes         ClusterIP      10.245.0.1       <none>            443/TCP           106d
```

You should be able to `grpcurl 178.128.143.154:27707` list and see both Jonline and the gRPC reflection service (that lets you list services)! You can test against my instance with `grpcurl be.jonline.io:27707`. list

## Building and Deploying Your Own Image
If you're interested in building your own version of Jonline, you must fork this repo and have your own Docker registry. The registry can be private as long as your k8s cluster can talk to it. You must update the [`image` in `k8s/server_external.yaml`](https://github.com/JonLatane/jonline/blob/main/backend/k8s/server_external.yaml#L32) and the [`CLOUD_REGISTRY` in `Makefile`](https://github.com/JonLatane/jonline/blob/main/Makefile#L5) to point at your registry.

A Dockerfile for a build server (to build `jonline` Linux x86 server images on whatever desktop you use) lives in `docker/build`. We will use it throughout the following build steps.

#### Create a Local Registry to host Build Image
`make local_registry_create` will setup a local container registry, named `local-registry`. You only need to do this once, or if you delete the registry. Other local registry management commands include:
* `make local_registry_stop` to stop the registry container.
* `make local_registry_destroy` to delete the registry container.

#### Build the `jonline-be-build` Image
`make release_builder_push_local` will build the `jonline-be-build` image and upload it to your local registry, which we use to build the images we will deploy. This allows you to build imaes for Linux servers from you macOS or Windows laptop. You only need to do this once, or if `docker/build/Dockerfile` has been updated.
* If you want to modify `jonline-be-build` and use/share it, `make release_builder_push_cloud` will push it to your remote `CLOUD_REGISTRY` you set in the `Makefile`.

#### Build an Image to Deploy
1. First, update `CLOUD_REGISTRY` in the `Makefile` to point to your registry. You will not be able to push to `docker.io/jonlatane` 🚫.
2. `make release` will build your release (essentially, `backend/target/release/jonline`).
3. `make release_be_push_cloud` will build the image and upload it to your Docker registry. The version will match that in the `Cargo.toml`.
    * Be careful! If you built with `cargo build --release` and not `make release`, you could end up creating a useless Linux Docker image with a macOS or Windows `jonline` binary.
    * You can also `make release_be_push_local` and test running the image from your local repo before pushing it to your cloud repo.

#### Deploying your image
Make sure to update `k8s/server_external.yaml` and the `Makefile` to point at your docker registry. As with the local build, you can simply `make deploy_be_create` to launch your forked Jonline.