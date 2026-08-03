# Jonline Email

A single shared [Stalwart](https://stalw.art) mail server that lets your `jonline` instances receive mail at `<username>@yourdomain`, without teaching any of them to speak SMTP. Stalwart does the actual internet-facing mail protocol/spam-fighting work; it never stores a mailbox. Instead, once it accepts a message for one of your onboarded domains, it hands the raw message straight to that domain's own namespace over an internal-only HTTP endpoint (`POST /email` on port 27705 -- see `backend/src/web/email.rs`), which parses it and stores it against the right Jonline user(s).

## How it works

```
sender's MTA -> DNS MX lookup for yourdomain.com -> Traefik (:25, shared LoadBalancer)
                                                        |
                                     plain TCP passthrough, HostSNI(`*`) catch-all --
                                     Stalwart is the only possible destination, so
                                     there's nothing to route *between* (see below)
                                                        |
                                                        v
                                                  Stalwart (ClusterIP)
                                                        |
                                              accepts mail for onboarded domains,
                                              fires an MTA Hook at the DATA stage
                                                        |
                                                        v
                                   POST http://jonline.<namespace>.svc.cluster.local:27705/email
                                   (X-Jonline-Email-Recipients: <envelope RCPT TO addresses>,
                                    body: raw MIME message)
                                                        |
                                                        v
                              that namespace's `jonline` backend parses it, stores the raw
                              message in MinIO, and indexes it in Postgres per recipient
```

Because Stalwart is the one thing that has to be a well-behaved, spam-resistant internet-facing SMTP server, this is a **single shared component per cluster** -- like `deploys/ingress`'s Traefik, not like each namespace's own `jonline` Deployment. Unlike `jonline`, though, it sits *behind* that same shared Traefik ingress rather than getting its own LoadBalancer: `deploys/ingress` has to peek at the TLS SNI on 443/27707 to decide which of several namespaces to forward to, but there's no such decision for SMTP -- Stalwart is the only possible destination cluster-wide (it does its own per-domain acceptance internally, after Traefik hands it the connection). So it's wired up as a plain TCP passthrough on a dedicated `smtp` entrypoint (port 25) with a catch-all ``HostSNI(`*`)`` route, requiring nothing from Traefik beyond "forward every byte" -- see `../ingress/k8s/traefik.yaml` and `k8s/stalwart.yaml`'s `IngressRouteTCP`. STARTTLS is transparent to this: it just upgrades the same already-routed connection in place, it doesn't open a new one Traefik would need to re-route.

This means **`deploys/ingress`'s shared controller must already be installed** (`make create_ingress`) before `create_email` below is useful -- Stalwart has no external IP of its own.

Port 27705 on each `jonline` Deployment is **internal-only** -- it has no authentication of its own and trusts whatever calls it completely. It's deliberately absent from `server_external.yaml`'s (LoadBalancer) Service; only `server_internal.yaml`/`server_internal_insecure.yaml` (ClusterIP) expose it, and only inside the cluster. If your threat model wants more than "not internet-routable," add a `NetworkPolicy` in each domain's namespace restricting port 27705 to pods in the `jonline-email` namespace.

## One-time setup: install the shared controller

Pre-code Stalwart's initial admin credentials (skip this and it falls back to a random one-time password logged via `kubectl logs`, but `add_email_domain`/etc. below need to know the password, so set one):

```bash
ADMIN_PASSWORD=correct-horse-battery-staple make create_email_admin_secret
```

Then boot the controller itself:

```bash
make create_email
```

This installs Stalwart (`Deployment`, two `ClusterIP` Services, a `PersistentVolumeClaim`, and an `IngressRouteTCP` onto the shared Traefik controller) into its own `jonline-email` namespace -- see `k8s/stalwart.yaml`'s comments for what each piece is for, in particular:

* The `stalwart-data` PVC holds **Stalwart's own configuration** (accepted domains, MTA Hook definitions, DKIM keys, TLS state) and its in-flight message queue -- not user mailboxes. Losing it means redoing a few minutes of setup, not losing anyone's mail, since accepted messages are handed off immediately and never stored here. If you'd rather this config lived in Postgres than the embedded RocksDB store, `make create_email_postgres` stands up a 1Gi Postgres instance in the same namespace -- see `k8s/k8s-stalwart-postgres-digitalocean.yaml`'s header comment; pick "PostgreSQL" in Stalwart's setup wizard and point it at `stalwart-postgres.jonline-email.svc.cluster.local:5432`.
* Port 8080 (the admin UI / setup wizard) is deliberately `ClusterIP`-only, never a `LoadBalancer`. Reach it with:

  ```bash
  make deploy_email_admin_port_forward
  # then open http://localhost:8080
  ```
* On a fresh volume, Stalwart boots into a setup wizard -- log in with the credentials from `create_email_admin_secret` above (or the random one-time password from `kubectl logs -n jonline-email deployment/stalwart` if you skipped it) and walk through hostname/storage/directory choices.

Get the shared ingress's external IP (what your MX records will point at -- Stalwart no longer has an IP of its own) with:

```bash
make deploy_email_get_ip
```

## Onboarding a domain

Unlike `deploys/ingress`'s `add_ingress_domain`, this isn't a `kubectl apply` of generated YAML -- Stalwart keeps its accepted-domains list and MTA Hook definitions in its own database. `add_email_domain`/`remove_email_domain`/`list_email_domains` script that database through Stalwart's REST Management API (its JMAP-based `x:Domain`/`x:MtaHook` extension objects; see [stalw.art/docs/api/management](https://stalw.art/docs/api/management/overview/)) instead of walking the admin UI by hand:

```bash
make deploy_email_admin_port_forward &   # the API is ClusterIP-only, same as the admin UI
NAMESPACE=mynamespace DOMAIN=my.domain.example.com make add_email_domain
```

This adds `my.domain.example.com` as an accepted domain and a `data`-stage MTA Hook scoped to it (via an `enable` expression matching `rcpt_domain`), pointed at that namespace's `jonline` Service. **This has been checked against Stalwart's documented API shape but not exercised against a live instance** -- verify the domain actually shows up (`make list_email_domains`, or the admin UI) before pointing real DNS at it, and if it starts failing, recheck the Makefile's `add_email_domain`/`remove_email_domain` targets against your running version -- Stalwart's API evolves between releases and what's encoded there might be stale by the time you read this.

The `X-Jonline-Email-Recipients` header the hook should send is the SMTP envelope's `RCPT TO` addresses, comma-separated -- this is deliberately the envelope, not the message's `To`/`Cc` headers, since that's the only place Bcc'd recipients show up at all (see `backend/src/web/email.rs`'s doc comment).

### DNS

Per domain, still in Cloudflare (or wherever it's hosted):

| Record | Example | Notes |
|---|---|---|
| MX | `my.domain.example.com. MX 10 <target>.` | `<target>` resolves to the shared ingress's IP from `make deploy_email_get_ip` -- the same IP your other domains' 443/27707 records may already point at. |
| A/AAAA (`<target>`) | `<target> A <ingress-ip>` | **Must be DNS-only ("grey cloud")** if you're on Cloudflare -- the proxy doesn't handle SMTP at all, only HTTP(S). |
| SPF | `my.domain.example.com. TXT "v=spf1 mx ~all"` | Helps other servers trust anything you bounce, even before you're sending real outbound mail. |
| DMARC | `_dmarc.my.domain.example.com TXT "v=DMARC1; p=none; rua=mailto:you@..."` | Start at `p=none` (report-only). |

Before touching DNS, validate mail actually reaches your namespace by watching `kubectl logs -f deployment/jonline -n mynamespace` while sending a test message with `swaks --to test@<target> --server <ingress-ip>`.

Also confirm your hosting/cloud provider allows inbound traffic on port 25 -- some block it by default even for receive-only use, and require a support ticket to lift it.

## Removing a domain / tearing down

Remove a domain's acceptance + MTA Hook through the same admin UI you added it in, then remove its DNS records. To remove the shared controller entirely:

```bash
make remove_email
```
