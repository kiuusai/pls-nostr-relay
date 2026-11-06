variable "name_prefix" {
  description = "Short prefix used to name Azure resources."
  type        = string
  default     = "pls-nostr"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "East US"
}

variable "relay_image" {
  description = "Public Docker Hub image containing this project's Dockerfile, config template, and entrypoint (for example, docker.io/your-user/pls-nostr-relay:latest)."
  type        = string

  validation {
    condition     = can(regex("^(docker[.]io/)?[a-z0-9][a-z0-9._/-]*:[A-Za-z0-9_][A-Za-z0-9_.-]*$", var.relay_image))
    error_message = "relay_image must be a Docker Hub image reference with an explicit tag."
  }
}

variable "relay_name" {
  description = "Nostr relay display name."
  type        = string
  default     = "Private Law Society Nostr relay"
}

variable "relay_description" {
  description = "Nostr relay description."
  type        = string
  default     = "Private Law Society Nostr relay."
}

variable "reject_future_seconds" {
  description = "Maximum allowed event timestamp drift into the future."
  type        = number
  default     = 1800
}

variable "subscriptions_per_min" {
  description = "Maximum subscriptions per minute for a client."
  type        = number
  default     = 10
}

variable "postgres_storage_gib" {
  description = "Azure Files capacity reserved for the Postgres share, in GiB."
  type        = number
  default     = 100
}

variable "postgres_image" {
  description = "Postgres container image from Docker Hub."
  type        = string
  default     = "docker.io/library/postgres:16-alpine"
}
