resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_password" "postgres" {
  length  = 32
  special = false
}

locals {
  suffix              = random_string.suffix.result
  resource_group_name  = "${var.name_prefix}-${local.suffix}-rg"
  environment_name     = "${var.name_prefix}-${local.suffix}-env"
  relay_app_name       = "${var.name_prefix}-${local.suffix}-relay"
  storage_account_name = "${replace(var.name_prefix, "-", "")}${local.suffix}"
  postgres_host        = azurerm_container_app.postgres.latest_revision_fqdn
  database_url         = "postgresql://nostr:${random_password.postgres.result}@${local.postgres_host}:5432/nostr"
  relay_url            = "https://${local.relay_app_name}.${azurerm_container_app_environment.main.default_domain}/"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-${local.suffix}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = local.environment_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_storage_account" "postgres" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_share" "postgres" {
  name               = "postgres-data"
  storage_account_id = azurerm_storage_account.postgres.id
  quota              = var.postgres_storage_gib
}

resource "azurerm_container_app_environment_storage" "postgres" {
  name                         = "postgres-files"
  container_app_environment_id = azurerm_container_app_environment.main.id
  account_name                 = azurerm_storage_account.postgres.name
  share_name                   = azurerm_storage_share.postgres.name
  access_key                   = azurerm_storage_account.postgres.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "postgres" {
  name                         = "${var.name_prefix}-${local.suffix}-db"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  secret {
    name  = "postgres-password"
    value = random_password.postgres.result
  }

  ingress {
    external_enabled = false
    target_port      = 5432
    transport        = "tcp"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    tcp_scale_rule {
      name                = "postgres-connections"
      concurrent_requests = "1"
    }

    volume {
      name         = "postgres-data"
      storage_name = azurerm_container_app_environment_storage.postgres.name
      storage_type = "AzureFile"
      mount_options = "dir_mode=0777,file_mode=0777,uid=999,gid=999"
    }

    container {
      name   = "postgres"
      image  = var.postgres_image
      cpu    = 1
      memory = "2Gi"

      env {
        name  = "POSTGRES_DB"
        value = "nostr"
      }

      env {
        name  = "POSTGRES_USER"
        value = "nostr"
      }

      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "postgres-password"
      }

      volume_mounts {
        name = "postgres-data"
        path = "/var/lib/postgresql/data"
      }
    }
  }
}

resource "azurerm_container_app" "relay" {
  name                         = local.relay_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  secret {
    name  = "database-url"
    value = local.database_url
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    http_scale_rule {
      name                = "relay-requests"
      concurrent_requests = "10"
    }

    container {
      name   = "relay"
      image  = var.relay_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      env {
        name  = "RELAY_URL"
        value = local.relay_url
      }

      env {
        name  = "RELAY_NAME"
        value = var.relay_name
      }

      env {
        name  = "RELAY_DESCRIPTION"
        value = var.relay_description
      }

      env {
        name  = "RELAY_PORT"
        value = "8080"
      }

      env {
        name  = "REJECT_FUTURE_SECONDS"
        value = tostring(var.reject_future_seconds)
      }

      env {
        name  = "SUBSCRIPTIONS_PER_MIN"
        value = tostring(var.subscriptions_per_min)
      }
    }
  }
}
