# Fetch ALL existing TCO policies from Coralogix before we apply anything.
# This lets us preserve policies we don't manage here.
data "coralogix_tco_policies_logs" "existing" {}

locals {
  # 1. Load the raw file
  raw_file_content = trimspace(file("${path.module}/applications.txt"))

  # 2. Parse into a Map: { "app_name" = limit_number }
  app_limits = {
    for line in split("\n", local.raw_file_content) :
      trimspace(split(",", line)[0]) => tonumber(trimspace(split(",", line)[1]))
      if length(split(",", line)) >= 2
  }

  # 3. List of names for use in other .tf files
  application_names = keys(local.app_limits)

  # 4. Total limit across all apps (used by the global recovery alert)
  total_system_limit = sum(values(local.app_limits))

  # -----------------------------------------------------------------------
  # MERGE LOGIC: preserve unmanaged policies and avoid deleting them
  # -----------------------------------------------------------------------

  # Names of every policy this Terraform config owns.
  # Any policy NOT in this set is considered "unmanaged" and must be kept as-is.
  managed_policy_names = toset([
    for app in local.application_names : "${app} - Alert Managed Webhook"
  ])

  # Existing policies that belong to someone else — pass them through unchanged.
  unmanaged_existing_policies = [
    for p in data.coralogix_tco_policies_logs.existing.policies :
    {
      name                 = p.name
      description          = p.description
      enabled              = p.enabled
      priority             = p.priority
      severities           = p.severities
      applications         = p.applications
      subsystems           = p.subsystems
      archive_retention_id = p.archive_retention_id
    }
    if !contains(local.managed_policy_names, p.name)
  ]

  # Policies this config owns (one per app in applications.txt).
  # For apps already in Coralogix we preserve their current `enabled` state
  # so that Terraform doesn't undo what webhooks have set.
  # For brand-new apps `enabled` defaults to false.
  managed_policies = [
    for app in local.application_names : {
      name        = "${app} - Alert Managed Webhook"
      description = "TCO policy to block logs for ${app} when enabled"
      enabled = try(
        [for p in data.coralogix_tco_policies_logs.existing.policies : p.enabled
        if p.name == "${app} - Alert Managed Webhook"][0],
        false
      )
      priority   = "block"
      severities = ["critical", "error", "warning", "info", "debug", "verbose"]
      applications = {
        names     = [app]
        rule_type = "is"
      }
    }
  ]

  # Final list sent to the resource:
  #   1. Unmanaged existing policies  (preserved in original order)
  #   2. Our managed policies          (new apps appended at the end)
  tco_policies_logs = concat(local.unmanaged_existing_policies, local.managed_policies)
}
