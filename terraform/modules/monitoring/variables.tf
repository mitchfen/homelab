variable "namespace" {
  description = "Kubernetes namespace for the monitoring stack."
  type        = string
  default     = "monitoring"
  nullable    = false
}

variable "kube_prometheus_stack_chart_version" {
  description = "Pinned kube-prometheus-stack Helm chart version."
  type        = string
  default     = "91.5.3"
  nullable    = false
}

variable "loki_chart_version" {
  description = "Pinned Loki Helm chart version."
  type        = string
  default     = "7.3.0"
  nullable    = false
}

variable "promtail_chart_version" {
  description = "Pinned Promtail Helm chart version."
  type        = string
  default     = "6.17.1"
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

variable "loki_storage_size" {
  description = "Persistent storage requested by Loki."
  type        = string
  default     = "20Gi"
  nullable    = false
}

variable "prometheus_retention" {
  description = "How long Prometheus retains collected metrics."
  type        = string
  default     = "14d"
  nullable    = false
}
