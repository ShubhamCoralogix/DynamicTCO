# =============================================================
# APPLICATION-WISE WEBHOOKS
# =============================================================

# Webhook: ENABLE app policy (Block Logs)
resource "coralogix_webhook" "enable_tco_policy_app" {
  for_each = toset(local.application_names)
  name     = "Enable-TCO-App-BlockLogs-${each.key}"

  custom = {
    url = "https://api.${var.coralogix_domain}/api/v1/external/tco/policies/${[
      for p in coralogix_tco_policies_logs.apps.policies : p.id
      if p.name == "${each.key} - Alert Managed Webhook"
    ][0]}"

    method = "put"

    headers = {
      "Authorization" = "Bearer ${var.coralogix_api_key}"
      "Content-Type"  = "application/json"
    }

    payload = jsonencode({
      name       = "${each.key} - Alert Managed Webhook"
      enabled    = true
      priority   = "block"
      order      = 1
      severities = [1, 2, 3, 4, 5, 6]
      applicationName = {
        type = "Starts With"
        rule = each.key
      }
    })
  }
}

# Webhook: DISABLE app policy (Unblock Logs)
resource "coralogix_webhook" "disable_tco_policy_app" {
  for_each = toset(local.application_names)
  name     = "Disable-TCO-App-AllowLogs-${each.key}"

  custom = {
    url = "https://api.${var.coralogix_domain}/api/v1/external/tco/policies/${[
      for p in coralogix_tco_policies_logs.apps.policies : p.id
      if p.name == "${each.key} - Alert Managed Webhook"
    ][0]}"

    method = "put"

    headers = {
      "Authorization" = "Bearer ${var.coralogix_api_key}"
      "Content-Type"  = "application/json"
    }

    payload = jsonencode({
      name       = "${each.key} - Alert Managed Webhook"
      enabled    = false
      priority   = "block"
      order      = 1
      severities = [1, 2, 3, 4, 5, 6]
      applicationName = {
        type = "Starts With"
        rule = each.key
      }
    })
  }
}

# =============================================================
# SUBSYSTEM-WISE WEBHOOKS
# =============================================================

# Webhook: ENABLE subsystem policy (Block Logs)
resource "coralogix_webhook" "enable_tco_policy_subsystem" {
  for_each = toset(local.subsystem_names)
  name     = "Enable-TCO-Subsystem-BlockLogs-${each.key}"

  custom = {
    url = "https://api.${var.coralogix_domain}/api/v1/external/tco/policies/${[
      for p in coralogix_tco_policies_logs.apps.policies : p.id
      if p.name == "${each.key} - Subsystem Alert Managed Webhook"
    ][0]}"

    method = "put"

    headers = {
      "Authorization" = "Bearer ${var.coralogix_api_key}"
      "Content-Type"  = "application/json"
    }

    payload = jsonencode({
      name       = "${each.key} - Subsystem Alert Managed Webhook"
      enabled    = true
      priority   = "block"
      order      = 1
      severities = [1, 2, 3, 4, 5, 6]
      subsystemName = {
        type = "Starts With"
        rule = each.key
      }
    })
  }
}

# Webhook: DISABLE subsystem policy (Unblock Logs)
resource "coralogix_webhook" "disable_tco_policy_subsystem" {
  for_each = toset(local.subsystem_names)
  name     = "Disable-TCO-Subsystem-AllowLogs-${each.key}"

  custom = {
    url = "https://api.${var.coralogix_domain}/api/v1/external/tco/policies/${[
      for p in coralogix_tco_policies_logs.apps.policies : p.id
      if p.name == "${each.key} - Subsystem Alert Managed Webhook"
    ][0]}"

    method = "put"

    headers = {
      "Authorization" = "Bearer ${var.coralogix_api_key}"
      "Content-Type"  = "application/json"
    }

    payload = jsonencode({
      name       = "${each.key} - Subsystem Alert Managed Webhook"
      enabled    = false
      priority   = "block"
      order      = 1
      severities = [1, 2, 3, 4, 5, 6]
      subsystemName = {
        type = "Starts With"
        rule = each.key
      }
    })
  }
}