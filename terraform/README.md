# Azure deployment

This Terraform configuration deploys the relay and Postgres as Azure Container Apps. Both apps can scale to zero while idle; the relay scales on HTTP requests and Postgres scales on TCP connections, with each capped at one replica. It creates an Azure Files share for Postgres data and mounts it at `/var/lib/postgresql/data`. The relay is externally reachable over HTTPS/WSS, while Postgres has internal TCP ingress only. Requests after scale-to-zero can have a cold-start delay, and the relay may need to retry a database connection while Postgres starts.

The relay image must be published to Docker Hub and must be built from this repository's Dockerfile so it contains the bundled `config.toml` template and config-rendering entrypoint. Terraform does not build or publish the image. There is no Azure Container Registry in this configuration.

## Deploy

1. Build and push the project image to a public Docker Hub repository.
2. Sign in to Azure with the Azure CLI (`az login`) and select the intended subscription (`az account set --subscription ...`).
3. From this directory, initialize Terraform and apply with the image reference:

   ```sh
   terraform init
   terraform apply -var='relay_image=docker.io/YOUR_DOCKERHUB_USER/pls-nostr-relay:TAG'
   ```

The AzureRM provider uses the active Azure CLI credentials. Terraform generates a Postgres password and stores it in Terraform state, so protect the state file and any remote backend that stores it.

## Configuration

`location`, `name_prefix`, relay metadata, ingress port, Postgres image, and Azure Files quota can be overridden with `-var` or a `terraform.tfvars` file. The relay Docker Hub image is required. For example:

```hcl
relay_image          = "docker.io/YOUR_DOCKERHUB_USER/pls-nostr-relay:TAG"
location             = "East US"
postgres_storage_gib = 100
```

The relay's Container Apps ingress uses port 8080 and maps to the image's `RELAY_PORT=8080`. Azure assigns the public HTTPS endpoint and does not expose a custom port mapping.

## Storage note

Azure Container Apps supports Azure Files SMB mounts. This configuration follows the requested Postgres-on-Azure-Files layout and pins Postgres to one replica. Azure Files SMB is file-share storage, not a managed PostgreSQL service; validate the workload's durability, locking, and performance requirements before using it for production database data.
