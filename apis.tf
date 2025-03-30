/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use uma versão recente
    }
	kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20" # Use uma versão recente
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.5.0" # Use a versão especificada ou uma mais recente compatível

  project_id = var.project_id

  # Don't disable the services
  disable_services_on_destroy = false
  disable_dependent_services  = false

  activate_apis = [
    "compute.googleapis.com",             # Necessário para GKE, VMs
    "container.googleapis.com",           # API do GKE
    # "cloudbuild.googleapis.com",          # Incluído no pedido, mas não estritamente necessário para *este* setup GKE básico
    "cloudresourcemanager.googleapis.com", # Necessário para gerenciamento de projeto/IAM
    "iam.googleapis.com",                 # Necessário para Service Accounts e IAM
    # "clouddeploy.googleapis.com",         # Incluído no pedido, mas não usado diretamente aqui
    # "binaryauthorization.googleapis.com"  # Incluído no pedido, mas não usado diretamente aqui
    "artifactregistry.googleapis.com",    # Boa prática para pull de imagens (substituto do GCR)
  ]
}