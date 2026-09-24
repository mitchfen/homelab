resource "kubectl_manifest" "namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = var.namespace
    }
  })
}

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
  version    = var.chart_version
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