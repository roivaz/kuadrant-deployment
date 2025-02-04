# deployment
This repo contains some example deployments for Kuadrant.

- All deployments use kustomize and regular kubernetes resources
- We will provide basic instructions for installing and configuring ArgoCD but more advanced topics should be found via argocd docs

## Phases



### **Phase 1** - Deploying Kuadrant via ArgoCD, configuring permissions and MultiAZ resilience

- HA deployments for Authorino and Limitador using topology constraints, multiple replicas (perhaps HPA), PodDisruption budgets and resource limits.
- RBAC setup to allow develoepr 1 to deploy a HTTRoute based API , RLP and AuthPolicy to a specific namespace via ArgoCD.
- RBAC setup to allow developer to see only his API in the Grafana dashboards in the single cluster setup.


### **Phase 2** Deployment of Kuadrant to 2 clusters and using thanos for observability

- Extend on phase 1 to include a second cluster
- Introduce an external redis configuration
- Introduce and install thanos

## Instructions

The following instructions assume you have cloned the repo locally and are in the project's root directory.

### Local

To deploy the setup in local kind clusters just issue a `make local-setup` command in a shell. Information on how to connect to the argocd UI will be printed in the output.

TIP: If using Linux, possibly `make local-setup` target fails with no clear information about the reason of the failure (you will need to increase kind log verbosity level starting with `-v 4`). It will possibly be caused by running out of inotify resources and inotify file watches. In order to increase them add the following 2 lines to `/etc/sysctl.conf`:

```
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=524288
```

And execute `sudo sysctl -p` so the new inotify configuration is loaded.

### Remote

To install in a remote cluster, it is assumed that an argocd instance is already up and running in the cluster. An example is available on how to install an argocd instance in OpenShift using the argocd-operator.

1. Label the clusters in your argocd instance. To do so, go to "**settings** > **clusters** > **<cluster-name>** > **edit**" in the argocd UI. This can also be achieved using the argocd CLI. The following labels must be set, depending on the desired effect:

    * `argocd.argoproj.io/secret-type=cluster`: all applicationsets expect that clusters have this label. This label is always present for clusters different that the 'in-cluster' one, which might not have it, depending on how argocd was installed. Make sure that 'in-cluster' also has this label, as it acts as the hub cluster.
    * `deployment.kuadrant.io/hub=true`: marks this cluster as the hub. Certain resources will only be installed in the hub cluster.
    * `vendor=OpenShift`: marks this cluster as an OpenShift cluster. A k8s cluster is assumed if this label is not present.

2. Use the following target to apply the `manifests/app-of-apps-application.yaml` manifest that will automatically manage all the other Applications in all the clusters. Make sure you have the correct kubeconfig context loaded in your shell.

```
make deploy ARGOCD_NAMESPACE="<argocd-installation-namespace>"
```

1. Coffee time. It should all be green after some minutes.


## Development

Fork the repo and create a branch. Then, deploy setting your repoURL and targetRevision accordingly.

* For a local setup with kind use:

```
make local-setup REPO_URL=<forked-repository-url> TARGET_REVISION=<branch|tag|commit>
```

* For a remote setup you need to also add the namespace where argocd is installed. Make sure to load the appropriate kubeconfig context.

```
make deploy REPO_URL=<forked-repository-url> TARGET_REVISION=<branch|tag|commit> ARGOCD_NAMESPACE=<argocd-installation-namespace>
```