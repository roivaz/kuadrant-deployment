---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: observability-worker
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
  template:
    metadata:
      name: {{` "observability-worker.{{.nameNormalized}}" `}}
    spec:
      destination:
        namespace: monitoring
        name: {{` "{{.name}}" `}}
      project: default
      
      source:
        path: {{` 'manifests/observability-worker/overlays/{{or (index .metadata.labels "vendor") "k8s" | lower}}' `}}
        repoURL: {{ $.Values.repoURL }}
        targetRevision: {{ $.Values.targetRevision }}
        kustomize:
          patches:
            - target:
                group: monitoring.coreos.com
                version: v1
                kind: Prometheus
                name: k8s
              patch: |-
                - op: replace
                  path: /spec/remoteWrite/0/writeRelabelConfigs/0/replacement
                  value: {{` "{{ .name }}" `}}
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
          - ServerSideApply=true
