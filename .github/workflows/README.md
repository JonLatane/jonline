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
7. After the GitHub release is created, build a macOS (Apple Silicon) binary release and push an updated `Formula/jonline.rb` to the [jonlatane/homebrew-jonline](https://github.com/jonlatane/homebrew-jonline) tap (`create_homebrew_release`), so `brew install jonlatane/jonline/jonline` stays up to date.
8. Also build amd64 and arm64 Linux binaries (statically linked against libpq) and assemble/upload a self-updating `jonline-<version>-linux.tar.bz2` release asset (`create_linux_release`), extractable on any Linux machine -- see `docs/linux_jonline.sh` for the bundled `bin/jonline` launcher (`update`/`show_latest`/`cleanup_updates` commands).

## Flutter Apps
Jonline also provides a single workflow for each Flutter native app (`flutter_android.yml`, `flutter_ios.yml`, `flutter_macos.yml`, and `flutter_wndws.yml`).


## Protobuf Consistency Check
Ideally, this check should build all the protos and docs (i.e. `make` from the root of the repo), and error if any files changed A general protobuf consistency check `proto_consistency.yml` that could use more test coverage.

