#terraform {
#  required_providers {
#    google = {
#      source  = "hashicorp/google"
#      version = "~> 5.0"
#    }
#    kubernetes = {
#      source  = "hashicorp/kubernetes"
#      version = "~> 2.20" # Use uma versão recente
#    }
#  }
#}

#provider "google" {
#  # Configurado em apis.tf
#}

# Conta de Serviço para os Nós do GKE
resource "google_service_account" "gke_node_sa" {
  project      = var.project_id
  account_id   = var.gke_node_sa_name
  display_name = "Service Account for GKE nodes"
}

# Permissões MÍNIMAS recomendadas para a conta de serviço dos nós
# Mesmo sem o Cloud Monitoring habilitado explicitamente, os nós podem precisar
# dessas permissões para operações básicas ou futuras integrações.
# A permissão artifactregistry é útil se você usar o Artifact Registry para imagens.
#resource "google_project_iam_member" "gke_node_sa_logging" {
#  project = var.project_id
#  role    = "roles/logging.logWriter"
#  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
#}

#resource "google_project_iam_member" "gke_node_sa_monitoring_viewer" {
#  project = var.project_id
#  role    = "roles/monitoring.viewer"
#  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
#}

#resource "google_project_iam_member" "gke_node_sa_monitoring_metric_writer" {
#  project = var.project_id
#  role    = "roles/monitoring.metricWriter"
#  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
#}

# Se for usar Artifact Registry para suas imagens
#resource "google_project_iam_member" "gke_node_sa_artifactregistry_reader" {
#  project = var.project_id
#  role    = "roles/artifactregistry.reader"
#  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
#}

# Cluster GKE Zonal
resource "google_container_cluster" "primary" {
  project                = var.project_id
  name                   = var.cluster_name
  location               = var.zone # Define como Zonal usando a variável de zona
  remove_default_node_pool = true     # Removemos o pool padrão para definir o nosso com configurações específicas
  initial_node_count   = 1     # Necessário mesmo com remove_default_node_pool=true

  # Desabilitar Monitoramento e Logging do GKE (conforme solicitado)
  #logging_service        = "logging.googleapis.com/none"
  #monitoring_service     = "monitoring.googleapis.com/none"

  # Networking (usando padrão por simplicidade)
  # network    = google_compute_network.vpc_network.name
  # subnetwork = google_compute_subnetwork.vpc_subnetwork.name

  # Configuração básica, outras opções podem ser adicionadas conforme necessário
  timeouts {
    create = "30m"
    update = "40m"
  }

  depends_on = [
    module.project-services # Garante que as APIs estejam ativas antes de criar o cluster
  ]
}

# Node Pool Personalizado
resource "google_container_node_pool" "primary_nodes" {
  project    = var.project_id
  name       = "default-pool" # Nome do node pool
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1 # Número inicial e fixo de nós (sem autoscaling)

  # NÃO incluir o bloco 'autoscaling' para desabilitar o autoscaling

  node_config {
    machine_type = var.gke_node_machine_type # Tipo de máquina e2-micro
    service_account = google_service_account.gke_node_sa.email # Usar nossa SA customizada

    # Escopos OAuth para permitir acesso a APIs do Google Cloud pelos nós
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Escopo amplo, controlado por IAM
      # Escopos mais específicos podem ser usados se necessário, por exemplo:
      # "https://www.googleapis.com/auth/compute",
      # "https://www.googleapis.com/auth/devstorage.read_only",
      # "https://www.googleapis.com/auth/logging.write",
      # "https://www.googleapis.com/auth/monitoring",
    ]

    # Metadata, tags, etc., podem ser adicionados aqui se necessário
  }

  timeouts {
    create = "30m"
    update = "20m"
  }

  management {
    auto_repair  = true # Recomendado
    auto_upgrade = true # Recomendado
  }
}

# --- Configuração do Provedor Kubernetes ---
# Obtém as credenciais do cluster GKE criado para configurar o provedor Kubernetes

data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  # Usamos um data source para buscar informações atualizadas após a criação/atualização
  # Isso evita problemas de dependência cíclica ou informações desatualizadas
  project  = var.project_id
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location

  depends_on = [
     google_container_node_pool.primary_nodes # Garante que o node pool está pronto
   ]
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

