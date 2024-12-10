apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kuadrant-install
spec:
  ignoreApplicationDifferences:
    - jsonPointers:
        - /spec/syncPolicy
        - /spec/source/targetRevision
  goTemplate: true
  generators:
    - matrix:
        generators:
          - clusters:
              selector:
                matchExpressions:
                  - key: argocd.argoproj.io/secret-type
                    operator: Exists
          - git:
              repoURL: {{ $.Values.repoURL }}
              revision: {{ $.Values.targetRevision }}
              files:
                - path: manifests/kuadrant/**/argocd-config.yaml
  template:
    metadata:
      name: {{` "{{.path.basename}}.{{.nameNormalized}}" `}}
    spec:
      project: default
      source:
        repoURL: {{ $.Values.repoURL }}
        targetRevision: {{ $.Values.targetRevision }}
        path: {{` '{{.path.path}}/overlays/{{or (index .metadata.labels "vendor") "k8s" | lower}}' `}}
      destination:
        name: {{` "{{.name}}" `}}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
