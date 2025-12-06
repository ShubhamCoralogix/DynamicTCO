locals {
  # 1. Load the raw file
  raw_file_content = trimspace(file("${path.module}/applications.txt"))

  # 2. Parse into a Map: { "app_name" = limit_number }
  # We split by new lines, then split by comma
  app_limits = {
    for line in split("\n", local.raw_file_content) : 
      trimspace(split(",", line)[0]) => tonumber(trimspace(split(",", line)[1]))
      if length(split(",", line)) >= 2 # Ensure line has name and limit
  }

  # 3. Create the list of names (Keys) to maintain compatibility with other .tf files
  application_names = keys(local.app_limits)

  # 4. Calculate Total System Limit (Sum of all app limits)
  # Useful for the Global Recovery Alert to know what the total "safe" capacity is.
  total_system_limit = sum(values(local.app_limits))

  # Policy Definition (Unchanged logic, but uses the derived application_names list)
  tco_policies_logs = [
    for app in local.application_names : {
      name        = "${app} - Alert Managed Webhook"
      description = "TCO policy to block logs for ${app} when enabled"
      enabled     = false  
      priority    = "block"
      severities  = ["critical", "error", "warning", "info", "debug", "verbose"]
      applications = {
        names     = [app]
        rule_type = "is"
      }
    }
  ]
}