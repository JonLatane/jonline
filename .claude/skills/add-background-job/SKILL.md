---
name: add-background-job
description: Add a new periodic background job binary (like delete_expired_tokens, delete_unowned_media, sync_event_sync_sources) to Jonline's backend. Use when asked to create a new scheduled/cron-style maintenance or sync job for the Rust backend, since there's no central registry -- it must be wired by hand into ~8 files.
---

Jonline's background jobs are small standalone binaries under `backend/src/bin/*.rs`, each doing one pass of work (no internal loop/sleep) and exiting. Looping/scheduling is entirely external: `backend/background_jobs.sh` (local/Homebrew/Linux tarball) or a K8s `CronJob` (cluster deploys) re-invoke the binary on an interval. There's no registry file to grep for "the list of jobs" -- every one of the touch points below has its own hand-maintained copy of the job list, so adding a job means editing all of them the same way `delete_expired_tokens`/`delete_unowned_media`/`sync_event_sync_sources` already are.

## 1. The binary: `backend/src/bin/<job_name>.rs`

- Put the actual logic in `backend/src/logic/` (e.g. `logic/event_sync.rs`) if it's non-trivial or needs to be unit-testable/reused by an RPC handler; keep the `bin/` file itself thin (connect, query what's due, call logic, log, exit).
- Boilerplate (copy `delete_expired_tokens.rs` for a sync job, or `delete_unowned_media.rs`/`generate_preview_images.rs` for an async one needing `#[tokio::main]`, e.g. MinIO/HTTP):
  ```rust
  extern crate diesel;
  extern crate jonline;
  use jonline::{db_connection, init_bin_logging, init_crypto};

  pub fn main() {
      init_crypto();
      init_bin_logging();
      log::info!("...");
      let pool = db_connection::establish_pool();       // NOT establish_connection() --
      let mut conn = pool.get().expect("...");            // that returns a bare PgConnection,
                                                            // but shared `logic/` fns expect
                                                            // PgPooledConnection (pool.get()).
      // ... do the work, log per-item errors and continue rather than panicking on one bad row ...
  }
  ```
- Sanity check it actually compiles as its own binary target (easy to miss a type mismatch that the lib build alone won't catch): `cd backend && cargo build --bin <job_name>`.

## 2. `deploys/docker/server/Dockerfile`

Add one `COPY` line under the `# Background job binaries` comment, following the `__server_release` naming CI renames binaries to:
```
COPY backend/target/release/<job_name>__server_release /opt/<job_name>
```

## 3. `.github/workflows/server_ci_cd.yml` -- three separate lists

- **`push_jonline_image` job**, step "Rename Rust binaries for Dockerfiles": add `mv backend/target/release/<job_name> backend/target/release/<job_name>__server_release &&` (this is what step 2's Dockerfile COPY consumes -- skip the `push_preview_generator` job's identical-looking rename step unless the job is actually copied into `deploys/docker/preview_generator/Dockerfile` too).
- **`create_homebrew_release` job**: add `<job_name>` to the `for bin in jonline disable_cdn_grpc ...; do` line.
- **`create_linux_release` job**: add `<job_name>` to its own (separate) `for bin in jonline disable_cdn_grpc ...; do` line.

## 4. `backend/background_jobs.sh`

Append one line to the `JOBS` array: `"<job_name> <startup_delay_seconds> <interval_seconds>"`. This file is copied verbatim into both the Homebrew and Linux tarball packages by the CI job in step 3 -- don't hand-edit a shipped copy.

## 5. `docs/linux_jonline.sh` and `docs/homebrew_jonline.sh`

Both are standalone launcher scripts (one becomes the Linux tarball's `bin/jonline`, the other gets spliced into the Homebrew formula) with the same shape -- edit both, identically, in three places each:
- The `Background jobs:` section of the `jonline_help` heredoc: add a one-line (or wrapped) description.
- A new shell function using the shared exec helper: `<job_name>() { _jonline_exec_bin <job_name> "$@" }` (add it near `delete_expired_tokens`/`delete_unowned_media`, under the `# Background jobs` comment).
- The `JONLINE_COMMANDS` array (near the top of the file, above `jonline_help`): add `<job_name>` to it -- it's the single source of truth for both dispatch (bottom of file) and `jonline --list-commands`/tab-completion, so this one edit covers both (it'll otherwise hit the `Unknown command` branch and won't tab-complete).

## 6. K8s CronJobs: `deploys/k8s/server_external.yaml`, `server_internal.yaml`, `server_internal_insecure.yaml`

These three files are near-duplicates (only the `Service.type` and whether `TLS_KEY`/`TLS_CERT` env vars are commented out differ) -- add the *same* `CronJob` block to all three, right after the `delete-expired-tokens` one, following its shape:
```yaml
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: <job-name-with-dashes>
spec:
  schedule: "<cron schedule>"
  successfulJobsHistoryLimit: 3
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: <job-name-with-dashes>
              image: docker.io/jonlatane/jonline:<current version>
              imagePullPolicy: IfNotPresent
              env:
                - name: DATABASE_URL
                  value: postgres://admin:secure_password1@jonline-postgres/jonline
                # + MINIO_* env vars too, copied from delete-unowned-media's CronJob, if the job touches MinIO
              command:
                - /opt/<job_name>
          restartPolicy: Never
```
Sanity check all three still parse (a stray copy/paste indent is the usual failure): `python3 -c "import yaml,sys; [print(d['metadata']['name']) for d in yaml.safe_load_all(open(f)) if d.get('kind')=='CronJob']" <file>` for each.

## Checklist

- [ ] `backend/src/bin/<job_name>.rs` (logic in `backend/src/logic/` if non-trivial) -- `cargo build --bin <job_name>` passes
- [ ] `deploys/docker/server/Dockerfile` COPY line
- [ ] `server_ci_cd.yml`: rename step (`push_jonline_image`), Homebrew `for bin`, Linux `for bin`
- [ ] `backend/background_jobs.sh` JOBS entry
- [ ] `docs/linux_jonline.sh`: help text, function, `JONLINE_COMMANDS` array
- [ ] `docs/homebrew_jonline.sh`: help text, function, `JONLINE_COMMANDS` array
- [ ] `deploys/k8s/server_external.yaml` + `server_internal.yaml` + `server_internal_insecure.yaml` CronJob (all three, identical)
