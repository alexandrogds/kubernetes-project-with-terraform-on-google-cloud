# my-google-cloud-kubernetes-terraform

## Inicialize o Terraform: No diretório onde salvou os arquivos, execute:

```
terraform init
```

## Planeje a Aplicação: Veja o que o Terraform fará:

```
terraform plan -var="project_id=$PROJECT_ID"
```

## Aplique a Configuração: Crie os recursos no Google Cloud:

```
terraform apply
```

Confirme digitando yes quando solicitado.

Após a conclusão, o Terraform terá criado:

 - Uma conta de serviço para os nós.

 - Ativado as APIs necessárias.

 - Um cluster GKE zonal em us-east1-b (ou a zona especificada).

 - Um node pool com 1 nó e2-micro, usando a conta de serviço criada e com os escopos OAuth corretos.

 - Três deployments no Kubernetes (test, staging, prod), cada um com 1 pod usando a imagem nginx:alpine.

Para verificar os pods após a criação, configure o kubectl para usar as credenciais do novo cluster (o Terraform pode gerar o comando para você, ou use `gcloud container clusters get-credentials SEU_CLUSTER_NAME --zone SUA_ZONA --project SEU_PROJECT_ID`) e então execute:

```
kubectl get pods -l app=my-app
```
