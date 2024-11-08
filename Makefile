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
kind-create-cluster-%: export KIND_EXPERIMENTAL_PROVIDER=$(CONTAINER_ENGINE)
kind-create-cluster-%: kind kustomize ## Create the "kuadrant-local" kind cluster.
	$(KIND) create cluster --wait 5m \
		--image kindest/node:$(KIND_K8S_VERSION) \
		--name $(KIND_CLUSTER_NAME)-$* \
		--config util/kind-cluster.yaml
	$(MAKE) kind-install-metallb-$*

kind-install-metallb-%: export PODMAN_IGNORE_CGROUPSV1_WARNING="1"
kind-install-metallb-%: yq
	kubectl config use-context kind-kuadrant-local-$*
	$(KUSTOMIZE) build https://github.com/metallb/metallb/config/native/?ref=v0.14.8 | kubectl apply -f -
	kubectl wait --for condition=established --timeout=60s crd --all
	kubectl -n metallb-system wait --for=condition=Available deployments controller --timeout=300s
	curl -sL https://raw.githubusercontent.com/Kuadrant/kuadrant-operator/refs/heads/main/utils/docker-network-ipaddresspool.sh | \
		bash -s -- kind $(YQ) $* | \
		kubectl -n metallb-system apply -f -


.PHONY: kind-delete-cluster
kind-delete-cluster-%: export KIND_EXPERIMENTAL_PROVIDER=$(CONTAINER_ENGINE)
kind-delete-cluster-%: kind ## Delete the "kuadrant-local" kind cluster.
	- $(KIND) delete cluster --name $(KIND_CLUSTER_NAME)-$*

kind-apply-argocd: kustomize
	$(KUSTOMIZE) build manifests/argocd-install | yq 'select(.kind == "CustomResourceDefinition")' | kubectl apply -f -
	sleep 2
	kubectl wait --for condition=established --timeout=60s crd --all
	$(KUSTOMIZE) build manifests/argocd-install | yq 'select(.kind != "CustomResourceDefinition")' | kubectl apply -f -

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

local-setup: argocd kind-create-cluster-0 kind-create-cluster-1
	kubectl config use-context kind-kuadrant-local-0
	$(MAKE) kind-apply-argocd
	kubectl -n argocd wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s
	kubectl -n argocd wait --for=jsonpath='{.status.loadBalancer.ingress}' service/argocd-server
	$(MAKE) argocd-login && $(ARGOCD) cluster add kind-kuadrant-local-1 --name kuadrant-local-1 --yes --cluster-endpoint kube-public
	$(MAKE) argocd-url

tear-down: kind-delete-cluster-0 kind-delete-cluster-1

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

##@ Install argocd-cli
ARGOCD ?= $(LOCALBIN)/argocd
ARGOCD_VERSION ?= v2.12.6
ARGOCD_DOWNLOAD_URL ?= https://github.com/argoproj/argo-cd/releases/download/$(ARGOCD_VERSION)/argocd-$(OS)-$(ARCH)
argocd: $(ARGOCD) ## Download argocd CLI locally if necessary
$(ARGOCD): $(LOCALBIN)
	curl -sL $(ARGOCD_DOWNLOAD_URL) -o $(ARGOCD)
	chmod +x $(ARGOCD)

##@ Install yq
.PHONY: yq
YQ ?= $(LOCALBIN)/yq
YQ_VERSION ?= v4.40.5
yq: $(YQ)
$(YQ):
	test -s $(YQ) || GOBIN=$(LOCALBIN) go install github.com/mikefarah/yq/v4@$(YQ_VERSION)

##@ Install skupper
SKUPPER ?= $(LOCALBIN)/skupper
SKUPPER_VERSION ?= 1.8.1
# Adjust the OS name for the Skupper download URL if necessary
ifeq ($(OS),darwin)
    OS_DL := mac
else
    OS_DL := $(OS)
endif
SKUPPER_DOWNLOAD_URL ?= https://github.com/skupperproject/skupper/releases/download/$(SKUPPER_VERSION)/skupper-cli-$(SKUPPER_VERSION)-$(OS_DL)-$(ARCH).tgz
skupper: $(SKUPPER) ## Download skupper CLI locally if necessary
$(SKUPPER): $(LOCALBIN)
	curl -sL $(SKUPPER_DOWNLOAD_URL) -o $(SKUPPER).tgz
	tar -xf $(SKUPPER).tgz -C $(LOCALBIN)
	chmod +x $(SKUPPER)
	rm $(LOCALBIN)/skupper.tgz
