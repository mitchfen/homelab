variable "kubeconfig_path" {
  description = "Absolute path to the kubeconfig used to connect to the k3s cluster."
  type        = string
  nullable    = false
}

variable "kubeconfig_context" {
  description = "Optional kubeconfig context name."
  type        = string
  default     = "default"
}