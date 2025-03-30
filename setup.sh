
# Esse arquivo é uma obra derivada do projeto
# https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials
# do arquivo `tutorials/base/setup.sh`.
# No arquivo setup.sh.LICENSE está uma cópia da licença para compliance.
# Esse arquivo deriva do original e foi modificado.

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Standard functions begin with manage or run.
# Walkthrough-specific functions begin with the abbreviation for
# that walkthrough
# Current walkthroughs:
# e2e - End-to-end (aka primary) walkthrough

GCLOUD_CONFIG=clouddeploy

export PROJECT_ID=$(gcloud config get-value core/project)
export REGION=us-east1

manage_apis() {
    # Enables any APIs that we need prior to Terraform being run

    echo "Enabling GCP APIs, please wait, this may take several minutes..."
    gcloud services enable storage.googleapis.com \
                           compute.googleapis.com \
                           container.googleapis.com \
                           artifactregistry.googleapis.com
}

manage_configs() {
    # Sets any SDK configs and ensures they'll persist across
    # Cloud Shell sessions

    echo "Creating persistent Cloud Shell configuration"
    SHELL_RC=${HOME}/.$(basename ${SHELL})rc
    echo export CLOUDSDK_CONFIG=${HOME}/.gcloud >> ${SHELL_RC}

    if [[ $(gcloud config configurations list --quiet --filter "name=${GCLOUD_CONFIG}") ]]; then
      echo "Config ${GCLOUD_CONFIG} already exists, skipping config creation"
    else
      gcloud config configurations create ${GCLOUD_CONFIG}
      echo "Created config ${GCLOUD_CONFIG}"
    fi

    gcloud config set project ${PROJECT_ID}
    gcloud config set compute/region ${REGION}
    gcloud config set deploy/region ${REGION}
}

run_terraform() {
    # Terraform workflows

    terraform init
    terraform plan -out=terraform.tfplan  -var="project_id=$PROJECT_ID" -var="region=$REGION"
    terraform apply -auto-approve terraform.tfplan
}

manage_apis()
manage_configs()
run_terraform()
