# Fetch ALL existing TCO policies from Coralogix before we apply anything.
data "coralogix_tco_policies_logs" "existing" {}

locals {
  # -----------------------------------------------------------------------
  # 1. PARSE applications.txt
  #    Format: type, name, limit
  #    Lines starting with '#' are ignored as comments.
  # -----------------------------------------------------------------------
  raw_file_content = trimspace(file("${path.module}/applications.txt"))

  all_entries = [
    for line in split("\n", local.raw_file_content) :
    {
      type  = trimspace(split(",", line)[0])
      name  = trimspace(split(",", line)[1])
      limit = tonumber(trimspace(split(",", line)[2]))
    }
    if length(split(",", line)) >= 3 && !startswith(trimspace(line), "#")
  ]

  # -----------------------------------------------------------------------
  # 2. APPLICATION-WISE MAPS
  # -----------------------------------------------------------------------
  app_limits = {
    for e in local.all_entries :
    e.name => e.limit
    if e.type == "app"
  }
  application_names = keys(local.app_limits)

  # -----------------------------------------------------------------------
  # 3. SUBSYSTEM-WISE MAPS
  # -----------------------------------------------------------------------
  subsystem_limits = {
    for e in local.all_entries :
    e.name => e.limit
    if e.type == "subsystem"
  }
  subsystem_names = keys(local.subsystem_limits)

  # -----------------------------------------------------------------------
  # 4. TOTAL SYSTEM LIMIT (sum of all apps + all subsystems)
  # -----------------------------------------------------------------------
  total_system_limit = sum(values(merge(local.app_limits, local.subsystem_limits)))

  # -----------------------------------------------------------------------
  # 5. MERGE LOGIC: preserve unmanaged policies
  # -----------------------------------------------------------------------
  managed_policy_names = toset(concat(
    [for app in local.application_names : "${app} - Alert Managed Webhook"],
    [for sub in local.subsystem_names : "${sub} - Subsystem Alert Managed Webhook"]
  ))

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

  # -----------------------------------------------------------------------
  # 6. MANAGED POLICIES — APPLICATION-WISE
  #    Filter on application name; subsystems = null (match all).
  # -----------------------------------------------------------------------
  managed_app_policies = [
    for app in local.application_names : {
      name        = "${app} - Alert Managed Webhook"
      description = "TCO policy to block logs for application '${app}' (limit: ${local.app_limits[app]})"
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
      subsystems = null
    }
  ]

  # -----------------------------------------------------------------------
  # 7. MANAGED POLICIES — SUBSYSTEM-WISE
  #    Filter on subsystem name; applications = null (match all).
  # -----------------------------------------------------------------------
  managed_subsystem_policies = [
    for sub in local.subsystem_names : {
      name        = "${sub} - Subsystem Alert Managed Webhook"
      description = "TCO policy to block logs for subsystem '${sub}' (limit: ${local.subsystem_limits[sub]})"
      enabled = try(
        [for p in data.coralogix_tco_policies_logs.existing.policies : p.enabled
          if p.name == "${sub} - Subsystem Alert Managed Webhook"][0],
        false
      )
      priority     = "block"
      severities   = ["critical", "error", "warning", "info", "debug", "verbose"]
      applications = null
      subsystems = {
        names     = [sub]
        rule_type = "is"
      }
    }
  ]

  # -----------------------------------------------------------------------
  # 8. FINAL MERGED LIST
  #    Order: unmanaged first → app policies → subsystem policies
  # -----------------------------------------------------------------------
  tco_policies_logs = concat(
    local.unmanaged_existing_policies,
    local.managed_app_policies,
    local.managed_subsystem_policies
  )
}