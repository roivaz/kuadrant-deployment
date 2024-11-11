#!/bin/bash

# Define the directory where dashboard files are stored
DASHBOARD_DIR="grafana/dashboards"

# Ensure the dashboard directory exists
mkdir -p "$DASHBOARD_DIR"

# Download and overwrite the JSON dashboard files
curl -sL https://github.com/Kuadrant/kuadrant-operator/raw/main/examples/dashboards/app_developer.json -o "${DASHBOARD_DIR}/grafana-dashboard-app-developer.json"
curl -sL https://github.com/Kuadrant/kuadrant-operator/raw/main/examples/dashboards/platform_engineer.json -o "${DASHBOARD_DIR}/grafana-dashboard-platform-eng.json"
curl -sL https://github.com/Kuadrant/kuadrant-operator/raw/main/examples/dashboards/business_user.json -o "${DASHBOARD_DIR}/grafana-dashboard-business-user.json"
curl -sL https://github.com/Kuadrant/kuadrant-operator/raw/main/examples/dashboards/controller-resources-metrics.json -o "${DASHBOARD_DIR}/grafana-dashboard-controller-resources-metrics.json"
curl -sL https://github.com/Kuadrant/kuadrant-operator/raw/main/examples/dashboards/controller-runtime-metrics.json -o "${DASHBOARD_DIR}/grafana-dashboard-controller-runtime-metrics.json"

echo "Dashboard files updated."
