# Jonline Architecture
Jonline is generally setup to be deployed using Make atop `kubectl` and `jq` (and `graphviz`, if editing architecture diagrams in this directory).

## Deployment Management
[Deployment management logic lives in `deploys/`](https://github.com/JonLatane/jonline/tree/main/deploys). Essentially this is some readable `Makefile` stuff built atop `kubectl`.

### TLS Certificate Generation
[Generated certs live in `deploys/generated_certs`](https://github.com/JonLatane/jonline/tree/main/deploys/generated_certs). Generally, if  you want to deploy to your own Kubernetes cluster, and secure it with TLS, you should take a look at these docs. Cert-Manager for DigitalOcean with DigitalOcean DNS is done. It should be possible to do this for other hosts with Cert-Manager support.


## CI/CD (Continuous Integration and Delivery)
[CI/CD logic is defined in `.github/workflows/`](https://github.com/JonLatane/jonline/tree/main/.github/workflows). If you can set up a Kubernetes deployment with the instructions in [`deploys/`](https://github.com/JonLatane/jonline/tree/main/deploys), hooking into the Server

The main CI jobs behind Jonline are:

[![Server CI/CD Badge](https://github.com/jonlatane/jonline/actions/workflows/server_ci_cd.yml/badge.svg)](https://github.com/jonlatane/jonline/actions/workflows/server_ci_cd.yml)
[![Proto Consistency Badge](https://github.com/jonlatane/jonline/actions/workflows/proto_consistency.yml/badge.svg)](https://github.com/jonlatane/jonline/actions/workflows/proto_consistency.yml)

### CI For iOS, Android, macOS, Windows, and Linux
[![Flutter iOS Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_ios.yml/badge.svg)](https://github.com/jonlatane/jonline/actions/workflows/flutter_ios.yml)
[![Flutter Android Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_android.yml/badge.svg)](https://github.com/jonlatane/jonline/actions/workflows/flutter_android.yml)
[![Flutter macOS Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_macos.yml/badge.svg)](https://github.com/jonlatane/jonline/actions/workflows/flutter_macos.yml)
[![Flutter Windows Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_windows.yml/badge.svg)](https://github.com/jonlatane/jonline/actions/workflows/flutter_windows.yml)
[![Flutter Linux Build Badge](https://github.com/jonlatane/jonline/actions/workflows/flutter_linux.yml/badge.svg)](https://github.com/jonlatane/jonline/actions/workflows/flutter_linux.yml)

## Example Kubernetes Cluster Setups
### K8s cluster with multiple Kubernetes LoadBalancers (without JBL)
This is how Jonline is currently deployed.

![K8s cluster with multiple Kubernetes LoadBalancers](https://github.com/JonLatane/jonline/blob/main/docs/architecture/Kubernetes_Deployment.svg)

### K8s cluster with multiple Jonline servers/deployments behind a single JBL LoadBalancer
Not yet implemented; an ongoing dev effort (that welcomes outside contributions)! See [the GitHub issue for more information](https://github.com/JonLatane/jonline/issues/15).
![System with multiple Kubernetes LoadBalancers](https://github.com/JonLatane/jonline/blob/main/docs/architecture/JBL_Kubernetes_Deployment.svg)
