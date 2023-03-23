## Jonline Release Management

While `/deploys/Makefile` deals with deployment of Jonline container images to
k8s clusters (and elsewhere), `/deploys/releases/Makefile` deals with building
those images and publishing them to your Container Registry of choice.

The `Makefile` also contains tooling for iOS builds.