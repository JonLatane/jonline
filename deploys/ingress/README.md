# Jonline Ingress

A single shared [Traefik](https://traefik.io) ingress that lets many Jonline instances (each in its own namespace, each with its own domain, Postgres, MinIO and Cert-Manager certs) share **one** external IP/LoadBalancer instead of one each. On most cloud providers a LoadBalancer/external IP is the most expensive part of running a small Jonline instance, so this is the difference between paying for `N` of them and paying for 1, no matter how many domains you host.

This whole setup is domain-agnostic and cluster-agnostic: nothing you type here ends up in a file this repo tracks in git (same principle as [the Cert-Manager setup](../generated_certs/README.md), which never commits your actual domain either).

## How it works

Your `jonline` backend already terminates its own TLS (see `deploy_be_internal_create`/`deploy_be_internal_update` in `../Makefile`, and `k8s/server_internal.yaml`) using the Cert-Manager certs set up per [`../generated_certs/README.md`](../generated_certs/README.md). This ingress does **not** re-terminate that TLS. Instead it reads the plaintext SNI hostname out of the TLS handshake's first message (the same mechanism that lets any single IP host multiple HTTPS sites) to decide which namespace's `jonline` Service to forward the still-encrypted bytes to, then gets out of the way. Your certs, your `jonline-generated-tls` secrets, and Cert-Manager's renewal all keep working completely untouched, in their existing per-namespace locations.

Plain HTTP (ports 80 and 8000) is routed the normal way, by `Host` header.

Because of this, a domain's routing config is a handful of small `IngressRoute`/`IngressRouteTCP` objects that live in *that domain's own namespace* (see `k8s/jonline-routes.template.yaml`), right next to its `jonline` Service -- not in some central config. Traefik discovers them across every namespace automatically.

## One-time setup: install the shared controller

From this directory (or `deploys`, since the root `Makefile` has passthroughs -- see below):

```bash
make create_ingress
```

This installs Traefik's CRDs (pinned to `TRAEFIK_VERSION` at the top of the `Makefile`) and the Traefik `Deployment`/`Service` itself, in the `traefik-ingress` namespace. It's completely generic -- run it once per cluster, regardless of how many domains you plan to host.

Get its external IP with:

```bash
make deploy_ingress_get_ip
```

## Onboarding a domain

Once a namespace already has its own `jonline` backend, Postgres, MinIO and Cert-Manager certs set up (i.e. you've already done the [Basic Deployment](../README.md#basic-deployment) for it) and it's currently using `server_external.yaml` (its own LoadBalancer), you can move it behind the shared ingress:

```bash
NAMESPACE=mynamespace DOMAIN=my.domain.example.com make add_ingress_domain
```

**Before touching DNS**, validate the route directly against the shared ingress's IP (from `make deploy_ingress_get_ip`), for all 4 ports:

```bash
curl --resolve my.domain.example.com:443:<ingress-ip> https://my.domain.example.com/
curl --resolve my.domain.example.com:80:<ingress-ip>  http://my.domain.example.com/
grpcurl -authority my.domain.example.com <ingress-ip>:27707 list
```

Once that all looks right, point `my.domain.example.com`'s DNS A record at the shared ingress's IP. Only *after* traffic has actually moved over (watch it drain from the old LoadBalancer, or just wait out the old DNS TTL), switch that namespace off its own LoadBalancer to reclaim its cost:

```bash
NAMESPACE=mynamespace make deploy_be_internal_update
```

Doing this out of order -- switching off the old LoadBalancer before DNS has actually moved -- will take the site down until DNS propagates, so don't skip the validation step above.

To see every namespace/domain currently wired up to the shared ingress (queried live from the cluster, not from local files):

```bash
make list_ingress_domains
```

To remove a domain from the shared ingress (e.g. to move it back to its own LoadBalancer):

```bash
NAMESPACE=mynamespace DOMAIN=my.domain.example.com make remove_ingress_domain
```
