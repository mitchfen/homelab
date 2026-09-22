resource "kubectl_manifest" "namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = var.namespace
    }
  })
}

resource "kubectl_manifest" "html" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "landing-page-html"
      namespace = var.namespace
    }
    data = {
      "index.html" = file(var.html_path)
    }
  })

  depends_on = [kubectl_manifest.namespace]
}

resource "kubectl_manifest" "deployment" {
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "landing-page"
      namespace = var.namespace
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

  depends_on = [kubectl_manifest.html]
}

resource "kubectl_manifest" "service" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "landing-page"
      namespace = var.namespace
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

  depends_on = [kubectl_manifest.namespace]
}