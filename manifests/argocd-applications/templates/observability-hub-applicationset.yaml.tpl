---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: observability-hub
spec:
  ignoreApplicationDifferences:
    - jsonPointers:
        - /spec/syncPolicy
        - /spec/source/targetRevision
  goTemplate: true
  generators:
    - clusters:
        selector:
          matchExpressions:
            # A cluster secret is not automatically created for the local cluster, so we need to
            # add one (or edit the in-cluster cluste rthrough the argocd UI) for it. Only after
            # evaluating that the secret exists it is safe to evaluate the other installation conditions
            - key: argocd.argoproj.io/secret-type
              operator: Exists
            # only install in Hub cluster
            - key: deployment.kuadrant.io/hub
              operator: In
              values:
                - "true"
  template:
    metadata:
      name: {{` "observability-hub.{{.nameNormalized}}" `}}
      namespace: argocd
    spec:
      destination:
        namespace: monitoring
        name: {{` "{{.name}}" `}}
      project: default
      source:
        path: {{` 'manifests/observability-hub/overlays/{{or (index .metadata.labels "vendor") "k8s" | lower}}' `}}
        repoURL: {{ $.Values.repoURL }}
        targetRevision: {{ $.Values.targetRevision }}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
