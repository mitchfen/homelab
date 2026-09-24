variable "namespace" {
  description = "Kubernetes namespace for the monitoring stack."
  type        = string
  default     = "monitoring"
  nullable    = false
}

variable "chart_version" {
  description = "Pinned kube-prometheus-stack Helm chart version."
  type        = string
  default     = "91.5.1"
  nullable    = false
}

variable "storage_class_name" {
  description = "StorageClass used for Grafana and Prometheus persistent data."
  type        = string
  default     = "local-path"
  nullable    = false
}

variable "grafana_storage_size" {
  description = "Persistent storage requested by Grafana."
  type        = string
  default     = "5Gi"
  nullable    = false
}

variable "prometheus_storage_size" {
  description = "Persistent storage requested by Prometheus."
  type        = string
  default     = "50Gi"
  nullable    = false
}

variable "prometheus_retention" {
  description = "How long Prometheus retains collected metrics."
  type        = string
  default     = "15d"
  nullable    = false
}