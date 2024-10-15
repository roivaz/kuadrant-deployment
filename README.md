# deployment
This repo contains some example deployments for Kuadrant. The initial focus is to allow deployment of Kuadrant via argocd to one or more clusters:

Phase 1

## Deployment of Kuadrant via ArgoCD and configuring permissions to allow team members to setup HTTPRoutes/RateLimitPolicies/AuthPolicies

- HA deployment for Authorino and Limitador using topology constraints, multiple replicas (perhaps HPA), PodDisruption budget and resource limits
- RBAC setup to allow develoepr 1 to deploy a HTTRoute , RLP an AuthPolicy to a specific namespace
- RBAC setup to allow developer to see only his API in the Grafana dashboards


Phase 2

## Deployment of Kuadrant to 2 clusters and using thanos

