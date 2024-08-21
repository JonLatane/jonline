# Jonline Deploys

- [Jonline Deploys](#jonline-deploys)
  - [Basic Deployment](#basic-deployment)
    - [Deploying to namespaces other than `jonline`](#deploying-to-namespaces-other-than-jonline)
  - [Validating your deployment](#validating-your-deployment)
    - [Kubernetes service statuses](#kubernetes-service-statuses)
      - [External IP Management](#external-ip-management)
  - [Pointing a domain at your deployment](#pointing-a-domain-at-your-deployment)
  - [Securing your deployment](#securing-your-deployment)
  - [Deleting your deployment](#deleting-your-deployment)
  - [Multiple Deployments](#multiple-deployments)
    - [Jonline Balancer of Loads (JBL), a load balancer for Kubernetes](#jonline-balancer-of-loads-jbl-a-load-balancer-for-kubernetes)
    - [Example Kubernetes Cluster Setups](#example-kubernetes-cluster-setups)
      - [K8s cluster with multiple Kubernetes LoadBalancers (without JBL)](#k8s-cluster-with-multiple-kubernetes-loadbalancers-without-jbl)
      - [K8s cluster with multiple Jonline servers/deployments behind a single JBL LoadBalancer](#k8s-cluster-with-multiple-jonline-serversdeployments-behind-a-single-jbl-loadbalancer)

Rather than requiring Helm, Ansible, Terraform, or other orchestration layers, Jonline deployment goes a more primitive route. Jonline deployment is built so you can simply maintain one cloned Jonline repo per cluster whose deployments you want to manage. Within your cluster's repo, you'll simply use `make` to deploy:

* Clone this repo.
* `cd deploys && make deploy_data_create deploy_be_create` to create backing Postgres and MinIO/S3 instances and your BE instance. (You actually don't have to `cd deploys` because the main `Makefile` has some passthroughs!)
    * This deploys Postgres, MinIO and Jonline to the namespace `jonline` in your cluster. You can `NAMESPACE=mynamespace make deploy_data_create deploy_be_create` to create your setup in `mynamespace`.
    * For "production-ready" performance you can (and should) skip the `deploy_data_create` part and instead configure external, managed Postgres and/or MinIO/S3 servers.

See [the Cert-Manager integration README](./generated_certs/README.md) for more info on generating certs. At a high level, for a K8s deploy, `generated_certs/Makefile` will simply generate Cert-Manager K8s YAML to `deploys/generated_certs/k8s/cert-manager.\[digitalocean\].\[my-domain.com\].generated.yaml`. Applying that YAML (also doable through the `Makefile`) sets up K8s/Cert-Manager to auto-generate the certs for your Jonline instance in its namespace where it will look for them.

As a user or a contributor, it's helpful to understand that Jonline deployment is built upon:

* `make` and the `Makefile` targets in this `deploys/` directory and its subdirectories, which use/require:
  * `sed`
  * `jq`
  * `kubectl`
* `Dockerfile`s in `deploys/docker`
  * As a user, these are really just for reference, as you'll likely be deploying pre-built images from [jonlatane/jonline](https://hub.docker.com/r/jonlatane/jonline).
* Kubernetes `.yml` files in `deploys/k8s` and `deploys/generated_certs/k8s` (for using Jonline's Cert-Manager integration)
  * `.template.yml` files are used to generate `.yml` files for managing your own deployment.
* 

Virtually all deployment-related targets will involve `make` calling `kubectl` with either predefinied `.yml`, or after modifying `.template.yml` files.

## Basic Deployment
By following these instructions, you will bring up one namespace as diagrammed here in your Kubernetes cluster:

[K8s cluster with multiple Kubernetes LoadBalancers](#k8s-cluster-with-multiple-kubernetes-loadbalancers)

If you have `kubectl` and `make`, you can be setup in a few minutes. (If you're looking for a quick, fairly priced, scalable Kubernetes host, [I recommend DigitalOcean](https://m.do.co/c/1eaa3f9e536c).) First make sure `kubectl` is setup correctly and your instance has the `jonline` namespace available with `kubectl get services` and `kubectl get namespace jonline`:

```bash
$ kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.245.0.1   <none>        443/TCP   161d
$ kubectl get namespace jonline
Error from server (NotFound): namespaces "jonline" not found
```

To begin setup, first clone this repo:

```bash
git clone https://github.com/JonLatane/jonline.git
cd jonline
```

Next, from the repo root, to create Postgres, Minio and two load-balanced Jonline servers in the namespace `jonline` (plus a few recurring jobs), run:

```bash
# THIS STEP WILL COST MONEY WITH MOST KUBERNETES PROVIDERS. ($12/mo. at DigitalOcean)
# The deploy_be_external_create Make target, specifically, will create the Joline service as a K8s LoadBalancer.
# Of course, it costs nothing to use Minikube.
# To deploy for use with a different ingress (say, a shared nginx, or Jonline's pending internal LB), use deploy_be_internal_create or deploy_be_internal_insecure_create to deploy it as a K8s ClusterIP instead.
make deploy_data_create deploy_be_external_create
```

That's it! You've created Minio and Postgres servers along with an *unsecured Jonline instance* where ***passwords and auth tokens will be sent in plain text*** (You should secure it immediately if you care about any data/people, but feel free to play around with it until you do! Simply `make deploy_data_delete deploy_data_create_external deploy_be_restart` to reset your server's data.) Because Jonline is a very tiny Rust service, it will all be up within seconds. Your Kubenetes provider will probably take some time to assign you an IP, though.

### Deploying to namespaces other than `jonline`
To deploy anything to a namespace other than `jonline`, simply add the environment variable `NAMESPACE=my_namespace`. So, for the initial deploy, `NAMESPACE=my_namespace make deploy_data_create deploy_be_external_create` to deploy to `my_namespace`. This should work for any of the `make deploy_*` targets in Jonline.

## Validating your deployment
### Kubernetes service statuses
To see *everything* you just deployed (minio, postgres, Jonline server and background cron jobs), run `make deploy_get_all`. It should look something like this (with fewer jobs after a fresh install, probably):

```bash
$ make deploy_get_all
kubectl get all -n jonline
NAME                                                  READY   STATUS        RESTARTS   AGE
pod/delete-expired-tokens-27742795--1-nlkh6           0/1     Completed     0          11m
pod/delete-expired-tokens-27742800--1-tpplp           0/1     Completed     0          6m49s
pod/delete-expired-tokens-27742805--1-dgrsb           0/1     Completed     0          109s
pod/generate-preview-images-27721161--1-2hqgq         0/1     Error         0          15d
pod/generate-preview-images-27721161--1-6fwvq         0/1     Error         0          15d
pod/generate-preview-images-27721161--1-kxtvt         0/1     Error         0          15d
pod/generate-preview-images-27721161--1-mpnbv         0/1     Error         0          15d
pod/generate-preview-images-27721161--1-sg7rz         0/1     Error         0          15d
pod/generate-preview-images-27721161--1-t24th         0/1     Error         0          15d
pod/generate-preview-images-27742804--1-q8vdn         0/1     Completed     0          2m49s
pod/generate-preview-images-27742805--1-tbbvm         0/1     Completed     0          109s
pod/generate-preview-images-27742806--1-qrrnx         0/1     Completed     0          49s
pod/jonline-7f69759bd7-x64nd                          1/1     Running       0          30s
pod/jonline-7f69759bd7-x6scq                          1/1     Running       0          36s
pod/jonline-c4b798878-l6xhk                           1/1     Terminating   0          53m
pod/jonline-c4b798878-tg5qf                           1/1     Terminating   0          53m
pod/jonline-expired-token-cleanup-27742795--1-l8fzs   0/1     Completed     0          11m
pod/jonline-expired-token-cleanup-27742800--1-x6gch   0/1     Completed     0          6m49s
pod/jonline-expired-token-cleanup-27742805--1-hd2wj   0/1     Completed     0          109s
pod/jonline-minio-84685f9bd4-8knxq                    1/1     Running       0          4d22h
pod/jonline-postgres-bf6cb7679-l6mcb                  1/1     Running       0          53m

NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                                                     AGE
service/jonline            LoadBalancer   10.245.199.164   178.128.137.194   27707:30679/TCP,443:32401/TCP,80:30932/TCP,8000:30414/TCP   20d
service/jonline-minio      LoadBalancer   10.245.220.21    174.138.106.145   9000:32603/TCP                                              2d
service/jonline-postgres   ClusterIP      10.245.198.74    <none>            5432/TCP                                                    53m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/jonline            2/2     2            2           20d
deployment.apps/jonline-minio      1/1     1            1           4d22h
deployment.apps/jonline-postgres   1/1     1            1           53m

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/jonline-54d8b475bb           0         0         0       4d6h
replicaset.apps/jonline-6b6655cd79           0         0         0       2d23h
replicaset.apps/jonline-6bb49b7c9c           0         0         0       24h
replicaset.apps/jonline-6c8899f68c           0         0         0       4d2h
replicaset.apps/jonline-6f5c8955f7           0         0         0       3d22h
replicaset.apps/jonline-74557695b            0         0         0       2d23h
replicaset.apps/jonline-77585dcf8            0         0         0       3d20h
replicaset.apps/jonline-7bff45979c           0         0         0       4d6h
replicaset.apps/jonline-7f69759bd7           2         2         2       38s
replicaset.apps/jonline-7f6d9d4cbd           0         0         0       3d23h
replicaset.apps/jonline-c4b798878            0         0         0       53m
replicaset.apps/jonline-minio-84685f9bd4     1         1         1       4d22h
replicaset.apps/jonline-postgres-bf6cb7679   1         1         1       53m

NAME                                          SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/delete-expired-tokens           */5 * * * *   False     0        113s            15d
cronjob.batch/generate-preview-images         * * * * *     False     0        53s             15d
cronjob.batch/jonline-expired-token-cleanup   0/5 * * * *   False     0        113s            20d

NAME                                               COMPLETIONS   DURATION   AGE
job.batch/delete-expired-tokens-27742795           1/1           4s         11m
job.batch/delete-expired-tokens-27742800           1/1           4s         6m53s
job.batch/delete-expired-tokens-27742805           1/1           4s         113s
job.batch/generate-preview-images-27721161         0/1           15d        15d
job.batch/generate-preview-images-27742804         1/1           1s         2m53s
job.batch/generate-preview-images-27742805         1/1           4s         113s
job.batch/generate-preview-images-27742806         1/1           1s         53s
job.batch/jonline-expired-token-cleanup-27721007   0/1           15d        15d
job.batch/jonline-expired-token-cleanup-27742795   1/1           4s         11m
job.batch/jonline-expired-token-cleanup-27742800   1/1           5s         6m53s
job.batch/jonline-expired-token-cleanup-27742805   1/1           4s         113s
```

#### External IP Management
Use `make deploy_be_external_get_ip` to see what your service's external IP is (until set, it will return `<pending>`).

```bash
$ make deploy_be_external_get_ip
188.166.203.133
```

Finally, once the IP is set, to test the service from your own computer, use `make deploy_test_be_unsecured` to run tests against that external IP (you need `grpcurl` for this; `brew install grpcurl` works for macOS):

```bash
$ make deploy_test_be
Getting services on target server...
grpcurl -plaintext 188.166.203.133:27707 list
grpc.reflection.v1alpha.ServerReflection
jonline.Jonline

Getting Jonline service version...
grpcurl -plaintext 188.166.203.133:27707 jonline.Jonline/GetServiceVersion
{
  "version": "0.1.18"
}

Getting available Jonline RPCs...
grpcurl -plaintext 188.166.203.133:27707 list jonline.Jonline
jonline.Jonline.CreateAccount
jonline.Jonline.GetCurrentUser
jonline.Jonline.GetServiceVersion
jonline.Jonline.Login
jonline.Jonline.AccessToken
```

That's it! You're up and running, although again, *it's an unsecured instance* where ***passwords and auth tokens will be sent in plain text***. Get that thing secured before you go telling people to use it!

## Pointing a domain at your deployment
Before you can secure with LetsEncrypt, you need to point a domain at your Jonline instance's IP. Again, you can get the IP with `make deploy_be_external_get_ip`, and create your DNS records with your DNS provider. If you're choosing a DNS provider, it's worth noting that [I recommend DigitalOcean DNS (sponsored link)](https://m.do.co/c/1eaa3f9e536c) and Jonline has scripts for it. However, any [Cert-Manager](http://cert-manager.io) supported DNS provider (for the LetsEncrypt dns01 challenge) should be pretty easy to set up.

Continue to the next section for more info about setting up encryption and its relation to your DNS provider.

## Securing your deployment
Jonline uses 🐕💩EZ, boring normal TLS certificate management to negotiate trust around its decentralized social network. If you're using DigitalOcean DNS you can be setup in a few minutes.

See [`deploys/generated_certs/README.md`](https://github.com/JonLatane/jonline/tree/main/deploys/generated_certs) for quick TLS setup instructions, either [using Cert-Manager (recommended)](https://github.com/JonLatane/jonline/blob/main/deploys/generated_certs/README.md#use-cert-manager-recommended), [some other CA](https://github.com/JonLatane/jonline/blob/main/deploys/generated_certs/README.md#use-certs-from-another-ca) or [your own custom CA](https://github.com/JonLatane/jonline/blob/main/generated_certs/README.md#use-your-own-custom-ca) (i.e. to distribute a secure, network-specific Flutter app and only let users in through that - custom CAs would break/disable the web app entirely).

See [`backend/README.md`](https://github.com/JonLatane/jonline/blob/main/backend/README.md) for more detailed descriptions of how the deployment and TLS system works.

## Deleting your deployment
You can delete your Jonline deployment piece by piece with `make deploy_be_delete deploy_db_delete` or simply `kubectl delete namespace jonline` assuming you deployed to the default namespace `jonline`. Otherwise, assuming you deployed to `my_namespace`, run `NAMESPACE=my_namespace make deploy_be_delete deploy_db_delete` or simply `kubectl delete namespace my_namespace`.


## Multiple Deployments
As mentioned in [Deploying to namespaces other than `jonline`](#deploying-to-namespaces-other-than-jonline): to deploy anything to a namespace other than `jonline`, simply add the environment variable `NAMESPACE=my_namespace`. So, for the initial deploy, `NAMESPACE=my_namespace make deploy_data_create deploy_be_external_create` to deploy to `my_namespace`. This should work for any of the `make deploy_*` targets in Jonline.

Note that multiple *external* deployments will each have a Kubernetes LoadBalancer. On many providers, this is relatively expensive (an external IP, $12/mo on DigitalOcean). Other Makefile targets include `deploy_be_internal_create` and `deploy_be_internal_insecure_create` (the latter of which will specifically ignore K8s-stored TLS certificates, to save CPU time by not encrypting interal services).

It should be possible to manage many Jonline instances using Nginx and any preferred certificate management scheme you'd like as a sysadmin. Additionally, JBL is a somewhat novel, 

### Jonline Balancer of Loads (JBL), a load balancer for Kubernetes
Jonline Balancer of Loads will be a dedicated Kubernetes LoadBalancer designed to use K8s secrets named `jonline-tls` to LoadBalance K8s services named `jonline` on ports 80, 443, 8000, and 27707 (Jonline's service ports) from across a variety of namespaces.

This feature is incomplete, but the `Makefile` scripts (that simply run `kubectl` and `jq` to manage configuration) are.

Envisioned functionality: the final JBL binary should be able to both spawn an Nginx server that's. But to start with, whichever is easier would be a welcome contribution from anyone who thinks they could contribute it!

### Example Kubernetes Cluster Setups
#### K8s cluster with multiple Kubernetes LoadBalancers (without JBL)
This is how Jonline is currently deployed.

![K8s cluster with multiple Kubernetes LoadBalancers](https://github.com/JonLatane/jonline/blob/main/docs/architecture/Kubernetes_Deployment.svg)

#### K8s cluster with multiple Jonline servers/deployments behind a single JBL LoadBalancer
Not yet implemented; an ongoing dev effort (that welcomes outside contributions)! See [the GitHub issue for more information](https://github.com/JonLatane/jonline/issues/15).
![System with multiple Kubernetes LoadBalancers](https://github.com/JonLatane/jonline/blob/main/docs/architecture/JBL_Kubernetes_Deployment.svg)
