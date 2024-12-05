# deployment
This repo contains some example deployments for Kuadrant. 

- All deployments use kustomize and regular kuberentes resources
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

The following instructions assume you have cloned the repo locally adn are in the project's root directory.

### Local

To deploy the setup in local kind clusters just issue a `make local-setup` command in a shell. Information on how to connect to the argocd UI will be printed in the output.

### Remote

To install in a remote cluster, it is assumed that an argocd instance is already up and running in the cluster. An example is available on how to install an argocd instance in OpenShift using the argocd-operator.

1. Label the clusters in your argocd instance. To do so, go to "**settings** > **clusters** > **<cluster-name>** > **edit**" in the argocd UI. This can also be achieved using the argocd CLI. The following labels must be set, depending on the desired effect:

    * argocd.argoproj.io/secret-type=cluster: all applicationsets expect that clusters have this label. This label is always present for clusters different that the 'in-cluster' one, which might not have it, depending on how argocd was installed. Make sure that 'in-cluster' also has this label, as it acts as the hub cluster.
    * deployment.kuadrant.io/hub=true: marks this cluster as the hub. Certain resources will only be installed in the hub cluster.
    * vendor=OpenShift: marks this cluster as an OpenShift cluster. A k8s cluster is assumed if this label is not present.

2. Apply the `app-of-apps-application.yaml` manifest to the namespace where the argocd instance is running. Note that you will need the `yq` tool for the following command to work. You can install the tool using `make yq`, otherwise you can manually edit the yaml file.

```
> export ARGOCD_NAMESPACE="namespace-here"
> yq e ".spec.destination.namespace = \"$ARGOCD_NAMESPACE\"" manifests/argocd-install/app-of-apps-application.yaml | kubectl -n $ARGOCD_NAMESPACE apply -f -
```

6. Coffee time. It should all be green afte some minutes.
