# my-google-cloud-kubernetes-terraform

## Selecione o projeto google cloud

```bash
gcloud config set project ecstatic-moon-449109-h2
```

## Set enviroments variables

```bash
export PROJECT_ID=$(gcloud config get-value core/project)
```

## crie o bucket

```bash
gsutil mb gs://terraform_tf_state_bucket || true
gsutil versioning set on gs://terraform_tf_state_bucket/ || true
```

## Inicialize o Terraform: No diretório onde salvou os arquivos, execute:

```bash
terraform init \
  -backend-config="bucket=terraform_tf_state_bucket"
# OR
terraform init \
  -backend-config="bucket=terraform_tf_state_bucket" \
  -reconfigure # Use -reconfigure se já tiver inicializado antes sem o backend GCS
```

## Planeje a Aplicação: Veja o que o Terraform fará:

```bash
terraform plan -var="project_id=$PROJECT_ID"
```

## Aplique a Configuração: Crie os recursos no Google Cloud:

```bash
terraform apply -var="project_id=$PROJECT_ID"
```

Confirme digitando yes quando solicitado.

Após a conclusão, o Terraform terá criado:

 - Uma conta de serviço para os nós.

 - Ativado as APIs necessárias.

 - Um cluster GKE zonal em us-east1-b (ou a zona especificada).

 - Um node pool com 1 nó e2-micro, usando a conta de serviço criada e com os escopos OAuth corretos.

 - Três deployments no Kubernetes (test, staging, prod), cada um com 1 pod usando a imagem nginx:alpine.

Para verificar os pods após a criação, configure o kubectl para usar as credenciais do novo cluster (o Terraform pode gerar o comando para você, ou use `gcloud container clusters get-credentials SEU_CLUSTER_NAME --zone SUA_ZONA --project SEU_PROJECT_ID`) e então execute:

```bash
kubectl get pods -l app=my-app
```
