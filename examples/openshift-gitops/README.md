After openshift-gitops  is installed in the cluster, resolution of helm charts by kustomize needs to be enabled by issuing the following command:

```
kubectl -n openshift-gitops patch argocd openshift-gitops --type=json -p='[{"op":"add","path":"/spec/kustomizeBuildOptions","value":"--enable-helm"}]'
```

If you experience errors in argocd about the flag '--enable-helm' not being set, delete the `openshift-gitops-application-controller-*` pods in the `openshift-gitops` namespace to force a refresh.
