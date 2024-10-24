# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))

OS := $(shell go env GOOS)
ARCH := $(shell go env GOARCH)
# Container Engine to be used for building image and with kind
CONTAINER_ENGINE ?= docker

## Location to install dependencies to
LOCALBIN ?= $(PROJECT_PATH)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Temp folder
tmp:
	umask 0000 && mkdir -p $@

##@ Kind

## Targets to use kind for deployment https://kind.sigs.k8s.io
export KUBECONFIG = $(PWD)/kubeconfig

KIND_CLUSTER_NAME ?= kuadrant-local
KIND_K8S_VERSION ?= v1.31.0@sha256:53df588e04085fd41ae12de0c3fe4c72f7013bba32a20e7325357a1ac94ba865
.PHONY: kind-create-cluster
kind-create-cluster-%: kind start-cloud-provider-kind ## Create the "kuadrant-local" kind cluster.
	KIND_EXPERIMENTAL_PROVIDER=$(CONTAINER_ENGINE) $(KIND) create cluster --wait 5m \
		--image kindest/node:$(KIND_K8S_VERSION) \
		--name $(KIND_CLUSTER_NAME)-$* \
		--config util/kind-cluster.yaml

.PHONY: kind-delete-cluster
kind-delete-cluster-%: kind stop-cloud-provider-kind ## Delete the "kuadrant-local" kind cluster.
	- KIND_EXPERIMENTAL_PROVIDER=$(CONTAINER_ENGINE) $(KIND) delete cluster --name $(KIND_CLUSTER_NAME)-$*

kind-apply-argocd: kustomize
	$(KUSTOMIZE) build manifests/argocd-install | yq 'select(.kind == "CustomResourceDefinition")' | kubectl apply -f -
	sleep 2
	kubectl wait --for condition=established --timeout=60s crd --all
	$(KUSTOMIZE) build manifests/argocd-install | yq 'select(.kind != "CustomResourceDefinition")' | kubectl apply -f -

##@ Kind cloud provider
CPK_PID_FILE = tmp/cloud-provider-kind.pid

start-cloud-provider-kind: kind-cloud-provider tmp
	hack/run-background-process.sh $(KIND_CLOUD_PROVIDER) $(CPK_PID_FILE) tmp/cloud-provider-kind.log

stop-cloud-provider-kind:
	- test -f $(CPK_PID_FILE) && kill -TERM $$(cat $(CPK_PID_FILE)) && rm $(CPK_PID_FILE)

##@ ArgoCD management targets
ARGOCD_PASSWD = $(shell kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
ARGOCD_IP = $(shell kubectl -n argocd get svc argocd-server -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

argocd-url:
	@echo -e "\n"
	@echo -e ">>> ArgoCD is now available at:"
	@echo -e ">>> \tURL: \thttps://$(ARGOCD_IP)"
	@echo -e ">>> \tuser: \tadmin"
	@echo -e ">>> \tpass: \t$(ARGOCD_PASSWD)"
	@echo -e "\n"

argocd-login: argocd
	$(ARGOCD) login $(ARGOCD_IP):443 --insecure --username admin --password $(ARGOCD_PASSWD)

##@ Local setup

local-setup: argocd kind-create-cluster-1 kind-create-cluster-2
	kubectl config set-context kind-kuadrant-local-1
	$(MAKE) kind-apply-argocd
	kubectl -n argocd wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s
	kubectl -n argocd wait --for=jsonpath='{.status.loadBalancer.ingress}' service/argocd-server
	$(MAKE) argocd-login && $(ARGOCD) cluster add kind-kuadrant-local-2 --yes --cluster-endpoint kube-public
	$(MAKE) argocd-url

tear-down: kind-delete-cluster-1 kind-delete-cluster-2

clean:
	rm -rf tmp bin kubeconfig

##@ Tooling

KUSTOMIZE = $(PROJECT_PATH)/bin/kustomize
KUSTOMIZE_VERSION = v5@v5.5.0
.PHONY: kustomize
kustomize: $(KUSTOMIZE) ## Download kustomize locally if necessary.
$(KUSTOMIZE): $(LOCALBIN)
	 test -s $(KUSTOMIZE) || GOBIN=$(LOCALBIN) go install sigs.k8s.io/kustomize/kustomize/$(KUSTOMIZE_VERSION)


KIND = $(PROJECT_PATH)/bin/kind
KIND_VERSION ?= v0.24.0
.PHONY: kind
kind: $(KIND) ## Download kind locally if necessary
$(KIND): $(LOCALBIN)
	test -s $(KIND) || GOBIN=$(LOCALBIN) go install sigs.k8s.io/kind@$(KIND_VERSION)

KIND_CLOUD_PROVIDER = $(PROJECT_PATH)/bin/cloud-provider-kind
KIND_CLOUD_PROVIDER_VERSION ?= latest
.PHONY: kind-cloud-provider
kind-cloud-provider: $(KIND_CLOUD_PROVIDER) ## Download kind locally if necessary
$(KIND_CLOUD_PROVIDER): $(LOCALBIN)
	test -s $(KIND_CLOUD_PROVIDER) || GOBIN=$(LOCALBIN) go install sigs.k8s.io/cloud-provider-kind@$(KIND_CLOUD_PROVIDER_VERSION)

##@ Install argocd-cli
ARGOCD ?= $(LOCALBIN)/argocd
ARGOCD_VERSION ?= v2.12.6
ARGOCD_DOWNLOAD_URL ?= https://github.com/argoproj/argo-cd/releases/download/$(ARGOCD_VERSION)/argocd-$(OS)-$(ARCH)
argocd: $(ARGOCD) ## Download argocd CLI locally if necessary
$(ARGOCD): $(LOCALBIN)
	curl -sL $(ARGOCD_DOWNLOAD_URL) -o $(ARGOCD)
	chmod +x $(ARGOCD)
