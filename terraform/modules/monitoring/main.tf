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

# Promtail does nothing except ferry logs between pfBlocker-ng and Loki
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = var.promtail_chart_version
  namespace  = var.namespace

  atomic  = true
  timeout = 600
  wait    = true

  values = [yamlencode({
    # Disable default host/pod log scraping
    config = {
      file_watch_config = {
        enabled = false
      }
      clients = [
        {
          url = "http://loki.${var.namespace}.svc.cluster.local:3100/loki/api/v1/push"
        }
      ]
      snippets = {
        # Overwrite default Kubernetes pod scrape configs so ONLY pfSense is ingested
        scrapeConfigs      = ""
        extraScrapeConfigs = <<-EOT
          - job_name: pfsense-syslog
            syslog:
              listen_address: 0.0.0.0:1514
              listen_protocol: udp
              idle_timeout: 1h
              label_structured_data: yes
              labels:
                job: pfsense
            relabel_configs:
              - source_labels: ['__syslog_message_hostname']
                target_label: 'host'
            pipeline_stages:
              - regex:
                  expression: 'DNSBL-python,[^,]+,(?P<queried_domain>[^,]+),(?P<client_ip>[^,]+),(?P<resolver>[^,]+),(?P<block_type>[^,]+),(?P<list_name>[^,]+),(?P<matched_domain>[^,]+),(?P<feed>[^,]+),(?P<action>[^,\s]+)'
              - labels:
                  queried_domain: ''
                  client_ip: ''
                  resolver: ''
                  block_type: ''
                  list_name: ''
                  matched_domain: ''
                  feed: ''
                  action: ''
        EOT
      }
    }
    extraPorts = {
      syslog = {
        name          = "syslog"
        containerPort = 1514
        protocol      = "UDP"
        service = {
          type     = "NodePort"
          port     = 1514
          nodePort = 32747
        }
      }
    }
  })]

  depends_on = [helm_release.loki]
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
