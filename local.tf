locals {
  # Read file and split into non-empty trimmed lines
  application_names = [
    for name in split("\n", trimspace(file("${path.module}/applications.txt"))) :
    trimspace(name)
    if trimspace(name) != ""
  ]

  # Policy Definition
  # Default state: enabled = false (Logs are ALLOWED/Flowing)
  # The alert will flip enabled to TRUE (Logs BLOCKED) when high.
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