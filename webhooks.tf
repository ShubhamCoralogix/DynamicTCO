# Webhook 1: ENABLE Policy (Block Logs) - Used by Individual App Alerts
resource "coralogix_webhook" "enable_tco_policy" {
  for_each = toset(local.application_names)
  name     = "Enable-TCO-BlockLogs-${each.key}"

  custom = {
    # URL targets the specific policy ID
    url = "https://api.${var.coralogix_domain}/api/v1/external/tco/policies/${[for p in coralogix_tco_policies_logs.apps.policies : p.id if p.name == "${each.key} - Alert Managed Webhook"][0]}"
    
    method = "put"
    
    headers = {
      "Authorization" = "Bearer ${var.coralogix_api_key}"
      "Content-Type"  = "application/json"
    }
    
    # FIX: Simplified payload explicitly constructing the required fields
    payload = jsonencode({
      name        = "${each.key} - Alert Managed Webhook"
      enabled     = true
      priority    = "block"
      order       = 1
      severities  = [1, 2, 3, 4, 5, 6]
      applicationName = {
        type = "Starts With" # Or "Is" depending on your exact need, working example used "Starts With" but your terraform uses "Is"
        rule = each.key      # Working example had string "payment", not list ["payment"]
      }
    })
  }
}

# Webhook 2: DISABLE Policy (Unblock Logs) - Used by Global Recovery Alert
resource "coralogix_webhook" "disable_tco_policy" {
  for_each = toset(local.application_names)
  name     = "Disable-TCO-AllowLogs-${each.key}"

  custom = {
    # URL targets the specific policy ID
    url = "https://api.${var.coralogix_domain}/api/v1/external/tco/policies/${[for p in coralogix_tco_policies_logs.apps.policies : p.id if p.name == "${each.key} - Alert Managed Webhook"][0]}"
    
    method = "put"
    
    headers = {
      "Authorization" = "Bearer ${var.coralogix_api_key}"
      "Content-Type"  = "application/json"
    }
    
    # FIX: Simplified payload
    payload = jsonencode({
      name        = "${each.key} - Alert Managed Webhook"
      enabled     = false
      priority    = "block"
      order       = 1
      severities  = [1, 2, 3, 4, 5, 6]
      applicationName = {
        type = "Starts With"
        rule = each.key
      }
    })
  }
}