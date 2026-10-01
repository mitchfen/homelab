#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="${SCRIPT_DIR}/modules/monitoring/variables.tf"

if [[ ! -f "${VARIABLES_FILE}" ]]; then
  echo "Error: Cannot find ${VARIABLES_FILE}" >&2
  exit 1
fi

echo "==== Updating Helm Repositories ===="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "==== Finding Latest Chart Versions ===="
LATEST_KUBE_PROM_VERSION="$(helm search repo prometheus-community/kube-prometheus-stack | awk '$1 == "prometheus-community/kube-prometheus-stack" {print $2}')"
LATEST_LOKI_VERSION="$(helm search repo grafana/loki | awk '$1 == "grafana/loki" {print $2}')"

if [[ -z "${LATEST_KUBE_PROM_VERSION}" ]]; then
  echo "Error: Could not determine latest version for prometheus-community/kube-prometheus-stack" >&2
  exit 1
fi

if [[ -z "${LATEST_LOKI_VERSION}" ]]; then
  echo "Error: Could not determine latest version for grafana/loki" >&2
  exit 1
fi

echo "Latest prometheus-community/kube-prometheus-stack: ${LATEST_KUBE_PROM_VERSION}"
echo "Latest grafana/loki:                             ${LATEST_LOKI_VERSION}"

echo "==== Updating ${VARIABLES_FILE} ===="
# Update kube_prometheus_stack_chart_version default in variables.tf
sed -i -E "/variable \"kube_prometheus_stack_chart_version\" \{/,/^\}/ s/(default[[:space:]]*=[[:space:]]*\")[^\"]+(\")/\1${LATEST_KUBE_PROM_VERSION}\2/" "${VARIABLES_FILE}"

# Update loki_chart_version default in variables.tf
sed -i -E "/variable \"loki_chart_version\" \{/,/^\}/ s/(default[[:space:]]*=[[:space:]]*\")[^\"]+(\")/\1${LATEST_LOKI_VERSION}\2/" "${VARIABLES_FILE}"

echo "==== Formatting Terraform files ===="
terraform fmt "${VARIABLES_FILE}"

echo "==== Done ===="
