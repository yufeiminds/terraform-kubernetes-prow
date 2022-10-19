output "kube_config_raw" {
  value       = module.aks.kube_admin_config_raw
  sensitive   = true
  description = "Kubernetes configuration for client"
}
