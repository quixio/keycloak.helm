.PHONY: help install install-dev install-prod upgrade uninstall template lint port-forward logs package publish-oci  login-oci clean status get-admin-password deps

CHART_NAME := keycloak
NAMESPACE := keycloak
RELEASE_NAME := keycloak
CHART_VERSION := $(shell awk -F': ' '/^version:/{print $$2}' Chart.yaml)
OUTPUT_DIR := dist

# Optional variables for publishing
# Set these when calling make, e.g.:
# make publish-oci OCI_REGISTRY=ghcr.io OCI_PATH=your-org/charts
OCI_REGISTRY ?=
OCI_PATH ?=
GHPAGES_URL ?=

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

deps: ## Update chart dependencies (PostgreSQL)
	helm dependency update

install: deps ## Install chart with default values
	helm install $(RELEASE_NAME) . --namespace $(NAMESPACE) --create-namespace

install-dev: deps ## Install chart with development values
	helm install $(RELEASE_NAME) . -f values-development.yaml --namespace $(NAMESPACE) --create-namespace

install-prod: deps ## Install chart with production values
	helm install $(RELEASE_NAME) . -f values-production.yaml --namespace $(NAMESPACE) --create-namespace

upgrade: ## Upgrade existing installation
	helm upgrade $(RELEASE_NAME) . --namespace $(NAMESPACE)

upgrade-dev: ## Upgrade with development values
	helm upgrade $(RELEASE_NAME) . -f values-development.yaml --namespace $(NAMESPACE)

upgrade-prod: ## Upgrade with production values
	helm upgrade $(RELEASE_NAME) . -f values-production.yaml --namespace $(NAMESPACE)
uninstall: ## Uninstall chart
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)

template: ## Generate Kubernetes manifests without installing
	helm template $(RELEASE_NAME) . --namespace $(NAMESPACE)

template-dev: ## Generate manifests with development values
	helm template $(RELEASE_NAME) . -f values-development.yaml --namespace $(NAMESPACE)

template-prod: ## Generate manifests with production values
	helm template $(RELEASE_NAME) . -f values-production.yaml --namespace $(NAMESPACE)

lint: ## Lint the chart
	helm lint .

lint-dev: ## Lint with development values
	helm lint . -f values-development.yaml

lint-prod: ## Lint with production values
	helm lint . -f values-production.yaml

port-forward: ## Port-forward to Keycloak service
	kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME) 8080:8080

logs: ## Show Keycloak logs
	kubectl logs -f -n $(NAMESPACE) -l app.kubernetes.io/name=$(CHART_NAME)

status: ## Show release status
	helm status $(RELEASE_NAME) --namespace $(NAMESPACE)

get-admin-password: ## Get admin password from secret
	@kubectl get secret $(RELEASE_NAME)-admin -n $(NAMESPACE) -o jsonpath="{.data.password}" | base64 --decode && echo

package: deps ## Package the chart to ./$(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)
	helm package . -d $(OUTPUT_DIR)
	@echo "Packaged: $(OUTPUT_DIR)/$(CHART_NAME)-$(CHART_VERSION).tgz"

login-oci: ## Login to OCI registry (use HELM_REGISTRY_USERNAME and HELM_REGISTRY_PASSWORD env vars)
	@if [ -z "$(OCI_REGISTRY)" ]; then echo "OCI_REGISTRY is required"; exit 1; fi
	@helm registry login $(OCI_REGISTRY) -u $$HELM_REGISTRY_USERNAME -p $$HELM_REGISTRY_PASSWORD

publish-oci: package ## Publish chart to OCI registry at oci://<REGISTRY>/<PARENT_PATH>, chart name auto-appended
	@if [ -z "$(OCI_REGISTRY)" ] || [ -z "$(OCI_PATH)" ]; then echo "OCI_REGISTRY and OCI_PATH are required (e.g., OCI_REGISTRY=quixpublic.azurecr.io OCI_PATH=helm)"; exit 1; fi
	@echo "Pushing to oci://$(OCI_REGISTRY)/$(OCI_PATH) (will become $(OCI_PATH)/$(CHART_NAME):$(CHART_VERSION))"
	helm push $(OUTPUT_DIR)/$(CHART_NAME)-$(CHART_VERSION).tgz oci://$(OCI_REGISTRY)/$(OCI_PATH)


dry-run: deps ## Perform a dry-run installation
	helm install $(RELEASE_NAME) . --namespace $(NAMESPACE) --dry-run --debug

dry-run-dev: ## Perform a dry-run with development values
	helm install $(RELEASE_NAME) . -f values-development.yaml --namespace $(NAMESPACE) --dry-run --debug

clean: ## Clean up generated files
	rm -f *.tgz
	rm -rf charts/


view-docs: ## Open documentation in browser
	@echo "Opening documentation..."
	@echo "Microsoft Entra Integration: docs/microsoft-entra-integration.md"
	@echo "Quick Start: docs/quick-start-microsoft-entra.md"
	@echo "Architecture: docs/architecture-diagram.md"

