output "grafana_admin_password" {
  description = "Generated Grafana administrator password."
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}