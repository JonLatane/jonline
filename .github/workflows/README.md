# Jonline GitHub Workflows

It's worth noting there is some overlap in the workflows: `backend`, `flutter_web` and `tamagui_web` all do a few of the same things as `deploy_server` and `deploy_preview_generator`. The latter, though, is really specifically oriented towards creating a deliverable release. The former three are separated out so we can have separate badges and better separation of the various build processes.

The `deploy_server` workflow in particular presents a multi-phase deploy process:

1. Built the Tamagui Web (React), Flutter Web, and Rust server binaries concurrently in different jobs and cache their outputs.
2. Assemble the Docker image from the cached build products and push to DockerHub.
3. Deploy to Jonline.io in a canary run, then any other configured domains.
