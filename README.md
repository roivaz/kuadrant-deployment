# deployment
This repo contains some example deployments for Kuadrant. 

- All deployments use kustomize and regular kuberentes resources
- We will provide basic instructions for installing and configuring ArgoCD but more advanced topics should be found via argocd docs

Phase 1

## Deploying Kuadrant via ArgoCD, configuring permissions and MultiAZ resilience

- HA deployments for Authorino and Limitador using topology constraints, multiple replicas (perhaps HPA), PodDisruption budgets and resource limits.
- RBAC setup to allow develoepr 1 to deploy a HTTRoute based API , RLP and AuthPolicy to a specific namespace via ArgoCD.
- RBAC setup to allow developer to see only his API in the Grafana dashboards in the single cluster setup.


Phase 2

## Deployment of Kuadrant to 2 clusters and using thanos for observability

- Extend on phase 1 to include a second cluster
- Introduce an external redis configuration
- Introduce and install thanos 

