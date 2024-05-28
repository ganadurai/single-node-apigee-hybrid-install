output "cluster_name" {
  description = "Cluster name."
  value       = module.gke-cluster.name
}

output "cluster_region" {
  description = "Cluster location."
  value       = module.gke-cluster.location
}

