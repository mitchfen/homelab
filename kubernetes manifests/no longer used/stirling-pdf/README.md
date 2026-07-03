```bash
helm repo add stirling https://stirling-tools.github.io/helm-charts
helm repo update
helm install stirling-pdf stirling/stirling-pdf-chart \
  -n stirling-pdf --create-namespace \
  -f values.yaml
```

