# deployment
This repo contains some example deployments for Kuadrant. 

- All deployments use kustomize and regular kuberentes resources
- We will provide basic instructions for installing and configuring ArgoCD but more advanced topics should be found via argocd docs

Phase 1

### Deploying Kuadrant via ArgoCD, configuring permissions and MultiAZ resliance

- HA deployment for Authorino and Limitador using topology constraints, multiple replicas (perhaps HPA), PodDisruption budget and resource limits.
- RBAC setup to allow develoepr 1 to deploy a HTTRoute based API , RLP and AuthPolicy to a specific namespace.
- RBAC setup to allow developer to see only his API in the Grafana dashboards in the single cluster setup


Phase 2

## Deployment of Kuadrant to 2 clusters and using thanos

- Extend on phase 1 to include a second cluster
- Introduce an external redis
- Introduce thanos 

