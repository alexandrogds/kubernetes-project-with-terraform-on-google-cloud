variable "project_id" {
  description = "O ID do seu projeto Google Cloud."
  type        = string
}

variable "region" {
  description = "A região para criar os recursos."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "A zona para criar o cluster GKE."
  type        = string
  default     = "us-east1-b" # Escolha uma zona dentro da região us-east1
}

variable "cluster_name" {
  description = "O nome do cluster GKE."
  type        = string
  default     = "meu-cluster-zonal"
}

variable "gke_node_machine_type" {
  description = "O tipo de máquina para os nós do GKE."
  type        = string
  default     = "e2-micro"
}

variable "gke_node_sa_name" {
  description = "O nome curto para a conta de serviço dos nós do GKE."
  type        = string
  default     = "gke-node-sa"
}

variable "mail" {
  description = "O email do admin."
  type        = string
  default     = "alexandrogonsan@outlook.com"
}
