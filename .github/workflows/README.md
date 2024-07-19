# Jonline GitHub Workflows
## Server CI
The `server_ci_cd.yml` workflow a multi-phase CI/CD process:

1. Built the Tamagui Web (React), Flutter Web, and Rust server binaries concurrently in different jobs and cache their outputs.
   * Also, start tests here. But do not block step 2.
2. Assemble the Docker image from the cached build products and push to DockerHub.
3. Wait for any tests to complete.
4. Deploy to Jonline.io in a canary run.
5. Deploy to BullCity.Social and OakCity.Social.
6. Deploy the Preview Generator everywhere.

## Flutter Apps
Jonline also provides a single workflow for each Flutter native app (`flutter_android.yml`, `flutter_ios.yml`, `flutter_macos.yml`, and `flutter_wndws.yml`).


## Protobuf Consistency Check
Ideally, this check should build all the protos and docs (i.e. `make` from the root of the repo), and error if any files changed A general protobuf consistency check `proto_consistency.yml` that could use more test coverage.