# Concede permissões de cluster-admin ao usuário que executa o Terraform
resource "kubernetes_cluster_role_binding" "terraform_admin" {
  metadata {
    name = "terraform-user-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin" # Papel com controle total
  }
  subject {
    kind      = "User"
    name      = var.mail
    api_group = "rbac.authorization.k8s.io"
  }

  # Garante que o cluster exista antes de tentar criar o binding
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes # Importante esperar o node pool tbm
  ]
}

# --- Deployments Kubernetes ---

# Deployment para o ambiente TEST
resource "kubernetes_deployment" "test_app" {
  metadata {
    name = "test-app-deployment"
    labels = {
      app = "my-app"
      env = "test"
    }
  }

  spec {
    replicas = 1 # Um pod para test

    selector {
      match_labels = {
        app = "my-app"
        env = "test"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
          env = "test"
        }
      }

      spec {
        container {
          image = "nginx:alpine" # Imagem de exemplo
          name  = "nginx-test"
          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_cluster_role_binding.terraform_admin
  ]
}

# Deployment para o ambiente STAGING
resource "kubernetes_deployment" "staging_app" {
  metadata {
    name = "staging-app-deployment"
    labels = {
      app = "my-app"
      env = "staging"
    }
  }

  spec {
    replicas = 1 # Um pod para staging

    selector {
      match_labels = {
        app = "my-app"
        env = "staging"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
          env = "staging"
        }
      }

      spec {
        container {
          image = "nginx:alpine" # Imagem de exemplo
          name  = "nginx-staging"
          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_cluster_role_binding.terraform_admin
  ]
}

# Deployment para o ambiente PROD
resource "kubernetes_deployment" "prod_app" {
  metadata {
    name = "prod-app-deployment"
    labels = {
      app = "my-app"
      env = "prod"
    }
  }

  spec {
    replicas = 1 # Um pod para prod

    selector {
      match_labels = {
        app = "my-app"
        env = "prod"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
          env = "prod"
        }
      }

      spec {
        container {
          image = "nginx:alpine" # Imagem de exemplo
          name  = "nginx-prod"
          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_cluster_role_binding.terraform_admin
  ]
}

# --- Serviços Kubernetes (LoadBalancer) ---

# Serviço para expor o Deployment TEST
resource "kubernetes_service" "test_app_service" {
  metadata {
    name = "test-app-service" # Nome do serviço Kubernetes
    labels = {
      app = kubernetes_deployment.test_app.metadata[0].labels.app
      env = kubernetes_deployment.test_app.metadata[0].labels.env
    }
  }
  spec {
    selector = {
      # Seleciona os pods criados pelo deployment de TEST
      app = kubernetes_deployment.test_app.spec[0].template[0].metadata[0].labels.app
      env = kubernetes_deployment.test_app.spec[0].template[0].metadata[0].labels.env
    }
    port {
      port        = 80 # Porta que o Load Balancer externo escutará
      target_port = 80 # Porta que o container (nginx) dentro do Pod escuta
      protocol    = "TCP"
    }
    type = "LoadBalancer" # Tipo de serviço para obter um IP público via Load Balancer do GCP
  }

  # Garante que o deployment exista antes de tentar criar o serviço
  # Embora não estritamente necessário para criação (o LB pode esperar pelos pods),
  # é uma boa prática para clareza.
  depends_on = [kubernetes_deployment.test_app]
}

# Serviço para expor o Deployment STAGING
resource "kubernetes_service" "staging_app_service" {
  metadata {
    name = "staging-app-service"
    labels = {
      app = kubernetes_deployment.staging_app.metadata[0].labels.app
      env = kubernetes_deployment.staging_app.metadata[0].labels.env
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.staging_app.spec[0].template[0].metadata[0].labels.app
      env = kubernetes_deployment.staging_app.spec[0].template[0].metadata[0].labels.env
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "LoadBalancer"
  }
  depends_on = [kubernetes_deployment.staging_app]
}

# Serviço para expor o Deployment PROD
resource "kubernetes_service" "prod_app_service" {
  metadata {
    name = "prod-app-service"
    labels = {
      app = kubernetes_deployment.prod_app.metadata[0].labels.app
      env = kubernetes_deployment.prod_app.metadata[0].labels.env
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.prod_app.spec[0].template[0].metadata[0].labels.app
      env = kubernetes_deployment.prod_app.spec[0].template[0].metadata[0].labels.env
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "LoadBalancer"
  }
  depends_on = [kubernetes_deployment.prod_app]
}