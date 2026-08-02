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

```bash
make create_email
```

This installs Stalwart (`Deployment`, two `ClusterIP` Services, a `PersistentVolumeClaim`, and an `IngressRouteTCP` onto the shared Traefik controller) into its own `jonline-email` namespace -- see `k8s/stalwart.yaml`'s comments for what each piece is for, in particular:

* The `stalwart-data` PVC holds **Stalwart's own configuration** (accepted domains, MTA Hook definitions, DKIM keys, TLS state) and its in-flight message queue -- not user mailboxes. Losing it means redoing a few minutes of admin-UI setup, not losing anyone's mail, since accepted messages are handed off immediately and never stored here.
* Port 8080 (the admin UI / setup wizard) is deliberately `ClusterIP`-only, never a `LoadBalancer`. Reach it with:

  ```bash
  make deploy_email_admin_port_forward
  # then open http://localhost:8080
  ```
* On a fresh volume, Stalwart boots into a setup wizard and logs a one-time random admin password to `kubectl logs -n jonline-email deployment/stalwart`. Walk through hostname/storage/directory choices there. (If you'd rather set a fixed initial password than go hunting through logs, uncomment the `STALWART_RECOVERY_ADMIN` env var in `k8s/stalwart.yaml`, ideally sourced from a `Secret` rather than a literal.)

Get the shared ingress's external IP (what your MX records will point at -- Stalwart no longer has an IP of its own) with:

```bash
make deploy_email_get_ip
```

## Onboarding a domain

Unlike `deploys/ingress`'s `add_ingress_domain`, this isn't a `kubectl apply` of generated YAML -- Stalwart keeps its accepted-domains list and MTA Hook definitions in its own database, configured through its admin UI (or REST Management API; see [stalw.art/docs/api/management](https://stalw.art/docs/api/management/overview/) if you want to script this later). Run:

```bash
NAMESPACE=mynamespace DOMAIN=my.domain.example.com make add_email_domain
```

which prints the concrete values for the three manual steps: adding the domain, adding a `data`-stage MTA Hook pointed at that namespace's `jonline` Service, and where to point DNS. **Verify the exact MTA Hook scoping options (matching a hook to one domain vs. all of them) against your running instance's admin UI** -- Stalwart's hook-matching expression syntax evolves between versions and isn't reproduced here to avoid shipping something that looks authoritative but might be stale by the time you read it.

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
