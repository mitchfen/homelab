#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT_DIR="${REPOSITORY_ROOT}/terraform/environments/homelab"
KUBECONFIG_PATH="${HOME}/.kube/config"

terraform -chdir="${ENVIRONMENT_DIR}" init -input=false
terraform fmt -check -recursive "${REPOSITORY_ROOT}/terraform"
terraform -chdir="${ENVIRONMENT_DIR}" validate

exec terraform -chdir="${ENVIRONMENT_DIR}" apply -var="kubeconfig_path=${KUBECONFIG_PATH}"