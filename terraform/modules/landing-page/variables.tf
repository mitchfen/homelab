variable "html_path" {
  description = "Path to the landing page HTML file."
  type        = string
  nullable    = false
}

variable "namespace" {
  description = "Kubernetes namespace for the landing page."
  type        = string
  default     = "landing-page"
  nullable    = false
}