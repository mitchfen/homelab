resource "kubectl_manifest" "namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = var.namespace
    }
  })
}

# Note: This is not a production grade setup. The password is persisted in state. 
# The state is protected by Azure RBAC and IP whitelisting which disallows any traffic to the storage account not from my IP. 
# In a real production environment, I would use an Azure Key Vault.
resource "random_password" "grafana_admin" {
  length  = 32
  special = true
}

resource "kubectl_manifest" "grafana_admin" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "grafana-admin"
      namespace = var.namespace
    }
    type = "Opaque"
    data = {
      "admin-user"     = base64encode("admin")
      "admin-password" = base64encode(random_password.grafana_admin.result)
    }
  })

  depends_on = [kubectl_manifest.namespace]
}

resource "helm_release" "monitoring" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_chart_version
  namespace  = var.namespace

  atomic  = true
  timeout = 600
  wait    = true

  values = [yamlencode({
    grafana = {
      admin = {
        existingSecret = "grafana-admin"
        userKey        = "admin-user"
        passwordKey    = "admin-password"
      }
      persistence = {
        enabled          = true
        size             = var.grafana_storage_size
        storageClassName = var.storage_class_name
      }
      # Provision Loki automatically as a Grafana data source
      additionalDataSources = [
        {
          name      = "Loki"
          type      = "loki"
          access    = "proxy"
          url       = "http://loki.${var.namespace}.svc.cluster.local:3100"
          isDefault = false
        }
      ]
    }
    prometheus = {
      prometheusSpec = {
        retention = var.prometheus_retention
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = var.storage_class_name
              resources = {
                requests = {
                  storage = var.prometheus_storage_size
                }
              }
            }
          }
        }
      }
    }
  })]

  depends_on = [kubectl_manifest.grafana_admin]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.loki_chart_version
  namespace  = var.namespace

  atomic  = true
  timeout = 600
  wait    = true

  values = [yamlencode({
    deploymentMode = "SingleBinary"
    loki = {
      auth_enabled = false
      commonConfig = {
        replication_factor = 1
      }
      limits_config = {
        retention_period = "30d"
      }
      compactor = {
        retention_enabled    = true
        delete_request_store = "filesystem"
      }
      schemaConfig = {
        configs = [
          {
            from         = "2024-04-01"
            store        = "tsdb"
            object_store = "filesystem"
            schema       = "v13"
            index = {
              prefix = "index_"
              period = "24h"
            }
          }
        ]
      }
      storage = {
        type = "filesystem"
      }
    }
    singleBinary = {
      replicas = 1
      persistence = {
        enabled          = true
        size             = var.loki_storage_size
        storageClassName = var.storage_class_name
      }
    }
    backend       = { replicas = 0 }
    read          = { replicas = 0 }
    write         = { replicas = 0 }
    ingester      = { replicas = 0 }
    querier       = { replicas = 0 }
    queryFrontend = { replicas = 0 }
  })]

  depends_on = [kubectl_manifest.namespace]
}


resource "kubectl_manifest" "dashboard_homelab_overview" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "grafana-dashboard-homelab-overview"
      namespace = var.namespace
      labels = {
        grafana_dashboard = "1"
      }
    }
    data = {
      "homelab-overview.json" = file("${path.module}/dashboards/homelab-overview.json")
    }
  })

  depends_on = [kubectl_manifest.namespace]
}
