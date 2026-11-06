output "relay_url" {
  description = "Public HTTPS endpoint for the relay."
  value       = "https://${azurerm_container_app.relay.latest_revision_fqdn}/"
}

output "relay_public_fqdn" {
  description = "Public Azure Container Apps FQDN for the relay."
  value       = azurerm_container_app.relay.latest_revision_fqdn
}

output "relay_websocket_url" {
  description = "Public WebSocket endpoint for Nostr clients."
  value       = "wss://${azurerm_container_app.relay.latest_revision_fqdn}/"
}

output "resource_group_name" {
  description = "Resource group containing the deployment."
  value       = azurerm_resource_group.main.name
}
