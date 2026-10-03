#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT_DIR="${REPOSITORY_ROOT}/terraform/environments/homelab"
KUBECONFIG_PATH="${HOME}/.kube/config"

#echo "==== terraform init ===="
#terraform -chdir="${ENVIRONMENT_DIR}" init -input=false
#echo Done.
echo "==== terraform fmt ===="
terraform fmt -recursive "${REPOSITORY_ROOT}/terraform"
echo Done.
echo "==== terraform validate ===="
terraform -chdir="${ENVIRONMENT_DIR}" validate
echo Done.
echo "==== terraform apply ===="
exec terraform -chdir="${ENVIRONMENT_DIR}" apply -var="kubeconfig_path=${KUBECONFIG_PATH}"
echo Done.