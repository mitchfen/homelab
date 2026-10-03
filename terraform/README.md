# Terraform Reminders

## How to deploy manifests

1. Install Terraform and Azure CLI, then clone this repository.

2. `az login`

3. Create `~/.kube/config`

4. `./makeItSo.sh`

## Grafana Password

The Grafana admin secret is managed out-of-band in Kubernetes to keep credentials out of Terraform state.

To retrieve the current Grafana administrator password from the cluster:

```bash
kubectl get secret -n monitoring grafana-admin -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

To create or rotate the secret out-of-band:

```bash
kubectl create secret generic grafana-admin \
  -n monitoring \
  --from-literal=admin-user='admin' \
  --from-literal=admin-password='<STRONG_PASSWORD>' \
  --dry-run=client -o yaml | kubectl apply -f -
```

> **Note:** Credentials are deliberately managed out-of-band so no plain-text passwords or secret tokens are persisted inside the Terraform state file. In an enterprise production setting, an external secret manager (e.g. Azure Key Vault, HashiCorp Vault) paired with the External Secrets Operator or Secrets Store CSI Driver would synchronize the secret directly into the cluster.

## How to Update The Monitoring Chart

You can automatically check available chart versions and update `modules/monitoring/variables.tf` by running:

```bash
./update-monitoring-charts.sh
```

Or perform the steps manually:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm search repo prometheus-community/kube-prometheus-stack 
helm search repo grafana/loki
```

