provider "kubectl" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

data "kubectl_file_documents" "manifests" {
  for_each = toset(fileset("${path.module}/../manifests", "**/*.yaml"))
  content  = file("${path.module}/../manifests/${each.value}")
}

locals {
  manifest_documents = {
    for filename, manifest in data.kubectl_file_documents.manifests :
    filename => one(manifest.documents)
    if !strcontains(filename, ".template.")
  }

  namespace_documents = {
    for filename, document in local.manifest_documents :
    filename => document
    if yamldecode(document).kind == "Namespace"
  }

  storage_class_documents = {
    for filename, document in local.manifest_documents :
    filename => document
    if yamldecode(document).kind == "StorageClass"
  }

  persistent_volume_claim_documents = {
    for filename, document in local.manifest_documents :
    filename => document
    if yamldecode(document).kind == "PersistentVolumeClaim"
  }

  workload_documents = {
    for filename, document in local.manifest_documents :
    filename => document
    if !contains(["Namespace", "PersistentVolumeClaim", "StorageClass"], yamldecode(document).kind)
  }
}

resource "kubectl_manifest" "namespaces" {
  for_each  = local.namespace_documents
  yaml_body = each.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubectl_manifest" "storage_classes" {
  for_each  = local.storage_class_documents
  yaml_body = each.value
}

resource "kubectl_manifest" "persistent_volume_claims" {
  for_each  = local.persistent_volume_claim_documents
  yaml_body = each.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubectl_manifest" "workloads" {
  for_each  = local.workload_documents
  yaml_body = each.value

  depends_on = [kubectl_manifest.namespaces, kubectl_manifest.persistent_volume_claims, kubectl_manifest.storage_classes]
}

resource "kubectl_manifest" "landing_page_namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "landing-page"
    }
  })
}

resource "kubectl_manifest" "landing_page_html" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "landing-page-html"
      namespace = "landing-page"
    }
    data = {
      "index.html" = file("${path.module}/../landing-page/index.html")
    }
  })

  depends_on = [kubectl_manifest.landing_page_namespace]
}

resource "kubectl_manifest" "landing_page" {
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "landing-page"
      namespace = "landing-page"
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "landing-page"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "landing-page"
          }
        }
        spec = {
          containers = [{
            name  = "nginx"
            image = "nginx:latest"
            ports = [{
              containerPort = 80
            }]
            volumeMounts = [{
              name      = "html"
              mountPath = "/usr/share/nginx/html"
            }]
            resources = {
              requests = {
                memory = "32Mi"
                cpu    = "10m"
              }
              limits = {
                memory = "64Mi"
                cpu    = "100m"
              }
            }
          }]
          volumes = [{
            name = "html"
            configMap = {
              name = "landing-page-html"
              items = [{
                key  = "index.html"
                path = "index.html"
              }]
            }
          }]
        }
      }
    }
  })

  depends_on = [kubectl_manifest.landing_page_html]
}

resource "kubectl_manifest" "landing_page_service" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "landing-page"
      namespace = "landing-page"
    }
    spec = {
      type = "ClusterIP"
      selector = {
        app = "landing-page"
      }
      ports = [{
        protocol   = "TCP"
        port       = 80
        targetPort = 80
      }]
    }
  })

  depends_on = [kubectl_manifest.landing_page_namespace]
}