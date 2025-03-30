output "cluster_name" {
  description = "O nome do cluster GKE criado."
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "O endpoint do Kubernetes API server."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true # O endpoint pode ser considerado sensível
}

output "cluster_location" {
  description = "A zona onde o cluster foi criado."
  value       = google_container_cluster.primary.location
}

output "node_pool_name" {
  description = "O nome do node pool primário."
  value       = google_container_node_pool.primary_nodes.name
}

output "node_service_account_email" {
  description = "O email da conta de serviço usada pelos nós."
  value       = google_service_account.gke_node_sa.email
}

output "test_app_external_ip" {
  description = "Endereço IP externo do serviço LoadBalancer para o ambiente TEST."
  value       = kubernetes_service.test_app_service.status[0].load_balancer[0].ingress[0].ip
}

output "staging_app_external_ip" {
  description = "Endereço IP externo do serviço LoadBalancer para o ambiente STAGING."
  value       = kubernetes_service.staging_app_service.status[0].load_balancer[0].ingress[0].ip
}

output "prod_app_external_ip" {
  description = "Endereço IP externo do serviço LoadBalancer para o ambiente PROD."
  value       = kubernetes_service.prod_app_service.status[0].load_balancer[0].ingress[0].ip
}
