# Terraform Reminders

## How to deploy manifests

1. Install Terraform and Azure CLI, then clone this repository.

2. `az login`

3. Create `~/.kube/config`

4. Initialize the Azure remote backend and providers:

   ```bash
   terraform -chdir=terraform/environments/homelab init
   ```

5. `./makeItSo.sh`

## Grafana Password

After applying the monitoring stack, retrieve the generated Grafana administrator password from the Kubernetes secret:

```bash
kubectl get secret -n monitoring grafana-admin -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

## How to Update The Monitoring Chart

The monitoring chart is deliberately pinned in `modules/monitoring/variables.tf`. Check available versions, review the chart's release notes, then update the `chart_version` default:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo prometheus-community/kube-prometheus-stack --versions
```
